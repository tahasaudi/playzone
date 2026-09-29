import 'package:drift/drift.dart';
import 'invoices_table.dart';
import 'employees_table.dart';

/// A product return against an existing invoice. The refund amount is
/// typically ≤ the invoice total; selected product lines are restocked
/// back into inventory (spec-driven) and the movement is posted to the
/// refunds account + written to the audit log.
@DataClassName('RefundRow')
class Refunds extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get invoiceId => integer().references(Invoices, #id)();
  RealColumn get amount => real()();
  RealColumn get quantity => real().withDefault(const Constant(0))();
  TextColumn get reason => text().nullable()();
  IntColumn get employeeId =>
      integer().nullable().references(Employees, #id)();
  BoolColumn get restocked => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}