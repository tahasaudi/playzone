import 'dart:convert';

import 'package:drift/drift.dart';

/// Row-level change tracking for the LAN sync feature.
///
/// Two small raw tables (drift knows nothing about them, which is the
/// point — they must survive schema refactors untouched):
///
///  * `sync_log` — one row per INSERT/UPDATE/DELETE on any business table,
///    written by SQLite triggers. This is the feed a client pulls from and
///    the queue it pushes from.
///  * `sync_state` — key/value flags (`suppress` turns triggers off while
///    remote rows are being replayed, `last_pull` remembers where a client
///    got to).
///
/// Triggers are installed in `beforeOpen` with `IF NOT EXISTS`, so they
/// are rebuilt on every launch and never drift out of step with the table
/// set. Nothing here appears in the generated drift code, so a table
/// rename in the schema only needs its trigger regenerated — which
/// happens automatically because the table list is read from
/// `sqlite_master` at open time.

const syncLogTable = 'sync_log';
const syncStateTable = 'sync_state';

/// Phones allocate row ids from here up. Everything below belongs to the
/// PC. The floor is applied on the phone at bootstrap — before that device
/// has handed out a single sequential id — so it reliably positions the
/// allocator. 1B rows gives the till an absurd amount of headroom before a
/// phone id could ever be mistaken for its own.
///
/// The reverse half — dragging the *till's* allocator back down after a
/// pushed client row lands — does not exist: SQLite's AUTOINCREMENT keeps
/// the largest id its in-memory sequence has ever been bumped to, and no
/// write to `sqlite_sequence` rewinds that cache (verified empirically).
/// The till therefore simply continues upward from the largest id it has
/// ever stored. Collisions between the two machines' allocators can only
/// happen inside the few seconds before the phone pulls the till's latest
/// id back, and the merge closes the gap by each side adopting the other's
/// max. That is what [syncBandCap] documents, not enforces.
const int syncBandStart = 1000000000;

/// The band the PC itself must stay under, reapplied after every client
/// push (a client row with a high id drags `sqlite_sequence` up with it).
const int syncBandCap = 90000000;

Future<void> installSyncSchema(DatabaseConnectionUser db) async {
  await db.customStatement(
      'CREATE TABLE IF NOT EXISTS $syncLogTable ('
      'seq INTEGER PRIMARY KEY AUTOINCREMENT, '
      'tbl TEXT NOT NULL, '
      'row_pk TEXT NOT NULL, '
      'op TEXT NOT NULL, '
      'ts INTEGER NOT NULL, '
      'pushed INTEGER NOT NULL DEFAULT 0)');
  await db.customStatement(
      'CREATE TABLE IF NOT EXISTS $syncStateTable ('
      'key TEXT PRIMARY KEY, '
      'value TEXT)');

  // Older builds reached `sqlite_sequence` with INSERT OR IGNORE, which
  // duplicates rows for a name (that table has no unique constraint) and
  // quietly corrupts autoincrement. Keep the oldest entry per name — the
  // one carrying the table's real sequence — and drop the rest.
  await db.customStatement(
      'DELETE FROM sqlite_sequence WHERE rowid NOT IN '
      '(SELECT MIN(rowid) FROM sqlite_sequence GROUP BY name)');

  for (final table in await syncTables(db)) {
    final pk = await _primaryKey(db, table);
    if (pk == null) continue;
    await _installTriggers(db, table, pk);
  }
}

/// Every business table — read from `sqlite_master` so a table added to
/// the schema tomorrow is tracked without touching this file.
Future<List<String>> syncTables(DatabaseConnectionUser db) async {
  final rows = await db.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name NOT LIKE 'sqlite_%' "
      "AND name NOT LIKE '$syncLogTable' "
      "AND name NOT LIKE '$syncStateTable' "
      "AND name NOT LIKE '\\_%' ESCAPE '\\' "
      "ORDER BY name").get();
  return [for (final r in rows) r.data['name'] as String];
}

/// Public form of the primary-key lookup, for callers that need to address
/// a row by name (the sync server answering `/changes`, for instance).
Future<String?> primaryKeyFor(DatabaseConnectionUser db, String table) =>
    _primaryKey(db, table);

/// The single-column primary key of [table], or null when the table has
/// none (or a composite one, which nothing in this schema uses).
Future<String?> _primaryKey(DatabaseConnectionUser db, String table) async {
  final cols = await _tableInfo(db, table);
  final pks = [for (final c in cols) if (c.pk > 0) c.name];
  return pks.length == 1 ? pks.first : null;
}

class _ColumnInfo {
  const _ColumnInfo(this.name, this.type, this.pk);
  final String name;
  final String type;
  final int pk;
}

Future<List<_ColumnInfo>> _tableInfo(DatabaseConnectionUser db, String t) async {
  final rows = await db.customSelect('PRAGMA table_info("$t")').get();
  return [
    for (final r in rows)
      _ColumnInfo(
        r.data['name'] as String,
        (r.data['type'] as String? ?? '').toUpperCase(),
        (r.data['pk'] as int?) ?? 0,
      )
  ];
}

Future<void> _installTriggers(
    DatabaseConnectionUser db, String table, String pk) async {
  // The suppress flag is how remote rows are replayed without bouncing
  // straight back out as "local" changes — without it every sync would
  // ping-pong forever.
  const guard = 'WHEN (SELECT value FROM $syncStateTable '
      "WHERE key = 'suppress') IS NULL ";
  Future<void> run(String suffix, String when, String insert) async {
    await db.customStatement('DROP TRIGGER IF EXISTS "trg_${table}_$suffix"');
    await db.customStatement(
        'CREATE TRIGGER "trg_${table}_$suffix" AFTER $when ON "$table" '
        '$guard BEGIN $insert; END');
  }

  final log =
      "INSERT INTO $syncLogTable(tbl, row_pk, op, ts) VALUES ("
      "'$table', CAST(new.\"$pk\" AS TEXT), ";
  await run('ai', 'INSERT', "$log 'I', strftime('%s','now'))");
  await run('au', 'UPDATE', "$log 'U', strftime('%s','now'))");
  await db.customStatement('DROP TRIGGER IF EXISTS "trg_${table}_ad"');
  await db.customStatement(
      'CREATE TRIGGER "trg_${table}_ad" AFTER DELETE ON "$table" '
      '$guard BEGIN '
      "INSERT INTO $syncLogTable(tbl, row_pk, op, ts) VALUES ("
      "'$table', CAST(old.\"$pk\" AS TEXT), 'D', strftime('%s','now')); "
      'END');
}

/// Reads one row as a plain JSON-ready map, keyed by column name.
Future<Map<String, Object?>?> readRow(DatabaseConnectionUser db,
    String table, String pkColumn, String pkValue) async {
  final info = await _tableInfo(db, table);
  final col = info.firstWhere((c) => c.name == pkColumn);
  final Variable pk = col.type.contains('INT')
      ? Variable.withInt(int.tryParse(pkValue) ?? 0)
      : Variable.withString(pkValue);
  final row = await db
      .customSelect('SELECT * FROM "$table" WHERE "$pkColumn" = ?',
          variables: [pk])
      .getSingleOrNull();
  return row == null ? null : _encodeValues(row.data);
}

Future<Map<String, Object?>> snapshot(DatabaseConnectionUser db) async {
  final out = <String, Object?>{};
  for (final table in await syncTables(db)) {
    final rows = await db.customSelect('SELECT * FROM "$table"').get();
    out[table] = [for (final r in rows) _encodeValues(r.data)];
  }
  return out;
}

/// Replaces this device's whole business data with a snapshot taken from
/// the PC — the client's first act, and the only time rows are thrown away.
///
/// The wipe and the load each run under the trigger guard so none of it is
/// ever logged as a local change and pushed straight back to the machine
/// that sent it. Foreign keys are the caller's job (see
/// [withoutForeignKeys]): the tables arrive in name order, not dependency
/// order, so the checks must already be off before the first DELETE.
Future<void> applySnapshot(
  DatabaseConnectionUser db,
  Map<String, Object?> snapshotData, {
  bool Function(String table, Map<String, Object?> row)? skip,
}) async {
  final tables = await syncTables(db);
  await applyingRemote(db, () async {
    for (final t in tables) {
      await db.customStatement('DELETE FROM "$t"');
    }
    // Whatever was queued locally is meaningless once the PC's data lands.
    await db.customStatement('DELETE FROM $syncLogTable');
    await db
        .customStatement("DELETE FROM $syncStateTable WHERE key = 'last_pull'");
  });
  await applyingRemote(db, () async {
    for (final t in tables) {
      final pk = await _primaryKey(db, t);
      if (pk == null) continue;
      final rows = snapshotData[t];
      if (rows is! List) continue;
      for (final raw in rows) {
        if (raw is! Map) continue;
        final data = {
          for (final e in raw.entries) e.key.toString(): e.value,
        };
        if (skip != null && skip(t, data)) continue;
        if (data[pk] == null) continue;
        await applyRemoteRow(
          db,
          table: t,
          op: 'I',
          pkColumn: pk,
          pkValue: '${data[pk]}',
          data: data,
        );
      }
    }
  });
  await setIdBand(db, syncBandStart);
}

/// SQLite hands back `Uint8List` for BLOBs, which `jsonEncode` refuses.
/// No column in this schema is a blob today; the codec exists so the day
/// one is added the sync does not start throwing at 2am.
Map<String, Object?> _encodeValues(Map<String, Object?> data) => {
      for (final e in data.entries)
        e.key: e.value is Uint8List
            ? {'__b64__': base64Encode(e.value as Uint8List)}
            : e.value,
    };

Object? _decodeValue(Object? v) {
  if (v is Map && v['__b64__'] is String) {
    return base64Decode(v['__b64__'] as String);
  }
  return v;
}

/// Runs [body] with the trigger guard up, so every row it writes is
/// accepted without being logged as a local change again.
Future<T> applyingRemote<T>(
    DatabaseConnectionUser db, Future<T> Function() body) {
  return db.transaction(() async {
    await db.customStatement(
        "INSERT INTO $syncStateTable(key, value) VALUES('suppress', '1') "
        "ON CONFLICT(key) DO UPDATE SET value = '1'");
    try {
      return await body();
    } finally {
      await db
          .customStatement("DELETE FROM $syncStateTable WHERE key = 'suppress'");
    }
  });
}

/// Runs [body] with the foreign-key checks off, then puts them back.
///
/// Sync replay is the one place in this program that writes rows it did not
/// create, in an order it did not choose. With the checks on, a single row
/// the PC deleted while a session still pointed at it would abort the whole
/// replay — and a sync that fails the same way every time is a sync that
/// never comes back. The app soft-deletes rather than removing parents, so
/// the checks buy nothing here and cost everything.
///
/// Must not be called with a transaction already open: SQLite ignores the
/// pragma inside one, and the re-enable at the end would be a lie.
Future<T> withoutForeignKeys<T>(
    DatabaseConnectionUser db, Future<T> Function() body) async {
  await db.customStatement('PRAGMA foreign_keys = OFF');
  try {
    return await body();
  } finally {
    await db.customStatement('PRAGMA foreign_keys = ON');
  }
}

/// Replays one remote change locally (inside a caller-managed guard).
Future<void> applyRemoteRow(
  DatabaseConnectionUser db, {
  required String table,
  required String op,
  required String pkColumn,
  required String pkValue,
  Map<String, Object?>? data,
}) async {
  final cols = await _tableInfo(db, table);
  var pkType = '';
  for (final c in cols) {
    if (c.name == pkColumn) {
      pkType = c.type;
      break;
    }
  }

  if (op == 'D') {
    await db.customStatement('DELETE FROM "$table" WHERE "$pkColumn" = ?', [
      pkType.contains('INT') ? (int.tryParse(pkValue) ?? pkValue) : pkValue,
    ]);
    return;
  }
  if (data == null) return;

  final names = [
    for (final c in cols)
      if (data.containsKey(c.name)) c.name
  ];
  if (names.isEmpty) return;

  final args = [
    for (final n in names) _decodeValue(data[n])
  ];
  // The feed carries every key as text. Bind the integer ones as integers
  // or `WHERE id = '5'` starts depending on SQLite being cleverer than it
  // promised to be.
  final pkIndex = names.indexOf(pkColumn);
  if (pkIndex >= 0 && pkType.contains('INT')) {
    args[pkIndex] = int.tryParse('${args[pkIndex]}') ?? args[pkIndex];
  }
  final placeholders = List.filled(names.length, '?').join(', ');
  final updates = [
    for (final n in names)
      if (n != pkColumn) '"$n" = excluded."$n"'
  ];
  final conflict = updates.isEmpty
      ? ''
      : ' DO UPDATE SET ${updates.join(', ')}';

  await db.customStatement(
    'INSERT INTO "$table" ("${names.join('", "')}") '
      'VALUES ($placeholders) '
      'ON CONFLICT("$pkColumn")$conflict',
    args,
  );
}

/// Positions this device's id allocator inside its band.
///
/// For a phone this is the whole mechanism: called after a snapshot, before
/// it has ever allocated a row, it puts the next sequential id at
/// [syncBandStart] and the phone stays above the PC's entire data set. The
/// PC calls it after a client push with `ceiling` set to a lower bound,
/// which is a no-op on a connection whose AUTOINCREMENT cache has already
/// moved past it — the true PC-side protection is the pull round-trip
/// converging on the pulled max.
Future<void> setIdBand(DatabaseConnectionUser db, int floor,
    {int? ceiling}) async {
  for (final table in await syncTables(db)) {
    final pk = await _primaryKey(db, table);
    if (pk == null) continue;
    final col = (await _tableInfo(db, table))
        .firstWhere((c) => c.name == pk, orElse: () => const _ColumnInfo('', 'INTEGER', 1));
    if (!col.type.contains('INT')) continue; // e.g. app_settings.key
    // `sqlite_sequence` is an ordinary two-column table: its `name` column
    // has no uniqueness guarantee, so an INSERT OR IGNORE on a table that
    // already has a row silently adds a *second* one. A duplicated row is a
    // corrupted sequencer — updates touch both, autoincrement reads either.
    // Update first; when no row existed the UPDATE is a no-op and the query
    // below confirms it, so one plain INSERT fills the gap. This path either
    // updates the single existing row or creates exactly one new one, never
    // both.
    final bound =
        ceiling == null ? 'MAX(seq, ?)' : 'MIN(MAX(seq, ?), ?)';
    final args = ceiling == null ? [floor] : [floor, ceiling];
    await db.customStatement(
        'UPDATE sqlite_sequence SET seq = $bound WHERE name = ?',
        [...args, table]);
    final missing = (await db.customSelect(
            'SELECT 1 FROM sqlite_sequence WHERE name = ?',
            variables: [Variable.withString(table)])
        .get()).isEmpty;
    if (missing) {
      await db
          .customStatement('INSERT INTO sqlite_sequence(name, seq) VALUES (?, ?)', [table, floor]);
    }
  }
}
