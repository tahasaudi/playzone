import 'package:drift/drift.dart';
import 'employees_table.dart';

/// An expense entry — spec §29. Profit anywhere in the app is computed
/// as revenue minus the sum of expenses in the same period, never
/// revenue alone.
@DataClassName('ExpenseRow')
class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  TextColumn get description => text().nullable()();
  IntColumn get employeeId =>
      integer().nullable().references(Employees, #id)();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
