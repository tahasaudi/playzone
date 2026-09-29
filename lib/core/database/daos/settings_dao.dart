import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/app_settings_table.dart';

part 'settings_dao.g.dart';

/// Key/value settings store — currently holds the PIN that unlocks the
/// protected dashboard metric buttons.
@DriftAccessor(tables: [AppSettings])
class SettingsDao extends DatabaseAccessor<AppDatabase> with _$SettingsDaoMixin {
  SettingsDao(super.db);

  /// Key of the PIN that must be entered before the locked dashboard
  /// buttons reveal their numbers.
  static const lockedAccessPinKey = 'locked_access_pin';

  Stream<Map<String, String>> watchAll() =>
      select(appSettings).watch().map((rows) => {
            for (final r in rows) r.key: r.value ?? '',
          });

  Future<String?> getValue(String key) async {
    final row = await (select(appSettings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setValue(String key, String value) =>
      into(appSettings).insertOnConflictUpdate(AppSettingsCompanion(
        key: Value(key),
        value: Value(value),
        updatedAt: Value(DateTime.now()),
      ));
}