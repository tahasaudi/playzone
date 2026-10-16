// One-off schema/link inspector. Read-only.
// Run: dart run tool/db_links.dart [path]
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final path = args.isNotEmpty
      ? args[0]
      : r'C:\Users\miza\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite';
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  print('=== $path ===');
  print('tables: ' +
      db
          .select("SELECT name FROM sqlite_master WHERE type='table' ORDER BY name")
          .map((r) => r['name'])
          .join(', '));

  final devCols = db
      .select("SELECT name FROM pragma_table_info('devices')")
      .map((r) => r['name'])
      .toList();
  print('devices columns: ${devCols.join(', ')}');

  print('--- devices (all, with active) ---');
  for (final r in db.select(
      'SELECT d.id, d.name, t.name AS type, d.active FROM devices d '
      'LEFT JOIN device_types t ON t.id = d.device_type_id ORDER BY d.id')) {
    print('  #${r['id']} ${r['name']} type=${r['type']} active=${r['active']}');
  }

  print('--- ALL app_settings ---');
  for (final r in db.select(
      'SELECT key, value FROM app_settings ORDER BY key')) {
    print('  ${r['key']} = ${r['value']}');
  }
  db.dispose();
}
