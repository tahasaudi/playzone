import 'package:drift/drift.dart';
import 'sessions_table.dart';

/// One thing that happened inside a session, with the moment it happened.
///
/// The session row itself only records the *current* answer — the mode it is
/// in, whether it is paused, which wall is showing it. Every new answer
/// overwrites the last one, so once a table is cleared there is no way left to
/// say WHEN it was paused or when it went multi. The café's question is exactly
/// that: not "was it paused", but "when".
///
/// Append-only, like the audit log: an event that happened happened. There is
/// deliberately no update or delete path.
@DataClassName('SessionEventRow')
class SessionEvents extends Table {
  IntColumn get id => integer().autoIncrement()();

  IntColumn get sessionId => integer().references(Sessions, #id)();

  /// start | pause | resume | screen_on | screen_off | mode | extend | timeup
  TextColumn get type => text()();

  DateTimeColumn get at => dateTime().withDefault(currentDateAndTime)();

  /// The value an event carries when its type alone is not the answer — the
  /// mode it switched TO, the minutes an extension bought, the wall it
  /// pointed at.
  TextColumn get note => text().nullable()();
}
