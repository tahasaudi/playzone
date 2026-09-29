import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open(
    r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite',
  );
  db.execute('PRAGMA query_only = ON;');

  final tables = [
    for (final r in db.select(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name"))
      r['name'] as String
  ];
  print('=== tables ===');
  for (final t in tables) {
    print('  $t');
  }

  for (final t in tables) {
    if (!t.toLowerCase().contains('setting')) continue;
    print('\n=== $t ===');
    for (final r in db.select('SELECT * FROM "$t"')) {
      print('  $r');
    }
  }

  print('\n=== sessions columns ===');
  for (final r in db.select('PRAGMA table_info(sessions)')) {
    print('  ${r['name']}');
  }
  db.dispose();
}
