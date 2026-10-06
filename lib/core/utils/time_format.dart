/// The café's own words for a clock.
///
/// Every printed time in PlayZone goes through here, so the whole program
/// answers "متى؟" the same way: **ص** صباحاً, **م** مساءاً — never a bare
/// 21:04 that the person behind the counter has to stop and translate. The
/// rule the shop asked for is program-wide, and a program-wide rule is only
/// real if there is one place to read it and one place to change it.
///
/// Elapsed time is NOT a clock and does not belong here. A session that has
/// run for 1:05:30 is a duration, not an hour of the day — it stays in plain
/// digits because nobody would say "من ساعة وخمس دقائق مساءاً".
library;

const String _am = 'ص';
const String _pm = 'م';

String _pad(int n) => n.toString().padLeft(2, '0');

/// `9:05 ص` · `12:00 م` · `11:59 م`
///
/// Twelve-hour with no leading zero on the hour, because that is how a clock
/// is read aloud here — `09:05` is a machine's idea of a time, `9:05 ص` is
/// a person's.
String clockOf(DateTime time) {
  final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$h:${_pad(time.minute)} ${time.hour < 12 ? _am : _pm}';
}

/// `9:05:30 ص` — [clockOf] for the handful of places where the second matters.
String clockWithSecondsOf(DateTime time) {
  final h = time.hour % 12 == 0 ? 12 : time.hour % 12;
  return '$h:${_pad(time.minute)}:${_pad(time.second)} '
      '${time.hour < 12 ? _am : _pm}';
}

/// `6/10/2026` — the day on its own, when the screen has said the day
/// elsewhere and repeating it would push the clock off the edge.
String dayOf(DateTime time) => '${time.day}/${time.month}/${time.year}';

/// `6/10/2026 9:05 ص` — a full stamp, for tables and ledgers.
String stampOf(DateTime time) => '${dayOf(time)} ${clockOf(time)}';

/// A day range label, `6/10` — short enough to sit above a column.
String shortDayOf(DateTime time) => '${time.day}/${time.month}';

/// An [hour] of the clock as it is said out loud: `5:00 م`.
///
/// For package windows and reservations, where the number is an hour of the
/// day and 17:00 would be read as a mistake.
String hourOf(int hour) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:00 ${hour < 12 ? _am : _pm}';
}

/// A picked [hour] and [minute] as they will be printed in a chip.
///
/// Kept as two ints rather than a `TimeOfDay` so this file stays pure Dart —
/// the clock rule belongs to the data, not to the widgets, and the TV report
/// has to read the same way without importing Flutter.
String clockOfDay(int hour, int minute) {
  final h = hour % 12 == 0 ? 12 : hour % 12;
  return '$h:${_pad(minute)} ${hour < 12 ? _am : _pm}';
}
