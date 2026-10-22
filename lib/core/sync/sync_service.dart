import 'dart:io';
import 'dart:math';

import '../database/app_database.dart';
import '../tv/hard_lock.dart';
import 'sync_client.dart';
import 'sync_config.dart';
import 'sync_schema.dart';
import 'sync_server.dart';

/// Boots the sync layer once, from the settings the install already has.
///
/// Started from the shell rather than from `main()` because it needs the
/// database, and the database opens lazily on first use. Everything that
/// decides *what* this machine is — owner, mirror, or on its own — is read
/// here and frozen into [SyncRuntime]; changing it is a restart, never a
/// mid-run change of mind.
class SyncService {
  SyncService._();

  static final SyncService instance = SyncService._();

  SyncServer? _server;
  SyncClient? _client;
  bool _started = false;

  SyncServer? get server => _server;
  SyncClient? get client => _client;
  bool get started => _started;

  /// The role an install with no `sync_role` written yet takes.
  ///
  /// The till owns the data; a phone mirrors it. That is the only pairing
  /// this business has, so the two platforms get their sensible answer
  /// without anyone having to configure anything on day one.
  static String defaultRole() => Platform.isWindows ? 'master' : 'client';

  Future<void> start(AppDatabase db) async {
    if (_started) return;
    _started = true;
    final settings = db.settingsDao;

    final wall = await settings.getValue(SyncKeys.wallNetwork);
    // Absent means nobody has decided yet, and the café's screens are
    // currently working — so they keep working. '0' is the explicit "cut
    // this machine off" answer, and the value is read before the first
    // frame that would otherwise act on it.
    WallNetwork.blocked = wall == '0';

    final storedRole = await settings.getValue(SyncKeys.role);
    final role = syncRoleOf(
        (storedRole == null || storedRole.trim().isEmpty)
            ? defaultRole()
            : storedRole);
    final url =
        (await settings.getValue(SyncKeys.serverUrl))?.trim() ?? '';
    var deviceId =
        (await settings.getValue(SyncKeys.deviceId))?.trim() ?? '';
    if (deviceId.isEmpty) {
      final random = Random.secure();
      final buffer = StringBuffer();
      for (var i = 0; i < 8; i++) {
        buffer.write(random.nextInt(256).toRadixString(16).padLeft(2, '0'));
      }
      deviceId = buffer.toString();
      await settings.setValue(SyncKeys.deviceId, deviceId);
    }

    SyncRuntime.role = role;
    SyncRuntime.deviceId = deviceId;
    SyncRuntime.baseUrl = _normalise(url);

    switch (role) {
      case SyncRole.master:
        SyncRuntime.status.value = 'الكمبيوتر صاحب البيانات';
        final server = SyncServer(db);
        _server = server;
        await server.start();
        SyncRuntime.firewallNote = server.isRunning ? '' : 'port';
        if (server.isRunning) {
          // A phone push can drag the autoincrement counter past the PC's
          // ceiling; hold it down before the first local insert too.
          await setIdBand(db, 0, ceiling: syncBandCap);
          final ip = await localIpv4();
          SyncRuntime.status.value = ip.isEmpty
              ? 'الكمبيوتر صاحب البيانات — منفذ $syncPort'
              : 'الكمبيوتر صاحب البيانات — $ip:$syncPort';
        } else {
          SyncRuntime.status.value =
              'ما قدرتش أفتح منفذ $syncPort — ${server.lastError ?? 'محاولة تانية'}';
        }
      case SyncRole.client:
        SyncRuntime.status.value = SyncRuntime.baseUrl.isEmpty
            ? 'ادخل عنوان الكمبيوتر أو اضغط "ابحث عن الكمبيوتر"'
            : 'التليفون بيتصل بالكمبيوتر';
        _client = SyncClient(db);
        // The phone's own rows must be born in the phone's band before
        // anything is written, or its first device would take id 1 and
        // quietly become the PC's device 1 on the next push.
        await setIdBand(db, syncBandStart);
        _client!.start();
      case SyncRole.standalone:
        SyncRuntime.status.value = 'المزامنة غير مفعّلة';
    }
  }

  Future<void> stop() async {
    _client?.stop();
    _client = null;
    await _server?.stop();
    _server = null;
  }

  /// Applies a settings change: stop, re-read, start again. Sync is not a
  /// live-updating thing on purpose — a machine that changes role while
  /// queues are in flight is how two databases end up disagreeing about
  /// which one is the truth.
  Future<void> restart(AppDatabase db) async {
    await stop();
    _started = false;
    await start(db);
  }

  static String _normalise(String url) {
    var clean = url.trim();
    if (clean.isEmpty) return '';
    clean = clean.replaceAll(RegExp(r'/+$'), '');
    if (!clean.contains('://')) clean = 'http://$clean';
    if (!clean.contains(':$syncPort')) clean = '$clean:$syncPort';
    return clean;
  }
}
