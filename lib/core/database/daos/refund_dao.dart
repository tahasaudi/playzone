import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/refunds_table.dart';
import '../tables/invoices_table.dart';
import '../tables/invoice_items_table.dart';
import '../tables/products_table.dart';
import '../tables/accounts_table.dart';
import '../tables/account_entries_table.dart';

part 'refund_dao.g.dart';

/// Product returns ("مرتجعات"). A refund records the money given back,
/// optionally returns the purchased quantities into stock, and posts the
/// movement to the refunds account so the ledger stays in balance.
@DriftAccessor(tables: [Refunds, Invoices, InvoiceItems, Products, Accounts, AccountEntries])
class RefundDao extends DatabaseAccessor<AppDatabase> with _$RefundDaoMixin {
  RefundDao(super.db);

  Stream<List<RefundRow>> watchRecent({int limit = 50}) =>
(select(refunds)
              ..orderBy([(r) => OrderingTerm.desc(r.createdAt)])
              ..limit(limit))
          .watch();

  /// One-shot ranged read (non-stream) — partnership/profit math.
  Future<List<RefundRow>> getBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await select(refunds).get();
    return rows
        .where((r) =>
            !r.createdAt.isBefore(from) && r.createdAt.isBefore(to))
        .toList();
  }

  /// Creates the refund, optionally restocking the original product
  /// lines, and posts the ledger movement to the refunds account.
  Future<int> createRefund({
    required int invoiceId,
    required double amount,
    String? reason,
    int? employeeId,
    bool restock = false,
  }) {
    return transaction(() async {
      final refundId = await into(refunds).insert(RefundsCompanion.insert(
        invoiceId: invoiceId,
        amount: amount,
        reason: Value(reason),
        employeeId: Value(employeeId),
        restocked: Value(restock),
      ));

      if (restock) {
        final items = await (select(invoiceItems)
              ..where((i) => i.invoiceId.equals(invoiceId)))
            .get();
        for (final item in items) {
          if (item.productId == null) continue;
          final product = await (select(products)
                ..where((p) => p.id.equals(item.productId!)))
              .getSingleOrNull();
          if (product == null) continue;
          await (update(products)..where((p) => p.id.equals(product.id)))
              .write(ProductsCompanion(
            stockQuantity: Value(product.stockQuantity + item.quantity),
            updatedAt: Value(DateTime.now()),
          ));
        }
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