import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/suppliers_table.dart';
import '../tables/products_table.dart';
import '../tables/expenses_table.dart';
import '../tables/accounts_table.dart';
import '../tables/account_entries_table.dart';

part 'supplier_dao.g.dart';

@DriftAccessor(tables: [
  Suppliers,
  Purchases,
  PurchaseItems,
  Products,
  Expenses,
  Accounts,
  AccountEntries,
])
class SupplierDao extends DatabaseAccessor<AppDatabase> with _$SupplierDaoMixin {
  SupplierDao(super.db);

  // ---------------------------------------------------------------- suppliers

  Stream<List<SupplierRow>> watchSuppliers() => (select(suppliers)
        ..where((s) => s.active.equals(true))
        ..orderBy([(s) => OrderingTerm.asc(s.name)]))
      .watch();

  Future<List<SupplierRow>> allSuppliers() => (select(suppliers)
        ..where((s) => s.active.equals(true))
        ..orderBy([(s) => OrderingTerm.asc(s.name)]))
      .get();

  /// The next free supplier number, so a new supplier is always the smallest
  /// unused one. [deleted] and [ignoreId] are excluded so renaming a supplier
  /// keeps its own code and re-adding a deleted one does not collide.
  Future<int> nextSupplierCode({Set<int> deleted = const {}, int? ignoreId}) async {
    final rows = await (select(suppliers)
          ..where((s) =>
              ignoreId == null ? const Constant(true) : s.id.equals(ignoreId).not()))
        .get();
    final taken = <int>{
      for (final r in rows) if (r.code != null) r.code!,
      ...deleted,
    };
    var candidate = 1;
    while (taken.contains(candidate)) {
      candidate++;
    }
    return candidate;
  }

  /// Case-insensitive lookup used to stop two rows being created for the same
  /// shop — "مورد النور" and "مورد النور " must not both exist.
  Future<SupplierRow?> supplierByName(String name) async {
    final target = name.trim().toLowerCase();
    final rows = await select(suppliers).get();
    for (final r in rows) {
      if (r.name.trim().toLowerCase() == target) return r;
    }
    return null;
  }

  Future<int> insertSupplier(SuppliersCompanion entry) =>
      into(suppliers).insert(entry);

  Future<void> updateSupplier(SuppliersCompanion entry) =>
      update(suppliers).replace(entry);

  Future<void> setSupplierActive(int id, bool active) =>
      (update(suppliers)..where((s) => s.id.equals(id))).write(
        SuppliersCompanion(
            active: Value(active), updatedAt: Value(DateTime.now())),
      );

  // ---------------------------------------------------------------- purchases

  Stream<List<PurchaseRow>> watchPurchases() => (select(purchases)
        ..orderBy([
          (p) => OrderingTerm.desc(p.purchaseDate),
          (p) => OrderingTerm.desc(p.id),
        ]))
      .watch();

  Future<List<PurchaseRow>> purchasesBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await select(purchases).get();
    return rows
        .where((r) =>
            !r.purchaseDate.isBefore(from) && r.purchaseDate.isBefore(to))
        .toList();
  }

  Stream<List<PurchaseItemRow>> watchItems(int purchaseId) =>
      (select(purchaseItems)..where((i) => i.purchaseId.equals(purchaseId)))
          .watch();

  Future<List<PurchaseItemRow>> itemsFor(int purchaseId) =>
      (select(purchaseItems)..where((i) => i.purchaseId.equals(purchaseId)))
          .get();

  /// Writes a whole purchase invoice in one transaction: the header, its
  /// lines, the stock each line adds, the product's new cost price, and the
  /// matching expense.
  ///
  /// All of it or none of it. A half-posted purchase would raise stock
  /// without recording the money, or record the money without the stock —
  /// and the café would have no way to tell which.
  Future<int> createPurchase({
    required int supplierId,
    required String supplierName,
    required DateTime purchaseDate,
    required List<PurchaseLine> lines,
    String? note,
    int? employeeId,
  }) {
    return transaction(() async {
      final total = lines.fold<double>(0, (s, l) => s + l.quantity * l.unitCost);

      // The expense is written first so its id can be stored on the header
      // (the ledger posting inside addExpense uses it too).
      final expenseId = await _postExpense(
        amount: total,
        description: 'مشتريات من $supplierName',
        employeeId: employeeId,
      );

      final purchaseId = await into(purchases).insert(PurchasesCompanion.insert(
        supplierId: supplierId,
        supplierName: supplierName,
        purchaseDate: purchaseDate,
        note: Value(note),
        total: Value(total),
        expenseId: Value(expenseId),
        employeeId: Value(employeeId),
      ));

      for (final line in lines) {
        final lineTotal = line.quantity * line.unitCost;
        await into(purchaseItems).insert(PurchaseItemsCompanion.insert(
          purchaseId: purchaseId,
          productId: line.productId,
          productName: line.productName,
          quantity: line.quantity,
          unitCost: line.unitCost,
          lineTotal: Value(lineTotal),
        ));

        // Stock goes UP by the quantity bought, and the cost price moves to
        // what was actually paid this time — both on the same rows the POS
        // and Inventory read, so the change is visible everywhere at once.
        final product = await (select(products)
              ..where((p) => p.id.equals(line.productId)))
            .getSingleOrNull();
        if (product == null) continue;
        await (update(products)..where((p) => p.id.equals(line.productId)))
            .write(ProductsCompanion(
          stockQuantity: Value(product.stockQuantity + line.quantity),
          costPrice: Value(line.unitCost),
          updatedAt: Value(DateTime.now()),
        ));
      }

      return purchaseId;
    });
  }

  /// Deletes a purchase and undoes everything it did: stock comes back down,
  /// the expense (and its ledger entry) goes away.
  ///
  /// The stock reversal is deliberately unconditional — a purchase that was
  /// posted raised stock by exactly these quantities, so taking them back is
  /// the honest inverse. It can drive a product negative if the goods were
  /// already sold, which is the truth worth seeing rather than a number that
  /// quietly hides the problem.
  Future<void> deletePurchase(int purchaseId) {
    return transaction(() async {
      final purchase = await (select(purchases)
            ..where((p) => p.id.equals(purchaseId)))
          .getSingleOrNull();
      if (purchase == null) return;

      final lines = await (select(purchaseItems)
            ..where((i) => i.purchaseId.equals(purchaseId)))
          .get();
      for (final line in lines) {
        final product = await (select(products)
              ..where((p) => p.id.equals(line.productId)))
            .getSingleOrNull();
        if (product == null) continue;
        await (update(products)..where((p) => p.id.equals(line.productId)))
            .write(ProductsCompanion(
          stockQuantity: Value(product.stockQuantity - line.quantity),
          updatedAt: Value(DateTime.now()),
        ));
      }

      await (delete(purchaseItems)
            ..where((i) => i.purchaseId.equals(purchaseId)))
          .go();
      await (delete(purchases)..where((p) => p.id.equals(purchaseId))).go();

      final expenseId = purchase.expenseId;
      if (expenseId != null) {
        await (delete(accountEntries)
              ..where((a) =>
                  a.source.equals('expense') & a.sourceId.equals(expenseId)))
            .go();
        await (delete(expenses)..where((e) => e.id.equals(expenseId))).go();
      }
    });
  }

  /// Writes the purchase to the expenses table and its money to the ledger,
  /// mirroring ExpenseDao.addExpense so a purchase shows up in الحسابات the
  /// same way a hand-typed expense does.
  Future<int> _postExpense({
    required double amount,
    required String description,
    int? employeeId,
  }) async {
    final id = await into(expenses).insert(ExpensesCompanion.insert(
      category: 'مشتريات بضاعة',
      amount: amount,
      description: Value(description),
      employeeId: Value(employeeId),
    ));
    final account = await (select(accounts)
          ..where((a) => a.code.equals('expenses')))
        .getSingleOrNull();
    if (account != null) {
      await into(accountEntries).insert(AccountEntriesCompanion.insert(
        accountId: account.id,
        amount: amount,
        direction: 'out',
        source: 'expense',
        sourceId: Value(id),
        note: Value(description),
      ));
    }
    return id;
  }
}

/// One line of a purchase, as it arrives from the form. A plain value type so
/// the repository and DAO agree on the shape without either importing the
/// other's companion classes.
class PurchaseLine {
  const PurchaseLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitCost,
  });

  final int productId;
  final String productName;
  final int quantity;
  final double unitCost;
}
