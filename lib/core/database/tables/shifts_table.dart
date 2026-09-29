import 'package:drift/drift.dart';
import 'employees_table.dart';

/// A shift-close snapshot. This is a simplified version of full shift
/// management (spec §27-28): closing a shift records opening cash,
/// what the system expects in the register, and what was actually
/// counted — no separate "open shift" step is required yet, so this
/// covers the "close the shift" icon on the Dashboard without blocking
/// on the fuller open/close workflow (a later addition).
@DataClassName('ShiftRow')
class Shifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId =>
      integer().nullable().references(Employees, #id)();
  DateTimeColumn get openedAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get closedAt => dateTime().withDefault(currentDateAndTime)();
  RealColumn get openingCash => real().withDefault(const Constant(0))();
  RealColumn get expectedCash => real().withDefault(const Constant(0))();
  RealColumn get actualCash => real().withDefault(const Constant(0))();
  RealColumn get difference => real().withDefault(const Constant(0))();
  TextColumn get notes => text().nullable()();
}
