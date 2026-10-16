import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/refund_dao.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';
import 'invoice_repository.dart';

/// Product returns ("مرتجعات"). Writing a refund requires the refund
/// permission (the DAO reverses the stock quantities and posts the
/// ledger movement). Every refund is audit-logged with its amount.
class RefundRepository {
  RefundRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<RefundRow>> watchRecent({int limit = 200}) =>
      _db.refundDao.watchRecent(limit: limit);

  Stream<List<RefundRow>> watchToday() => _db.refundDao.watchToday();

  Stream<List<RefundRow>> watchBetween({
    required DateTime from,
    required DateTime to,
  }) =>
      _db.refundDao.watchBetween(from: from, to: to);

  /// Units already returned per invoice line — lets the refund dialog cap the
  /// quantity at what is left and hide fully-returned lines.
  Future<Map<int, int>> refundedQuantities(int invoiceId) =>
      _db.refundDao.refundedQuantities(invoiceId);

  /// The returned lines of one refund, for the refund report.
  Stream<List<RefundLineView>> watchRefundLines(int refundId) =>
      _db.refundDao.watchRefundLines(refundId);

  Future<int> createRefund({
    required int invoiceId,
    required double amount,
    List<RefundLineInput> lines = const [],
    String? reason,
    int? employeeId,
    bool restock = true,
  }) async {
    _permissions.require(_permissions.canRefund, 'تسجيل مرتجع');
    final id = await _db.refundDao.createRefund(
      invoiceId: invoiceId,
      amount: amount,
      lines: lines,
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

/// Today's refunds — the shift drawer and the protected screen subtract these.
final todayRefundsProvider = StreamProvider<List<RefundRow>>((ref) {
  return ref.watch(refundRepositoryProvider).watchToday();
});

/// Refunds inside the currently-selected report window (reportPeriodProvider),
/// so the reports' profit subtracts returns alongside expenses.
final refundsInRangeProvider = StreamProvider<List<RefundRow>>((ref) {
  final range = currentReportRange(ref.watch(reportPeriodProvider));
  return ref
      .watch(refundRepositoryProvider)
      .watchBetween(from: range.from, to: range.to);
});

/// Total refunded per invoice — the sum of every refund written against it.
/// Derived from [recentRefundsProvider] so the invoice list and the report
/// always agree on how much is left on a bill.
final refundedTotalsProvider = Provider<Map<int, double>>((ref) {
  final refunds = ref.watch(recentRefundsProvider).valueOrNull ?? const [];
  final totals = <int, double>{};
  for (final r in refunds) {
    totals[r.invoiceId] = (totals[r.invoiceId] ?? 0) + r.amount;
  }
  return totals;
});

/// Units already returned per invoice line, keyed by invoice id.
final refundedQuantitiesProvider =
    FutureProvider.family<Map<int, int>, int>((ref, invoiceId) {
  return ref.watch(refundRepositoryProvider).refundedQuantities(invoiceId);
});

/// The returned lines of one refund, for the refund report.
final refundLinesProvider =
    StreamProvider.family<List<RefundLineView>, int>((ref, refundId) {
  return ref.watch(refundRepositoryProvider).watchRefundLines(refundId);
});