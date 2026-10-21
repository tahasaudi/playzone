import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final tmp = r'C:\Users\tahas\AppData\Local\Temp\opencode';
  final db = sqlite3.open('$tmp\\pz_phone.sqlite');
  db.execute('PRAGMA wal_checkpoint(TRUNCATE)');
  final setUrl = args.isNotEmpty && args.first == 'seturl';
  if (setUrl) {
    db.execute(
        "INSERT OR REPLACE INTO app_settings(key, value) "
        "VALUES ('sync_server_url', 'http://10.0.2.2:41779')");
    print('set sync_server_url = http://10.0.2.2:41779');
  }
  final rows = db.select('SELECT key, value FROM app_settings ORDER BY key');
  for (final r in rows) {
    print('  ${r.keys.map((n) => '$n=${r[n]}').join(' | ')}');
  }
  final st = db.select('SELECT key, value FROM sync_state');
  final stRows = [for (final r in st) '${r['key']}=${r['value']}'];
  print('sync_state: ${stRows.isEmpty ? "(empty)" : stRows.join(', ')}');
  db.dispose();
}