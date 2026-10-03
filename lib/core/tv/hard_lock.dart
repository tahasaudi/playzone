/// Wall-network lock for this machine.
///
/// One codebase, two machines, one café network. The code is edited on the
/// home machine and the till runs on the shop machine, and a program that
/// starts for a quick look on the home machine will happily find the five
/// wall screens, push a black frame at them and hand them back — which means a
/// television the moment a developer opens the app is a television a customer
/// is watching go dark.
///
/// So the wall network is cut by something outside the program, that the
/// machine's owner sets once: `PLAYZONE_TV=off`.
///
/// - Home machine  -> `setx PLAYZONE_TV off`  -> locked, cannot touch a screen.
/// - Shop machine  -> nothing set            -> live, screens work normally.
///
/// This used to be a hardcoded `true` in the source, which meant every build
/// was locked and the shop machine would have had no screens at all. A missing
/// variable means allowed, because the till must work with nothing set: only an
/// explicit "off" closes it, so a typo can never silently take the walls down
/// in a full café.
library;

import 'dart:io';

/// Whether every wall-screen / TV / IR-box network command is cut at the socket
/// level: no magic packet, no NetCast socket, no SSDP, no HTTP push, no ESP32
/// request, and the local image server never binds.
///
/// Kept as its own name because the guard is read all over the TV and IR code.
/// It is the same switch as `TvDisplayService.tvAllowed` — one machine, one
/// decision, two names for it.
final bool kHardLockWallNetwork = _readWallSwitch();

bool _readWallSwitch() {
  final fromEnv = Platform.environment['PLAYZONE_TV'];
  return fromEnv != null && fromEnv.trim().toLowerCase() == 'off';
}