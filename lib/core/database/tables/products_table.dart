import 'package:drift/drift.dart';
import 'categories_table.dart';

/// Café product — spec §17. Soft-delete only (via `active`): a product
/// referenced by historical invoices must never be hard-deleted.
@DataClassName('ProductRow')
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get categoryId => integer().references(Categories, #id)();
  TextColumn get sku => text().nullable()();
  TextColumn get barcode => text().nullable()();
  RealColumn get costPrice => real().withDefault(const Constant(0))();
  RealColumn get sellingPrice => real().withDefault(const Constant(0))();
  IntColumn get stockQuantity => integer().withDefault(const Constant(0))();
  IntColumn get minimumStock => integer().withDefault(const Constant(5))();
  IntColumn get maximumStock => integer().nullable()();
  TextColumn get unit => text().withDefault(const Constant('قطعة'))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
