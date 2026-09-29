import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/auth/role_provider.dart';
import '../../core/auth/current_employee_provider.dart';

/// Thin wrapper other repositories call after a sensitive write
/// succeeds. Reads the acting role from [currentRoleProvider] so
/// callers never have to pass it explicitly — one less thing for a
/// repository method to get wrong (spec §33: every sensitive operation
/// must be logged).
class AuditLogRepository {
  AuditLogRepository(this._db, this._role);
  final AppDatabase _db;
  final UserRole _role;

  Stream<List<AuditLogRow>> watchRecent({int limit = 100}) =>
      _db.auditLogDao.watchRecent(limit: limit);

  Stream<List<AuditLogRow>> watchFor({
    String? entityType,
    String? action,
    int limit = 200,
  }) =>
      _db.auditLogDao.watchFor(
          entityType: entityType, action: action, limit: limit);

  Future<void> log({
    required String action,
    required String entityType,
    int? entityId,
    String? oldValue,
    String? newValue,
    String? reason,
  }) {
    return _db.auditLogDao.log(
      action: action,
      entityType: entityType,
      entityId: entityId,
      oldValue: oldValue,
      newValue: newValue,
      reason: reason,
      performedByRole: _role.labelAr,
    );
  }
}

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return AuditLogRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(effectiveRoleProvider),
  );
});

final recentAuditLogsProvider = StreamProvider<List<AuditLogRow>>((ref) {
  return ref.watch(auditLogRepositoryProvider).watchRecent();
});
