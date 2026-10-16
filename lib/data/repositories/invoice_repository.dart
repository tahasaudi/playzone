import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/invoice_dao.dart';

class InvoiceRepository {
  InvoiceRepository(this._db);
  final AppDatabase _db;

  Stream<List<InvoiceRow>> watchRecent({int limit = 50}) =>
      _db.invoiceDao.watchRecent(limit: limit);

  /// Recent invoices with their customer attached — powers the refunds
  /// screen's search/list so a bill can be found by name, phone or code.
  Stream<List<InvoiceWithCustomer>> watchSearchable({int limit = 200}) =>
      _db.invoiceDao.watchSearchable(limit: limit);

  Stream<List<InvoiceRow>> watchToday() => _db.invoiceDao.watchToday();

  Stream<List<InvoiceRow>> watchBetween({
    required DateTime from,
    required DateTime to,
  }) =>
      _db.invoiceDao.watchBetween(from: from, to: to);

  Stream<List<InvoiceItemRow>> watchItemsBetween({
    required DateTime from,
    required DateTime to,
  }) =>
      _db.invoiceDao.watchItemsBetween(from: from, to: to);

  Stream<List<InvoiceItemRow>> watchItemsToday() =>
      _db.invoiceDao.watchItemsToday();

  /// Café orders already charged against a live session (cashed in
  /// earlier, so the session panel shows "تم السداد" amounts).
  Stream<List<InvoiceRow>> watchForSession(int sessionId) =>
      _db.invoiceDao.watchForSession(sessionId);

  Stream<List<InvoiceItemRow>> watchItemsForSession(int sessionId) =>
      _db.invoiceDao.watchItemsForSession(sessionId);

  Future<List<InvoiceItemRow>> itemsForInvoice(int invoiceId) =>
      _db.invoiceDao.itemsForInvoice(invoiceId);

  /// The café lines already on a live session's open tab (its unpaid drafts).
  Future<List<InvoiceLineInput>> draftLinesForSession(int sessionId) =>
      _db.invoiceDao.draftLinesForSession(sessionId);

  /// Rewrites a live session's open tab to exactly [lines] — the correction
  /// path behind "انقّص اللي على الكارت". See [InvoiceDao.syncSessionDraft].
  Future<int?> syncSessionDraft({
    required int sessionId,
    required List<InvoiceLineInput> lines,
    int? customerId,
    int? employeeId,
  }) {
    return _db.invoiceDao.syncSessionDraft(
      sessionId: sessionId,
      lines: lines,
      customerId: customerId,
      employeeId: employeeId,
    );
  }

  /// Takes one unit off a live session's open tab and puts it back on the
  /// shelf — the quick "إرجاع واحد" button.
  ///
  /// [productId] picks which item to take back; when null the newest line is
  /// used, which is the one the customer most likely means ("أنا هاخد واحدة
  /// بس"). Returns the item's name so the caller can confirm what moved, or
  /// null when the tab was empty (or that product was not on it).
  Future<String?> returnOneFromSession(int sessionId, {int? productId}) async {
    final lines = await draftLinesForSession(sessionId);
    if (lines.isEmpty) return null;

    // Fold the tab to one entry per product, remembering the order they were
    // first asked for so the newest can be found and the rest kept in place.
    final order = <int>[];
    final qty = <int, int>{};
    final proto = <int, InvoiceLineInput>{};
    final firstAt = <int, DateTime?>{};
    for (final line in lines) {
      final id = line.productId;
      if (id == null) continue;
      if (!qty.containsKey(id)) {
        order.add(id);
        proto[id] = line;
        firstAt[id] = line.createdAt;
      }
      qty[id] = (qty[id] ?? 0) + line.quantity;
      final when = line.createdAt;
      if (when != null && (firstAt[id] == null || when.isBefore(firstAt[id]!))) {
        firstAt[id] = when;
      }
    }
    if (order.isEmpty) return null;

    final targetId = productId ?? order.first;
    if (!qty.containsKey(targetId)) return null;
    final targetName = proto[targetId]!.description;

    final newLines = <InvoiceLineInput>[
      for (final id in order)
        if ((id == targetId ? qty[id]! - 1 : qty[id]!) > 0)
          InvoiceLineInput(
            productId: id,
            description: proto[id]!.description,
            quantity: id == targetId ? qty[id]! - 1 : qty[id]!,
            unitPrice: proto[id]!.unitPrice,
            createdAt: firstAt[id],
          ),
    ];
    await syncSessionDraft(sessionId: sessionId, lines: newLines);
    return targetName;
  }

  double totalOf(List<InvoiceRow> invoices) =>
      invoices.fold(0.0, (sum, i) => sum + i.total);

  /// Single write-path to create a sale. Pass throughs to InvoiceDao's
  /// transaction — which also earns/spends loyalty points when a
  /// [customerId] is attached (see InvoiceDao.createInvoice docs).
  Future<int> createInvoice({
    required List<InvoiceLineInput> lines,
    int? sessionId,
    int? customerId,
    int? employeeId,
    double discount = 0,
    int redeemedPoints = 0,
    double paidCash = 0,
    double paidCard = 0,
    double paidOnAccount = 0,
    bool settled = true,
  }) {
    return _db.invoiceDao.createInvoice(
      lines: lines,
      sessionId: sessionId,
      customerId: customerId,
      employeeId: employeeId,
      discount: discount,
      redeemedPoints: redeemedPoints,
      paidCash: paidCash,
      paidCard: paidCard,
      paidOnAccount: paidOnAccount,
      settled: settled,
    );
  }
}

final invoiceRepositoryProvider = Provider<InvoiceRepository>((ref) {
  return InvoiceRepository(ref.watch(appDatabaseProvider));
});

final recentInvoicesProvider = StreamProvider<List<InvoiceRow>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchRecent();
});

/// Invoices (with customer info) that the refunds screen lists and searches.
final searchableInvoicesProvider =
    StreamProvider<List<InvoiceWithCustomer>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchSearchable();
});

/// The lines of one invoice — what was actually ordered/charged on it.
final invoiceItemsProvider =
    FutureProvider.family<List<InvoiceItemRow>, int>((ref, invoiceId) {
  return ref.watch(invoiceRepositoryProvider).itemsForInvoice(invoiceId);
});

final todayInvoicesProvider = StreamProvider<List<InvoiceRow>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchToday();
});

/// Today's settled invoice lines — the cost-of-goods side of the day's profit
/// on the protected screen. (Drafts are excluded by the DAO.)
final todayInvoiceItemsProvider = StreamProvider<List<InvoiceItemRow>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchItemsToday();
});

/// Report window selector for the performance/report screens.
enum ReportPeriod { today, week, month }

final reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.today);

/// The [from, to) window for the currently-selected [reportPeriodProvider].
({DateTime from, DateTime to}) currentReportRange(ReportPeriod period) {
  final now = DateTime.now();
  final from = switch (period) {
    ReportPeriod.today => DateTime(now.year, now.month, now.day),
    ReportPeriod.week => now.subtract(const Duration(days: 7)),
    ReportPeriod.month => DateTime(now.year, now.month, 1),
  };
  return (from: from, to: now);
}

/// Invoices inside the currently-selected [reportPeriodProvider] window.
final invoicesInRangeProvider = StreamProvider<List<InvoiceRow>>((ref) {
  final range = currentReportRange(ref.watch(reportPeriodProvider));
  return ref
      .watch(invoiceRepositoryProvider)
      .watchBetween(from: range.from, to: range.to);
});

/// Invoice lines inside the selected window — the Statistics screen's
/// top-products ranking.
final invoiceItemsInRangeProvider = StreamProvider<List<InvoiceItemRow>>((ref) {
  final range = currentReportRange(ref.watch(reportPeriodProvider));
  return ref
      .watch(invoiceRepositoryProvider)
      .watchItemsBetween(from: range.from, to: range.to);
});

/// What one live session actually ordered, line by line.
///
/// Family, not a single stream, because the dashboard asks this question about
/// the session the cashier just tapped — and a card that lists everybody's
/// orders would be a card nobody could read.
final sessionOrderLinesProvider =
    StreamProvider.family<List<InvoiceItemRow>, int>((ref, sessionId) {
  return ref.watch(invoiceRepositoryProvider).watchItemsForSession(sessionId);
});

/// The open tab of a live session — its unpaid café drafts in the shape the
/// order modal edits them. Distinct from [sessionOrderLinesProvider], which
/// returns every line on the session (including anything already settled),
/// because the modal may only rewrite what has not been paid for yet.
///
/// Invalidated after a save so reopening the modal shows the corrected tab.
final sessionDraftLinesProvider =
    FutureProvider.family<List<InvoiceLineInput>, int>((ref, sessionId) {
  return ref.watch(invoiceRepositoryProvider).draftLinesForSession(sessionId);
});
