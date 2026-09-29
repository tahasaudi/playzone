import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// The accounting ledger ("شاشة حسابات"). Read-side only at the
/// repository layer — every movement is posted automatically by the
/// DAOs that own the transaction (invoice, expense, refund). Renames are
/// admin-owned and audited.
class AccountRepository {
  AccountRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<AccountRow>> watchAll() => _db.accountDao.watchAll();
  Stream<List<AccountEntryRow>> watchEntries() => _db.accountDao.watchEntries();
  Stream<List<AccountEntryRow>> watchEntriesFor(int accountId) =>
      _db.accountDao.watchEntriesFor(accountId);

  /// Net balance of one category from its movements.
  double balanceOf(AccountRow account, List<AccountEntryRow> entries) {
    final mine = entries.where((e) => e.accountId == account.id);
    return mine.fold<double>(
      0,
      (sum, e) => sum + (e.direction == 'in' ? e.amount : -e.amount),
    );
  }

  Future<void> rename(int id, String name) async {
    _permissions.require(_permissions.canEditSettings, 'تغيير اسم البند');
    await _db.accountDao.updateName(id, name);
    await _auditLog.log(
      action: 'renamed',
      entityType: 'account',
      entityId: id,
      newValue: name,
    );
  }
}

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return AccountRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final accountsProvider = StreamProvider<List<AccountRow>>((ref) {
  return ref.watch(accountRepositoryProvider).watchAll();
});

final accountEntriesProvider = StreamProvider<List<AccountEntryRow>>((ref) {
  return ref.watch(accountRepositoryProvider).watchEntries();
});