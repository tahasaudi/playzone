import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/invoice_dao.dart';

class InvoiceRepository {
  InvoiceRepository(this._db);
  final AppDatabase _db;

  Stream<List<InvoiceRow>> watchRecent({int limit = 50}) =>
      _db.invoiceDao.watchRecent(limit: limit);

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

  /// Café orders already charged against a live session (cashed in
  /// earlier, so the session panel shows "تم السداد" amounts).
  Stream<List<InvoiceRow>> watchForSession(int sessionId) =>
      _db.invoiceDao.watchForSession(sessionId);

  Stream<List<InvoiceItemRow>> watchItemsForSession(int sessionId) =>
      _db.invoiceDao.watchItemsForSession(sessionId);

  Future<List<InvoiceItemRow>> itemsForInvoice(int invoiceId) =>
      _db.invoiceDao.itemsForInvoice(invoiceId);

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

final todayInvoicesProvider = StreamProvider<List<InvoiceRow>>((ref) {
  return ref.watch(invoiceRepositoryProvider).watchToday();
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
