import 'package:sqlite3/sqlite3.dart';

/// Sets up one wall screen: its address, its name and which machine it drives.
///
/// This is the tool you reach for when a television is mounted, moved to a
/// different corner, or plugged in for the first time. It writes one screen and
/// touches nothing else, and it refuses rather than guesses.
///
/// It prints the whole current setup before it writes and the changed screen
/// after, so a wrong binding is visible in this log rather than discovered on a
/// wall with a customer watching.
///
///   dart run tool/bind_screen.dart <screen> <machine name> [ip] [name]
///
/// <screen> is 1 to 6. The address and name are optional: pass them to set a
/// new screen up, leave them out to only move it to a different machine.
void main(List<String> args) {
  final db = sqlite3.open(
    r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite',
  );

  void out(String s) => print(s);

  /// The setting keys for one screen, numbered from 1.
  ///
  /// One place, so the third screen is not a special case anyone has to
  /// remember to spell — and so this tool and the app cannot disagree about
  /// where a screen is stored.
  String keyOf(int screen, String kind) {
    final suffix = switch (kind) {
      'ip' => 'ip',
      'device' => 'device_id',
      _ => 'name',
    };
    return screen == 1 ? 'tv_$suffix' : 'tv_${suffix}_$screen';
  }

  const maxScreens = 6;

  void showSetup() {
    out('');
    out('=== screens as configured now ===');
    final rows = db.select(
        "SELECT key, value FROM app_settings WHERE key LIKE 'tv_%' ORDER BY key");
    if (rows.isEmpty) out('  (none saved)');
    for (final r in rows) {
      out('  ${r['key']} = "${r['value']}"');
    }
  }

  out('=== machines ===');
  for (final r in db.select('SELECT id, name FROM devices ORDER BY id')) {
    out('  id ${r['id']}  "${r['name']}"');
  }

  // The sessions table has no started_at column on this schema, so it is read
  // the same way the app reads it: all columns, filtered by status. A screen
  // being moved out from under a live session is the one mistake here that
  // reaches a customer, so it is worth seeing before writing.
  out('');
  out('=== live sessions ===');
  final sessions = db
      .select("SELECT * FROM sessions WHERE status = 'running' ORDER BY id DESC");
  if (sessions.isEmpty) {
    out('  none');
  } else {
    for (final s in sessions) {
      final m = <String>[];
      s.forEach((k, v) => m.add('$k=$v'));
      out('  ${m.join('  ')}');
    }
  }
  showSetup();

  if (args.isEmpty) {
    out('');
    out('Nothing written.');
    out('usage: dart run tool/bind_screen.dart <1-$maxScreens> '
        '<machine name> [ip] [name]');
    db.dispose();
    return;
  }

  // Nothing is written until the screen and the machine are both named. A
  // half-specified command must not be allowed to guess, because a guess here
  // silently points a paid-for wall at a machine that is not there.
  final screen = int.tryParse(args[0].trim());
  if (screen == null || screen < 1 || screen > maxScreens) {
    out('');
    out('!! Screen "${args[0]}" is not one of 1-$maxScreens. NOT writing '
        'anything.');
    db.dispose();
    return;
  }
  if (args.length < 2) {
    out('');
    out('!! Which machine? NOT writing anything.');
    out('usage: dart run tool/bind_screen.dart <1-$maxScreens> '
        '<machine name> [ip] [name]');
    db.dispose();
    return;
  }

  final wanted = args[1].trim();
  final machine =
      db.select('SELECT id FROM devices WHERE TRIM(CAST(name AS TEXT)) = ?',
          [wanted]);
  if (machine.isEmpty) {
    out('');
    out('!! No machine is named "$wanted". NOT writing anything.');
    out('   The names above are the only ones that will match.');
    db.dispose();
    return;
  }
  final id = machine.first['id'] as int;

  String? read(String key) {
    final r = db.select('SELECT value FROM app_settings WHERE key = ?', [key]);
    return r.isEmpty ? null : r.first['value'].toString();
  }

  // Two screens sharing a machine means one session drives two walls, and one
  // of them is then either dark or showing the other customer's game. Refuse
  // rather than allow it, and say which screen already has it.
  for (var other = 1; other <= maxScreens; other++) {
    if (other == screen) continue;
    if (read(keyOf(other, 'device')) == '$id') {
      out('');
      out('!! Machine $id ("$wanted") is already on screen $other. '
          'NOT writing anything.');
      out('   One machine drives one screen. Unbind it there first.');
      db.dispose();
      return;
    }
  }

  final newIp = args.length > 2 ? args[2].trim() : null;
  // The same rule for the address: two slots on one television is one wall that
  // does not react at checkout, described as two broken screens.
  if (newIp != null && newIp.isNotEmpty) {
    for (var other = 1; other <= maxScreens; other++) {
      if (other == screen) continue;
      if (read(keyOf(other, 'ip'))?.trim() == newIp) {
        out('');
        out('!! $newIp is already on screen $other. NOT writing anything.');
        db.dispose();
        return;
      }
    }
  }

  final newName = args.length > 3 ? args[3].trim() : null;
  final isNewScreen = (read(keyOf(screen, 'ip')) ?? '').trim().isEmpty;

  // A screen with no address is one nothing can be sent to, so a new screen
  // without one is refused rather than saved as a row that silently does
  // nothing. An existing screen may keep its address.
  if (isNewScreen && (newIp == null || newIp.isEmpty)) {
    out('');
    out('!! Screen $screen has no address yet, and none was given. NOT '
        'writing anything.');
    out('   usage: dart run tool/bind_screen.dart $screen "$wanted" '
        '<ip> [name]');
    db.dispose();
    return;
  }

  void write(String key, String value) {
    db.execute(
      "INSERT INTO app_settings (key, value, updated_at) "
      "VALUES (?, ?, strftime('%s','now')) "
      "ON CONFLICT(key) DO UPDATE SET value = excluded.value, "
      "updated_at = excluded.updated_at",
      [key, value],
    );
  }

  final changes = <String>[];
  final ipKey = keyOf(screen, 'ip');
  if (newIp != null && newIp.isNotEmpty) {
    final before = read(ipKey) ?? '(unset)';
    write(ipKey, newIp);
    changes.add('  $ipKey   $before -> $newIp');
  }
  write(keyOf(screen, 'device'), '$id');

  // Named on first sight, never left blank: a screen with no name is a screen
  // nobody can point at over the counter, which is the whole reason names are
  // stored rather than made up from the address.
  final nameKey = keyOf(screen, 'name');
  if (newName != null && newName.isNotEmpty) {
    final before = read(nameKey) ?? '(unset)';
    write(nameKey, newName);
    changes.add('  $nameKey   $before -> $newName');
  } else if ((read(nameKey) ?? '').trim().isEmpty) {
    write(nameKey, 'شاشة $screen');
    changes.add('  $nameKey   (unset) -> شاشة $screen');
  }

  out('');
  out('=== changed ===');
  out('  screen $screen -> machine $id ("$wanted")'
      '${isNewScreen ? "   (new screen)" : ""}');
  for (final c in changes) {
    out(c);
  }
  showSetup();
  out('');
  out('The running app reads these once at startup, so restart PlayZone for '
      'the new binding to take effect.');

  db.dispose();
}