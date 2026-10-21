import 'package:drift/drift.dart';
import 'employees_table.dart';
import 'products_table.dart';

/// A supplier ("مورد") the café buys stock from.
///
/// Soft-delete only (via [active]), for the same reason products are: a
/// purchase invoice that names this supplier must keep a live row to point
/// at, so the history of "I bought this from whom" never develops a hole.
/// Deactivating hides it from the picker without erasing anything.
@DataClassName('SupplierRow')
class Suppliers extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// The supplier's number, shown on screen as كود المورد.
  ///
  /// Assigned automatically by the DAO as "the next free number" rather than
  /// by SQLite's rowid, because [id] is shared with purchase rows and would
  /// skip numbers as those come and go — a supplier list numbered 1, 2, 7 is
  /// harder to scan than one numbered 1, 2, 3. Nullable only so an older row
  /// created before this column existed still reads; the DAO fills it in.
  ///
  /// Deliberately NOT a `unique()` column: SQLite refuses to add a UNIQUE
  /// column to an existing table (`ALTER TABLE ... ADD COLUMN ... UNIQUE`
  /// is a hard error), which is what stopped the v16 upgrade from running at
  /// all and left the program on a white screen. Uniqueness is guaranteed by
  /// [SupplierDao.nextSupplierCode] instead, which is where the number is
  /// decided anyway.
  IntColumn get code => integer().nullable()();

  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().nullable()();
  TextColumn get note => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}

/// One purchase invoice from a supplier ("فاتورة شراء").
///
/// This is the record the café was missing: who the goods came from, on what
/// day, and for how much. Its [total] is the sum of its [PurchaseItems], and
/// posting it both raises product stock and writes an expense — so the money
/// shows up in الحسابات without anyone re-typing it.
@DataClassName('PurchaseRow')
class Purchases extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get supplierId => integer().references(Suppliers, #id)();

  /// Snapshot of the supplier's name at the time of purchase. The row above
  /// stays live, but this keeps the printed invoice readable even if the
  /// supplier is later renamed.
  TextColumn get supplierName => text()();

  /// The day the goods arrived. Separate from [createdAt] because it is the
  /// date the cashier typed, and a purchase is often entered a day late.
  DateTimeColumn get purchaseDate => dateTime()();

  TextColumn get note => text().nullable()();
  RealColumn get total => real().withDefault(const Constant(0))();

  /// The expense this purchase posted (nullable: a purchase made before an
  /// expense row could be written, or one deliberately not treated as an
  /// expense, must not break the list).
  IntColumn get expenseId => integer().nullable()();

  IntColumn get employeeId =>
      integer().nullable().references(Employees, #id)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

/// One line of a purchase invoice: which product, how many, at what cost.
///
/// [productName] is a snapshot for the same reason the supplier's is — the
/// invoice must still read correctly after a product is renamed or hidden.
@DataClassName('PurchaseItemRow')
class PurchaseItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get purchaseId => integer().references(Purchases, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();

  /// What the café paid per unit on this invoice. Kept here, not read back
  /// from the product, so the price on an old invoice stays true even after
  /// the cost price is updated by a more recent purchase.
  RealColumn get unitCost => real()();
  RealColumn get lineTotal => real().withDefault(const Constant(0))();
}
