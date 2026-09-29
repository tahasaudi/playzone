import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'tv_display_service.dart';

/// Controls the LG TV's wall screen, so a session can switch it on and off.
///
/// How the 55UP7760PVB behaves (all verified on the real set):
///
/// 1. **We cannot change the input.** `ssap://tv/switchInput` answers
///    `401 insufficient permissions`, and the DIAL service's `Start` answers
///    HTTP 500. Nothing on the network selects HDMI 1 for us.
/// 2. **We can get out of the way.** A single DLNA `Stop` ends our playback.
///    Once we are not the source, HDMI-CEC takes over: the PS4/PS5 waking up
///    pulls the TV to its HDMI input on its own. So a session start only has
///    to clear the screen, not steer the TV.
/// 3. **ON works.** A Wake-on-LAN magic packet wakes the panel from standby,
///    and CEC then wakes the PS5 with it. No TV setting needed beyond
///    "Quick Start" / "تشغيل الجهاز بالهاتف المحمول".
/// 4. **OFF does not.** LG's NetCast port (9922/9081) stays closed even with
///    that setting enabled, and `ssap://system/turnOff` is refused the same
///    way. So "off" is a single black frame.
///
/// NetCast is still attempted on both ends in case a newer firmware opens it
/// up, but the DLNA path is what actually runs.
class TvPowerService {
  TvPowerService._();
  static final TvPowerService instance = TvPowerService._();

  /// MAC addresses the TV advertises (Wi-Fi first, then wired).
  ///
  /// Keyed by the screen's IP so a session on the PS5 wakes the 65" and
  /// leaves the 55" alone. Broadcasting one magic packet to both would
  /// light up a screen nobody is sitting at.
  static const Map<String, List<String>> macsByScreen = {
    // 55UP7760PVB — PS4 corner
    '192.168.1.22': ['A8:A2:37:41:98:7E', '7C:64:6C:05:B5:82'],
    // 65UP7500PVG — PS5 corner
    '192.168.1.31': ['4C:BA:D7:4A:25:26', 'AC:5A:F0:99:24:11'],
  };

  /// Used when a screen's address is not one we know yet.
  static const List<String> fallbackMacs = [
    'A8:A2:37:41:98:7E',
    '7C:64:6C:05:B5:82',
    '4C:BA:D7:4A:25:26',
    'AC:5A:F0:99:24:11',
  ];

  /// The MACs to poke for [tvIp], falling back to every known one.
  static List<String> macsFor(String tvIp) =>
      macsByScreen[tvIp] ?? fallbackMacs;

  bool _paired = false;
  bool get isPaired => _paired;

  /// NetCast is a dead end on this set — ports 9922/9081 never open, and
  /// every attempt just burned a connect-timeout. After the first miss we
  /// stop trying, so a session start is one `Stop` and nothing else.
  bool _netcastUseless = false;
  DateTime? _lastCommandAt;
  String? _lastResult;
  String? get lastResult => _lastResult;
  DateTime? get lastCommandAt => _lastCommandAt;

  /// How long the last command took end to end, in milliseconds.
  int? _lastTookMs;
  int? get lastTookMs => _lastTookMs;

  /// Starts the stopwatch for a command.
  Stopwatch? _watch;
  void _beginTiming() => _watch = Stopwatch()..start();

  void _endTiming() {
    _watch?.stop();
    _lastTookMs = _watch?.elapsedMilliseconds;
    _watch = null;
  }

  /// Hands [tvIp] back to the console sitting on its HDMI input.
  ///
  /// Returns immediately: the panel takes seconds to wake, so waiting for it
  /// would only make the button feel broken. The work happens in the
  /// background — a burst of magic packets to switch it on, and a `Stop` on
  /// our DLNA playback so HDMI-CEC can pull the TV to the console.
  ///
  /// Discovery is deliberately NOT on this path. A port scan takes the best
  /// part of ten seconds, and running it here is what made session start
  /// feel like the whole app had frozen.
  bool turnOn(String tvIp) {
    _lastCommandAt = DateTime.now();
    _beginTiming();
    _tvHost = tvIp;
    final tv = TvDisplayService.instance;
    tv.unblank();
    tv.stopPushing();
    _lastResult = 'الشاشة بتفتح';
    _endTiming();
    unawaited(_wakeThenRelease(tvIp));
    return true;
  }

  /// The slow half of `turnOn`, deliberately off the critical path.
  ///
  /// A waking LG panel needs a moment before its renderer answers, and the
  /// visible result — leaving our black frame for HDMI — can only happen
  /// after that. So we poll hard and fast at first: the panel is usually up
  /// in well under a second, and every extra second we wait is a second the
  /// customer stares at a black wall.
  Future<void> _wakeThenRelease(String tvIp) async {
    final tv = TvDisplayService.instance;
    await _sendMagicPacket();
    const fastTries = 10;
    for (var i = 0; i < fastTries; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (await tv.releaseToInput(tvIp)) {
        _lastResult = 'الشاشة رجعت للبلايستيشن';
        return;
      }
      if (tv.refusesDlna(tvIp)) break;
    }
    // Still nothing after five seconds: keep a slower rhythm going so a
    // slow-booting panel eventually gets there on its own.
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (await tv.releaseToInput(tvIp)) {
        _lastResult = 'الشاشة رجعت للبلايستيشن';
        return;
      }
      if (tv.refusesDlna(tvIp)) break;
    }
    _lastResult = 'الشاشة اتفتحت';
  }

  /// Forgets that NetCast is dead, so the settings screen can re-test it
  /// after the user changes something on the TV.
  void retryNetCast() => _netcastUseless = false;

  /// Closes the wall screen.
  ///
  /// There is no network power-off for this set: LG's NetCast port is closed
  /// and webOS 4.1 rejects `ssap://system/turnOff` with 401. So "off" is a
  /// single black frame — the screen goes dark and reads as switched off.
  /// Closes the wall screen at [tvIp] by painting it black.
  ///
  /// Also returns immediately — the invoice is already written, and the
  /// cashier must never wait on a TV.
  bool turnOff(String tvIp) {
    _lastCommandAt = DateTime.now();
    _beginTiming();
    _tvHost = tvIp;
    final tv = TvDisplayService.instance;
    // Stop the loop first so a background push cannot overwrite the black.
    tv.stopPushing();
    _lastResult = 'الشاشة بتتغمّض';
    _endTiming();
    unawaited(_blankOut(tvIp));
    return true;
  }

  Future<void> _blankOut(String tvIp) async {
    final tv = TvDisplayService.instance;
    final netcast = await _netcastPower(2);
    if (netcast) {
      _lastResult = 'الشاشة اتقفلت';
      return;
    }
    // A screen that answers 500 will not answer on the third try either.
    // Say so once, and let the cashier close the session knowing the TV
    // still needs the remote.
    for (var i = 0; i < 2; i++) {
      if (await tv.pushBlack(tvIp)) {
        _lastResult = 'الشاشة اتغمّضت';
        return;
      }
      if (tv.refusesDlna(tvIp)) break;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    _lastResult = 'الشاشة رفضت الأمر — اقفلها بالريموت';
  }

  /// Classic magic packet: 6 × 0xFF + 16 × the MAC, to the broadcast
  /// address on port 9.
  ///
  /// A single packet is often not enough when the set has been asleep for a
  /// while, so we send a short burst — the cost is nil and the wake becomes
  /// reliable regardless of where the TV was in its power cycle.
  Future<void> _sendMagicPacket() async {
    for (var round = 0; round < 3; round++) {
      await _sendMagicPacketOnce(macsFor(_tvHost));
      if (round < 2) await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> _sendMagicPacketOnce(List<String> macs) async {
    for (final mac in macs) {
      final bytes = _magicPacket(mac);
      RawDatagramSocket? socket;
      try {
        socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        socket.broadcastEnabled = true;
        for (final target in const ['255.255.255.255', '192.168.1.255']) {
          socket.send(bytes, InternetAddress(target), 9);
        }
        await Future<void>.delayed(const Duration(milliseconds: 200));
      } catch (_) {
        // A failed magic packet is not fatal — the TV may already be on.
      } finally {
        socket?.close();
      }
    }
  }

  List<int> _magicPacket(String mac) {
    final hex = mac.replaceAll(':', '');
    final macBytes = <int>[
      for (var i = 0; i < hex.length; i += 2)
        int.parse(hex.substring(i, i + 2), radix: 16),
    ];
    return [
      ...List<int>.filled(6, 0xFF),
      for (var r = 0; r < 16; r++) ...macBytes,
    ];
  }

  /// NetCast / LG TV Plus: 1 = power on, 2 = power off.
  ///
  /// Cheap no-op once we know the ports are closed — which they are on this
  /// firmware, and a connect attempt to a closed port costs seconds.
  Future<bool> _netcastPower(int command) async {
    if (_netcastUseless) return false;
    for (final port in const [9922, 9081]) {
      Socket? socket;
      try {
        socket = await Socket.connect(_tvHost, port,
            timeout: const Duration(milliseconds: 400));
        if (!_paired) {
          // Identify ourselves; the TV asks the user to allow it once.
          socket.write('$_identifier$_clientName\r\n');
          await socket.flush();
          await Future<void>.delayed(const Duration(milliseconds: 600));
        }
        socket.write('power/click $command\r\n');
        await socket.flush();
        await Future<void>.delayed(const Duration(milliseconds: 400));
        _paired = true;
        _netcastUseless = false;
        return true;
      } catch (_) {
        continue;
      } finally {
        socket?.destroy();
      }
    }
    _netcastUseless = true;
    return false;
  }

  static const _identifier = '8675309';
  static const _clientName = 'PlayZone';
  static String _tvHost = '192.168.1.22';

  /// Points the service at a different TV (its IP, from the settings).
  set tvIp(String value) => _tvHost = value;

  /// Best-effort probe used by the settings screen: is the TV reachable
  /// and does it answer the remote port?
  Future<String> diagnostics() async {
    final lines = <String>[];
    for (final port in const [9922, 9081]) {
      try {
        final s = await Socket.connect(_tvHost, port,
            timeout: const Duration(milliseconds: 800));
        s.destroy();
        lines.add('LG TV Plus port $port: متاح ✅');
      } catch (_) {
        lines.add('LG TV Plus port $port: مقفول');
      }
    }
    // The probe above is the user explicitly asking, so let a later session
    // try again for real in case the firmware changed.
    _netcastUseless = lines.every((l) => l.contains('مقفول'));
    return lines.join('\n');
  }

  /// Text protocol helper kept public for tests/debugging.
  static String encodeCommand(int command) =>
      utf8.encode('power/click $command\r\n').toString();
}
