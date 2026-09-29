import 'package:drift/drift.dart';
import 'employees_table.dart';

/// A single attendance record (حضور وانصراف): check-in punches a row,
/// check-out fills it in. An employee has at most one open record at a
/// time (enforced by the repository).
@DataClassName('EmployeeAttendanceRow')
class EmployeeAttendance extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  DateTimeColumn get checkIn => dateTime()();
  DateTimeColumn get checkOut => dateTime().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}