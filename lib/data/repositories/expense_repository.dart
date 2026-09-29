import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// Expenses — spec §16. Writes are admin/config-gated (an expense is a
/// money movement: deleting/renaming one is sensitive) and audit-logged.
class ExpenseRepository {
  ExpenseRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<ExpenseRow>> watchAll() => _db.expenseDao.watchAll();
  Stream<List<ExpenseRow>> watchToday() => _db.expenseDao.watchToday();
  Stream<List<ExpenseRow>> watchByCategory(String category) =>
      _db.expenseDao.watchByCategory(category);

  Future<int> addExpense({
    required String category,
    required double amount,
    String? description,
    int? employeeId,
  }) async {
    _permissions.require(_permissions.canChangePrice, 'تسجيل مصروف');
    final id = await _db.expenseDao.addExpense(
      category: category,
      amount: amount,
      description: description,
      employeeId: employeeId,
    );
    await _auditLog.log(
      action: 'expense_added',
      entityType: 'expense',
      entityId: id,
      newValue: '$category - $amount',
    );
    return id;
  }

  Future<void> deleteExpense(int id) async {
    _permissions.require(_permissions.canEditSettings, 'حذف مصروف');
    await _db.expenseDao.deleteExpense(id);
    await _auditLog.log(
      action: 'expense_deleted',
      entityType: 'expense',
      entityId: id,
    );
  }

  Future<void> updateCategory(int id, String category) async {
    _permissions.require(_permissions.canChangePrice, 'تغيير تصنيف المصروف');
    await _db.expenseDao.updateCategory(id, category);
    await _auditLog.log(
      action: 'expense_category_changed',
      entityType: 'expense',
      entityId: id,
      newValue: category,
    );
  }
}

final expenseRepositoryProvider = Provider<ExpenseRepository>((ref) {
  return ExpenseRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final todayExpensesProvider = StreamProvider<List<ExpenseRow>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchToday();
});

/// Every expense ever recorded — Statistics/Reports filter it to the
/// selected report window (the expense table is small enough for that to
/// be cheap and keeps date math in one place).
final allExpensesProvider = StreamProvider<List<ExpenseRow>>((ref) {
  return ref.watch(expenseRepositoryProvider).watchAll();
});