import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:drift/drift.dart' show Variable;

import '../database/app_database.dart';
import 'sync_config.dart';
import 'sync_schema.dart';

/// The phone's side of the LAN sync.
///
/// One timer, one direction at a time: everything this install has written
/// since the last successful push goes up, then everything the PC has
/// written since the last pull comes down. There is no websocket and no
/// callback — a café's Wi-Fi drops, the phone walks out of range, and the
/// only thing that has to be true is that when it comes back the two
/// databases converge without anyone restarting anything.
///
/// Local edits are queued by the SQLite triggers into `sync_log`; remote
/// rows are replayed with that queue suppressed, so a row arriving from the
/// PC is never re-sent to the PC. That suppression is the whole reason this
/// cannot loop.
class SyncClient {
  SyncClient(this._db);

  final AppDatabase _db;
  final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 4);

  Timer? _timer;
  Timer? _nudgeTimer;
  bool _busy = false;
  int _failures = 0;

  /// Pending count seen on the last fast check. Used to fire a push the
  /// moment a new local edit is queued, rather than on every tick.
  int _lastPending = 0;

  final Map<String, String?> _pkCache = {};

  bool get running => _timer != null;

  void start() {
    if (_timer != null) return;
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => tick());
    // The heartbeat above is the reliable slow path. This fast path only
    // watches the local queue (a tiny indexed SELECT — no network) so that
    // an edit the cashier makes on the phone goes up in well under a
    // second, which is what makes a phone-started session open its screen
    // on the PC right away instead of up to four seconds later.
    _nudgeTimer =
        Timer.periodic(const Duration(milliseconds: 500), (_) => _nudge());
    unawaited(tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _nudgeTimer?.cancel();
    _nudgeTimer = null;
  }

  /// Fires a cycle the instant the local queue grows.
  ///
  /// Only a *change* triggers it: if a push fails and leaves rows queued,
  /// this stays quiet and the 4s heartbeat retries, so a phone with the
  /// PC switched off is not hammering every half second.
  Future<void> _nudge() async {
    if (_busy) return;
    if (SyncRuntime.baseUrl.isEmpty) return;
    final pending = await _pending();
    if (pending == _lastPending) return;
    _lastPending = pending;
    if (pending > 0) await tick();
  }

  Future<void> tick() async {
    if (_busy) return;
    if (SyncRuntime.baseUrl.isEmpty) {
      _say('لسه محتاج عنوان الكمبيوتر في الإعدادات');
      return;
    }
    _busy = true;
    try {
      final ping = await _get('/ping');
      if (ping['ok'] != true) throw StateError('الكمبيوتر ما ردّش');
      final theirSchema = ping['schema'];
      if (theirSchema is int && theirSchema != _db.schemaVersion) {
        _say('قاعدة بيانات الكمبيوتر بنسخة مختلفة — حدّث البرنامج على '
            'الجهازين');
        return;
      }
      await _pushOutgoing();
      await _pullIncoming();
      _failures = 0;
      SyncRuntime.lastExchange.value = DateTime.now();
      final pending = await _pending();
      _say(pending == 0
          ? 'متصل بالكمبيوتر — كل حاجة متزامنة'
          : 'متصل بالكمبيوتر — $pending تعديل في الطريق');
    } catch (e) {
      _failures++;
      _say(_failures >= 3
          ? 'الاتصال بالكمبيوتر فاصل (${_short(e)})'
          : 'جارٍ الاتصال بالكمبيوتر…');
    } finally {
      _busy = false;
    }
  }

  /// Forces a cycle right now, for the "مزامنة الآن" button.
  Future<void> syncNow() => tick();

  String _short(Object e) {
    final s = '$e';
    return s.length > 60 ? '${s.substring(0, 57)}…' : s;
  }

  void _say(String message) => SyncRuntime.status.value = message;

  Future<int> _pending() async {
    final row = await _db
        .customSelect(
            'SELECT COUNT(*) AS c FROM $syncLogTable WHERE pushed = 0')
        .getSingleOrNull();
    final c = row?.data['c'];
    return c is int ? c : 0;
  }

  Future<String?> _pkFor(String table) async {
    if (_pkCache.containsKey(table)) return _pkCache[table];
    final pk = await primaryKeyFor(_db, table);
    _pkCache[table] = pk;
    return pk;
  }

  Future<String?> _stateGet(String key) async {
    final row = await _db.customSelect(
        'SELECT value FROM $syncStateTable WHERE key = ?',
        variables: [Variable.withString(key)]).getSingleOrNull();
    final v = row?.data['value'];
    return v is String ? v : null;
  }

  Future<void> _stateSet(String key, String value) => _db.customStatement(
      'INSERT INTO $syncStateTable(key, value) VALUES(?, ?) '
      'ON CONFLICT(key) DO UPDATE SET value = excluded.value',
      [key, value]);

  static bool _isDeviceLocal(String table, Map<String, Object?> row) =>
      table == 'app_settings' && SyncKeys.localOnly.contains('${row['key']}');

  /// Sends everything queued, in batches, until nothing is left. A phone
  /// that was offline over a busy Saturday can have thousands of rows
  /// waiting; one request each keeps every payload small enough that a flaky
  /// access point does not have to carry all of them at once.
  Future<void> _pushOutgoing() async {
    for (var round = 0; round < 40; round++) {
      final rows = await _db.customSelect(
        'SELECT seq, tbl, row_pk, op FROM $syncLogTable '
        'WHERE pushed = 0 ORDER BY seq LIMIT 400',
      ).get();
      if (rows.isEmpty) return;

      var maxSeq = 0;
      final changes = <Map<String, Object?>>[];
      for (final row in rows) {
        final seq = row.data['seq'];
        final n = seq is int ? seq : (seq is num ? seq.toInt() : 0);
        if (n > maxSeq) maxSeq = n;
        final tbl = '${row.data['tbl']}';
        final rowPk = '${row.data['row_pk']}';
        var op = '${row.data['op']}';
        // Device-local settings stay put: the PC must never learn this
        // phone's role, and this phone must never learn the PC's.
        if (_isDeviceLocal(tbl, {'key': rowPk})) continue;
        final pk = await _pkFor(tbl);
        if (pk == null) continue;
        Map<String, Object?>? data;
        if (op != 'D') {
          data = await readRow(_db, tbl, pk, rowPk);
          if (data == null) op = 'D';
        }
        changes.add({
          'tbl': tbl,
          'row_pk': rowPk,
          'op': op,
          if (data != null) 'data': data,
        });
      }

      final reply = await _post('/push', {
        'deviceId': SyncRuntime.deviceId,
        'changes': changes,
      });
      if (reply['ok'] != true) {
        throw StateError('${reply['error'] ?? 'الكمبيوتر رفض التعديلات'}');
      }

      // Marked in one sweep up to the batch's highest sequence, including
      // the rows deliberately left out — otherwise a device-local setting
      // would sit at pushed=0 forever and be re-read on every cycle.
      await _db.customStatement(
          'UPDATE $syncLogTable SET pushed = 1 '
          'WHERE pushed = 0 AND seq <= ?',
          [maxSeq]);
      if (rows.length < 400) return;
    }
  }

  /// First contact with the PC: the PC's whole database replaces this one.
  /// After that it is incremental, one page of changes at a time.
  Future<void> _pullIncoming() async {
    final cursor = await _stateGet('last_pull');
    if (cursor == null) {
      _say('بنحمّل البيانات من الكمبيوتر…');
      final snap = await _get('/snapshot');
      if (snap['ok'] != true) {
        throw StateError('${snap['error'] ?? 'ما قدرناش نقرأ البيانات'}');
      }
      final data = snap['data'];
      if (data is! Map) throw const FormatException('snapshot malformed');
      final mapped = {
        for (final e in data.entries) e.key.toString(): e.value,
      };
      await withoutForeignKeys(
          _db, () => applySnapshot(_db, mapped, skip: _isDeviceLocal));
      await _stateSet('last_pull', '${snap['seq'] ?? 0}');
      return;
    }

    final since = int.tryParse(cursor) ?? 0;
    final reply = await _get('/changes?since=$since&limit=1000');
    if (reply['ok'] != true) {
      throw StateError('${reply['error'] ?? 'ما قدرناش نقرأ التحديثات'}');
    }
    final rawChanges = reply['changes'];
    final changes = rawChanges is List ? rawChanges : const [];
    if (changes.isNotEmpty) {
      await withoutForeignKeys(_db, () async {
        await applyingRemote(_db, () async {
          for (final raw in changes) {
            if (raw is! Map) continue;
            final tbl = '${raw['tbl']}';
            final rowPk = '${raw['row_pk']}';
            final op = '${raw['op']}';
            final dataRaw = raw['data'];
            Map<String, Object?>? data;
            if (dataRaw is Map) {
              data = {
                for (final e in dataRaw.entries) e.key.toString(): e.value,
              };
            }
            if (_isDeviceLocal(tbl, data ?? {'key': rowPk})) continue;
            final pk = await _pkFor(tbl);
            if (pk == null) continue;
            await applyRemoteRow(
              _db,
              table: tbl,
              op: op,
              pkColumn: pk,
              pkValue: rowPk,
              data: data,
            );
          }
        });
      });
    }
    final seq = reply['seq'];
    await _stateSet(
        'last_pull', '${seq is int ? seq : (seq is num ? seq.toInt() : since)}');
  }

  Future<Map<String, Object?>> _get(String path) =>
      _exchange(() => _http.getUrl(_uri(path)), const Duration(seconds: 8));

  Future<Map<String, Object?>> _post(String path, Object body) {
    final encoded = jsonEncode(body);
    return _exchange(() async {
      final req = await _http.postUrl(_uri(path));
      req.headers.contentType =
          ContentType('application', 'json', charset: 'utf-8');
      req.write(encoded);
      return req;
    }, const Duration(seconds: 20));
  }

  Uri _uri(String path) => Uri.parse('${SyncRuntime.baseUrl}$path');

  Future<Map<String, Object?>> _exchange(
      Future<HttpClientRequest> Function() open, Duration wait) async {
    final req = await open().timeout(const Duration(seconds: 6));
    final res = await req.close().timeout(wait);
    final text =
        await res.transform(utf8.decoder).join().timeout(wait);
    if (res.statusCode >= 400) {
      throw HttpException('HTTP ${res.statusCode} ${text.substring(0, min(80, text.length))}');
    }
    final decoded = jsonDecode(text);
    if (decoded is! Map) throw const FormatException('bad reply');
    return {
      for (final e in decoded.entries) e.key.toString(): e.value,
    };
  }

  /// Asks the LAN who the till is. The reply carries the address the PC
  /// sent from, which is the one thing a phone cannot work out for itself
  /// on a network where the PC's address was never written down.
  static Future<String?> discoverMaster(
      {Duration window = const Duration(seconds: 3)}) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0,
          reuseAddress: true);
      socket.broadcastEnabled = true;
      final done = Completer<String?>();
      final sub = socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final d = socket?.receive();
        if (d == null) return;
        final text = utf8.decode(d.data, allowMalformed: true);
        if (text.startsWith('PLAYZONE_MASTER:') && !done.isCompleted) {
          done.complete(d.address.address);
        }
      }, onError: (_) {}, cancelOnError: false);
      socket.send(utf8.encode('PLAYZONE_DISCOVER'),
          InternetAddress('255.255.255.255'), syncPort);
      final address = await done.future.timeout(window, onTimeout: () => null);
      await sub.cancel();
      return address;
    } catch (_) {
      return null;
    } finally {
      socket?.close();
    }
  }
}
