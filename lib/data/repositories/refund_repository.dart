import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// Product returns ("مرتجعات"). Writing a refund requires the refund
/// permission (the DAO reverses the stock quantities and posts the
/// ledger movement). Every refund is audit-logged with its amount.
class RefundRepository {
  RefundRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<RefundRow>> watchRecent({int limit = 50}) =>
      _db.refundDao.watchRecent(limit: limit);

  Future<int> createRefund({
    required int invoiceId,
    required double amount,
    String? reason,
    int? employeeId,
    bool restock = false,
  }) async {
    _permissions.require(_permissions.canRefund, 'تسجيل مرتجع');
    final id = await _db.refundDao.createRefund(
      invoiceId: invoiceId,
      amount: amount,
      reason: reason,
      employeeId: employeeId,
      restock: restock,
    );
    await _auditLog.log(
      action: 'refund_created',
      entityType: 'refund',
      entityId: id,
      newValue: '$amount جنيه',
    );
    return id;
  }
}

final refundRepositoryProvider = Provider<RefundRepository>((ref) {
  return RefundRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final recentRefundsProvider = StreamProvider<List<RefundRow>>((ref) {
  return ref.watch(refundRepositoryProvider).watchRecent();
});