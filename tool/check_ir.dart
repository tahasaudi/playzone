import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open(
    r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite',
  );
  final tables = db
      .select("SELECT name FROM sqlite_master WHERE type='table'")
      .map((r) => r['name'] as String)
      .toList();
  for (final t in tables) {
    if (t.toLowerCase().contains('ir') ||
        t.toLowerCase().contains('link') ||
        t.toLowerCase().contains('esp')) {
      try {
        final rows = db.select('SELECT * FROM $t LIMIT 10');
        print('$t -> ${rows.length} row(s)');
        for (final r in rows) {
          print('   ${r.toString()}');
        }
      } catch (e) {
        print('$t -> error $e');
      }
    }
  }
  print('--- devices columns ---');
  for (final r in db.select('PRAGMA table_info(devices)')) {
    print('  ${r['name']}');
  }
  db.dispose();
}
