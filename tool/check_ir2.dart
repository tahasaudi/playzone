import 'package:sqlite3/sqlite3.dart';
void main() {
  final db = sqlite3.open(r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite');
  print('=== tables with ir/tv in the name ===');
  for (final r in db.select("SELECT name FROM sqlite_master WHERE type='table' AND (name LIKE '%ir%' OR name LIKE '%tv%' OR name LIKE '%remote%')")) {
    print('  ${r['name']}');
  }
  print('=== ir slots ===');
  try {
    for (final r in db.select('SELECT * FROM ir_slots')) {
      print('  ${r.toString()}');
    }
  } catch (e) { print('  ir_slots: $e'); }
  try {
    for (final r in db.select('SELECT * FROM ir_box_link_map')) {
      print('  link: ${r.toString()}');
    }
  } catch (e) { print('  ir_box_link_map: $e'); }
  db.dispose();
}
