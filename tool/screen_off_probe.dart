// Asks one screen, word for word, what it does with its own screen command.
//
// The screen's "off" is the command the cashier waits on, and on the shop's
// walls it works once and is then refused once, over and over. This prints
// the exact answers so that the reason can be read instead of guessed.
//
//   dart run tool/screen_off_probe.dart 192.168.1.4
import 'dart:convert';

import 'package:playzone/core/tv/tv_ssap_service.dart';
import 'package:sqlite3/sqlite3.dart';

const String defaultPath =
    r'C:\Users\miza\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite';

Future<void> main(List<String> args) async {
  final address = args.firstWhere(
    (a) => a.contains('.') && !a.startsWith('-'),
    orElse: () => '192.168.1.4',
  );
  final db = sqlite3.open(defaultPath);
  final ssap = TvSsapService.instance;
  await ssap.load(_SqliteKeyStore(db));
  if (!ssap.isPaired(address)) {
    print('$address is not let in');
    return;
  }

  const tvpower = 'ssap://com.webos.service.tvpower/power';
  const tvpowerRoot = 'ssap://com.webos.service.tvpower';
  const oldPower = 'ssap://com.webos.service.tv.power';

  Future<void> ask(String label, String uri, [Map<String, dynamic>? body]) async {
    final started = Stopwatch()..start();
    final answer = await ssap.askRaw(address, uri, body);
    started.stop();
    print('${label.padRight(34)} ${started.elapsedMilliseconds.toString().padLeft(4)}ms  '
        '${answer == null ? 'null' : jsonEncode(answer)}');
  }

  print('--- $address ---');
  for (var cycle = 1; cycle <= 2; cycle++) {
    print('cycle $cycle');
    await ask('state tvpower', '$tvpowerRoot/getPowerState');
    await ask('state tv.power', '$oldPower/getPowerState');
    await ask('OFF tvpower standby', '$tvpower/turnOffScreen',
        const {'standbyMode': 'active'});
    await ask('state tvpower', '$tvpowerRoot/getPowerState');
    await ask('ON  tvpower standby', '$tvpower/turnOnScreen',
        const {'standbyMode': 'active'});
    await ask('state tvpower', '$tvpowerRoot/getPowerState');
    await ask('OFF tvpower standby (2)', '$tvpower/turnOffScreen',
        const {'standbyMode': 'active'});
    await ask('ON  tvpower standby (2)', '$tvpower/turnOnScreen',
        const {'standbyMode': 'active'});
    await ask('OFF tvpower no body', '$tvpower/turnOffScreen');
    await ask('OFF tv.power standby', '$oldPower/turnOffScreen',
        const {'standbyMode': 'active'});
    await ask('ON  tv.power standby', '$oldPower/turnOnScreen',
        const {'standbyMode': 'active'});
    await ask('state tvpower', '$tvpowerRoot/getPowerState');
    print('');
  }
  await ssap.closeAll();
  db.dispose();
}

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
  Future<void> setValue(String key, String value) async {}
}
