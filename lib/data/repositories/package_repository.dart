import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/package_dao.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// Packages — spec (packages & offers phase). Packages are pricing
/// configuration, so every write is gated on canChangePrice AND logged
/// (spec §22 + §33). The Dashboard's "بدء بباقة" journey only reads.
class PackageRepository {
  PackageRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<PackageWithType>> watchAll() => _db.packageDao.watchAllWithType();

  Stream<List<PackageWithType>> watchActive() =>
      _db.packageDao.watchActiveWithType();

  Future<int> addPackage({
    required String name,
    required int deviceTypeId,
    required double fixedPrice,
    required int durationMinutes,
  }) async {
    _permissions.require(_permissions.canChangePrice, 'إضافة باقة');
    final id = await _db.packageDao.addPackage(PackagesCompanion.insert(
      name: name,
      deviceTypeId: deviceTypeId,
      fixedPrice: Value(fixedPrice),
      durationMinutes: Value(durationMinutes),
    ));
    await _auditLog.log(
      action: 'package_added',
      entityType: 'package',
      entityId: id,
      newValue: name,
    );
    return id;
  }

  Future<void> updatePackage(PackageRow package) async {
    _permissions.require(_permissions.canChangePrice, 'تعديل باقة');
    await _db.packageDao.updatePackage(package.toCompanion(true));
    await _auditLog.log(
      action: 'package_updated',
      entityType: 'package',
      entityId: package.id,
      newValue: package.name,
    );
  }

  Future<void> deletePackage(int id) async {
    _permissions.require(_permissions.canChangePrice, 'حذف باقة');
    await _db.packageDao.deletePackage(id);
    await _auditLog.log(
      action: 'package_deleted',
      entityType: 'package',
      entityId: id,
    );
  }

  Future<void> renamePackage(int id, String name) async {
    _permissions.require(_permissions.canChangePrice, 'تعديل اسم الباقة');
    await _db.packageDao.renamePackage(id, name);
    await _auditLog.log(
      action: 'renamed',
      entityType: 'package',
      entityId: id,
      newValue: name,
    );
  }
}

final packageRepositoryProvider = Provider<PackageRepository>((ref) {
  return PackageRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final allPackagesProvider = StreamProvider<List<PackageWithType>>((ref) {
  return ref.watch(packageRepositoryProvider).watchAll();
});

/// Sellable packages (active only) — what the package picker shows.
final activePackagesProvider = StreamProvider<List<PackageWithType>>((ref) {
  return ref.watch(packageRepositoryProvider).watchActive();
});