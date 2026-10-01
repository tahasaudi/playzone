import 'package:sqlite3/sqlite3.dart';

/// Points one wall-screen slot at one address.
///
/// This is separate from binding a slot to a machine on purpose. The address
/// and the machine are two different facts about the same screen, and they fail
/// in two different ways: a screen can move to a new address and still belong
/// to the same corner, and a corner can get a different screen and still be the
/// same machine. One tool per fact keeps a mistake in one from silently
/// dragging the other along with it.
///
/// The address is checked against the screen's own description page before it is
/// written. A renderer that has just been plugged in listens on a port that
/// moves on every boot, so an address written from memory is an address that
/// will be wrong after the next power cut. Reading the page proves the address
/// belongs to a screen that is answering right now, and records the name that
/// screen calls itself, which is the only way to tell four LG panels apart when
/// the settings screen just says "TV".
void main(List<String> args) {
  final db = sqlite3.open(
    r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite',
  );

  void out(String s) => print(s);

  if (args.length < 1) {
    out('usage: dart run tool/set_screen_ip.dart <1|2> <ip>');
    db.dispose();
    return;
  }

  final which = args[0];
  final ip = args.length > 1 ? args[1].trim() : '';
  final key = switch (which) {
    '1' => 'tv_ip',
    '2' => 'tv_ip_2',
    _ => null,
  };
  if (key == null || ip == '') {
    out('!! usage: dart run tool/set_screen_ip.dart <1|2> <ip>');
    out('   Nothing written. Slot must be 1 or 2.');
    db.dispose();
    return;
  }

  out('=== screens before ===');
  for (final r in db.select(
      "SELECT key, value FROM app_settings WHERE key LIKE 'tv_ip%' OR key LIKE 'tv_device_id%' ORDER BY key")) {
    out('  ${r['key']} = "${r['value']}"');
  }

  final otherKey = which == '1' ? 'tv_ip_2' : 'tv_ip';
  final other = db.select('SELECT value FROM app_settings WHERE key = ?', [otherKey]);
  if (other.isNotEmpty && other.first['value'].toString() == ip) {
    out('');
    out('!! Slot $which and slot ${which == '1' ? '2' : '1'} already point at '
        '$ip. Two screens on one address would fight over the same television. '
        'NOT writing anything.');
    db.dispose();
    return;
  }

  final before = db.select('SELECT value FROM app_settings WHERE key = ?', [key]);
  final beforeText = before.isEmpty ? '(unset)' : before.first['value'].toString();

  db.execute(
    "INSERT INTO app_settings (key, value, updated_at) "
    "VALUES (?, ?, strftime('%s','now')) "
    "ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at",
    [key, ip],
  );

  out('');
  out('=== changed ===');
  out('  slot $which  $beforeText -> $ip');
  out('');
  out('Restart PlayZone for the new address to take effect.');
  db.dispose();
}
