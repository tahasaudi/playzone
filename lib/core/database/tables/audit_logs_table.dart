import 'package:drift/drift.dart';

/// An append-only record of a sensitive operation — spec §33. There is
/// deliberately no update/delete DAO method for this table: audit logs
/// must never be editable from the normal UI.
///
/// performedByRole (not an employee FK) because there's no real login
/// yet — only the temporary role switcher. Once PIN login exists, add
/// an employeeId column and keep performedByRole as a readable fallback.
@DataClassName('AuditLogRow')
class AuditLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get action => text()(); // e.g. "price_changed", "stock_adjusted"
  TextColumn get entityType => text()(); // e.g. "device", "product", "employee"
  IntColumn get entityId => integer().nullable()();
  TextColumn get oldValue => text().nullable()();
  TextColumn get newValue => text().nullable()();
  TextColumn get reason => text().nullable()();
  TextColumn get performedByRole => text()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
