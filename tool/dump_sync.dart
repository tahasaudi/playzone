import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final tmp = r'C:\Users\tahas\AppData\Local\Temp\opencode';
  final db = sqlite3.open(args.isNotEmpty ? args[0] : '$tmp\\pz_phone.sqlite');
  db.execute('PRAGMA wal_checkpoint(TRUNCATE)');

  void dump(String label, String sql) {
    final rows = db.select(sql);
    print('== $label ==');
    for (final r in rows) {
      print('  ${r.keys.map((n) => '$n=${r[n]}').join(' | ')}');
    }
  }

  dump('TABLES', "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name");
  dump('APP_SETTINGS', 'SELECT key, value FROM app_settings ORDER BY key');
  dump('SYNC_STATE', 'SELECT key, value FROM sync_state');
  dump('SYNC_LOG', 'SELECT seq, tbl, row_pk, op, pushed FROM sync_log ORDER BY seq DESC LIMIT 25');
  dump('SQLITE_SEQUENCE', 'SELECT name, seq FROM sqlite_sequence');

  for (final t in ['devices', 'categories', 'products', 'customers', 'invoices', 'sessions']) {
    final rows = db.select('SELECT COUNT(*) AS c FROM "$t"');
    print('COUNT $t = ${rows[0]['c']}');
  }

  db.dispose();
}