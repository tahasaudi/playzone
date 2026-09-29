import 'package:sqlite3/sqlite3.dart';

void main() {
  final db = sqlite3.open(
    r'C:\Users\HP\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite',
  );
  db.execute('PRAGMA query_only = ON;');

  print('=== running / open sessions ===');
  for (final r in db.select('''
      SELECT s.id, s.device_id, d.name AS device, t.name AS type,
             s.start_time, s.status, s.planned_minutes, s.time_up_at
      FROM sessions s
      JOIN devices d ON s.device_id = d.id
      LEFT JOIN device_types t ON d.device_type_id = t.id
      WHERE s.end_time IS NULL
      ORDER BY s.id DESC''')) {
    print('  sess ${r['id']} | deviceId ${r['device_id']} | name "${r['device']}" '
        '| ${r['type']} | status ${r['status']} | planned ${r['planned_minutes']}');
  }

  print('\n=== which devices are active ===');
  for (final r in db.select('''
      SELECT d.id, d.name, d.status, t.name AS type
      FROM devices d LEFT JOIN device_types t ON d.device_type_id = t.id
      WHERE d.status = 'active'
      ORDER BY d.id''')) {
    print('  id ${r['id']} | "${r['name']}" | ${r['type']}');
  }

  print('\n=== how many sessions per device (all time) ===');
  for (final r in db.select('''
      SELECT d.id, d.name, t.name AS type, COUNT(s.id) AS n
      FROM devices d
      LEFT JOIN device_types t ON d.device_type_id = t.id
      LEFT JOIN sessions s ON s.device_id = d.id
      GROUP BY d.id ORDER BY d.id''')) {
    print('  id ${r['id']} | "${r['name']}" | ${r['type']} | ${r['n']} sessions');
  }
  db.dispose();
}
