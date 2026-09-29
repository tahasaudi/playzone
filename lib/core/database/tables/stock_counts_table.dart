import 'package:drift/drift.dart';
import 'products_table.dart';
import 'employees_table.dart';

/// A periodic stock-count session ("جرد دوري"): a header + one row per
/// product snapshotting the system quantity against the counted one.
/// Until [applied] is true the differences are just a report; applying
/// the count writes the counted quantities back to Products.
@DataClassName('StockCountRow')
class StockCounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId =>
      integer().nullable().references(Employees, #id)();
  TextColumn get note => text().nullable()();
  BoolColumn get applied => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get appliedAt => dateTime().nullable()();
}

@DataClassName('StockCountItemRow')
class StockCountItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get stockCountId => integer().references(StockCounts, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  TextColumn get productName => text()(); // snapshot of the name
  IntColumn get systemQty => integer()();
  IntColumn get countedQty => integer().withDefault(const Constant(0))();
  IntColumn get difference => integer().withDefault(const Constant(0))();

  /// True only once the cashier actually typed a number for THIS product.
  /// [applyCount] writes back only the rows flagged here, so counting one
  /// product can never zero out the stock of everything else (the old
  /// code wrote countedQty for every row, and every untouched row was 0).
  BoolColumn get counted => boolean().withDefault(const Constant(false))();
}