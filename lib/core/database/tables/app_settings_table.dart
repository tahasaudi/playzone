import 'package:drift/drift.dart';

/// Generic key/value settings store (one row per setting). Used for
/// app-wide preferences that don't deserve their own table — currently
/// the password that unlocks the protected dashboard metric buttons.
@DataClassName('AppSettingRow')
class AppSettings extends Table {
  TextColumn get key => text()();
  TextColumn get value => text().nullable()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {key};
}
