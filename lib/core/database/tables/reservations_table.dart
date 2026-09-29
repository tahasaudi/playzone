import 'package:drift/drift.dart';
import 'customers_table.dart';
import 'devices_table.dart';
import 'employees_table.dart';

/// A device reservation — spec §15. Lifecycle: Pending → Confirmed →
/// Arrived → (Start Session marks it Completed), with Cancelled / NoShow
/// as terminal dead-ends. Overlap detection lives in the repository so
/// every create path gets the same check (UI + business logic).
@DataClassName('ReservationRow')
class Reservations extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get deviceId => integer().references(Devices, #id)();
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime()();

  // Pending, Confirmed, Arrived, Cancelled, NoShow, Completed
  TextColumn get status => text().withDefault(const Constant('Pending'))();

  /// Who booked it — attributed to the employee who created it so a
  /// started session inherits the same employee for revenue reporting.
  IntColumn get employeeId =>
      integer().nullable().references(Employees, #id)();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}