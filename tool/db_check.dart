// One-off read-only data check (not part of the app).
// Run with:  dart run tool/db_check.dart [path-to-sqlite]
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final path = args.isEmpty
      ? r'C:\Users\miza\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite'
      : args.first;
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  print('=== $path ===');
  print('user_version -> ${db.select('PRAGMA user_version').first.values.first}');

  int count(String sql) => db.select(sql).first.values.first as int? ?? 0;

  print('products=${count('SELECT COUNT(*) FROM products')}'
      ' categories=${count('SELECT COUNT(*) FROM categories')}'
      ' invoices=${count('SELECT COUNT(*) FROM invoices')}'
      ' sessions=${count('SELECT COUNT(*) FROM sessions')}');

  print('products columns -> ' +
      db
          .select("SELECT name FROM pragma_table_info('products')")
          .map((r) => r['name'])
          .join(', '));

  print('--- categories ---');
  for (final r in db.select('SELECT id, name FROM categories ORDER BY id')) {
    print('  #${r['id']} ${r['name']}');
  }

  print('--- all products ---');
  for (final r in db.select(
      'SELECT p.id, p.name, p.category_id, p.active FROM products p ORDER BY p.id')) {
    print('  #${r['id']} ${r['name']} cat=${r['category_id']} active=${r['active']}');
  }

  print('--- newest invoices (cashier) ---');
  for (final r in db.select(
      'SELECT id, total, created_at FROM invoices ORDER BY id DESC LIMIT 5')) {
    print('  #${r['id']} total=${r['total']} at=${r['created_at']}');
  }
  print('invoice totals sum -> '
      '${db.select('SELECT COALESCE(SUM(total),0) s FROM invoices').first['s']}');

  print('--- app_settings (TV first) ---');
  for (final r in db.select(
      'SELECT key, value FROM app_settings ORDER BY key')) {
    print('  ${r['key']} = ${r['value']}');
  }
  db.dispose();
}
