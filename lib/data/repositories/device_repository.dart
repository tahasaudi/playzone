import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/device_dao.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';
import 'product_repository.dart' show ProductValidationException;

/// Device management — spec §37 + pricing spec §7-8.
///
/// Permission checks live HERE, not just in the UI (spec §22:
/// "UI restrictions are NOT enough. Business logic must also validate
/// permissions."). If a widget somehow calls setDeviceRate without the
/// sidebar having blocked it, this still throws.
class DeviceRepository {
  DeviceRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<DeviceWithType>> watchAllWithType() =>
      _db.deviceDao.watchAllWithType();

  Future<List<DeviceTypeRow>> allTypes() => _db.deviceDao.allTypes();

  Future<void> updateStatus(int deviceId, String status) =>
      _db.deviceDao.updateStatus(deviceId, status);

  /// Cost for a session so far, billed per minute — spec §8 formula.
  /// (hourlyRate / 60) * elapsedMinutes, never rounded up to a full hour.
  double costForMinutes(DeviceWithType device, double elapsedMinutes) {
    return (device.effectiveHourlyRate / 60) * elapsedMinutes;
  }

  /// Sets a per-device custom hourly rate override. Throws
  /// [PermissionDeniedException] if the current role can't change
  /// pricing — enforced here even though the Settings screen already
  /// hides this from unauthorized roles. Logs the change (spec §33).
  Future<void> setDeviceRate(int deviceId, double? rate) async {
    _permissions.require(_permissions.canChangePrice, 'تغيير سعر الجهاز');
    await _db.deviceDao.setCustomRate(deviceId, rate);
    await _auditLog.log(
      action: 'price_changed',
      entityType: 'device',
      entityId: deviceId,
      newValue: rate?.toString() ?? 'افتراضي',
    );
  }

  Future<void> setTypeDefaultRate(int typeId, double rate) async {
    _permissions.require(
        _permissions.canChangePrice, 'تغيير السعر الافتراضي للنوع');
    await _db.deviceDao.setTypeDefaultRate(typeId, rate);
    await _auditLog.log(
      action: 'price_changed',
      entityType: 'device_type',
      entityId: typeId,
      newValue: rate.toString(),
    );
  }

  /// Per-device custom "مالتي" (multi-player) rate — same guards/logging.
  Future<void> setDeviceRateMulti(int deviceId, double? rate) async {
    _permissions.require(
        _permissions.canChangePrice, 'تغيير سعر الجهاز (مالتي)');
    await _db.deviceDao.setCustomRateMulti(deviceId, rate);
    await _auditLog.log(
      action: 'price_changed',
      entityType: 'device',
      entityId: deviceId,
      newValue: 'multi: ${rate?.toString() ?? 'افتراضي'}',
    );
  }

  /// Default "مالتي" rate for a device TYPE — same guards/logging.
  Future<void> setTypeDefaultRateMulti(int typeId, double rate) async {
    _permissions.require(
        _permissions.canChangePrice, 'تغيير السعر الافتراضي (مالتي)');
    await _db.deviceDao.setTypeDefaultRateMulti(typeId, rate);
    await _auditLog.log(
      action: 'price_changed',
      entityType: 'device_type',
      entityId: typeId,
      newValue: 'multi: $rate',
    );
  }

  Future<int> addDevice({
    required String name,
    required int deviceTypeId,
  }) {
    return _db.deviceDao.insertDevice(DevicesCompanion.insert(
      name: name,
      deviceTypeId: deviceTypeId,
    ));
  }

  Future<void> renameDevice(int id, String name) async {
    _permissions.require(_permissions.canChangePrice, 'تغيير اسم الجهاز');
    await _db.deviceDao.renameDevice(id, name);
    await _auditLog.log(
      action: 'renamed',
      entityType: 'device',
      entityId: id,
      newValue: name,
    );
  }

  Future<void> renameType(int id, String name) async {
    _permissions.require(_permissions.canChangePrice, 'تغيير اسم نوع الجهاز');
    await _db.deviceDao.renameType(id, name);
    await _auditLog.log(
      action: 'renamed',
      entityType: 'device_type',
      entityId: id,
      newValue: name,
    );
  }

  /// Only a type nothing points at can go — machines would vanish from the
  /// roster join and packages would lose the scope they quote otherwise.
  /// Same empty-slot rule as category deletion, same friendly Arabic error.
  Future<void> deleteType(DeviceTypeRow type) async {
    _permissions.require(_permissions.canChangePrice, 'حذف نوع جهاز');
    final devices = await _db.deviceDao.countDevicesInType(type.id);
    final packages = await _db.deviceDao.countPackagesInType(type.id);
    if (devices > 0 || packages > 0) {
      final blockers = <String>[
        if (devices > 0) '$devices أجهزة',
        if (packages > 0) '$packages باقات',
      ];
      throw ProductValidationException(
          'مينفعش تحذف النوع لوجود ${blockers.join(' و')} عليه — حوّلهم أو احذفهم الأول');
    }
    await _db.deviceDao.deleteType(type.id);
    await _auditLog.log(
      action: 'device_type_deleted',
      entityType: 'device_type',
      entityId: type.id,
      oldValue: type.name,
    );
  }

  /// Re-classifies a device to another type. Returns false when a session
  /// is running on it — the caller shows the reason.
  Future<bool> setDeviceType(
      int deviceId, int deviceTypeId, String typeName) async {
    _permissions.require(_permissions.canChangePrice, 'تغيير نوع الجهاز');
    final ok = await _db.deviceDao.setDeviceType(deviceId, deviceTypeId);
    if (ok) {
      await _auditLog.log(
        action: 'device_type_changed',
        entityType: 'device',
        entityId: deviceId,
        newValue: typeName,
      );
    }
    return ok;
  }

  /// Creates a new device type (e.g. "بلياردو") with its default rates.
  Future<int> addType({
    required String name,
    required double singleRate,
    required double multiRate,
  }) async {
    _permissions.require(_permissions.canChangePrice, 'إضافة نوع جهاز');
    final clean = name.trim();
    if (clean.isEmpty) {
      throw ProductValidationException('اسم النوع مطلوب');
    }
    return _db.deviceDao.insertType(DeviceTypesCompanion.insert(
      name: clean,
      defaultHourlyRate: Value(singleRate),
      defaultHourlyRateMulti: Value(multiRate),
    ));
  }

  /// Soft-delete: hides the device from the roster while keeping its
  /// history intact.
  Future<void> deleteDevice(int id) async {
    _permissions.require(_permissions.canEditSettings, 'حذف جهاز');
    await _db.deviceDao.deactivateDevice(id);
    await _auditLog.log(
      action: 'device_deleted',
      entityType: 'device',
      entityId: id,
    );
  }
}

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  return DeviceRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final devicesWithTypeProvider = StreamProvider<List<DeviceWithType>>((ref) {
  return ref.watch(deviceRepositoryProvider).watchAllWithType();
});

/// All device TYPES (not devices) — used by the package form to pick
/// which type a fixed-price package applies to.
final deviceTypesProvider = FutureProvider<List<DeviceTypeRow>>((ref) {
  return ref.watch(deviceRepositoryProvider).allTypes();
});
