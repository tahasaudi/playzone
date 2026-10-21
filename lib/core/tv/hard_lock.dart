/// Master wall-network lock for this machine.
///
/// When [WallNetwork.blocked] is true, EVERY wall-screen / TV / IR-box
/// network command is cut at the socket level: no magic packet, no NetCast
/// socket, no SSDP, no HTTP push, no ESP32 request, and the local image
/// server never binds — this build neither sends to nor accepts from the
/// café's devices.
///
/// The value is loaded at startup from the `wall_network_enabled` app
/// setting (Settings → المزامنة) instead of being baked in at compile
/// time, so the same binary runs safely on the development machine and
/// live on the shop floor. Safe default while settings are still loading:
/// blocked.
class WallNetwork {
  WallNetwork._();

  static bool blocked = true;
}

/// Legacy name kept so every existing call site reads the same way; now a
/// live getter instead of a compile-time constant.
bool get kHardLockWallNetwork => WallNetwork.blocked;
