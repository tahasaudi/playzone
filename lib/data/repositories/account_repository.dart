import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';
import 'invoice_repository.dart';

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

  /// Movements inside [from, to) — the windowed read the ledger screen uses.
  Stream<List<AccountEntryRow>> watchEntriesBetween({
    required DateTime from,
    required DateTime to,
  }) =>
      _db.accountDao.watchEntriesBetween(from: from, to: to);

  /// Net balance of one category from its movements.
  double balanceOf(AccountRow account, List<AccountEntryRow> entries) {
    final mine = entries.where((e) => e.accountId == account.id);
    return mine.fold<double>(
      0,
      (sum, e) => sum + (e.direction == 'in' ? e.amount : -e.amount),
    );
  }

  /// The ledger totals as the screen must show them.
  ///
  /// [totalIn] and [totalOut] sum the given movements — so they always agree
  /// with the list underneath and with the per-category cards, which is *not*
  /// true of a naive in/out split: a refund is money going out of the till, but
  /// it is recorded 'out' against the refunds book, and a sale recorded 'in'
  /// still leaves the till lighter after the refund. Summing the raw directions
  /// therefore double-counts movement and misreports the month.
  ///
  /// What the shop actually wants from these three numbers is: what came in,
  /// what went out, and what is left. [net] is that remainder, and it is
  /// computed as revenue − expenses − refunds so it ties to the profit figure
  /// the reports screen shows. Refunds are subtracted once, from the revenue
  /// they reverse, never from both sides.
  ({double totalIn, double totalOut, double net}) totalsOf(
    List<AccountRow> accounts,
    List<AccountEntryRow> entries,
  ) {
    final kindOf = {for (final a in accounts) a.id: a.kind};
    var revenue = 0.0;
    var spend = 0.0;
    for (final e in entries) {
      final kind = kindOf[e.accountId];
      if (kind == 'revenue') {
        // Revenue accounts only ever post 'in'; a refund is filed under the
        // expense-side refunds book, so this stays a clean gross figure.
        revenue += e.amount;
      } else {
        // Every non-revenue movement is money the shop gave up: expenses and
        // refunds both land here, each counted exactly once.
        spend += e.amount;
      }
    }

    // "الداخل" and "الخارج" are shown gross — the owner reads them as how much
    // moved through the till each way. Net is what is left, which is the
    // number that has to match profit, so it is computed from the same
    // revenue-minus-cost definition the rest of the app uses rather than as
    // totalIn − totalOut (which would net a refund off against the sale it
    // reverses, hiding both).
    return (totalIn: revenue, totalOut: spend, net: revenue - spend);
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

  /// Adds a category to the chart of accounts. Admin-only, like renaming —
  /// both reshape how every future movement is filed.
  ///
  /// The four seeded books are always present, but a shop grows lines of its
  /// own (مصاريف نقل، صيانة، إيجار) and until now there was no way in from the
  /// screen: the chart could only be seeded, never extended.
  Future<int> createAccount({
    required String name,
    required String kind,
  }) async {
    _permissions.require(_permissions.canEditSettings, 'إضافة بند حساب');
    final trimmed = name.trim();
    if (trimmed.isEmpty) throw ArgumentError('اسم البند مطلوب');
    if (kind != 'revenue' && kind != 'expense') {
      throw ArgumentError('نوع البند لازم يكون إيراد أو مصروف');
    }
    final id = await _db.accountDao.createAccount(name: trimmed, kind: kind);
    await _auditLog.log(
      action: 'account_added',
      entityType: 'account',
      entityId: id,
      newValue: '$trimmed (${kind == 'revenue' ? 'إيراد' : 'مصروف'})',
    );
    return id;
  }

  /// Movements whose label, note or amount matches [query].
  ///
  /// Matched in Dart rather than SQL because the owner searches in Arabic by
  /// feel ("كوكاكولا", "نقل") and SQLite's LIKE is byte-wise: it would need the
  /// exact spelling and case, which is no use for a free-text box. The window
  /// being searched is already the current period, so the set is small.
  List<AccountEntryRow> search(
    List<AccountEntryRow> entries,
    List<AccountRow> accounts,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return entries;
    final nameOf = {for (final a in accounts) a.id: a.name.toLowerCase()};
    return entries.where((e) {
      if (e.note?.toLowerCase().contains(q) == true) return true;
      if ((nameOf[e.accountId] ?? '').contains(q)) return true;
      if (e.source.toLowerCase().contains(q)) return true;
      // Amounts are searched on their plain form so '150' finds EGP 150.00.
      if (e.amount.toStringAsFixed(2).contains(q)) return true;
      return false;
    }).toList();
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

/// The window the accounting screen shows. Kept separate from the shared
/// [reportPeriodProvider] so switching the ledger to "الشهر" does not silently
/// change every report screen behind the owner's back — the same reasoning the
/// partnership ledger uses for its own period.
final accountingPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.today);

/// Movements for the currently-selected [accountingPeriodProvider] window.
///
/// This is what the screen lists and totals. The unwindowed
/// [accountEntriesProvider] still exists for anything that genuinely needs the
/// full history, but the ledger deliberately does not — rendering every
/// movement the shop has ever made is what made the screen crawl.
final accountingEntriesProvider =
    StreamProvider<List<AccountEntryRow>>((ref) {
  final range = currentReportRange(ref.watch(accountingPeriodProvider));
  return ref
      .watch(accountRepositoryProvider)
      .watchEntriesBetween(from: range.from, to: range.to);
});

/// The window immediately before the current one, of the same length.
///
/// Used by the "vs الفترة السابقة" comparison. "Same length" is the point:
/// comparing a 7-day window against the 30 days before it would flatter every
/// number. For today this is yesterday; for the week, the 7 days before; for
/// the month, the previous calendar month.
({DateTime from, DateTime to}) previousReportRange(ReportPeriod period) {
  final now = DateTime.now();
  final current = currentReportRange(period);
  final span = current.to.difference(current.from);
  return switch (period) {
    // A calendar month is compared against the whole previous calendar month,
    // not a sliding 30-day block, so the two windows line up with how the
    // owner thinks about "الشهر".
    ReportPeriod.month => (
        from: DateTime(now.year, now.month - 1, 1),
        to: DateTime(now.year, now.month, 1),
      ),
    _ => (from: current.from.subtract(span), to: current.from),
  };
}

/// Movements in the [previousReportRange] window — the left-hand side of the
/// comparison shown next to the current totals.
final previousAccountingEntriesProvider =
    StreamProvider<List<AccountEntryRow>>((ref) {
  final range = previousReportRange(ref.watch(accountingPeriodProvider));
  return ref
      .watch(accountRepositoryProvider)
      .watchEntriesBetween(from: range.from, to: range.to);
});