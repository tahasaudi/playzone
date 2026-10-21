import 'dart:io';

import 'package:flutter/foundation.dart';

import '../tv/hard_lock.dart';

/// The one port the LAN sync uses, TCP for the API and UDP for "where is
/// the till?". Deliberately not 41777/41778 — those belong to the wall
/// picture server, and two services arguing over a port is the kind of
/// fault that only shows up on a busy evening.
const int syncPort = 41779;

/// App-settings keys that describe THIS device and must never cross the
/// wire. Everything else in `app_settings` (the wall screens, their names,
/// their addresses, the locked PIN) is shared data and syncs like any
/// other table.
class SyncKeys {
  SyncKeys._();

  /// `master` = this machine owns the database, `client` = mirror of the
  /// PC, absent/anything else = no sync at all.
  static const String role = 'sync_role';

  /// Base URL of the PC, e.g. `http://192.168.1.20:41779`.
  static const String serverUrl = 'sync_server_url';

  /// Random id for this install, so the server can tell two phones apart.
  static const String deviceId = 'sync_device_id';

  /// Wall/TV/IR network permission. Not sync data — each machine decides
  /// for itself — but it lives in `app_settings` like the rest.
  static const String wallNetwork = 'wall_network_enabled';

  static const Set<String> localOnly = {role, serverUrl, deviceId, wallNetwork};
}

enum SyncRole { standalone, master, client }

SyncRole syncRoleOf(String? raw) => switch (raw?.trim()) {
      'master' => SyncRole.master,
      'client' => SyncRole.client,
      _ => SyncRole.standalone,
    };

/// True when this install may drive the wall screens (announce, push,
/// black, hand back to the console).
///
/// Three separate conditions, and all three must hold: the wall-network
/// switch is on, this machine is not a phone-sized mirror of the PC, and
/// — by way of [kHardLockWallNetwork] — nothing has locked the network
/// down. Discovery and IR are deliberately NOT gated by this, so a phone
/// can still find and talk to the screens; only *pushing pictures* to
/// them belongs to the till.
bool get kWallPushAllowed =>
    !kHardLockWallNetwork && SyncRuntime.role != SyncRole.client;

/// Live state of the sync layer, read by the settings tab and written by
/// the service. Plain statics rather than a provider because the service
/// runs outside the widget tree and the UI only ever observes it.
class SyncRuntime {
  SyncRuntime._();

  static SyncRole role = SyncRole.standalone;

  /// Normalised base URL (no trailing slash) of the PC, as the client
  /// talks to it. Empty when this machine is not a client.
  static String baseUrl = '';

  static String deviceId = '';

  /// One line of Arabic, whatever the settings tab should be showing.
  static final ValueNotifier<String> status =
      ValueNotifier<String>('المزامنة غير مفعّلة');

  /// Bumped on every successful exchange, so the tab can say "آخر مزامنة".
  static final ValueNotifier<DateTime?> lastExchange =
      ValueNotifier<DateTime?>(null);

  /// Set once the Windows firewall rule has been attempted (or refused),
  /// master only — the phone has no firewall to open.
  static String firewallNote = '';

  static bool get running =>
      role == SyncRole.master || (role == SyncRole.client && baseUrl.isNotEmpty);
}

/// Reads the firewall note / address helpers shared by server and UI.
Future<String> localIpv4() async {
  try {
    final interfaces = await NetworkInterface.list(
        includeLinkLocal: false, type: InternetAddressType.IPv4);
    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        if (addr.isLoopback) continue;
        if (addr.address.startsWith('169.254.')) continue;
        return addr.address;
      }
    }
  } catch (_) {}
  return '';
}
