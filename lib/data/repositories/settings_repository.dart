import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/settings_dao.dart';
import '../../core/permissions/pin_hasher.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// App-wide key/value settings. Today that's one thing: the custom PIN
/// that unlocks the protected dashboard metric buttons.
class SettingsRepository {
  SettingsRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<Map<String, String>> watchAll() => _db.settingsDao.watchAll();

  Future<String?> getValue(String key) => _db.settingsDao.getValue(key);

  /// Unrestricted key/value write — used by non-sensitive system
  /// config (e.g. the device→ESP32 IR box map). Sensitive values like
  /// the locked PIN go through dedicated methods with permission checks.
  Future<void> setValue(String key, String value) =>
      _db.settingsDao.setValue(key, value);

  Future<String?> lockedPinHash() =>
      _db.settingsDao.getValue(SettingsDao.lockedAccessPinKey);

  /// Changes the PIN used to unlock the hidden dashboard numbers.
  /// Admin-only: changing the gate is itself a gated action.
  Future<void> changeLockedPin(String newPin) async {
    _permissions.require(_permissions.canEditSettings, 'تغيير رمز الحماية');
    await _db.settingsDao
        .setValue(SettingsDao.lockedAccessPinKey, pinHashFor(newPin));
    await _auditLog.log(
      action: 'locked_pin_changed',
      entityType: 'settings',
    );
  }

  /// Verifies an entered PIN against the stored one (hashed). Callers
  /// show a generic "wrong PIN" failure — never hint at why.
  Future<bool> verifyLockedPin(String pin) async {
    final stored = await lockedPinHash();
    return stored != null && stored == pinHashFor(pin);
  }
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

/// Streams the whole settings map; widgets react to PIN changes live.
final appSettingsProvider = StreamProvider<Map<String, String>>((ref) {
  return ref.watch(settingsRepositoryProvider).watchAll();
});