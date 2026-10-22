// Reads and writes the screen pairing keys in the shop's real database.
//
// The screens are let in once, by the television itself, and the key it hands
// out is kept with the rest of the settings. This tool exists so the key can
// be put there from the outside as well — for a screen that was let in by
// hand, or after the database was moved.
//
//   dart run tool/ssap_key_tool.dart                 # show what is stored
//   dart run tool/ssap_key_tool.dart --set <ip> <key> # remember a key
//   dart run tool/ssap_key_tool.dart --forget <ip>    # forget one
import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

const String defaultPath =
    r'C:\Users\miza\AppData\Roaming\PlayZone\PlayZone\playzone.sqlite';

const String settingsKey = 'tv_ssap_keys';

void main(List<String> args) {
  final path = args.isNotEmpty && !args[0].startsWith('--')
      ? args[0]
      : defaultPath;
  final file = File(path);
  if (!file.existsSync()) {
    stderr.writeln('no database at $path');
    exit(1);
  }

  final db = sqlite3.open(path);
  try {
    final rows = db.select(
      'SELECT key, value FROM app_settings WHERE key = ?',
      [settingsKey],
    );
    final keys = <String, String>{};
    if (rows.isNotEmpty) {
      final raw = rows.first['value'] as String?;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          decoded.forEach((address, key) {
            if (address is String && key is String) keys[address] = key;
          });
        }
      }
    }

    if (args.contains('--set')) {
      final at = args.indexOf('--set');
      if (at + 2 >= args.length) {
        stderr.writeln('usage: --set <address> <key>');
        exit(1);
      }
      keys[args[at + 1]] = args[at + 2];
      _write(db, keys);
      stdout.writeln('remembered ${keys.length} screen(s)');
      return;
    }

    if (args.contains('--forget')) {
      final at = args.indexOf('--forget');
      if (at + 1 >= args.length) {
        stderr.writeln('usage: --forget <address>');
        exit(1);
      }
      keys.remove(args[at + 1]);
      _write(db, keys);
      stdout.writeln('remembered ${keys.length} screen(s)');
      return;
    }

    if (keys.isEmpty) {
      stdout.writeln('no screen has been let in yet');
      return;
    }
    keys.forEach((address, key) {
      stdout.writeln('$address -> $key');
    });
  } finally {
    db.dispose();
  }
}

/// Writes the keys back, in the shape the settings table expects.
void _write(Database db, Map<String, String> keys) {
  final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
  db.execute(
    'INSERT INTO app_settings (key, value, updated_at) VALUES (?, ?, ?) '
    'ON CONFLICT(key) DO UPDATE SET value = excluded.value, '
    'updated_at = excluded.updated_at',
    [settingsKey, jsonEncode(keys), now],
  );
}
