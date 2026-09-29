import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/permissions/pin_hasher.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// UI/business layer for employees. Widgets never touch EmployeeDao or
/// AppDatabase directly — spec §4 (Business Logic Separation). Writes
/// are canManageUsers-gated and audit-logged here so adding/resetting/
/// deactivating an account is protected even if a stale UI button sneaks
/// through (spec §22 + §33).
class EmployeeRepository {
  EmployeeRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<EmployeeRow>> watchActive() => _db.employeeDao.watchActive();
  Stream<List<EmployeeRow>> watchPartners() => _db.employeeDao.watchPartners();

  /// Validates a PIN login attempt. Returns the employee on success, or
  /// null on failure — the caller must show a generic "wrong PIN"
  /// message either way (spec §21: "Do not reveal whether the PIN
  /// exists").
  Future<EmployeeRow?> authenticate(String phone, String pin) async {
    final employee = await _db.employeeDao.getByPhone(phone);
    if (employee == null || !employee.active) return null;
    if (employee.pinHash != pinHashFor(pin)) return null;
    return employee;
  }

  Future<int> addEmployee({
    required String name,
    required String phone,
    required String role,
    required String pin,
    bool isPartner = false,
    double? partnerShare,
  }) async {
    _permissions.require(_permissions.canManageUsers, 'إضافة موظف');
    final id = await _db.employeeDao.insertEmployee(EmployeesCompanion.insert(
      name: name,
      phone: phone,
      role: role,
      pinHash: pinHashFor(pin),
      isPartner: Value(isPartner),
      partnerShare: Value(partnerShare),
    ));
    await _auditLog.log(
      action: 'employee_added',
      entityType: 'employee',
      entityId: id,
      newValue: '$name ($role)${isPartner ? ' — شريك' : ''}',
    );
    return id;
  }

  /// Marks an employee as a business partner (شريك) and sets their
  /// profit-share percent (شركاء بنص → 50).
  Future<void> setPartner(int id, {required bool isPartner, double? share}) async {
    _permissions.require(_permissions.canManageUsers, 'تعديل فريق الشراكة');
    await _db.employeeDao.setPartner(
      id,
      isPartner: isPartner,
      share: isPartner ? share : null,
    );
    await _auditLog.log(
      action: isPartner ? 'employee_marked_partner' : 'employee_unmarked_partner',
      entityType: 'employee',
      entityId: id,
      newValue: isPartner ? 'شريك ${(share ?? 0).toStringAsFixed(0)}%' : 'مش شريك',
    );
  }

  Future<void> resetPin(EmployeeRow employee, String newPin) async {
    _permissions.require(_permissions.canManageUsers, 'إعادة تعيين رمز الموظف');
    await _db.employeeDao.updateEmployee(EmployeesCompanion(
      id: Value(employee.id),
      pinHash: Value(pinHashFor(newPin)),
      updatedAt: Value(DateTime.now()),
    ));
    await _auditLog.log(
      action: 'employee_pin_reset',
      entityType: 'employee',
      entityId: employee.id,
    );
  }

  Future<void> deactivate(int id) async {
    _permissions.require(_permissions.canManageUsers, 'تعطيل موظف');
    await _db.employeeDao.deactivate(id);
    await _auditLog.log(
      action: 'employee_deactivated',
      entityType: 'employee',
      entityId: id,
    );
  }

  Future<void> reactivate(int id) async {
    _permissions.require(_permissions.canManageUsers, 'إعادة تفعيل موظف');
    await _db.employeeDao.reactivate(id);
    await _auditLog.log(
      action: 'employee_reactivated',
      entityType: 'employee',
      entityId: id,
    );
  }

  Future<void> rename(int id, String name) async {
    _permissions.require(_permissions.canManageUsers, 'تغيير اسم الموظف');
    await _db.employeeDao.updateEmployee(EmployeesCompanion(
      id: Value(id),
      name: Value(name),
      updatedAt: Value(DateTime.now()),
    ));
    await _auditLog.log(
      action: 'renamed',
      entityType: 'employee',
      entityId: id,
      newValue: name,
    );
  }

  // ── مسحوبات وسداد ────────────────────────────────────────────────
  Stream<List<EmployeeTransactionRow>> watchTransactions() =>
      _db.employeeDao.watchTransactions();

  Stream<List<EmployeeTransactionRow>> watchTransactionsForEmployee(int id) =>
      _db.employeeDao.watchTransactionsForEmployee(id);

  /// Records a withdrawal (مسحوبات كأنها سلفة من شريحة الربح) or a
  /// repayment (سداد يرجع فلوس للدرج). For partners these offset the
  /// automatic profit share; for everyone else they're a tracked debt.
  Future<int> addTransaction({
    required int employeeId,
    required String kind, // 'withdraw' | 'repayment'
    required double amount,
    String? note,
  }) async {
    _permissions.require(_permissions.canManageUsers, 'عملية مسحوبات/سداد');
    if (amount <= 0) throw ArgumentError('المبلغ لازم يكون أكبر من صفر');
    final id = await _db.employeeDao.insertTransaction(
        EmployeeTransactionsCompanion.insert(
      employeeId: employeeId,
      kind: kind,
      amount: amount,
      note: Value(note),
    ));
    await _auditLog.log(
      action: kind == 'withdraw' ? 'employee_withdrawal' : 'employee_repayment',
      entityType: 'employee',
      entityId: employeeId,
      newValue: '${kind == 'withdraw' ? 'مسحوبات' : 'سداد'} - $amount',
    );
    return id;
  }

  /// Deletes a wrongly-recorded withdrawal/repayment. Money movements are
  /// sensitive — admin-only + audit logged.
  Future<void> deleteTransaction(int id) async {
    _permissions.require(_permissions.canEditSettings, 'حذف عملية مالية');
    await _db.employeeDao.deleteTransaction(id);
    await _auditLog.log(
      action: 'employee_transaction_deleted',
      entityType: 'employee_transaction',
      entityId: id,
    );
  }

  /// Partnership ledger snapshot for a period. Profit = revenue
  /// − expenses − refunds; each partner's share = profit × share%, then
  /// their net = share − withdrawals + repayments.
  Future<PartnersSnapshot> partnersSnapshot({
    required DateTime from,
    required DateTime to,
  }) async {
    final invoices =
        await _db.invoiceDao.getBetween(from: from, to: to);
    final expenses =
        await _db.expenseDao.getBetween(from: from, to: to);
    final refunds =
        await _db.refundDao.getBetween(from: from, to: to);
    final transactions =
        await _db.employeeDao.getTransactionsBetween(from: from, to: to);

    final revenue =
        invoices.fold<double>(0, (s, i) => s + i.total);
    final expenseTotal =
        expenses.fold<double>(0, (s, e) => s + e.amount);
    final refundsTotal =
        refunds.fold<double>(0, (s, r) => s + r.amount);
    final profit = revenue - expenseTotal - refundsTotal;

    final partners = await _db.employeeDao.getPartners();
    final entries = partners.map((p) {
      final sharePercent = p.partnerShare ?? 50;
      final share = profit * (sharePercent / 100);
      final withdrawals = transactions
          .where((t) => t.employeeId == p.id && t.kind == 'withdraw')
          .fold<double>(0, (s, t) => s + t.amount);
      final repayments = transactions
          .where((t) => t.employeeId == p.id && t.kind == 'repayment')
          .fold<double>(0, (s, t) => s + t.amount);
      return PartnerLedgerEntry(
        partner: p,
        sharePercent: sharePercent,
        share: share,
        withdrawals: withdrawals,
        repayments: repayments,
      );
    }).toList()
      ..sort((a, b) => b.share.compareTo(a.share));

    return PartnersSnapshot(
      revenue: revenue,
      expenses: expenseTotal,
      refunds: refundsTotal,
      profit: profit,
      partners: entries,
    );
  }

  // ── حضور وانصراف ────────────────────────────────────────────────
  Stream<List<EmployeeAttendanceRow>> watchAttendance() =>
      _db.employeeDao.watchAttendance();

  Future<EmployeeAttendanceRow?> openAttendanceFor(int employeeId) =>
      _db.employeeDao.openAttendanceFor(employeeId);

  /// يحضر الموظف (تسجيل دخول). مش محتاج صلاحية — أي موظف بيسجل
  /// حضوره بنفسه.
  Future<int> clockIn(int employeeId) async {
    final open = await _db.employeeDao.openAttendanceFor(employeeId);
    if (open != null) return open.id;
    return _db.employeeDao.insertAttendance(EmployeeAttendanceCompanion.insert(
      employeeId: employeeId,
      checkIn: DateTime.now(),
    ));
  }

  /// ينصرف الموظف — يبين سجل الحضور اللي مفتوح.
  Future<void> clockOut(int employeeId) async {
    final open = await _db.employeeDao.openAttendanceFor(employeeId);
    if (open == null) return;
    await _db.employeeDao.markCheckOut(open.id, DateTime.now());
  }
}

/// One partner's computed row in the partnership ledger.
class PartnerLedgerEntry {
  PartnerLedgerEntry({
    required this.partner,
    required this.sharePercent,
    required this.share,
    required this.withdrawals,
    required this.repayments,
  });
  final EmployeeRow partner;
  final double sharePercent;
  final double share;
  final double withdrawals;
  final double repayments;

  /// الصافي المستحق: نصيبه − مسحوبات + سداد.
  double get net => share - withdrawals + repayments;
}

/// The partnership math for a period — shared by all partners.
class PartnersSnapshot {
  PartnersSnapshot({
    required this.revenue,
    required this.expenses,
    required this.refunds,
    required this.profit,
    required this.partners,
  });
  final double revenue;
  final double expenses;
  final double refunds;
  final double profit;
  final List<PartnerLedgerEntry> partners;
}

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return EmployeeRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final activeEmployeesProvider = StreamProvider<List<EmployeeRow>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchActive();
});

final partnersProvider = StreamProvider<List<EmployeeRow>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchPartners();
});

/// Every withdrawal/repayment movement, newest first.
final employeeTransactionsProvider =
    StreamProvider<List<EmployeeTransactionRow>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchTransactions();
});

/// The attendance register, newest first.
final employeeAttendanceProvider =
    StreamProvider<List<EmployeeAttendanceRow>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchAttendance();
});