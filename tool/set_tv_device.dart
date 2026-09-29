import 'package:sqlite3/sqlite3.dart';

/// Two wall screens again, each following one machine:
///   55"  192.168.1.22 -> machine "2" (PS4 corner)
///   65"  192.168.1.31 -> machine "4" (PS5 corner)
void main() {
  final db = sqlite3.open(
    r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite',
  );

  int? idFor(String name) {
    final rows = db.select(
        "SELECT id FROM devices WHERE TRIM(CAST(name AS TEXT)) = ?", [name]);
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  final ps4 = idFor('2');
  final ps5 = idFor('4');
  print('machine "2" (PS4 corner) = $ps4');
  print('machine "4" (PS5 corner) = $ps5');

  void put(String key, String value) {
    db.execute(
      "INSERT INTO app_settings (key, value, updated_at) VALUES (?, ?, strftime('%s','now')) "
      "ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at",
      [key, value],
    );
  }

  put('tv_ip', '192.168.1.22');
  put('tv_device_id', '${ps4 ?? 'all'}');
  put('tv_ip_2', '192.168.1.31');
  put('tv_device_id_2', '${ps5 ?? 'all'}');
  put('tv_enabled', '1');
  put('tv_show_cards', '0');

  print('\n=== screens ===');
  for (final r in db.select(
      "SELECT key, value FROM app_settings WHERE key LIKE 'tv_%' ORDER BY key")) {
    print('  ${r['key']} = "${r['value']}"');
  }
  db.dispose();
}
