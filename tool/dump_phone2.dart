import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final tmp = r'C:\Users\tahas\AppData\Local\Temp\opencode';
  final db = sqlite3.open('$tmp\\pz_phone2.sqlite');
  db.execute('PRAGMA wal_checkpoint(TRUNCATE)');

  void dump(String label, String sql) {
    final rows = db.select(sql);
    print('== $label ==');
    for (final r in rows) {
      print('  ${r.keys.map((n) => '$n=${r[n]}').join(' | ')}');
    }
  }

  dump('APP_SETTINGS', 'SELECT key, value FROM app_settings ORDER BY key');
  dump('SYNC_STATE', 'SELECT key, value FROM sync_state');
  dump('SYNC_LOG', 'SELECT seq, tbl, row_pk, op, pushed FROM sync_log ORDER BY seq DESC LIMIT 10');
  dump('DEVICES', 'SELECT id, name, device_type_id FROM devices ORDER BY id');
  dump('CATEGORIES', 'SELECT id, name FROM categories ORDER BY id');
  dump('PRODUCTS', 'SELECT id, name, selling_price FROM products ORDER BY id LIMIT 5');
  dump('SEQ_DEVICES', "SELECT seq FROM sqlite_sequence WHERE name='devices'");

  db.dispose();
}