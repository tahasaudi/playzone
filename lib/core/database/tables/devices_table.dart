import 'package:drift/drift.dart';
import 'device_types_table.dart';

/// A single physical device (e.g. "PS5 #01"). customHourlyRate is nullable
/// — when null, the device uses its type's defaultHourlyRate (spec §7,
/// Level 2 pricing). status covers the 5 states from spec §37.
@DataClassName('DeviceRow')
class Devices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)(); // e.g. "#01"
  IntColumn get deviceTypeId =>
      integer().references(DeviceTypes, #id)();
  RealColumn get customHourlyRate => real().nullable()();
  RealColumn get customHourlyRateMulti => real().nullable()();
  // available | active | paused | maintenance | reserved
  TextColumn get status =>
      text().withDefault(const Constant('available'))();
  TextColumn get notes => text().nullable()();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
