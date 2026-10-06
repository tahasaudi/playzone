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

  /// When this particular thing was asked for, which is not when it was
  /// billed. A café order is rung up when the customer orders it and folded
  /// into the session's one bill minutes or hours later — and once the drafts
  /// are folded away, the bill's own createdAt is all that is left, so the
  /// answer to "امتى طلب المياه" would become "at checkout".
  ///
  /// Null on rows written before v10; those fall back to their invoice's
  /// time, which is the truth the app used to tell anyway.
  DateTimeColumn get createdAt => dateTime().nullable()();
}
