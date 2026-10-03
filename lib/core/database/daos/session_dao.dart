import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/sessions_table.dart';
import '../tables/devices_table.dart';
import '../tables/device_types_table.dart';
import '../tables/customers_table.dart';

part 'session_dao.g.dart';

@DriftAccessor(tables: [Sessions, Devices, DeviceTypes, Customers])
class SessionDao extends DatabaseAccessor<AppDatabase> with _$SessionDaoMixin {
  SessionDao(super.db);

  /// All non-completed sessions, joined with their device/type/customer —
  /// this is exactly what the Dashboard's device grid needs to show a
  /// live card (spec §12, §36 "Live Devices").
  Stream<List<SessionBoardEntry>> watchActiveOrPaused() {
    final query = select(sessions).join([
      innerJoin(devices, devices.id.equalsExp(sessions.deviceId)),
      innerJoin(deviceTypes, deviceTypes.id.equalsExp(devices.deviceTypeId)),
      leftOuterJoin(customers, customers.id.equalsExp(sessions.customerId)),
    ])
      ..where(sessions.status.isNotValue('completed'));

    return query.watch().map((rows) => rows
        .map((row) => SessionBoardEntry(
              session: row.readTable(sessions),
              device: row.readTable(devices),
              type: row.readTable(deviceTypes),
              customer: row.readTableOrNull(customers),
            ))
        .toList());
  }

  Future<int> start({
    required int deviceId,
    int? customerId,
    int? employeeId,
    int? packageId,
    double? fixedPrice,
    int? plannedMinutes,
    String mode = 'single',
  }) async {
    // Package sessions are billed at a flat price — no per-second
    // segment accrual, so segmentStartAt stays null for their whole run.
    // A fixed-duration session (60/30/15 from the quick buttons) gets a
    // timeUpAt deadline: billing is capped there and the session ends by
    // itself when it passes.
    final now = DateTime.now();
    final id = await into(sessions).insert(SessionsCompanion.insert(
      deviceId: deviceId,
      customerId: Value(customerId),
      employeeId: Value(employeeId),
      packageId: Value(packageId),
      fixedPrice: Value(fixedPrice),
      plannedMinutes: Value(plannedMinutes),
      mode: Value(mode),
      timeUpAt: Value(plannedMinutes == null || plannedMinutes <= 0
          ? null
          : now.add(Duration(minutes: plannedMinutes))),
      segmentStartAt: fixedPrice == null ? Value(now) : const Value(null),
    ));
    await (update(devices)..where((d) => d.id.equals(deviceId))).write(
      DevicesCompanion(
          status: const Value('active'), updatedAt: Value(DateTime.now())),
    );
    return id;
  }

  /// Ends the current segment and folds its cost into accumulatedCost.
  /// Used by pause, mode-switch, time-up, and complete — every path that
  /// stops the "clock" for whatever reason funnels through here so the
  /// cost math only lives in one place.
  double _freezeCurrentSegment(
      SessionRow session, DeviceRow device, DeviceTypeRow type) {
    if (session.segmentStartAt == null) return session.accumulatedCost;
    var elapsedSeconds =
        DateTime.now().difference(session.segmentStartAt!).inMilliseconds /
            1000.0;
    // A fixed-duration session stops billing at its deadline, even if the
    // auto-expiry write hasn't landed yet — the cost can never exceed the
    // minutes the cashier actually sold.
    final end = session.timeUpAt;
    if (end != null) {
      final capped =
          end.difference(session.segmentStartAt!).inMilliseconds / 1000.0;
      if (capped < elapsedSeconds) elapsedSeconds = capped;
    }
    if (elapsedSeconds < 0) elapsedSeconds = 0;
    final rate = _hourlyRateFor(session.mode, device, type);
    // Per-second billing (spec: "السعر بيتقسم على الثواني") — an hour
    // is 3600 seconds, never rounded up to a full minute or hour.
    final segmentCost = (rate / 3600) * elapsedSeconds;
    return session.accumulatedCost + segmentCost;
  }

  double _hourlyRateFor(String mode, DeviceRow device, DeviceTypeRow type) {
    final single = device.customHourlyRate ?? type.defaultHourlyRate;
    if (mode == 'multi') {
      final multi = device.customHourlyRateMulti ?? type.defaultHourlyRateMulti;
      // "مالتي" wasn't priced on DBs created before it existed (migrated
      // with 0) — fall back to the single rate so it always prices.
      return multi > 0 ? multi : single;
    }
    return single;
  }

  Future<void> pause(SessionBoardEntry entry) async {
    final frozenCost =
        _freezeCurrentSegment(entry.session, entry.device, entry.type);
    await (update(sessions)..where((s) => s.id.equals(entry.session.id))).write(
      SessionsCompanion(
        pausedAt: Value(DateTime.now()),
        accumulatedCost: Value(frozenCost),
        segmentStartAt: const Value(null),
        status: const Value('paused'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (update(devices)..where((d) => d.id.equals(entry.device.id))).write(
      DevicesCompanion(
          status: const Value('paused'), updatedAt: Value(DateTime.now())),
    );
  }

  Future<void> resume(SessionBoardEntry entry) async {
    final session = entry.session;
    final pausedSince = session.pausedAt == null
        ? 0.0
        : DateTime.now().difference(session.pausedAt!).inSeconds / 60.0;
    // Push the deadline forward by the paused span: a pause must never
    // burn the customer's paid minutes.
    final pausedMs = session.pausedAt == null
        ? 0
        : DateTime.now().difference(session.pausedAt!).inMilliseconds;
    await (update(sessions)..where((s) => s.id.equals(session.id))).write(
      SessionsCompanion(
        pausedAt: const Value(null),
        totalPausedMinutes: Value(session.totalPausedMinutes + pausedSince),
        segmentStartAt: Value(DateTime.now()), // a fresh segment begins
        timeUpAt:
            Value(session.timeUpAt?.add(Duration(milliseconds: pausedMs))),
        status: const Value('active'),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (update(devices)..where((d) => d.id.equals(session.deviceId))).write(
      DevicesCompanion(
          status: const Value('active'), updatedAt: Value(DateTime.now())),
    );
  }

  /// Switches between "single" and "multi" pricing mid-session — freely
  /// reversible any number of times. Whatever time was just spent in the
  /// old mode is billed at the old mode's rate and locked into
  /// accumulatedCost; a new segment then starts in [newMode].
  Future<void> switchMode(SessionBoardEntry entry, String newMode) async {
    if (entry.session.status != 'active')
      return; // only makes sense while running
    final frozenCost =
        _freezeCurrentSegment(entry.session, entry.device, entry.type);
    await (update(sessions)..where((s) => s.id.equals(entry.session.id))).write(
      SessionsCompanion(
        mode: Value(newMode),
        accumulatedCost: Value(frozenCost),
        segmentStartAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  /// The paid time is over: stop the clock, freeze the cost at exactly the
  /// minutes that were sold, and hand the DEVICE back to 'available' so it
  /// jumps to the waiting row on its own. The session row is kept as
  /// 'timeup' (not 'completed') precisely so the cashier can still press
  /// تحصيل on it and settle the bill — the money is never lost.
  Future<void> timeUp(SessionBoardEntry entry) async {
    final frozen =
        _freezeCurrentSegment(entry.session, entry.device, entry.type);
    await (update(sessions)..where((s) => s.id.equals(entry.session.id))).write(
      SessionsCompanion(
        accumulatedCost: Value(frozen),
        segmentStartAt: const Value(null),
        status: const Value('timeup'),
        endTime: Value(entry.session.timeUpAt ?? DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (update(devices)..where((d) => d.id.equals(entry.device.id))).write(
      DevicesCompanion(
          status: const Value('available'), updatedAt: Value(DateTime.now())),
    );
  }

  /// The players want to keep playing after time-up: push the deadline
  /// out by [minutes], restart the clock and hand the device back. Only
  /// the NEW minutes are billed — whatever was already frozen stays.
  Future<void> extend(SessionBoardEntry entry, int minutes) async {
    final now = DateTime.now();
    final previousDeadline = entry.session.timeUpAt;
    final base = previousDeadline != null && previousDeadline.isAfter(now)
        ? previousDeadline
        : now;
    await (update(sessions)..where((s) => s.id.equals(entry.session.id))).write(
      SessionsCompanion(
        plannedMinutes: Value((entry.session.plannedMinutes ?? 0) + minutes),
        timeUpAt: Value(base.add(Duration(minutes: minutes))),
        segmentStartAt: Value(now),
        pausedAt: const Value(null),
        status: const Value('active'),
        updatedAt: Value(now),
      ),
    );
    await (update(devices)..where((d) => d.id.equals(entry.device.id))).write(
      DevicesCompanion(status: const Value('active'), updatedAt: Value(now)),
    );
  }

  /// Every session whose deadline has already passed — polled by
  /// [SessionRepository] once a second so the flip happens on its own.
  Future<List<SessionBoardEntry>> dueForTimeUp() async {
    final rows = await (select(sessions).join([
      innerJoin(devices, devices.id.equalsExp(sessions.deviceId)),
      innerJoin(deviceTypes, deviceTypes.id.equalsExp(devices.deviceTypeId)),
      leftOuterJoin(customers, customers.id.equalsExp(sessions.customerId)),
    ])
          ..where(sessions.status.equals('active') &
              sessions.timeUpAt.isNotNull() &
              sessions.timeUpAt.isSmallerOrEqualValue(DateTime.now())))
        .get();
    return rows
        .map((row) => SessionBoardEntry(
              session: row.readTable(sessions),
              device: row.readTable(devices),
              type: row.readTable(deviceTypes),
              customer: row.readTableOrNull(customers),
            ))
        .toList();
  }

  /// When each device's last session actually finished — the Dashboard's
  /// waiting row sorts by this, so whoever ran out of time first is served
  /// first, and a device that just freed up sits ahead of one that has
  /// been idle all day.
  Stream<Map<int, DateTime>> watchLastFinishedByDevice() {
    final query = selectOnly(sessions)
      ..addColumns([sessions.deviceId, sessions.endTime.max()])
      ..where(sessions.endTime.isNotNull())
      ..groupBy([sessions.deviceId]);

    return query.watch().map((rows) {
      final map = <int, DateTime>{};
      for (final row in rows) {
        final deviceId = row.read(sessions.deviceId);
        final ended = row.read(sessions.endTime.max());
        if (deviceId != null && ended != null) map[deviceId] = ended;
      }
      return map;
    });
  }

  Future<void> complete(SessionBoardEntry entry,
      {double? overrideFinalCost}) async {
    final finalCost = overrideFinalCost ??
        entry.session.fixedPrice ??
        _freezeCurrentSegment(entry.session, entry.device, entry.type);
    await (update(sessions)..where((s) => s.id.equals(entry.session.id))).write(
      SessionsCompanion(
        endTime: Value(DateTime.now()),
        accumulatedCost: Value(finalCost),
        segmentStartAt: const Value(null),
        status: const Value('completed'),
        finalCost: Value(finalCost),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await (update(devices)..where((d) => d.id.equals(entry.device.id))).write(
      DevicesCompanion(
          status: const Value('available'), updatedAt: Value(DateTime.now())),
    );
  }

  /// Most recently completed sessions, joined with device/type/customer
  /// so the Sessions screen's history list can show names without a
  /// follow-up query per row.
  Stream<List<SessionBoardEntry>> watchCompleted({int limit = 50}) {
    final query = select(sessions).join([
      innerJoin(devices, devices.id.equalsExp(sessions.deviceId)),
      innerJoin(deviceTypes, deviceTypes.id.equalsExp(devices.deviceTypeId)),
      leftOuterJoin(customers, customers.id.equalsExp(sessions.customerId)),
    ])
      ..where(sessions.status.equals('completed'))
      ..orderBy([OrderingTerm.desc(sessions.endTime)])
      ..limit(limit);

    return query.watch().map((rows) => rows
        .map((row) => SessionBoardEntry(
              session: row.readTable(sessions),
              device: row.readTable(devices),
              type: row.readTable(deviceTypes),
              customer: row.readTableOrNull(customers),
            ))
        .toList());
  }

  /// All sessions started inside [from]..[to] (inclusive start time) —
  /// feeds the per-employee performance report. Filtered in Dart like
  /// the other ranged reads; consistent and version-proof.
  Stream<List<SessionRow>> watchBetween({
    required DateTime from,
    required DateTime to,
  }) {
    return select(sessions).watch().map((rows) => rows
        .where((r) => !r.startTime.isBefore(from) && r.startTime.isBefore(to))
        .toList());
  }
}

/// A live session bundled with everything the Dashboard card needs to
/// render — avoids per-device follow-up queries from inside a widget.
class SessionBoardEntry {
  SessionBoardEntry({
    required this.session,
    required this.device,
    required this.type,
    required this.customer,
  });

  final SessionRow session;
  final DeviceRow device;
  final DeviceTypeRow type;
  final CustomerRow? customer;

  double get singleHourlyRate =>
      device.customHourlyRate ?? type.defaultHourlyRate;
  double get multiHourlyRate {
    final multi = device.customHourlyRateMulti ?? type.defaultHourlyRateMulti;
    // DBs migrated before multi pricing existed store 0 — treat that as
    // "use the single rate" so "مالتي" never bills at zero.
    return multi > 0 ? multi : singleHourlyRate;
  }

  double get currentHourlyRate =>
      session.mode == 'multi' ? multiHourlyRate : singleHourlyRate;

  /// Elapsed ACTIVE minutes (for the on-screen timer) — total time since
  /// start minus every minute spent paused, and never more than the
  /// duration that was actually sold. This is display-only; the actual
  /// bill comes from accumulatedCost + the live segment below, which
  /// correctly accounts for mode switches.
  double get elapsedActiveMinutes {
    final totalSinceStart =
        DateTime.now().difference(session.startTime).inSeconds / 60.0;
    final currentPause = session.pausedAt == null
        ? 0.0
        : DateTime.now().difference(session.pausedAt!).inSeconds / 60.0;
    var elapsed = totalSinceStart - session.totalPausedMinutes - currentPause;
    if (elapsed < 0) elapsed = 0;
    final planned = session.plannedMinutes;
    if (planned != null && planned > 0 && elapsed > planned)
      elapsed = planned.toDouble();
    return elapsed;
  }

  /// True for a session started from one of the quick duration buttons
  /// (60/30/15/7) — it has a deadline and ends by itself.
  bool get isTimed => (session.plannedMinutes ?? 0) > 0;

  /// Minutes left on the paid time, or null for an open-ended session.
  /// While paused the clock is frozen, so it's measured from [pausedAt].
  double? get remainingMinutes {
    final end = session.timeUpAt;
    if (!isTimed || end == null) return null;
    final from = session.pausedAt ?? DateTime.now();
    final left = end.difference(from).inSeconds / 60.0;
    return left < 0 ? 0 : left;
  }

  bool get isTimeUp => session.status == 'timeup';

  /// Live cost so far: a package session shows its flat fixedPrice;
  /// otherwise everything already locked in from past segments, plus
  /// whatever the CURRENT segment has accrued (billed per second, at
  /// whichever mode is active right now). Never rounded up to a full
  /// minute or hour — and hard-capped at the session's deadline, so a
  /// fixed-duration session stops charging the second its time is up.
  double get liveCost {
    if (session.fixedPrice != null) return session.fixedPrice!;
    if (session.segmentStartAt == null) return session.accumulatedCost;
    var elapsedSeconds =
        DateTime.now().difference(session.segmentStartAt!).inMilliseconds /
            1000.0;
    final end = session.timeUpAt;
    if (end != null) {
      final capped =
          end.difference(session.segmentStartAt!).inMilliseconds / 1000.0;
      if (capped < elapsedSeconds) elapsedSeconds = capped;
    }
    if (elapsedSeconds < 0) elapsedSeconds = 0;
    return session.accumulatedCost +
        (currentHourlyRate / 3600) * elapsedSeconds;
  }
}
