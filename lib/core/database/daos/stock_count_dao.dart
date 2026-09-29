import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/stock_counts_table.dart';
import '../tables/products_table.dart';

part 'stock_count_dao.g.dart';

/// Periodic inventory ("جرد دوري"). A count session snapshots every
/// product's system quantity; the cashier enters the counted quantity
/// per product (difference computed automatically), then applying the
/// count writes the counted values back into inventory.
@DriftAccessor(tables: [StockCounts, StockCountItems, Products])
class StockCountDao extends DatabaseAccessor<AppDatabase>
    with _$StockCountDaoMixin {
  StockCountDao(super.db);

  Stream<List<StockCountRow>> watchRecent({int limit = 30}) =>
      (select(stockCounts)
            ..orderBy([(s) => OrderingTerm.desc(s.createdAt)])
            ..limit(limit))
          .watch();

  Stream<List<StockCountItemRow>> watchItems(int countId) =>
      (select(stockCountItems)
            ..where((i) => i.stockCountId.equals(countId)))
          .watch();

  /// Opens a new count: header + one row per active product. Rows start
  /// UNCOUNTED (counted = false, difference = 0) — a row only becomes
  /// "counted" when the cashier actually types a number for it.
  Future<int> createCount({int? employeeId, String? note}) {
    return transaction(() async {
      final countId = await into(stockCounts).insert(StockCountsCompanion.insert(
        employeeId: Value(employeeId),
        note: Value(note),
      ));
      final productRows = await (select(products)
            ..where((p) => p.active.equals(true)))
          .get();
      for (final p in productRows) {
        await into(stockCountItems).insert(
            StockCountItemsCompanion.insert(
          stockCountId: countId,
          productId: p.id,
          productName: p.name,
          systemQty: p.stockQuantity,
          countedQty: const Value(0),
          counted: const Value(false),
        ));
      }
      return countId;
    });
  }

  Future<void> setCounted(int countId, int productId, int counted) async {
    final item = await (select(stockCountItems)
          ..where((i) =>
              i.stockCountId.equals(countId) & i.productId.equals(productId)))
        .getSingleOrNull();
    if (item == null) return;
    await (update(stockCountItems)..where((i) => i.id.equals(item.id)))
        .write(StockCountItemsCompanion(
      countedQty: Value(counted),
      difference: Value(counted - item.systemQty),
      counted: const Value(true),
    ));
  }

  /// Writes the counted quantities back into Products and marks the
  /// count as applied (with audit performed by the repository).
  ///
  /// ONLY rows the cashier actually counted are written back. Every other
  /// product keeps its stored stock untouched — counting one item can
  /// never zero out the rest of the café.
  Future<int> applyCount(int countId) {
    return transaction(() async {
      final items = await (select(stockCountItems)
            ..where((i) =>
                i.stockCountId.equals(countId) & i.counted.equals(true)))
          .get();
      for (final item in items) {
        await (update(products)..where((p) => p.id.equals(item.productId)))
            .write(ProductsCompanion(
          stockQuantity: Value(item.countedQty),
          updatedAt: Value(DateTime.now()),
        ));
      }
      await (update(stockCounts)..where((s) => s.id.equals(countId)))
          .write(StockCountsCompanion(
        applied: const Value(true),
        appliedAt: Value(DateTime.now()),
      ));
      return items.length;
    });
  }
}