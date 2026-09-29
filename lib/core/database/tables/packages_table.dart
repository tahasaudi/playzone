import 'package:drift/drift.dart';
import 'device_types_table.dart';

/// A fixed-price gaming package — e.g. "باقة شباب 3 ساعات PS5 بـ 75 ج".
/// Starting a session from a package freezes billing at [fixedPrice]
/// instead of the per-second accrual; [durationMinutes] is informational
/// (what the price buys), shown on the picker so staff can sell it fast.
@DataClassName('PackageRow')
class Packages extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get deviceTypeId => integer().references(DeviceTypes, #id)();
  RealColumn get fixedPrice => real().withDefault(const Constant(0))();
  IntColumn get durationMinutes =>
      integer().withDefault(const Constant(60))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}