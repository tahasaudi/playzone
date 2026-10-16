import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/refunds_table.dart';
import '../tables/refund_items_table.dart';
import '../tables/invoice_items_table.dart';
import '../tables/products_table.dart';
import '../tables/accounts_table.dart';
import '../tables/account_entries_table.dart';

part 'refund_dao.g.dart';

/// One line the cashier chose to return: which invoice line, how many units,
/// at what unit price. Gathering it here (instead of re-reading every line of
/// the invoice) is what makes "أرجّع منتج لوحده" possible.
class RefundLineInput {
  const RefundLineInput({
    required this.invoiceItemId,
    required this.quantity,
    required this.unitPrice,
    this.productId,
  });

  final int invoiceItemId;
  final int quantity;
  final double unitPrice;

  /// Null for a "وقت اللعب" line — a monetary return with nothing to restock.
  final int? productId;

  double get total => unitPrice * quantity;
}

/// A returned line as the report shows it: the invoice line's own label plus
/// the quantity and money that came back.
class RefundLineView {
  const RefundLineView({
    required this.description,
    required this.quantity,
    required this.amount,
  });
  final String description;
  final int quantity;
  final double amount;
}

/// Product returns ("مرتجعات"). Writing a refund requires the refund
/// permission; the DAO restocks the selected product lines and posts the
/// ledger movement.
@DriftAccessor(
    tables: [Refunds, RefundItems, InvoiceItems, Products, Accounts, AccountEntries])
class RefundDao extends DatabaseAccessor<AppDatabase> with _$RefundDaoMixin {
  RefundDao(super.db);

  Stream<List<RefundRow>> watchRecent({int limit = 50}) =>
      (select(refunds)
            ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
            ..limit(limit))
          .watch();

  /// Refunds inside [from]..[to] — feeds the period reports' profit math
  /// (a returned item is money out, so it has to be subtracted with expenses).
  Stream<List<RefundRow>> watchBetween({
    required DateTime from,
    required DateTime to,
  }) =>
      (select(refunds)
            ..where((r) =>
                r.createdAt.isBiggerOrEqualValue(from) &
                r.createdAt.isSmallerThanValue(to)))
          .watch();

  /// Today's refunds — the shift-close drawer math and the protected screen.
  Stream<List<RefundRow>> watchToday() {
    return select(refunds).watch().map((rows) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      return rows.where((r) => !r.createdAt.isBefore(startOfDay)).toList();
    });
  }

  /// The lines that came back on one refund, labelled with the invoice line's
  /// own description (product name, or "وقت اللعب").
  Stream<List<RefundLineView>> watchRefundLines(int refundId) {
    final query = select(refundItems).join([
      leftOuterJoin(
          invoiceItems, invoiceItems.id.equalsExp(refundItems.invoiceItemId)),
    ])
      ..where(refundItems.refundId.equals(refundId));
    return query.watch().map((rows) => rows.map((r) {
          final line = r.readTable(refundItems);
          final item = r.readTableOrNull(invoiceItems);
          return RefundLineView(
            description: item?.description ?? 'بند #${line.invoiceItemId}',
            quantity: line.quantity,
            amount: line.amount,
          );
        }).toList());
  }

  /// How many units of each invoice line have already been returned.
  ///
  /// Joins [refundItems] back to [refunds] so an invoice's whole refund
  /// history answers "اترجّع منه كام؟" in one read — which is what stops the
  /// same bottle being refunded twice.
  Future<Map<int, int>> refundedQuantities(int invoiceId) async {
    final query = select(refundItems).join([
      innerJoin(refunds, refunds.id.equalsExp(refundItems.refundId)),
    ])
      ..where(refunds.invoiceId.equals(invoiceId));
    final rows = await query.get();
    final map = <int, int>{};
    for (final r in rows) {
      final item = r.readTable(refundItems);
      map[item.invoiceItemId] = (map[item.invoiceItemId] ?? 0) + item.quantity;
    }
    return map;
  }

  /// Every refund created in [from]..[to] — partnership/profit math.
  Future<List<RefundRow>> getBetween({
    required DateTime from,
    required DateTime to,
  }) =>
      (select(refunds)
            ..where((r) =>
                r.createdAt.isBiggerOrEqualValue(from) &
                r.createdAt.isSmallerThanValue(to)))
          .get();

  /// Creates the refund, records the returned lines, optionally restocks the
  /// selected product lines, and posts the ledger movement to the refunds
  /// account.
  Future<int> createRefund({
    required int invoiceId,
    required double amount,
    List<RefundLineInput> lines = const [],
    String? reason,
    int? employeeId,
    bool restock = true,
  }) {
    return transaction(() async {
      final refundId = await into(refunds).insert(RefundsCompanion.insert(
        invoiceId: invoiceId,
        amount: amount,
        reason: Value(reason),
        employeeId: Value(employeeId),
        restocked: Value(restock && lines.any((l) => l.productId != null)),
      ));

      for (final line in lines) {
        await into(refundItems).insert(RefundItemsCompanion.insert(
          refundId: refundId,
          invoiceItemId: line.invoiceItemId,
          quantity: line.quantity,
          amount: Value(line.total),
        ));

        if (!restock || line.productId == null) continue;
        final product = await (select(products)
              ..where((p) => p.id.equals(line.productId!)))
            .getSingleOrNull();
        if (product == null) continue;
        await (update(products)..where((p) => p.id.equals(product.id)))
            .write(ProductsCompanion(
          stockQuantity: Value(product.stockQuantity + line.quantity),
          updatedAt: Value(DateTime.now()),
        ));
      }

      final refundAccount =
          await (select(accounts)..where((a) => a.code.equals('refunds')))
              .getSingleOrNull();
      if (refundAccount != null) {
        await into(accountEntries).insert(AccountEntriesCompanion.insert(
          accountId: refundAccount.id,
          amount: amount,
          direction: 'out',
          source: 'refund',
          sourceId: Value(refundId),
          note: Value(reason),
        ));
      }

      return refundId;
    });
  }
}
