import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// Periodic inventory ("جرد دوري"). Opening and applying a count both
/// require the stock-count permission; applying writes the counted
/// quantities into inventory, so it is audit-logged with the mismatch
/// summary.
class StockCountRepository {
  StockCountRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<StockCountRow>> watchRecent({int limit = 30}) =>
      _db.stockCountDao.watchRecent(limit: limit);

  Stream<List<StockCountItemRow>> watchItems(int countId) =>
      _db.stockCountDao.watchItems(countId);

  Future<int> createCount({int? employeeId, String? note}) async {
    _permissions.require(_permissions.canStockCount, 'بدء جرد');
    return _db.stockCountDao.createCount(employeeId: employeeId, note: note);
  }

  Future<void> setCounted(int countId, int productId, int counted) async {
    _permissions.require(_permissions.canStockCount, 'تسجيل كمية الجرد');
    return _db.stockCountDao.setCounted(countId, productId, counted);
  }

  /// Applies ONLY the products that were actually counted; every other
  /// product keeps its stored quantity. Returns how many products moved.
  Future<int> applyCount(int countId) async {
    _permissions.require(_permissions.canAdjustStock, 'اعتماد الجرد');
    final applied = await _db.stockCountDao.applyCount(countId);
    await _auditLog.log(
      action: 'stock_count_applied',
      entityType: 'stock_count',
      entityId: countId,
      newValue: '$applied منتج',
    );
    return applied;
  }
}

final stockCountRepositoryProvider = Provider<StockCountRepository>((ref) {
  return StockCountRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final recentStockCountsProvider = StreamProvider<List<StockCountRow>>((ref) {
  return ref.watch(stockCountRepositoryProvider).watchRecent();
});