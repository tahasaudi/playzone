// Measures how long the sound buttons take to reach a screen and be answered.
//
// A button that takes a second to answer feels broken to the person holding
// it, and a button that takes five feels like the program is hung. So the
// time is measured here, per screen, and printed in milliseconds.
//
//   dart run tool/ssap_speed.dart              # every screen that has a key
//   dart run tool/ssap_speed.dart 192.168.1.4  # just that one
import 'dart:io';

import 'package:playzone/core/tv/tv_ssap_service.dart';
import 'package:sqlite3/sqlite3.dart';

const String defaultPath =
    r'C:\Users\miza\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite';

/// The screens of this shop.
const List<String> screens = [
  '192.168.1.4',
  '192.168.1.5',
  '192.168.1.7',
  '192.168.1.3',
  '192.168.1.11',
];

Future<void> main(List<String> args) async {
  final path = args.isNotEmpty && _looksLikeAPath(args[0])
      ? args[0]
      : defaultPath;
  final file = File(path);
  if (!file.existsSync()) {
    print('no database at $path');
    return;
  }
  final wanted = args.where((a) => !a.startsWith('-')).toList();
  final targets = wanted.isEmpty ? screens : wanted;

  final ssap = TvSsapService.instance;
  await ssap.load(_SqliteKeyStore(sqlite3.open(path)));
  print('keys: ${targets.map((ip) => '$ip=${ssap.isPaired(ip)}').join(' ')}');

  for (final ip in targets) {
    if (!ssap.isPaired(ip)) {
      print('$ip  not let in');
      continue;
    }
    await _time(ssap, ip, 'open the socket', () => ssap.getVolume(ip));
    await _time(ssap, ip, 'read the level', () => ssap.getVolume(ip));
    await _time(ssap, ip, 'up five', () => ssap.changeVolume(ip, 5));
    await _time(ssap, ip, 'up five again', () => ssap.changeVolume(ip, 5));
    await _time(ssap, ip, 'down five', () => ssap.changeVolume(ip, -5));
  }
  // An open socket keeps the program alive, so it is shut before finishing.
  await ssap.closeAll();
}

/// Whether the argument is a file path rather than a screen address.
bool _looksLikeAPath(String argument) =>
    argument.contains(':') || argument.contains('\\');

/// Runs one command and says how long it took.
Future<void> _time(
  TvSsapService ssap,
  String ip,
  String what,
  Future<int?> Function() action,
) async {
  final started = DateTime.now();
  int? level;
  try {
    level = await action();
  } catch (_) {
    level = null;
  }
  final ms = DateTime.now().difference(started).inMilliseconds;
  print('$ip  $what  ${ms}ms  level=${level ?? "no answer"}');
}

/// The pairing keys, read from the shop's own settings table.
class _SqliteKeyStore implements TvSsapKeyStore {
  _SqliteKeyStore(this._db);

  final Database _db;

  @override
  Future<String?> getValue(String key) async {
    final rows =
        _db.select('SELECT value FROM app_settings WHERE key = ?', [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  @override
  Future<void> setValue(String key, String value) async {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    _db.execute(
      'INSERT INTO app_settings (key, value, updated_at) VALUES (?, ?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value, '
      'updated_at = excluded.updated_at',
      [key, value, now],
    );
  }
}
