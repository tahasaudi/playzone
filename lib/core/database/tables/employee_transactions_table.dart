import 'package:drift/drift.dart';
import 'employees_table.dart';

/// A money movement on an employee's personal account:
/// kind = 'withdraw' (مسحوبات/سلفة) or 'repayment' (سداد يرجع للدرج).
///
/// For partners the net (withdrawals − repayments) is deducted from
/// their profit share at the partnership ledger; for non-partners it's
/// simply a tracked debt against the employee.
@DataClassName('EmployeeTransactionRow')
class EmployeeTransactions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  // withdraw | repayment
  TextColumn get kind => text()();
  RealColumn get amount => real()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}