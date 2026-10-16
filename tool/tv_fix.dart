// One-off TV-settings fixer. Touches ONLY the tv_* keys in app_settings.
// Run:  dart run tool/tv_fix.dart [path-to-sqlite] [apply]
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final path = args.isNotEmpty
      ? args[0]
      : r'C:\Users\miza\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite';
  final apply = args.contains('apply');
  final db = apply
      ? sqlite3.open(path)
      : sqlite3.open(path, mode: OpenMode.readOnly);
  print('=== $path (apply=$apply) ===');
  print('columns -> ' +
      db
          .select("SELECT name FROM pragma_table_info('app_settings')")
          .map((r) => r['name'])
          .join(', '));
  print('--- tv_* before ---');
  for (final r in db.select(
      "SELECT key, value, updated_at FROM app_settings WHERE key LIKE 'tv_%' ORDER BY key")) {
    print('  ${r['key']} = ${r['value']}');
  }

  if (apply) {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    void put(String k, String v) {
      final existing = db.select(
          'SELECT key FROM app_settings WHERE key = ?', [k]);
      if (existing.isEmpty) {
        db.execute(
            'INSERT INTO app_settings(key, value, updated_at) VALUES(?,?,?)',
            [k, v, now]);
      } else {
        db.execute(
            'UPDATE app_settings SET value = ?, updated_at = ? WHERE key = ?',
            [v, now, k]);
      }
    }

    put('tv_enabled', '1');
    put('tv_device_id', '1');
    put('tv_name', 'الشاشة الأولى (55 بوصة)');
    // Second wall screen: the 65" by the PS5 corner, bound to PS5 #4.
    put('tv_ip_2', '192.168.1.31');
    put('tv_device_id_2', '4');
    put('tv_name_2', 'الشاشة التانية (65 بوصة)');
    // Third wall screen: the 55" found on the LAN. Left WITHOUT a device so it
    // can be linked to its console from the screens-management page.
    put('tv_ip_3', '192.168.1.38');
    put('tv_name_3', 'الشاشة التالتة (55 بوصة)');
    // Fourth wall screen: the 65" LG 65UQ80006LD. No device -> link from the UI.
    put('tv_ip_4', '192.168.1.13');
    put('tv_name_4', 'الشاشة الرابعة (65 بوصة)');
    // Fifth wall screen: the LG UR78006LL. No device -> link from the UI.
    put('tv_ip_5', '192.168.1.11');
    put('tv_name_5', 'الشاشة الخامسة');
    print('--- tv_* after ---');
    for (final r in db.select(
        "SELECT key, value FROM app_settings WHERE key LIKE 'tv_%' ORDER BY key")) {
      print('  ${r['key']} = ${r['value']}');
    }
    print('applied.');
  }
  db.dispose();
}
