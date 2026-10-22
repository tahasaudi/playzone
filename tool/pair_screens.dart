// Lets this program in on every screen, one screen at a time.
//
// Each television asks on its own screen and the staff presses OK on the
// remote for that television. The key it hands back is written straight to
// the shop's settings, so the program never asks again.
//
//   dart run tool/pair_screens.dart                 # every screen
//   dart run tool/pair_screens.dart 192.168.1.5     # just that one
import 'dart:io';

import 'package:playzone/core/tv/tv_ssap_service.dart';
import 'package:sqlite3/sqlite3.dart';

const String defaultPath =
    r'C:\Users\miza\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite';

/// The screens of this shop, in the order they are asked.
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

  for (final ip in targets) {
    if (ssap.isPaired(ip)) {
      print('$ip  already let in');
      continue;
    }
    print('');
    print('$ip  ->  press OK on that television now...');
    final result = await ssap.pair(ip, askForPin: _askForPin);
    if (result.paired) {
      print('$ip  OK');
    } else {
      print('$ip  FAILED  ${result.error}');
    }
  }

  print('');
  print('--- what is stored now ---');
  for (final ip in targets) {
    print('$ip -> ${ssap.isPaired(ip) ? ssap.keyFor(ip) : "not let in"}');
  }
  await ssap.closeAll();
}

/// Whether the argument is a file path rather than a screen address.
bool _looksLikeAPath(String argument) =>
    argument.contains(':') || argument.contains('\\');

/// Asks for the number some televisions put on the screen instead of a yes/no
/// question.
Future<String?> _askForPin() async {
  print('   type the number shown on that television:');
  final line = stdin.readLineSync();
  return (line == null || line.trim().isEmpty) ? null : line.trim();
}

/// The pairing keys, kept in the shop's own settings table.
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
