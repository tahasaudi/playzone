import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/accounting/profit.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/permissions/pin_hasher.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';
import 'invoice_repository.dart';

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

  /// Every employee including disabled ones — the roster screen shows both so
  /// a switched-off account is visible and can be switched back on.
  Stream<List<EmployeeRow>> watchAll() => _db.employeeDao.watchAll();

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
  ///
  /// The partners' shares must never add up to more than 100% — two names
  /// claiming 60% each would divide out more profit than the shop made. The
  /// check lives here so no screen can set a set of shares that cannot pay.
  Future<void> setPartner(int id, {required bool isPartner, double? share}) async {
    _permissions.require(_permissions.canManageUsers, 'تعديل فريق الشراكة');
    if (isPartner) {
      final percent = _normalizedShare(share);
      final others = await _db.employeeDao.getPartners();
      final committed = others
          .where((p) => p.id != id)
          .fold<double>(0, (s, p) => s + _normalizedShare(p.partnerShare));
      if (committed + percent > 100.001) {
        throw Exception(
            'مجموع نسب الشركاء هيعدّي 100% (المتاح ${(100 - committed).toStringAsFixed(0)}%)');
      }
    }
    await _db.employeeDao.setPartner(
      id,
      isPartner: isPartner,
      share: isPartner ? _normalizedShare(share) : null,
    );
    await _auditLog.log(
      action: isPartner ? 'employee_marked_partner' : 'employee_unmarked_partner',
      entityType: 'employee',
      entityId: id,
      newValue: isPartner ? 'شريك ${_normalizedShare(share).toStringAsFixed(0)}%' : 'مش شريك',
    );
  }

  /// A partner's share, clamped to a sane 0–100. A missing/blank value reads
  /// as the café's default of an equal split (50), never as "no share".
  static double normalizedShare(double? raw) {
    if (raw == null || raw.isNaN) return 50;
    return raw.clamp(0, 100).toDouble();
  }

  static double _normalizedShare(double? raw) => normalizedShare(raw);

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

  /// Changes the employee's phone. The phone doubles as the login handle
  /// (see [authenticate]), so moving it moves how this person signs in —
  /// admin-only, and audit-logged for the same reason a PIN reset is.
  Future<void> setPhone(int id, String phone) async {
    _permissions.require(_permissions.canManageUsers, 'تغيير رقم موظف');
    final trimmed = phone.trim();
    if (trimmed.isEmpty) throw ArgumentError('رقم الموبايل مطلوب');
    final clash = await _db.employeeDao.getByPhone(trimmed);
    if (clash != null && clash.id != id) {
      throw Exception('الرقم ده مسجّل لموظف تاني');
    }
    await _db.employeeDao.updateEmployee(EmployeesCompanion(
      id: Value(id),
      phone: Value(trimmed),
      updatedAt: Value(DateTime.now()),
    ));
    await _auditLog.log(
      action: 'employee_phone_changed',
      entityType: 'employee',
      entityId: id,
      newValue: trimmed,
    );
  }

  /// Changes the employee's job role (admin-only). Roles gate the whole
  /// permission baseline, so this is as sensitive as a PIN reset.
  Future<void> setRole(int id, String role) async {
    _permissions.require(_permissions.canManageUsers, 'تغيير وظيفة موظف');
    await _db.employeeDao.updateEmployee(EmployeesCompanion(
      id: Value(id),
      role: Value(role),
      updatedAt: Value(DateTime.now()),
    ));
    await _auditLog.log(
      action: 'employee_role_changed',
      entityType: 'employee',
      entityId: id,
      newValue: role,
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

  /// Partnership ledger snapshot for a period.
  ///
  /// The split is over **صافي الربح** — not revenue — and that profit follows
  /// the one definition the whole app shares ([Accounting]):
  ///
  ///   الإيراد (المسدَّد فقط) − تكلفة البضاعة − المصروفات − المرتجعات
  ///
  /// Each partner's share is `profit × share%`, and their net due is that
  /// share minus their withdrawals plus their repayments (مسحوبات/سداد).
  Future<PartnersSnapshot> partnersSnapshot({
    required DateTime from,
    required DateTime to,
  }) async {
    final invoices = await _db.invoiceDao.getBetween(from: from, to: to);
    final items = await _db.invoiceDao.getItemsBetween(from: from, to: to);
    final expenses = await _db.expenseDao.getBetween(from: from, to: to);
    final refunds = await _db.refundDao.getBetween(from: from, to: to);
    final transactions =
        await _db.employeeDao.getTransactionsBetween(from: from, to: to);
    final products = await _db.productDao.allProducts();

    final costByProduct = {for (final p in products) p.id: p.costPrice};

    final breakdown = Accounting.revenueBreakdown(invoices: invoices, items: items);
    final cogs = Accounting.costOfGoods(items, costByProduct);
    final expenseTotal = Accounting.expenses(expenses);
    final refundsTotal = Accounting.refunds(refunds);
    final profit = Accounting.netProfit(
      revenue: breakdown.revenue,
      costOfGoods: cogs,
      expenses: expenseTotal,
      refunds: refundsTotal,
    );

    final partners = await _db.employeeDao.getPartners();
    final entries = partners.map((p) {
      final sharePercent = _normalizedShare(p.partnerShare);
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
      revenue: breakdown.revenue,
      gamingRevenue: breakdown.gaming,
      cafeRevenue: breakdown.cafe,
      discounts: breakdown.discounts,
      costOfGoods: cogs,
      expenses: expenseTotal,
      refunds: refundsTotal,
      profit: profit,
      partners: entries,
      invoices: Accounting.settledOnly(invoices),
      items: items,
      expenseRows: expenses,
      refundRows: refunds,
      transactions: transactions,
      productsById: {for (final p in products) p.id: p},
      costByProduct: costByProduct,
    );
  }

  // ── حضور وانصراف ────────────────────────────────────────────────
  Stream<List<EmployeeAttendanceRow>> watchAttendance() =>
      _db.employeeDao.watchAttendance();

  Stream<List<EmployeeAttendanceRow>> watchAttendanceFor(int employeeId) =>
      _db.employeeDao.watchAttendanceFor(employeeId);

  Stream<List<EmployeeAttendanceRow>> watchOpenAttendance() =>
      _db.employeeDao.watchOpenAttendance();

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
///
/// It carries not just the totals but the raw rows behind them, so every
/// "تفصيل" button opens the exact movements the numbers on the row were summed
/// from — no second query that could disagree with the figure above it.
class PartnersSnapshot {
  PartnersSnapshot({
    required this.revenue,
    required this.gamingRevenue,
    required this.cafeRevenue,
    required this.discounts,
    required this.costOfGoods,
    required this.expenses,
    required this.refunds,
    required this.profit,
    required this.partners,
    required this.invoices,
    required this.items,
    required this.expenseRows,
    required this.refundRows,
    required this.transactions,
    required this.productsById,
    required this.costByProduct,
  });

  /// الإيراد (المسدَّد). The gross three lines below always add back up to it:
  /// `gamingRevenue + cafeRevenue − discounts == revenue`.
  final double revenue;

  /// The PlayStation side — settled «وقت اللعب» lines.
  final double gamingRevenue;

  /// Everything the café sold on the settled bills.
  final double cafeRevenue;

  /// What was knocked off the bills, so the split reconciles to the total.
  final double discounts;

  final double costOfGoods;
  final double expenses;
  final double refunds;
  final double profit;
  final List<PartnerLedgerEntry> partners;

  /// The settled bills of the period — the revenue detail's source.
  final List<InvoiceRow> invoices;

  /// Every settled bill line — the gaming/café/cost-of-goods detail's source.
  final List<InvoiceItemRow> items;

  final List<ExpenseRow> expenseRows;
  final List<RefundRow> refundRows;

  /// Every withdrawal/repayment movement in the period (all employees).
  final List<EmployeeTransactionRow> transactions;

  /// Product id → product, for naming the cost-of-goods detail (includes
  /// soft-deleted products, which historical bills still reference).
  final Map<int, ProductRow> productsById;

  final Map<int, double> costByProduct;

  /// The share percent actually committed across all partners. Over 100 means
  /// the shares would pay out more than the shop earned; the UI warns on it.
  double get totalSharePercent =>
      partners.fold(0.0, (s, p) => s + p.sharePercent);

  /// المجموع الكلي لنصيب الشركاء من الربح.
  double get totalShares => partners.fold(0.0, (s, p) => s + p.share);

  /// إجمالي المسحوبات على كل الشركاء في الفترة.
  double get totalWithdrawals =>
      partners.fold(0.0, (s, p) => s + p.withdrawals);

  /// إجمالي السداد اللي رجع للدرج من الشركاء.
  double get totalRepayments => partners.fold(0.0, (s, p) => s + p.repayments);

  /// اللي يتبقّى للمحل بعد نصيب الشركاء (لو النسب أقل من 100%).
  double get keptByShop => profit - totalShares;
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

/// The full roster — active *and* disabled. The employees screen watches this
/// so an admin can see a switched-off account and bring it back, which a
/// watchActive list can never show.
final allEmployeesProvider = StreamProvider<List<EmployeeRow>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchAll();
});

final partnersProvider = StreamProvider<List<EmployeeRow>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchPartners();
});

/// The partnership window. Deliberately its own switch rather than the shared
/// [reportPeriodProvider]: "how did the partners do this month" is a different
/// question from "how did today's shift go", and nudging one must not silently
/// move the other screen's numbers.
final partnershipPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.today);

/// The partnership ledger for the currently-selected partnership window. A
/// Future (not a Stream) because it is a one-shot aggregation across four
/// tables; any write to shares/withdrawals refreshes it by invalidating this
/// provider.
final partnershipSnapshotProvider =
    FutureProvider.autoDispose<PartnersSnapshot>((ref) {
  final range = currentReportRange(ref.watch(partnershipPeriodProvider));
  return ref
      .watch(employeeRepositoryProvider)
      .partnersSnapshot(from: range.from, to: range.to);
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

/// One employee's attendance history, newest first.
final employeeAttendanceForProvider =
    StreamProvider.family<List<EmployeeAttendanceRow>, int>((ref, employeeId) {
  return ref.watch(employeeRepositoryProvider).watchAttendanceFor(employeeId);
});

/// Who is clocked in right now (open attendance records, one per employee).
final openAttendanceProvider =
    StreamProvider<List<EmployeeAttendanceRow>>((ref) {
  return ref.watch(employeeRepositoryProvider).watchOpenAttendance();
});