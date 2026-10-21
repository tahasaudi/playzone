import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'hard_lock.dart';
import 'tv_display_service.dart';
import 'tv_mac_index.dart';

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
    // 55UP7550PVG
    '192.168.1.38': ['C4:E5:32:17:6A:50', '74:E6:B8:30:36:F1'],
    // 65UQ80006LD
    '192.168.1.13': ['B8:16:5F:DE:CA:9A', '7C:64:6C:E4:4E:CC'],
    // UR78006LL
    '192.168.1.11': ['D8:E3:5E:67:9F:28', '64:E4:A5:4A:D7:EF'],
  };

  /// Used when a screen's address is not one we know yet.
  static const List<String> fallbackMacs = [
    'A8:A2:37:41:98:7E',
    '7C:64:6C:05:B5:82',
    '4C:BA:D7:4A:25:26',
    'AC:5A:F0:99:24:11',
    'C4:E5:32:17:6A:50',
    '74:E6:B8:30:36:F1',
    'B8:16:5F:DE:CA:9A',
    '7C:64:6C:E4:4E:CC',
    'D8:E3:5E:67:9F:28',
    '64:E4:A5:4A:D7:EF',
  ];

  /// The MACs to poke for [tvIp], falling back to every known one.
  static List<String> macsFor(String tvIp) =>
      macsByScreen[tvIp] ?? fallbackMacs;

  /// The address the panel shows so staff can match a screen by its label.
  static String? primaryMacFor(String tvIp) {
    final list = macsByScreen[tvIp];
    return (list == null || list.isEmpty) ? null : list.first;
  }

  /// MACs learned for addresses the fixed table does not know, so a screen
  /// that is moved to a new address still reports the right label. A cached
  /// `null` means "we asked and it did not answer" — kept so a screen that is
  /// off does not get pinged again on every rebuild of the page.
  static final Map<String, String?> _learned = {};

  /// The MAC behind [tvIp]:
  ///  - the fixed table if this is one of the shop's screens, otherwise
  ///  - a lookup in this machine's own neighbour table, so typing a different
  ///    address brings that address's MAC without anyone having to look it up.
  ///
  /// The MAC is the part that stays put when a screen's address changes, so it
  /// is the label the rest of the app recognises a screen by.
  static Future<String?> resolveMac(String tvIp) async {
    final known = primaryMacFor(tvIp);
    if (known != null) return known;
    if (_learned.containsKey(tvIp)) return _learned[tvIp];
    try {
      // One nudge so the entry exists, then read it. `arp -a <ip>` limits the
      // output to that one address.
      await Process.run('ping', ['-n', '1', '-w', '700', tvIp]);
      final res = await Process.run('arp', ['-a', tvIp]);
      final match = RegExp(r'([0-9A-Fa-f]{2}[-:]){5}[0-9A-Fa-f]{2}')
          .firstMatch(res.stdout.toString());
      final mac = match?.group(0)?.replaceAll('-', ':').toUpperCase();
      _learned[tvIp] = mac;
      return mac;
    } catch (_) {
      _learned[tvIp] = null;
      return null;
    }
  }

  /// The MACs the shop's own table lists for [tvIp] — empty for anything the
  /// table does not know, which is the caller's cue to look it up instead.
  static List<String> knownMacsFor(String tvIp) =>
      macsByScreen[tvIp.trim()] ?? const <String>[];

  /// Every neighbour this machine can see right now, as IP → MAC.
  ///
  /// This is the one direction that answers "the screen moved, where is it
  /// now?": a screen keeps its MAC when the router hands it a different
  /// address, so the MAC is what we follow and the address is what we find.
  ///
  /// The table it reads is a cache, and it only holds the neighbours this
  /// machine has actually spoken to. So we speak to the whole subnet first —
  /// one tiny UDP datagram per address is enough to make the operating system
  /// resolve it — and only then read the table back.
  /// Every neighbour this machine can see right now, as IP → MAC.
  ///
  /// [targets] are the MACs actually being looked for. When every one of them
  /// has answered, the sweep stops instead of waiting out its budget — which is
  /// what makes it feel instant when the screens are right there, instead of
  /// pausing a fixed second "just in case".
  static Future<Map<String, String>> discoverNeighbours({
    Set<String> targets = const <String>{},
  }) async {
    final wanted = targets.map((m) => m.toUpperCase()).toSet();

    // The table may already hold what we want — a screen we spoke to a minute
    // ago is still a neighbour. Reading it is nearly free, so try it first and
    // skip the sweep entirely when the screens are already in it.
    var table = await _readNeighbourTable();
    if (_foundAll(wanted, table)) return table;

    await _pokeLocalSubnet();

    // Poll rather than sleep a fixed second: answers trickle in over a few
    // hundred milliseconds, so stopping the moment the last one lands is what
    // makes this feel immediate instead of "why is it waiting".
    for (final wait in const [80, 110, 140, 170, 200, 230, 260]) {
      await Future<void>.delayed(Duration(milliseconds: wait));
      table = await _readNeighbourTable();
      if (_foundAll(wanted, table)) break;
    }
    return table;
  }

  static bool _foundAll(Set<String> wanted, Map<String, String> table) {
    if (wanted.isEmpty) return false;
    for (final mac in wanted) {
      if (!table.containsKey(mac)) return false;
    }
    return true;
  }

  static Map<String, String>? _cachedTable;
  static DateTime? _cachedTableAt;

  /// The operating system's neighbour table, read without any sweep.
  ///
  /// This is the cheap half of [discoverNeighbours]: it reports only what the
  /// machine already knows, which is exactly what a command path wants — a
  /// MAC → address lookup that costs one `arp -a` at worst and nothing at all
  /// while the last read is still fresh. Waking a screen, or steering one whose
  /// lease moved, must never wait on a /24 sweep first.
  static Future<Map<String, String>> neighbourTable({
    Duration maxAge = const Duration(seconds: 4),
  }) async {
    final at = _cachedTableAt;
    if (_cachedTable != null &&
        at != null &&
        DateTime.now().difference(at) < maxAge) {
      return _cachedTable!;
    }
    final table = await _readNeighbourTable();
    _cachedTable = table;
    _cachedTableAt = DateTime.now();
    return table;
  }

  /// Pokes every host on every /24 this machine is on, plus the /24 the shop's
  /// own screens live on.
  ///
  /// All of them, not just one: a counter PC often carries several IPv4
  /// addresses at once — Wi-Fi, cable, and the shared-connection adapter
  /// Windows invents — and picking the wrong one would sweep an empty network
  /// while the screens sit on the other.
  static Future<void> _pokeLocalSubnet() async {
    final prefixes = <String>{};
    for (final ip in await _localIPv4s()) {
      final prefix = _subnetOf(ip);
      if (prefix != null) prefixes.add(prefix);
    }
    for (final ip in macsByScreen.keys) {
      final prefix = _subnetOf(ip);
      if (prefix != null) prefixes.add(prefix);
    }

    final hosts = <String>{
      for (final prefix in prefixes)
        for (var i = 1; i <= 254; i++) '$prefix.$i',
    };

    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      // A single port is enough now: the point is to make the operating
      // system resolve each address so it lands in its neighbour table, and
      // one datagram per host does that. Sending a second one to a port that
      // some stacks filter before the ARP lookup just doubled the burst for
      // nothing.
      for (final host in hosts) {
        try {
          socket.send(const [0], InternetAddress(host), 9);
        } catch (_) {
          // An unroutable address is not fatal — the rest still resolve.
        }
      }
    } catch (_) {
      // A failed poke only means a shorter table; the read still happens.
    } finally {
      socket?.close();
    }
  }

  static String? _subnetOf(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  /// Every usable IPv4 address on this machine, ignoring loopback and the
  /// self-assigned 169.254.x addresses a cable with no network produces.
  static Future<List<String>> _localIPv4s() async {
    final found = <String>[];
    try {
      final interfaces = await NetworkInterface.list(
          type: InternetAddressType.IPv4, includeLoopback: false);
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final ip = address.address;
          if (ip.startsWith('169.254.')) continue;
          found.add(ip);
        }
      }
    } catch (_) {}
    return found;
  }

  /// Reads `arp -a` into IP → MAC, dropping multicast and broadcast rows that
  /// are never a screen.
  static Future<Map<String, String>> _readNeighbourTable() async {
    final table = <String, String>{};
    try {
      final res = await Process.run('arp', ['-a']);
      final row = RegExp(
          r'^\s*(\d{1,3}(?:\.\d{1,3}){3})\s+([0-9A-Fa-f]{2}(?:[-:][0-9A-Fa-f]{2}){5})\b');
      for (final line in res.stdout.toString().split('\n')) {
        final match = row.firstMatch(line);
        if (match == null) continue;
        final ip = match.group(1)!;
        if (ip == '255.255.255.255') continue;
        final mac = match.group(2)!.replaceAll('-', ':').toUpperCase();
        // The least-significant bit of the first octet marks a multicast
        // address; those (and the all-FF broadcast) are never a TV.
        final firstByte = int.tryParse(mac.substring(0, 2), radix: 16) ?? 0;
        if (firstByte & 1 == 1) continue;
        table.putIfAbsent(mac, () => ip);
      }
    } catch (_) {
      // No arp command means no table; the caller shows a plain "not found".
    }
    return table;
  }

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
    if (kHardLockWallNetwork) return true;
    // Anchor on the MAC, not the lease: steer the screen wherever it answers
    // now, so a router move never sends this command into an empty address.
    tvIp = TvMacIndex.instance.resolve(tvIp);
    _lastCommandAt = DateTime.now();
    _beginTiming();
    _tvHost = tvIp;
    _activeScreen = tvIp;
    final tv = TvDisplayService.instance;
    tv.markScreenOpen(tvIp);
    tv.unblank(tvIp: tvIp);
    tv.stopPushingScreen(tvIp);
    _lastResult = 'الشاشة بتفتح';
    _endTiming();
    // The screen's own history is written immediately, so a panel that is
    // still waking up already says "we asked for this" instead of looking
    // untouched. The outcome follows once the release lands.
    tv.noteCommand(tvIp, 'فتح', 'بنفتح', tookMs: _lastTookMs);
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
    final watch = Stopwatch()..start();
    await _sendMagicPacket();
    // A checkout that landed while this loop was still waiting on a slow
    // panel. The wall is dark and paid for, so this release no longer applies
    // to anything — and it is the exact command that used to put the screen
    // back on the console a second after a customer paid.
    bool closedNow() => tv.isScreenClosed(tvIp);

    const fastTries = 10;
    for (var i = 0; i < fastTries; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 500));
      if (closedNow()) {
        _done(tvIp, 'الجلسة اتقفلت — الشاشة فضلت مقفولة', watch);
        return;
      }
      if (await tv.releaseToInput(tvIp)) {
        _done(tvIp, 'الشاشة رجعت للبلايستيشن', watch);
        return;
      }
      if (tv.refusesDlna(tvIp)) break;
    }
    // Still nothing after five seconds: keep a slower rhythm going so a
    // slow-booting panel eventually gets there on its own.
    for (var i = 0; i < 4; i++) {
      await Future<void>.delayed(const Duration(seconds: 2));
      if (closedNow()) {
        _done(tvIp, 'الجلسة اتقفلت — الشاشة فضلت مقفولة', watch);
        return;
      }
      if (await tv.releaseToInput(tvIp)) {
        _done(tvIp, 'الشاشة رجعت للبلايستيشن', watch);
        return;
      }
      if (tv.refusesDlna(tvIp)) break;
    }
    _done(tvIp, 'الشاشة اتفتحت', watch);
  }

  /// Closes the outcome of a wake: one Arabic sentence, in this screen's own
  /// history and in the shared status line.
  void _done(String tvIp, String message, Stopwatch watch) {
    watch.stop();
    _lastResult = message;
    _lastTookMs = watch.elapsedMilliseconds;
    TvDisplayService.instance.noteCommand(
      tvIp,
      'فتح',
      message,
      tookMs: _lastTookMs,
    );
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
  /// Whether the wall at [tvIp] is currently showing our black frame.
  ///
  /// Asked, not remembered: the screen also goes dark on its own when a
  /// session's minutes run out, and a button that says "مفتوحة" over a wall
  /// that has already gone black would be asking the cashier to press a
  /// switch that is already pressed.
  bool isScreenDark(String tvIp) =>
      TvDisplayService.instance.isScreenClosed(tvIp);

  bool turnOff(String tvIp) {
    if (kHardLockWallNetwork) return true;
    // Same MAC-first anchor as [turnOn]: a screen that moved is still the same
    // screen, and this command belongs on its new address.
    tvIp = TvMacIndex.instance.resolve(tvIp);
    _lastCommandAt = DateTime.now();
    _beginTiming();
    _tvHost = tvIp;
    _activeScreen = tvIp;
    final tv = TvDisplayService.instance;
    // Stop the loop first so a background push cannot overwrite the black, and
    // put the screen out of reach of any release still retrying from the
    // session that just ended. That retry is the reason a wall used to go dark
    // on payment and spring back to the console a second later: the checkout
    // won, and then a `Stop` that belonged to the session before it arrived
    // anyway. The screen now refuses it, and says so in its own history
    // instead of quietly undoing the sale.
    tv.markScreenClosed(tvIp);
    tv.stopPushing();
    _lastResult = 'الشاشة بتتغمّض';
    _endTiming();
    tv.noteCommand(tvIp, 'إغلاق', 'بتتغمّض', tookMs: _lastTookMs);
    unawaited(_blankOut(tvIp));
    return true;
  }

  Future<void> _blankOut(String tvIp) async {
    final tv = TvDisplayService.instance;
    final watch = Stopwatch()..start();
    final netcast = await _netcastPower(2);
    if (netcast) {
      _blanked(tvIp, 'الشاشة اتقفلت', watch);
      return;
    }
    // A screen that answers 500 will not answer on the third try either.
    // Say so once, and let the cashier close the session knowing the TV
    // still needs the remote.
    for (var i = 0; i < 2; i++) {
      if (await tv.pushBlack(tvIp)) {
        _blanked(tvIp, 'الشاشة اتغمّضت', watch);
        return;
      }
      if (tv.refusesDlna(tvIp)) break;
      await Future<void>.delayed(const Duration(seconds: 2));
    }
    _blanked(tvIp, 'الشاشة رفضت الأمر — اقفلها بالريموت', watch, ok: false);
  }

  void _blanked(String tvIp, String message, Stopwatch watch,
      {bool ok = true}) {
    watch.stop();
    _lastResult = message;
    _lastTookMs = watch.elapsedMilliseconds;
    TvDisplayService.instance.noteCommand(
      tvIp,
      'إغلاق',
      message,
      ok: ok,
      tookMs: _lastTookMs,
    );
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
      if (round < 2)
        await Future<void>.delayed(const Duration(milliseconds: 350));
    }
  }

  Future<void> _sendMagicPacketOnce(List<String> macs) async {
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      final targets = await _broadcastTargets();
      // One socket for the whole round. A socket per MAC meant a burst of
      // binds (the fallback list is ten addresses) for a message that only
      // ever needed to leave the machine once per MAC per target.
      for (final mac in macs) {
        final bytes = _magicPacket(mac);
        for (final target in targets) {
          socket.send(bytes, InternetAddress(target), 9);
        }
      }
      await Future<void>.delayed(const Duration(milliseconds: 200));
    } catch (_) {
      // A failed magic packet is not fatal — the TV may already be on.
    } finally {
      socket?.close();
    }
  }

  /// Every broadcast a magic packet should go out on: the global one plus the
  /// directed broadcast of each subnet this machine is really on.
  ///
  /// A counter PC often sits on Wi-Fi and cable at once, and the screens may
  /// live on either. Waking them used to depend on a single hard-coded
  /// `192.168.1.255`, so on any other subnet the packet went nowhere and
  /// "افتح الشاشة" quietly did nothing.
  Future<List<String>> _broadcastTargets() async {
    final targets = <String>{'255.255.255.255'};
    for (final ip in await _localIPv4s()) {
      final prefix = _subnetOf(ip);
      if (prefix != null) targets.add('$prefix.255');
    }
    return targets.toList();
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

  /// Which screen the last command was aimed at. Recorded so the shared status
  /// line can be honest about whose result it is showing — with two screens,
  /// "الشاشة اتغمّضت" is meaningless without it.
  static String _activeScreen = '';
  static String get activeScreen => _activeScreen;

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
