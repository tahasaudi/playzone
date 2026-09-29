import 'package:drift/drift.dart';

/// An employee/staff account. Roles are stored as plain text
/// ('admin' | 'shiftSupervisor' | 'cashier') matching UserRole.name so
/// the DB layer stays independent of the UI enum location.
///
/// pinHash is a SHA-256 hash — the raw PIN is NEVER persisted (spec §20:
/// "Never store plain-text PINs").
@DataClassName('EmployeeRow')
class Employees extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withLength(min: 1, max: 20)();
  TextColumn get role => text()(); // admin | shiftSupervisor | cashier
  TextColumn get pinHash => text()();

  /// Partner of the business (شريك): eligible for a profit share, and
  /// their withdrawals (مسحوبات) reduce their share rather than being a
  /// plain debt. Whether the share applies is a per-employee admin call.
  BoolColumn get isPartner => boolean().withDefault(const Constant(false))();

  /// Profit share as a percent 0–100 (شركاء بنص = 50).
  RealColumn get partnerShare => real().nullable()();

  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {phone},
      ];
}
