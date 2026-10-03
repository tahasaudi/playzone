import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/session_dao.dart';
import '../../core/database/daos/invoice_dao.dart';

/// Session lifecycle — spec §8 (billing) + §36 (live devices). This is
/// the piece that turns the Dashboard from a mock display into an
/// actually-operating cash register: starting a session, pausing it,
/// resuming it, switching single/multi mode, and closing it out all
/// happen here, with the DB as the single source of truth for elapsed
/// time and cost (never trust client-side timers for the final bill —
/// only for the live on-screen ticking).
class SessionRepository {
  SessionRepository(this._db);
  final AppDatabase _db;

  Stream<List<SessionBoardEntry>> watchActiveOrPaused() =>
      _db.sessionDao.watchActiveOrPaused();

  Stream<List<SessionBoardEntry>> watchCompleted({int limit = 50}) =>
      _db.sessionDao.watchCompleted(limit: limit);

  Stream<List<SessionRow>> watchBetween({
    required DateTime from,
    required DateTime to,
  }) =>
      _db.sessionDao.watchBetween(from: from, to: to);

  /// Starts a session. Passing [packageId]/[fixedPrice] starts it as a
  /// package session — billed at the flat price instead of per-second
  /// accrual. Passing [plannedMinutes] starts a fixed-duration session
  /// (60/30/15/7): it bills only up to that many minutes and ends itself
  /// when the time is up, freeing the device back to the waiting row.
  Future<int> start({
    required int deviceId,
    int? customerId,
    int? employeeId,
    int? packageId,
    double? fixedPrice,
    int? plannedMinutes,
    String mode = 'single',
  }) =>
      _db.sessionDao.start(
        deviceId: deviceId,
        customerId: customerId,
        employeeId: employeeId,
        packageId: packageId,
        fixedPrice: fixedPrice,
        plannedMinutes: plannedMinutes,
        mode: mode,
      );

  /// Flips every fixed-duration session whose deadline has passed to
  /// 'timeup' — cost frozen, device released. Called on a timer by
  /// [timeUpWatcherProvider]; safe to call repeatedly.
  Future<int> settleDueTimeUps() async {
    final due = await _db.sessionDao.dueForTimeUp();
    for (final entry in due) {
      await _db.sessionDao.timeUp(entry);
    }
    return due.length;
  }

  Future<void> pause(SessionBoardEntry entry) => _db.sessionDao.pause(entry);

  Future<void> resume(SessionBoardEntry entry) => _db.sessionDao.resume(entry);

  /// Flips the session between "single" and "multi" pricing — reversible
  /// any number of times within the same session. Whatever time was
  /// spent under the old mode bills at the old rate; time from this
  /// point on bills at the new rate.
  Future<void> switchMode(SessionBoardEntry entry, String newMode) =>
      _db.sessionDao.switchMode(entry, newMode);

  /// Adds [minutes] of paid time to a session that ran out.
  Future<void> extend(SessionBoardEntry entry, int minutes) =>
      _db.sessionDao.extend(entry, minutes);

  Stream<Map<int, DateTime>> watchLastFinishedByDevice() =>
      _db.sessionDao.watchLastFinishedByDevice();

  /// Closes the session out with its final, DB-computed cost AND writes
  /// a real invoice for it (spec §30) — this is what the Checkout modal
  /// calls on "إتمام التحصيل". [paidCash]/[paidCard] carry the tender
  /// split (mixed payment), [redeemedPoints] spends the customer's
  /// loyalty points against the bill. The gaming-time line is separate
  /// from any café items (those are POS's own invoices for now).
  ///
  /// [collectedTimeCost] is the exact time cost the cashier confirmed in
  /// the modal (frozen at open). It is used verbatim for the final bill
  /// so the invoice total always matches the tender — the live clock
  /// never re-prices the bill after the customer has been quoted.
  Future<void> checkout(
    SessionBoardEntry entry,
    InvoiceDao invoiceDao, {
    double discount = 0,
    int redeemedPoints = 0,
    double paidCash = 0,
    double paidCard = 0,
    double? collectedTimeCost,
  }) async {
    final finalCost =
        entry.session.fixedPrice ?? (collectedTimeCost ?? entry.liveCost);
    await _db.sessionDao.complete(entry, overrideFinalCost: finalCost);
    await invoiceDao.createInvoice(
      sessionId: entry.session.id,
      customerId: entry.session.customerId,
      employeeId: entry.session.employeeId,
      discount: discount,
      redeemedPoints: redeemedPoints,
      paidCash: paidCash,
      paidCard: paidCard,
      lines: [
        InvoiceLineInput(
          description: '${entry.type.name} — ${entry.device.name} (وقت اللعب)',
          quantity: 1,
          unitPrice: finalCost,
        ),
      ],
    );
  }
}

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(appDatabaseProvider));
});

final activeSessionsProvider = StreamProvider<List<SessionBoardEntry>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchActiveOrPaused();
});

/// Recently completed sessions (newest first) — the history half of the
/// Sessions screen. The limit is generous on purpose: the "حصر" panel
/// counts sessions over a date range, and a 50-row cap would make the
/// count lie for any busy period.
final completedSessionsProvider =
    StreamProvider<List<SessionBoardEntry>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchCompleted(limit: 2000);
});

/// Ticks once a second so widgets showing a live timer/cost rebuild —
/// the DB values (startTime, pausedAt, accumulatedCost) don't change
/// every second, only the *displayed* elapsed time/cost does.
final oneSecondTickerProvider = StreamProvider<int>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) => i);
});

/// The quick duration buttons on the Dashboard, in the order the cashier
/// reads them. Null duration = open-ended (per-second) session.
const List<int?> quickDurations = [60, 30, 15];

/// The café's default session length. Every device starts on this, and the
/// cashier can override it per machine from the card's own duration chips.
const int defaultSessionMinutes = 60;

/// The default duration applied to devices that haven't been given their
/// own choice yet.
final selectedDurationProvider =
    StateProvider<int?>((ref) => defaultSessionMinutes);

/// Per-device duration overrides (deviceId → minutes). A value of 0 (or
/// less) means "وقت مفتوح" for that machine. Each device on the dashboard
/// remembers its own time, so a 60-minute PS5 and a 15-minute PS4 can run
/// side by side without re-picking anything.
final deviceDurationsProvider = StateProvider<Map<int, int>>((ref) => {});

/// The duration to use when starting (or topping up) [deviceId]: its own
/// choice if it has one, otherwise the café default. Returns null for an
/// open-ended session.
int? durationForDevice(WidgetRef ref, int deviceId) {
  final chosen = ref.read(deviceDurationsProvider)[deviceId] ??
      ref.read(selectedDurationProvider) ??
      defaultSessionMinutes;
  return chosen <= 0 ? null : chosen;
}

/// Per-device "فردي/مالتي" choice (deviceId → "single" | "multi"). The
/// cashier picks it on the device card and the session starts in that
/// mode — [SessionDao.start] writes it into the session row.
final deviceModesProvider = StateProvider<Map<int, String>>((ref) => {});

/// Per-device amount the cashier last typed on the card (deviceId → EGP).
/// Kept so a mode switch can re-price the same money at the other rate.
final deviceAmountsProvider = StateProvider<Map<int, double>>((ref) => {});

/// When each device's last session finished — the waiting row is sorted by
/// this so the device that ran out of time first is served first.
final lastFinishedByDeviceProvider = StreamProvider<Map<int, DateTime>>((ref) {
  return ref.watch(sessionRepositoryProvider).watchLastFinishedByDevice();
});

/// Background watchdog: settles fixed-duration sessions the moment their
/// time runs out (no polling from any widget, no cashier action needed).
/// Watched once by the Dashboard; cancels itself when nothing watches it.
final timeUpWatcherProvider = Provider<int>((ref) {
  final repo = ref.watch(sessionRepositoryProvider);
  final timer = Timer.periodic(const Duration(seconds: 5), (_) async {
    try {
      await repo.settleDueTimeUps();
    } catch (_) {
      // A transient DB error must not kill the timer — the next tick
      // tries again.
    }
  });
  ref.onDispose(timer.cancel);
  return 0;
});
