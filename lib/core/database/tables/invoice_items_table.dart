import 'package:drift/drift.dart';
import 'invoices_table.dart';
import 'products_table.dart';

/// A single line on an invoice. productId is nullable so a "gaming time"
/// line (no product behind it) can share the same table as café product
/// lines — description carries the label either way.
@DataClassName('InvoiceItemRow')
class InvoiceItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  IntColumn get productId => integer().nullable().references(Products, #id)();
  TextColumn get description => text()(); // e.g. "وقت اللعب" or product name
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  RealColumn get unitPrice => real()();
  RealColumn get total => real()();
}
