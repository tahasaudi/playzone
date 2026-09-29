// One-off verification helper (not part of the app).
// Run with:  dart run tool/verify_db.dart [path-to-sqlite]
import 'package:sqlite3/sqlite3.dart';

void main(List<String> args) {
  final path = args.isEmpty
      ? r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite'
      : args.first;
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  print('=== $path ===');

  int count(String sql) =>
      db.select(sql).first.values.first as int? ?? 0;

  Set<String> columns(String table) => db
      .select("SELECT name FROM pragma_table_info('$table')")
      .map((r) => r['name'] as String)
      .toSet();

  final sessionCols = columns('sessions');
  final itemCols = columns('stock_count_items');
  print('schema v9 -> planned_minutes:${sessionCols.contains('planned_minutes')}'
      ' time_up_at:${sessionCols.contains('time_up_at')}'
      ' counted:${itemCols.contains('counted')}');

  print('active devices -> ' + db
      .select('''SELECT d.name || ':' || t.name AS x FROM devices d
                 JOIN device_types t ON t.id = d.device_type_id
                 WHERE d.active = 1 ORDER BY d.id''')
      .map((r) => r['x'])
      .join(' | '));

  print('catalog -> products:${count('SELECT COUNT(*) FROM products')}'
      ' categories:${count('SELECT COUNT(*) FROM categories')}'
      ' invoices:${count('SELECT COUNT(*) FROM invoices')}'
      ' sessions:${count('SELECT COUNT(*) FROM sessions')}');

  print('drinks (مشروبات) -> ' + db
      .select('''SELECT p.name FROM products p JOIN categories c
                 ON c.id = p.category_id
                 WHERE c.name = 'مشروبات' AND p.active = 1 ORDER BY p.id''')
      .map((r) => r['name'])
      .join(' , '));
}
