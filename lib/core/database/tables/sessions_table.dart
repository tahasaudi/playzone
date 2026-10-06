import 'package:drift/drift.dart';
import 'devices_table.dart';
import 'customers_table.dart';
import 'employees_table.dart';
import 'packages_table.dart';

/// A single device usage session. Billing works in "segments": every
/// time the session starts, resumes, or switches mode, a new segment
/// begins at [segmentStartAt]. Whenever a segment ends (pause, mode
/// switch, or checkout) its cost — computed at whichever mode's rate
/// was active during that segment — is folded into [accumulatedCost].
/// This is what lets a session flip between "single" and "multi"
/// pricing any number of times and always bill correctly for exactly
/// the time spent in each mode.
///
/// Pausing doesn't delete anything — it freezes billing by accumulating
/// totalPausedMinutes and marking pausedAt, so the elapsed-time math
/// (spec §8) can subtract paused time from the live duration shown on
/// screen (separate from the segment-based cost accounting above).
@DataClassName('SessionRow')
class Sessions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get deviceId => integer().references(Devices, #id)();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();

  /// The employee who opened/is running this session — used to
  /// attribute revenue per employee (spec: daily revenue by employee).
  IntColumn get employeeId => integer().nullable().references(Employees, #id)();

  DateTimeColumn get startTime => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get pausedAt => dateTime().nullable()();
  RealColumn get totalPausedMinutes => real().withDefault(const Constant(0))();

  // single | multi — which rate the CURRENT segment bills at.
  TextColumn get mode => text().withDefault(const Constant('single'))();

  /// Cost already locked in from previous segments (before the current
  /// one). The live/final cost is always accumulatedCost + whatever the
  /// current segment has accrued so far.
  RealColumn get accumulatedCost => real().withDefault(const Constant(0))();

  /// What this sitting billed at each rate, kept apart from
  /// [accumulatedCost] so the detail sheet can say what the single play
  /// and the multi play each cost instead of only their sum.
  ///
  /// Folded forward by the same freeze that stops a segment — never
  /// recomputed from history — so the two always add to
  /// [accumulatedCost] exactly, with no rounding to explain.
  RealColumn get singleCost => real().withDefault(const Constant(0))();
  RealColumn get multiCost => real().withDefault(const Constant(0))();

  /// When the CURRENT segment began. Null while paused (no segment is
  /// running, so nothing is accruing cost).
  DateTimeColumn get segmentStartAt => dateTime().nullable()();

  DateTimeColumn get endTime => dateTime().nullable()();
  // active | paused | timeup | completed
  TextColumn get status => text().withDefault(const Constant('active'))();
  RealColumn get finalCost => real().nullable()();

  /// The fixed duration the cashier picked from the quick buttons
  /// (60 / 30 / 15 / 7). Null = open-ended session that never times out.
  IntColumn get plannedMinutes => integer().nullable()();

  /// Absolute wall-clock moment the paid time runs out. Billing is hard
  /// capped at it (see SessionDao._freezeCurrentSegment), and the moment
  /// it passes the session flips itself to 'timeup': the cost stops and
  /// the device returns to the waiting row without the cashier touching
  /// anything. Pause pushes it forward by the paused duration so a pause
  /// never burns the customer's paid minutes.
  DateTimeColumn get timeUpAt => dateTime().nullable()();

  /// Set when the session was started "from a package" — billing then
  /// becomes the flat [fixedPrice] instead of per-second segment
  /// accrual (segmentStartAt stays null for the whole session).
  IntColumn get packageId => integer().nullable().references(Packages, #id)();
  RealColumn get fixedPrice => real().nullable()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}
