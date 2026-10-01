import 'package:sqlite3/sqlite3.dart';

/// Binds one wall screen to one machine, by name, without touching anything
/// else. This is the tool you reach for when a screen is being moved to a
/// different corner, or a machine is being renamed, and the only thing that
/// actually changes is which device id sits in the settings row.
///
/// It prints the current state before it writes, and prints it again after, so
/// a wrong binding is visible in the log rather than discovered on a wall.
void main(List<String> args) {
  final db = sqlite3.open(
    r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite',
  );

  void out(String s) => print(s);

  out('=== machines ===');
  for (final r in db.select('SELECT id, name FROM devices ORDER BY id')) {
    out('  id ${r['id']}  "${r['name']}"');
  }

  // The sessions table has no started_at column on this schema, so it is read
  // the same way the app reads it: all columns, filtered by status.
  out('');
  out('=== live sessions ===');
  final sessions =
      db.select("SELECT * FROM sessions WHERE status = 'running' ORDER BY id DESC");
  if (sessions.isEmpty) {
    out('  none');
  } else {
    for (final s in sessions) {
      final m = <String>[];
      s.forEach((k, v) => m.add('$k=$v'));
      out('  ${m.join('  ')}');
    }
  }

  out('');
  out('=== screens as configured now ===');
  for (final r in db.select(
      "SELECT key, value FROM app_settings WHERE key LIKE 'tv_%' ORDER BY key")) {
    out('  ${r['key']} = "${r['value']}"');
  }

  // Nothing is written until both the screen and the machine are named. A
  // half-specified command must not be allowed to guess, because a guess here
  // silently points a paid-for wall at a machine that is not there.
  if (args.length < 2) {
    out('');
    out('Nothing written.');
    out('usage: dart run tool/bind_screen.dart <1|2> <machine name>');
    db.dispose();
    return;
  }

  final which = args[0];
  final wanted = args[1].trim();

  final key = switch (which) {
    '1' => 'tv_device_id',
    '2' => 'tv_device_id_2',
    _ => null,
  };
  if (key == null) {
    out('');
    out('!! Screen "$which" is not one of the two slots (use 1 or 2). '
        'NOT writing anything.');
    db.dispose();
    return;
  }

  final rows =
      db.select('SELECT id FROM devices WHERE TRIM(CAST(name AS TEXT)) = ?', [wanted]);
  if (rows.isEmpty) {
    out('');
    out('!! No machine is named "$wanted". NOT writing anything.');
    out('   The names above are the only ones that will match.');
    db.dispose();
    return;
  }
  final id = rows.first['id'] as int;

  // Two screens sharing a machine means one session drives two walls, and one
  // of them is then either dark or showing the other customer's game. Refuse
  // rather than allow it.
  final otherKey = which == '1' ? 'tv_device_id_2' : 'tv_device_id';
  final other = db.select('SELECT value FROM app_settings WHERE key = ?', [otherKey]);
  if (other.isNotEmpty && other.first['value'].toString() == '$id') {
    out('');
    out('!! Screen $which is already on machine $id, and so is the other '
        'screen. NOT writing anything.');
    db.dispose();
    return;
  }

  final before = db.select('SELECT value FROM app_settings WHERE key = ?', [key]);
  final beforeText = before.isEmpty ? '(unset)' : before.first['value'].toString();

  db.execute(
    "INSERT INTO app_settings (key, value, updated_at) "
    "VALUES (?, ?, strftime('%s','now')) "
    "ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at",
    [key, '$id'],
  );

  out('');
  out('=== changed ===');
  out('  screen $which  $beforeText -> $id   (machine "$wanted")');
  for (final r in db.select(
      "SELECT key, value FROM app_settings WHERE key LIKE 'tv_device_id%' ORDER BY key")) {
    out('  ${r['key']} = "${r['value']}"');
  }
  out('');
  out('The running app reads these once at startup, so restart PlayZone for '
      'the new binding to take effect.');

  db.dispose();
}
