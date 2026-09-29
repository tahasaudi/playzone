import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open(
    r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite',
  );
  db.execute('PRAGMA query_only = ON;');

  final rows = db.select(
      "SELECT key, value FROM app_settings WHERE key LIKE 'ir%' OR key LIKE '%ir_box%'");
  print('=== IR settings ===');
  if (rows.isEmpty) {
    print('  (none — no IR box is linked to any device)');
  }
  for (final r in rows) {
    print('  ${r['key']} = ${r['value']}');
  }
  db.dispose();
}
