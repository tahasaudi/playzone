// Prints every machine in the café with its id, read straight out of the
// database. Pure Dart on purpose: `dart run` cannot compile the Flutter side of
// the app, so a tool that could only be run from inside the app would not be a
// check at all.
//
// It reports; it does not decide. The walk order lives in one place
// (`cafeRosterOrder`) and copying it here so the two can disagree would be the
// very drift this file exists to catch.
//
// Run: dart run tool/roster_order.dart
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

void main() {
  final path =
      Platform.environment['APPDATA']! + r'\PlayZone\PlayZone\playzone.sqlite';
  final db = sqlite3.open(path, mode: OpenMode.readOnly);
  for (final r
      in db.select('SELECT id, name, status FROM devices ORDER BY id')) {
    print('  id=${r['id']}  name="${r['name']}"  status=${r['status']}');
  }
  db.dispose();
}
