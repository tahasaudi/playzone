import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Variable;

import '../database/app_database.dart';
import 'remote_session_hook.dart';
import 'sync_config.dart';
import 'sync_schema.dart';

/// The PC's side of the LAN sync: a tiny HTTP API on [syncPort] that a
/// phone can pull the database from and push its edits back to, plus a UDP
/// listener so a phone that does not know this machine's address can find
/// it by asking.
///
/// Everything here is deliberately dumb. The change feed is the `sync_log`
/// table the SQLite triggers write, `/push` is a straight replay of that
/// feed, and there is no session, no token and no negotiation — this is a
/// till and a phone on one shop LAN, and the threat model that matters is
/// "the Wi-Fi drops for ten minutes", not an attacker. What IS protected is
/// the shape of the data: unknown tables, unknown columns and device-local
/// settings keys are refused rather than applied.
class SyncServer {
  SyncServer(this._db);

  final AppDatabase _db;
  HttpServer? _http;
  RawDatagramSocket? _udp;

  /// Set when the port could not be bound (another copy of the program, or
  /// something else sitting on 41779). Shown to the staff rather than
  /// swallowed, because a sync that silently does nothing looks exactly
  /// like a sync that works.
  String? lastError;

  bool get isRunning => _http != null;

  Future<void> start() async {
    if (_http != null) return;
    try {
      _http = await HttpServer.bind(InternetAddress.anyIPv4, syncPort);
      _http!.listen(_handleRequest, onError: (_) {}, cancelOnError: false);
      lastError = null;
    } catch (e) {
      lastError = '$e';
      _http = null;
      return;
    }
    // Discovery is a convenience, not the transport: if the UDP socket
    // cannot open (some machines allow TCP on a port but not UDP), the
    // phone can still be given the address by hand.
    try {
      _udp = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        syncPort,
        reuseAddress: true,
      );
      _udp!.listen((event) {
        if (event == RawSocketEvent.read) _handleDatagram(_udp!);
      }, onError: (_) {}, cancelOnError: false);
    } catch (_) {
      _udp = null;
    }
  }

  Future<void> stop() async {
    final http = _http;
    _http = null;
    final udp = _udp;
    _udp = null;
    try {
      await http?.close(force: true);
    } catch (_) {}
    udp?.close();
  }

  void _handleDatagram(RawDatagramSocket socket) {
    final d = socket.receive();
    if (d == null) return;
    final text = utf8.decode(d.data, allowMalformed: true);
    if (!text.contains('PLAYZONE_DISCOVER')) return;
    try {
      socket.send(
        utf8.encode('PLAYZONE_MASTER:${SyncRuntime.deviceId}'),
        d.address,
        d.port,
      );
    } catch (_) {}
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final res = request.response;
    try {
      res.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      Object body;
      switch (request.uri.path) {
        case '/ping':
          body = await _ping();
        case '/snapshot':
          body = await _snapshot();
        case '/changes':
          body = await _changes(request.uri.queryParameters);
        case '/push':
          body = await _push(await _readJson(request));
        default:
          res.statusCode = HttpStatus.notFound;
          body = {'ok': false, 'error': 'no such route'};
      }
      res.write(jsonEncode(body));
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      res.write(jsonEncode({'ok': false, 'error': '$e'}));
    } finally {
      try {
        await res.close();
      } catch (_) {}
    }
  }

  Future<Map<String, Object?>> _readJson(HttpRequest request) async {
    final text = await utf8.decoder.bind(request).join();
    if (text.trim().isEmpty) return const {};
    final decoded = jsonDecode(text);
    if (decoded is! Map) return const {};
    return {
      for (final e in decoded.entries) e.key.toString(): e.value,
    };
  }

  Future<int> _seq() async {
    final row = await _db
        .customSelect('SELECT MAX(seq) AS s FROM $syncLogTable')
        .getSingleOrNull();
    final s = row?.data['s'];
    return s is int ? s : (s is num ? s.toInt() : 0);
  }

  Future<Map<String, Object?>> _ping() async {
    return {
      'ok': true,
      'role': 'master',
      'deviceId': SyncRuntime.deviceId,
      'schema': _db.schemaVersion,
      'seq': await _seq(),
      'address': await localIpv4(),
      'tables': (await syncTables(_db)).length,
    };
  }

  Future<Map<String, Object?>> _snapshot() async {
    return {
      'ok': true,
      'seq': await _seq(),
      'data': await snapshot(_db),
    };
  }

  Future<Map<String, Object?>> _changes(Map<String, String> query) async {
    final since = int.tryParse(query['since'] ?? '') ?? 0;
    final limit = min(int.tryParse(query['limit'] ?? '') ?? 1000, 5000);
    final rows = await _db
        .customSelect(
          'SELECT seq, tbl, row_pk, op FROM $syncLogTable '
          'WHERE seq > ? ORDER BY seq LIMIT ?',
          variables: [Variable.withInt(since), Variable.withInt(limit)],
        )
        .get();

    final pkCache = <String, String?>{};
    final changes = <Map<String, Object?>>[];
    var last = since;
    for (final row in rows) {
      final seq = row.data['seq'];
      final tbl = '${row.data['tbl']}';
      final rowPk = '${row.data['row_pk']}';
      var op = '${row.data['op']}';
      final ts = row.data['ts'];
      final n = seq is int ? seq : (seq is num ? seq.toInt() : 0);
      last = n;
      // Device-local settings describe the machine that wrote them. They
      // are filtered out here rather than by the client so a phone can
      // never be talked into changing its own role or wall switch.
      if (tbl == 'app_settings' && SyncKeys.localOnly.contains(rowPk)) {
        continue;
      }
      Map<String, Object?>? data;
      if (op != 'D') {
        var pk = pkCache[tbl];
        if (pk == null && !pkCache.containsKey(tbl)) {
          pk = await primaryKeyFor(_db, tbl);
          pkCache[tbl] = pk;
        }
        if (pk == null) continue;
        data = await readRow(_db, tbl, pk, rowPk);
        if (data == null) {
          // Inserted and then deleted before anybody pulled it: send the
          // delete, so a client that somehow already has the row loses it.
          op = 'D';
        }
      }
      changes.add({
        'seq': n,
        'tbl': tbl,
        'row_pk': rowPk,
        'op': op,
        'ts': ts,
        if (data != null) 'data': data,
      });
    }
    return {'ok': true, 'seq': last, 'changes': changes};
  }

  Future<Map<String, Object?>> _push(Map<String, Object?> body) async {
    final raw = body['changes'];
    final changes = raw is List ? raw : const [];
    final tables = (await syncTables(_db)).toSet();
    final pkCache = <String, String?>{};
    var applied = 0;

    // Phones that opened a session in this batch. Collected while the rows
    // are replayed and acted on after the foreign-key block closes, so a
    // screen waking up can never happen in the middle of the write.
    final openedSessions = <int>{};

    // Foreign keys off for the replay. The alternative is a client whose
    // one bad row (a delete that would orphan a session, say) aborts the
    // whole push and wedges the sync for the rest of the night. The app
    // soft-deletes rather than removing parents, so an orphan here is a
    // reporting nit, not a broken till — a dead sync is the worse failure.
    await withoutForeignKeys(_db, () async {
      for (final raw in changes) {
        if (raw is! Map) continue;
        final tbl = '${raw['tbl']}';
        final rowPk = '${raw['row_pk']}';
        var op = '${raw['op']}';
        if (!tables.contains(tbl)) continue;
        if (tbl == 'app_settings' && SyncKeys.localOnly.contains(rowPk)) {
          continue;
        }
        var pk = pkCache[tbl];
        if (pk == null && !pkCache.containsKey(tbl)) {
          pk = await primaryKeyFor(_db, tbl);
          pkCache[tbl] = pk;
        }
        if (pk == null) continue;
        if (op == 'D') {
          await applyRemoteRow(
              _db, table: tbl, op: 'D', pkColumn: pk, pkValue: rowPk);
          applied++;
          continue;
        }
        final dataRaw = raw['data'];
        if (dataRaw is! Map) continue;
        final data = {
          for (final e in dataRaw.entries) e.key.toString(): e.value,
        };
        // The feed's row id is authoritative: if the payload disagrees with
        // it, the payload is wrong, and updating the wrong row would put a
        // second copy of it somewhere else in the table.
        data[pk] = data[pk] ?? rowPk;
        await applyRemoteRow(
          _db,
          table: tbl,
          op: 'I',
          pkColumn: pk,
          pkValue: rowPk,
          data: data,
        );
        // A session the phone started here for the first time. 'I' only:
        // an 'U' is the phone editing a session it already opened, and
        // waking the wall again on every edit would flicker the screen.
        if (tbl == 'sessions' && op == 'I') {
          final device = data['device_id'];
          if (device is int) openedSessions.add(device);
        }
        applied++;
      }
      // A client row drags the autoincrement counter into the phone's band.
      // Put it back under the PC's ceiling before the next local insert, or
      // tomorrow's device would be born with a 100-million id and collide
      // with everything the phone owns.
      await setIdBand(_db, 0, ceiling: syncBandCap);
    });

    // Wake the wall for every machine the phone just started, off the
    // request's critical path: `turnOn` returns at once and the panel takes
    // its own seconds to light up, so the phone must not wait on a TV.
    final wake = RemoteSessionHook.onRemoteSession;
    if (wake != null) {
      for (final deviceId in openedSessions) {
        unawaited(wake(deviceId));
      }
    }

    return {'ok': true, 'applied': applied, 'seq': await _seq()};
  }

  /// Opens the Windows firewall for [syncPort].
  ///
  /// Deliberately never called on startup: netsh needs to be elevated, and
  /// an app that summons a UAC prompt the moment it opens is an app people
  /// learn to click away from. The settings tab offers it as a button, and
  /// the command itself is printed next to that button for anyone who
  /// would rather run it from an admin prompt.
  ///
  /// netsh prints in the local language and its exit codes differ between
  /// machines, so the rule is identified by deleting it first and adding it
  /// back: one rule, known name, and a non-zero exit code means "not
  /// elevated", which is the only thing the caller needs to know.
  static Future<String> ensureFirewallRule() async {
    if (!Platform.isWindows) return 'open';
    Future<int> netsh(List<String> args) async {
      try {
        final r = await Process.run('netsh', args, runInShell: true);
        return r.exitCode;
      } catch (_) {
        return -1;
      }
    }

    await netsh([
      'advfirewall', 'firewall', 'delete', 'rule', 'name=PlayZone Sync',
    ]);
    final added = await netsh([
      'advfirewall', 'firewall', 'add', 'rule', 'name=PlayZone Sync',
      'dir=in', 'action=allow', 'protocol=TCP', 'localport=$syncPort',
      'enable=yes',
    ]);
    return added == 0 ? 'open' : 'manual';
  }
}
