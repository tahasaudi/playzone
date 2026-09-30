import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'tv_power_service.dart';

/// Pushes a still image to an LG (webOS) TV over DLNA / UPnP AVTransport.
///
/// How it works, end to end:
///  1. A tiny HTTP server on this PC serves the current card image at
///     `http://<pc-ip>:41777/tv.jpg` (the TV pulls, we never push bytes).
///  2. We tell the TV "play this URL" with two SOAP calls to its
///     AVTransport control endpoint (Stop → SetAVTransportURI → Play).
///  3. The TV issues `HEAD /tv.jpg` then `GET /tv.jpg`; the server answers
///     both, with a cache-busting query so a new image is really fetched.
///
/// Robustness notes learned from testing a real 55UP7760PVB:
///  - The TV's renderer sometimes gets stuck in `LG_TRANSITIONING` after a
///    failed push, so every cycle starts with `Stop` (which also returns it
///    to a state where it will fetch again).
///  - `Play` frequently never answers (the TV holds the SOAP call while it
///    loads) — that is NOT a failure, so timeouts are swallowed.
///  - The image is served with `Cache-Control: no-store` and a changing
///    URL so the TV never shows a stale frame.
class TvDisplayService {
  TvDisplayService._();

  static final TvDisplayService instance = TvDisplayService._();

  /// The port the TV connects to. A matching inbound firewall rule must
  /// exist on this machine (Windows blocks LAN traffic otherwise).
  static const int port = 41777;

  static const _soapEnvelope =
      '<?xml version="1.0" encoding="utf-8"?>'
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
      's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
      '%BODY%</s:Body></s:Envelope>';

  HttpServer? _server;
  Uint8List? _image;
  int _imageBytes = 0;
  int _revision = 0;
  String? _lastError;
  DateTime? _lastPushAt;
  bool _tvFetched = false;
  DateTime? _lastFetchAt;
  DateTime? get lastFetchAt => _lastFetchAt;
  Timer? _timer;

  /// Screens with a push in flight. A set, not a flag: the café has two and
  /// one must never cancel the other.
  final Set<String> _pushing = {};

  /// Called with a fresh image every tick. The service re-pushes it.
  final _controller = StreamController<Uint8List>.broadcast();
  Stream<Uint8List> get images => _controller.stream;

  bool get isRunning => _server != null;
  bool get tvFetched => _tvFetched;
  DateTime? get lastPushAt => _lastPushAt;
  String? get lastError => _lastError;
  int get portNumber => port;
  int get lastImageBytes => _imageBytes;
  int get imagesServed => _imagesServed;

  /// Starts the local image server. Idempotent.
  Future<bool> startServer() async {
    if (_server != null) return true;
    try {
      _server = await HttpServer.bind(InternetAddress.anyIPv4, port,
          shared: false);
      _server!.listen(_handleRequest, onError: (_) {});
      // Have a frame ready before anyone asks for one. A TV that is sent a
      // URI for an image that 404s comes back with UPnP error 716
      // ("Resource not found"), which looks exactly like the TV refusing
      // us — and we would then write that screen off as unusable when the
      // real cause was simply that nothing had painted yet.
      _black ??= await _buildBlackFrame();
      if (_image == null) {
        _image = _black;
        _imageBytes = _black!.length;
      }
      return true;
    } catch (e) {
      _lastError = 'تعذر فتح البورت $port: $e';
      return false;
    }
  }

  Future<void> stopServer() async {
    _timer?.cancel();
    _timer = null;
    await _server?.close(force: true);
    _server = null;
  }

  /// This machine's LAN address (what the TV must dial).
  String? get localAddress => _localAddress ??= _detectLocalAddress();
  String? _localAddress;

  String? _detectLocalAddress() {
    try {
      final ifaces = NetworkInterface.list(type: InternetAddressType.IPv4);
      ifaces.then((list) {
        for (final iface in list) {
          for (final addr in iface.addresses) {
            if (addr.isLoopback) continue;
            final ip = addr.address;
            if (ip.startsWith('192.168.') || ip.startsWith('10.')) {
              _localAddress ??= ip;
            } else if (RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip)) {
              _fallback ??= ip;
            }
          }
        }
      });
      return _localAddress;
    } catch (_) {
      return null;
    }
  }

  /// Resolves the LAN address once, asynchronously, and caches it.
  Future<String?> resolveLocalAddress() async {
    if (_localAddress != null) return _localAddress;
    try {
      final list = await NetworkInterface.list(type: InternetAddressType.IPv4);
      String? tenDot;
      for (final iface in list) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final ip = addr.address;
          if (ip.startsWith('192.168.') || ip.startsWith('10.')) {
            _localAddress ??= ip;
          } else if (RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip)) {
            tenDot ??= ip;
          }
        }
      }
      return _localAddress ?? tenDot;
    } catch (_) {
      return null;
    }
  }

  String? _fallback;

  /// Replaces the image being displayed and (re)tries the push.
  Future<void> publish(Uint8List pngBytes) async {
    _image = pngBytes;
    _imageBytes = pngBytes.length;
    _tvFetched = false;
    // A real frame from the broadcaster always wins over the blank one, so
    // the screen comes back to life the moment a session starts again.
    _blanked = false;
    _controller.add(pngBytes);
  }

  /// The wall screen's "off" state.
  ///
  /// This TV (webOS 4.1, 2016) refuses every network power-off command, so
  /// a black frame is what "off" looks like: the pixels are dark, the
  /// screen looks dead, and the next session's `turnOn()` wakes the panel
  /// for real. Cheaper and more reliable than a hardware relay.
  bool _blanked = false;
  bool get isBlanked => _blanked;

  /// Serves a solid black frame instead of the session cards.
  Future<void> blank() async {
    if (_image == null) {
      _black ??= await _buildBlackFrame();
      _image = _black;
    }
    _imageBytes = _image!.length;
    _blanked = true;
    _tvFetched = false;
    _revision++;
  }

  /// Back to normal: the next capture from the broadcaster is shown again.
  void unblank() => _blanked = false;

  /// Hands the TV at [tvIp] back to whatever it was watching — in practice
  /// HDMI 1, the console — by ending our playback.
  ///
  /// This is the "show the game" state. It is a single SOAP `Stop` against
  /// an endpoint we already discovered and cached, so it lands in well under
  /// a second. Verified on a 55UP7760PVB: the renderer's transport goes
  /// PLAYING → STOPPED and the panel returns to the HDMI input.
  Future<bool> releaseToInput(String tvIp) async {
    _blanked = false;
    // Only ever use an endpoint we already know. Discovering here would put
    // a 2,100-port sweep in the middle of a session start, which is exactly
    // the multi-second pause the cashier feels. Background discovery covers
    // the case where we have nothing, and a failed command invalidates the
    // cache so the next attempt rediscovers.
    final hit = _controlCache[tvIp];
    if (hit == null) {
      if (!_warming.contains(tvIp)) unawaited(warmUp(tvIp: tvIp));
      return false;
    }
    final ok = await _soap(hit.$1, 'Stop', '<InstanceID>0</InstanceID>');
    if (ok) _lastPushAt = DateTime.now();
    return ok;
  }

  /// Paints the screen at [tvIp] black — our stand-in for "off", since this
  /// TV refuses a real network power-off. One push, no loop, so it is
  /// immediate.
  Future<bool> pushBlack(String tvIp) async {
    if (!_controlCache.containsKey(tvIp)) {
      // Nothing known yet — kick discovery off in the background and say so
      // rather than making checkout wait for a port sweep.
      if (!_warming.contains(tvIp)) unawaited(warmUp(tvIp: tvIp));
      await blank();
      return false;
    }
    await announce();
    await blank();
    return _pushOnce(tvIp);
  }

  /// A single SOAP push, for callers that manage their own timing.
  Future<bool> pushOnceNow() => _pushOnce(_currentTvIp);

  /// Remembers where the TV lives so `pushOnceNow()` works without being
  /// handed the address every time.
  void useTv(String ip) => _currentTvIp = ip;

  String _currentTvIp = '';

  /// The cached AVTransport endpoint for [tvIp], discovering it if needed.
  Future<String?> _controlUrlFor(String tvIp) async {
    if (tvIp.isEmpty) return null;
    final cached = _controlCache[tvIp];
    if (cached != null &&
        DateTime.now().difference(cached.$2) < const Duration(minutes: 30)) {
      return cached.$1;
    }
    return _findControlUrl(tvIp);
  }

  /// Finds (and remembers) the TV's control endpoint ahead of time.
  ///
  /// Runs in the background and keeps retrying, because the renderer port
  /// moves on every TV restart and a screen that is off answers nothing on
  /// the first try. Stops once the endpoint is known.
  Future<void> warmUp({required String tvIp, bool force = false}) async {
    _currentTvIp = tvIp;
    if (_warming.contains(tvIp)) return;
    _warming.add(tvIp);
    try {
      // Three quick passes. A panel that is merely asleep needs a moment, and
      // a long tight retry loop means a 2,100-port sweep every few seconds —
      // that background churn is exactly what the cashier feels as
      // sluggishness.
      for (var attempt = 0; attempt < 3; attempt++) {
        if (force) {
          // A manual "look again" must not be blocked by the cooldown.
          _lastDiscoveryAt.remove(tvIp);
          _controlCache.remove(tvIp);
          _dlnaRefused.remove(tvIp);
          _suspect.remove(tvIp);
        }
        await announce();
        if (await _findControlUrl(tvIp) != null) {
          _suspect.remove(tvIp);
          if (force) _lastError = null;
          return;
        }
        if (refusesDlna(tvIp)) return;
        await Future<void>.delayed(const Duration(seconds: 8));
      }
      // Nothing yet — the screen is probably off. Come back a few times on a
      // slow, self-scheduled rhythm instead of hammering it, so a screen that
      // powers on overnight is usable by the next session without anyone
      // touching a button.
      final rounds = (_keepTrying[tvIp] ?? 0) + 1;
      if (rounds <= 4) {
        _keepTrying[tvIp] = rounds;
        Timer(const Duration(seconds: 45), () {
          _warming.remove(tvIp);
          unawaited(warmUp(tvIp: tvIp));
        });
      } else {
        _keepTrying.remove(tvIp);
      }
    } finally {
      _warming.remove(tvIp);
    }
  }

  /// How many slow follow-up passes each screen has used up.
  final Map<String, int> _keepTrying = {};

  /// Whether this screen's endpoint is currently known and still trusted.
  ///
  /// Deliberately generous. The renderer port only moves when the TV itself
  /// reboots, and every re-check used to mean a 2,100-port sweep — so a
  /// one-minute freshness window had the app scanning constantly in the
  /// background, which is exactly what made the whole thing feel sluggish.
  /// A failed command is what invalidates the cache now, not the clock.
  bool hasControlUrlFor(String tvIp) {
    if (_suspect.contains(tvIp)) return false;
    final hit = _controlCache[tvIp];
    return hit != null &&
        DateTime.now().difference(hit.$2) < const Duration(minutes: 30);
  }

  /// Discards what we think we know and looks again. Wired to the "ابحث عن
  /// الشاشة" button so a TV that rebooted into a new port can be fixed
  /// without restarting the app.
  void rediscover(String tvIp) {
    _controlCache.remove(tvIp);
    _lastDiscoveryAt.remove(tvIp);
    _dlnaRefused.remove(tvIp);
    _suspect.remove(tvIp);
    _keepTrying.remove(tvIp);
    _warming.remove(tvIp);
    unawaited(warmUp(tvIp: tvIp, force: true));
  }

  final Set<String> _warming = {};

  /// A 1280×720 black PNG, built once and reused for the whole "off" state.
  static Uint8List? _black;

  static Future<Uint8List> _buildBlackFrame() async {
    const rect = ui.Rect.fromLTWH(0, 0, 1280, 720);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder, rect)
        .drawRect(rect, ui.Paint()..color = const ui.Color(0xFF000000));
    final picture = recorder.endRecording();
    final image = await picture.toImage(1280, 720);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return Uint8List.fromList(data!.buffer.asUint8List());
  }

  /// Re-asserts the image on the TV every [every].
  ///
  /// Only used when the session cards are actually being shown. The normal
  /// flow (HDMI on, black off) is one-shot: `releaseToInput()` and
  /// `pushBlack()` each fire a single command, so nothing polls in the
  /// background and a session start feels instant.
  void startPushing({required String tvIp, Duration every = const Duration(seconds: 2)}) {
    stopPushing();
    if (tvIp.isEmpty) return;
    _currentTvIp = tvIp;
    unawaited(announce());
    var tick = 0;
    _timer = Timer.periodic(every, (_) {
      tick++;
      // The TV only renders media from a device it has "met" on SSDP, so we
      // re-announce periodically (and immediately after the first push).
      if (tick % 10 == 0) unawaited(announce());
      unawaited(_pushOnce(tvIp));
    });
    // Fire immediately so the screen lights up without waiting a cycle.
    unawaited(_pushOnce(tvIp));
  }

  /// SSDP alive announcement. Without it an LG renderer answers Play with
  /// HTTP 500 because it never saw this PC on the network.
  Future<void> announce() async {
    final self = await resolveLocalAddress();
    if (self == null) return;
    try {
      final socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.multicastHops = 4;
      const group = '239.255.255.250';
      final location = 'http://$self:$port/desc.xml';
      for (final nt in const [
        'upnp:rootdevice',
        'urn:schemas-upnp-org:device:MediaServer:1',
        'urn:schemas-upnp-org:device:MediaRenderer:1',
      ]) {
        final message = 'NOTIFY * HTTP/1.1\r\n'
            'HOST: $group:1900\r\n'
            'NT: $nt\r\n'
            'NTS: ssdp:alive\r\n'
            'LOCATION: $location\r\n'
            'SERVER: Linux/5 UPnP/1.0 PlayZone/1.0\r\n'
            'CACHE-CONTROL: max-age=1800\r\n'
            'AL: http://$self:$port/\r\n'
            'X-User-Agent: redsonic UPnP/1.0 PlayZone/1.0\r\n\r\n';
        socket.send(utf8.encode(message), InternetAddress(group), 1900);
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
      socket.close();
      _announced = true;
    } catch (e) {
      _lastError = 'SSDP announce: $e';
    }
  }

  bool _announced = false;
  bool get announced => _announced;

  void stopPushing() {
    _timer?.cancel();
    _timer = null;
  }

  Future<bool> _pushOnce(String tvIp) async {
    // The guard is per screen and covers the WHOLE cycle (discovery
    // included), otherwise every tick would kick off a full port scan and
    // one screen's push would cancel the other's.
    if (_pushing.contains(tvIp)) return false;
    _pushing.add(tvIp);
    try {
      final self = await resolveLocalAddress();
      if (self == null) {
        _lastError = 'ما قدرتش أعرف IP الجهاز على الشبكة';
        return false;
      }
      final ctl = await _findControlUrl(tvIp);
      if (ctl == null) {
        _lastError = 'التلفزيون $tvIp مش راد على استعلام DLNA';
        return false;
      }
      // A new query string forces the TV to re-fetch instead of using its
      // cached copy of the same URL.
      _revision++;
      final uri = 'http://$self:$port/tv.jpg?v=$_revision';
      // LG renderers REJECT the play request with HTTP 500 when
      // CurrentURIMetaData is empty — the DIDL-Lite descriptor is what
      // tells the TV this is a still image it can display. (Verified
      // against a 55UP7760PVB: empty metadata → 500, DIDL → works.)
      final didl = '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"'
          ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
          ' xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
          '<item id="0" parentID="-1" restricted="1">'
          '<dc:title>PlayZone</dc:title>'
          '<upnp:class>object.item.imageItem.photo</upnp:class>'
          '<res protocolInfo="http-get:*:image/png:DLNA.ORG_OP=01;'
          'DLNA.ORG_CI=0">$uri</res>'
          '</item></DIDL-Lite>';
      final meta = _escapeXml(didl);

      // The renderer is moody: it answers 500 when it thinks it is still
      // playing something. Stop, breathe, set, play — and if Set is
      // refused, stop properly and try once more before giving up.
      await _soap(ctl, 'Stop', '<InstanceID>0</InstanceID>');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      var ok = await _soap(ctl, 'SetAVTransportURI',
          '<InstanceID>0</InstanceID><CurrentURI>$uri</CurrentURI>'
          '<CurrentURIMetaData>$meta</CurrentURIMetaData>');
      if (!ok) {
        await _soap(ctl, 'Stop', '<InstanceID>0</InstanceID>');
        await Future<void>.delayed(const Duration(seconds: 1));
        ok = await _soap(ctl, 'SetAVTransportURI',
            '<InstanceID>0</InstanceID><CurrentURI>$uri</CurrentURI>'
            '<CurrentURIMetaData>$meta</CurrentURIMetaData>');
      }
      if (ok) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
        await _soap(ctl, 'Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
        _lastPushAt = DateTime.now();
        // Forget a past refusal: this screen clearly accepts us now.
        _dlnaRefused.remove(tvIp);
      }
      return ok;
    } finally {
      _pushing.remove(tvIp);
    }
  }

  /// Screens that answered a push with an error, and when they did.
  ///
  /// Time-limited on purpose. A push can fail because the TV said no, but it
  /// fails just as easily because the panel was asleep, or because a firewall
  /// on this PC stopped the TV from fetching the image (LG then answers with
  /// UPnP error 716, which reads like a refusal). Treating one bad minute as
  /// permanent wrote a screen off for the whole day, so the verdict expires
  /// and the screen is tried again on its own.
  final Map<String, DateTime> _dlnaRefused = {};

  /// How long a refusal is believed before the screen is retried.
  static const _refusalTtl = Duration(minutes: 10);

  /// True when this screen has refused our image recently enough to be
  /// believed, and we should stop hammering it.
  bool refusesDlna(String tvIp) {
    final at = _dlnaRefused[tvIp];
    if (at == null) return false;
    if (DateTime.now().difference(at) > _refusalTtl) {
      _dlnaRefused.remove(tvIp);
      return false;
    }
    return true;
  }

  void noteDlnaRefused(String tvIp) =>
      _dlnaRefused[tvIp] = DateTime.now();

  static const _xmlEscapes = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&apos;',
  };

  static String _escapeXml(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  /// Finds the TV's AVTransport control endpoint.
  ///
  /// The ports are NOT stable across a TV restart (we have seen 1165 turn
  /// into 1063/1990/2028 on the same set), so we ask the TV itself over
  /// SSDP and parse the LOCATION it hands back. The old fixed port list is
  /// only a fallback.
  Future<String?> _findControlUrl(String tvIp) async {
    // Re-use the endpoint we already found. The TV only renumbers its port
    // on reboot, and a command that fails is what tells us to look again.
    final cached = _controlCache[tvIp];
    final fresh = cached != null &&
        DateTime.now().difference(cached.$2) < const Duration(minutes: 30);
    if (fresh) return cached.$1;
    // The cooldown is PER TV. A single shared timestamp would let the first
    // screen's discovery throttle the second one's, leaving it unreachable
    // for as long as the app ran.
    final last = _lastDiscoveryAt[tvIp];
    if (!fresh &&
        last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 30)) {
      return cached?.$1;
    }
    _lastDiscoveryAt[tvIp] = DateTime.now();

    // Every port either wall screen has served its renderer on, across
    // restarts. Checked first because it costs nothing, and it is the
    // difference between a screen that lights up immediately and one that
    // sits black for ten seconds waiting for a scan.
    //
    // The list is a cache, never the source of truth: the renderer port is
    // chosen fresh on every TV boot, so the sweep below is what actually
    // keeps this working. A miss here must never look like "no screen".
    final candidates = <String>[
      for (final port in const [
        // 55UP7760PVB
        1063, 1083, 1165, 1341, 1360, 1438, 1490, 1574, 1691, 1715, 1817,
        1856, 1862, 1868, 1876, 1887, 1899, 1990, 2028,
        // 65UP7500PVG
        1102, 1104, 1180, 1299, 1313, 1315, 1356, 1415, 1567, 1694,
        3001,
      ])
        'http://$tvIp:$port/',
    ];
    if (await _hasControlUrl(tvIp, candidates)) return _controlCache[tvIp]!.$1;

    // The sweep is the only method that has never let us down: the TV moves
    // its renderer port on every boot and only answers on the new one. SSDP
    // is tried alongside it, but a reply we filter out must not stop the
    // scan, which used to leave the screen unreachable all day.
    _targetHost = tvIp;
    final found = await _scanLocations(tvIp);
    if (found.isNotEmpty) return _firstControlUrl(tvIp, found);
    found.addAll(await _ssdpSearch(tvIp));

    return _firstControlUrl(tvIp, found);
  }

  /// Returns the first AVTransport endpoint among [locations], caching it.
  Future<String?> _firstControlUrl(String tvIp, List<String> locations) async {
    for (final location in locations) {
      final control = await _controlUrlFrom(location);
      if (control != null) {
        _controlCache[tvIp] = (control, DateTime.now());
        return control;
      }
    }
    return null;
  }

  /// Tries a list of known device-description URLs in parallel and caches
  /// the first AVTransport endpoint among them.
  Future<bool> _hasControlUrl(String tvIp, List<String> candidates) async {
    final controls =
        await Future.wait(candidates.map(_controlUrlFrom), eagerError: false);
    for (final control in controls) {
      if (control != null) {
        _controlCache[tvIp] = (control, DateTime.now());
        _lastLocations = 'known ports';
        return true;
      }
    }
    return false;
  }

  final Map<String, (String, DateTime)> _controlCache = {};
  final Map<String, DateTime> _lastDiscoveryAt = {};

  int _ssdpDatagrams = 0;
  String _lastSsdpSample = '';
  String _lastLocations = '';

  /// Sweeps the port range LG uses for its DLNA services and reads each
  /// device description, looking for the one that carries an AVTransport
  /// endpoint.
  ///
  /// This is the method that actually works. The TV picks a fresh renderer
  /// port on every boot, so a cached list is always behind; the sweep is
  /// what keeps a screen reachable after it has been restarted. Batched and
  /// short-timeout, it costs about ten seconds — which is why it runs in the
  /// background and never on the path a session start waits for.
  Future<List<String>> _scanLocations(String tvIp) async {
    final found = <String>[];
    const batch = 96;
    final candidates = <int>[
      for (var p = 1000; p <= 2200; p++) p,
      for (var p = 2201; p <= 3100; p++) p,
    ];

    try {
      for (var i = 0; i < candidates.length; i += batch) {
        final slice = candidates.sublist(
            i, (i + batch).clamp(0, candidates.length));
        final results = await Future.wait(slice.map(_isPortOpen));
        for (var j = 0; j < slice.length; j++) {
          if (results[j] == true) found.add('http://$tvIp:${slice[j]}/');
        }
      }
    } catch (e) {
      // Keep whatever we found before the trouble — a partial answer still
      // beats none, and the renderer's port could well be in it.
      _lastError = 'فحص المنافذ: $e';
    }
    _lastLocations = 'scanned ${candidates.length}, open: ${found.length}'
        '${found.isEmpty ? '' : ' -> ${found.map((u) => Uri.parse(u).port).join(',')}'}';
    return found;
  }

  /// Whether something is listening on [port] of the TV.
  ///
  /// It must NEVER throw. A closed port rejects the connect, and
  /// `Future.wait` treats the first rejection as a failure of the whole
  /// batch — so one closed port used to abort the entire sweep before it
  /// reached the real one. That is why discovery silently never worked and
  /// the app kept using a stale port from an older TV boot.
  Future<bool> _isPortOpen(int port) async {
    Socket? socket;
    try {
      socket = await Socket.connect(
        _targetHost,
        port,
        timeout: const Duration(milliseconds: 400),
      );
      return true;
    } catch (_) {
      return false;
    } finally {
      socket?.destroy();
    }
  }

  String _targetHost = '';

  Future<List<String>> _ssdpSearch(String tvIp) async {
    final locations = <String>{};
    _ssdpDatagrams = 0;
    RawDatagramSocket? socket;
    try {
      socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
      socket.broadcastEnabled = true;
      socket.multicastHops = 4;
      socket.listen((event) {
        if (event != RawSocketEvent.read) return;
        final datagram = socket?.receive();
        if (datagram == null) return;
        _ssdpDatagrams++;
        // Only the TV we asked about counts. An M-SEARCH is multicast, so
        // every DLNA device on the café Wi-Fi answers it; taking their
        // locations too leaves us testing someone else's endpoints and
        // never falling back to a port scan of the real TV.
        if (datagram.address.address != tvIp) return;
        final text = utf8.decode(datagram.data, allowMalformed: true);
        final match = RegExp(r'(?im)^LOCATION:\s*(\S+)').firstMatch(text);
        if (match != null) {
          locations.add(match.group(1)!.trim());
        } else if (_ssdpDatagrams <= 3) {
          _lastSsdpSample = text.split('\r\n').first.trim();
        }
      });

      for (final st in const [
        'urn:schemas-upnp-org:device:MediaRenderer:1',
        'upnp:rootdevice',
      ]) {
        socket.send(
          utf8.encode('M-SEARCH * HTTP/1.1\r\n'
              'HOST: 239.255.255.250:1900\r\n'
              'MAN: "ssdp:discover"\r\n'
              'MX: 2\r\n'
              'ST: $st\r\n\r\n'),
          InternetAddress('239.255.255.250'),
          1900,
        );
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
      await Future<void>.delayed(const Duration(milliseconds: 1600));
    } catch (e) {
      _lastError = 'SSDP search: $e';
    } finally {
      socket?.close();
    }
    _lastLocations = locations.join(' , ');
    return locations.toList();
  }

  /// Fetches one device description and extracts its AVTransport
  /// controlURL (absolute, resolved against the description's base).
  Future<String?> _controlUrlFrom(String location) async {
    HttpClient? client;
    try {
      client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      final req = await client.getUrl(Uri.parse(location));
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body = await res.transform(utf8.decoder).join();
      // Any AVTransport block followed by its own controlURL.
      final match = RegExp(
              r'<serviceType>\s*urn:schemas-upnp-org:service:AVTransport:1\s*</serviceType>(?:(?!</service>).)*?<controlURL>\s*([^<]+?)\s*</controlURL>',
              dotAll: true,
              caseSensitive: false)
          .firstMatch(body);
      if (match == null) return null;
      final base = Uri.parse(location);
      final resolved = base.resolve(match.group(1)!.trim());
      if (resolved.path.isEmpty || resolved.path == '/') return null;
      return resolved.toString();
    } catch (_) {
      return null;
    } finally {
      client?.close();
    }
  }

  /// The UPnP fault number inside a SOAP error, if the panel sent one.
  ///
  /// 701 "transition not available" and 716 "resource not found" look
  /// identical from the outside — both are HTTP 500 — and they mean opposite
  /// things, so the number is what the log needs to carry.
  static String? _upnpErrorCode(String soapBody) {
    final m = RegExp(r'<errorCode>(\d+)</errorCode>')
        .firstMatch(soapBody);
    if (m == null) return null;
    final d = RegExp(r'<errorDescription>([^<]*)</errorDescription>')
        .firstMatch(soapBody);
    final desc = d?.group(1)?.trim();
    return desc == null || desc.isEmpty ? m.group(1) : '${m.group(1)} $desc';
  }

  Future<bool> _soap(String controlUrl, String action, String body) async {
    const service = 'urn:schemas-upnp-org:service:AVTransport:1';
    final xml = _soapEnvelope.replaceAll(
        '%BODY%',
        '<u:$action xmlns:u="$service"><InstanceID>0</InstanceID>$body</u:$action>');
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
      final req = await client.postUrl(Uri.parse(controlUrl));
      req.headers.set(HttpHeaders.contentTypeHeader, 'text/xml; charset="utf-8"');
      req.headers.set('SOAPACTION', '"$service#$action"');
      req.add(utf8.encode(xml));
      final res = await req.close().timeout(const Duration(seconds: 5));
      // Read the body even on failure: a bare "HTTP 500" says nothing, while
      // the UPnP fault inside says exactly what went wrong. 716 means the
      // panel could not fetch our image (a network problem on this PC);
      // 701 means it is mid-transition and will accept the command in a
      // moment. Those two call for completely different fixes, and guessing
      // between them is what made this look like an uncooperative TV.
      final payload = await res.transform(utf8.decoder).join();
      client.close();
      if (res.statusCode >= 400) {
        final code = _upnpErrorCode(payload);
        _lastError = code == null
            ? '$action -> HTTP ${res.statusCode}'
            : '$action -> HTTP ${res.statusCode} (UPnP $code)';
        // A 404 almost always means the TV rebooted into a different renderer
        // port. Mark the endpoint as needing a re-check rather than deleting
        // it: a sweep costs 2,100 ports, while re-trying the address we have
        // costs one request and is right again the moment the panel is up.
        if (res.statusCode == 404) {
          _noteSuspect(controlUrl);
        }
        // LG answers 500 when it will not take media from us — most often
        // because it could not fetch the image (UPnP error 716), which is a
        // network problem on our side as often as it is the TV saying no.
        // Remember it so we stop hammering the screen, but only for as long
        // as the verdict is worth anything.
        if (res.statusCode >= 500 && controlUrl.contains('://')) {
          final host = Uri.parse(controlUrl).host;
          if (host.isNotEmpty) noteDlnaRefused(host);
        }
        return false;
      }
      _lastError = null;
      return true;
    } on TimeoutException {
      // The TV holds the call while it loads the image — treat as fine.
      return true;
    } catch (e) {
      _lastError = '$action: $e';
      // An unreachable endpoint is almost always a panel that is asleep, not
      // a screen that moved. Keep the address and let a re-check decide.
      _noteSuspect(controlUrl);
      return false;
    }
  }

  /// Flags the screen behind [controlUrl] as needing a fresh look, without
  /// throwing the address away.
  ///
  /// Deleting the entry outright was the bug that took device 2 down: one
  /// command sent while the panel was still booting erased a working
  /// endpoint, and recovery needed a full port sweep — which is the very
  /// thing we refuse to do on a command path. A screen that is merely
  /// unreachable comes back on the same port, so we keep it and try again.
  void _noteSuspect(String controlUrl) {
    final host = Uri.tryParse(controlUrl)?.host;
    if (host == null || host.isEmpty) return;
    if (_suspect.add(host)) {
      // Re-discovery runs in the background, is per-screen, and is guarded by
      // the cooldown, so a dead screen cannot start a sweep per command.
      if (!_warming.contains(host)) unawaited(warmUp(tvIp: host));
    }
  }

  /// Screens whose cached endpoint is known to be wrong and needs a sweep.
  final Set<String> _suspect = {};

  static const _contentDirectoryScpd = '''
<?xml version="1.0" encoding="utf-8"?>
<scpd xmlns="urn:schemas-upnp-org:service-1-0">
  <specVersion><major>1</major><minor>0</minor></specVersion>
  <actionList>
    <action>
      <name>Browse</name>
      <argumentList>
        <argument><name>ObjectID</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_ObjectID</relatedStateVariable></argument>
        <argument><name>BrowseFlag</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_BrowseFlag</relatedStateVariable></argument>
        <argument><name>Filter</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Filter</relatedStateVariable></argument>
        <argument><name>StartingIndex</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Index</relatedStateVariable></argument>
        <argument><name>RequestedCount</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_Count</relatedStateVariable></argument>
        <argument><name>SortCriteria</name><direction>in</direction><relatedStateVariable>A_ARG_TYPE_SortCriteria</relatedStateVariable></argument>
        <argument><name>Result</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_Result</relatedStateVariable></argument>
        <argument><name>NumberReturned</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_Count</relatedStateVariable></argument>
        <argument><name>TotalMatches</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_Count</relatedStateVariable></argument>
        <argument><name>UpdateID</name><direction>out</direction><relatedStateVariable>A_ARG_TYPE_UpdateID</relatedStateVariable></argument>
      </argumentList>
    </action>
    <action>
      <name>GetSearchCapabilities</name>
      <argumentList>
        <argument><name>SearchCaps</name><direction>out</direction><relatedStateVariable>SearchCapabilities</relatedStateVariable></argument>
      </argumentList>
    </action>
    <action>
      <name>GetSortCapabilities</name>
      <argumentList>
        <argument><name>SortCaps</name><direction>out</direction><relatedStateVariable>SortCapabilities</relatedStateVariable></argument>
      </argumentList>
    </action>
  </actionList>
  <serviceStateTable>
    <stateVariable sendEvents="no"><name>SearchCapabilities</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>SortCapabilities</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>NumberOfTracks</name><dataType>ui4</dataType></stateVariable>
    <stateVariable sendEvents="yes"><name>TotalStorageSpace</name><dataType>ui8</dataType></stateVariable>
    <stateVariable sendEvents="yes"><name>UsedStorageSpace</name><dataType>ui8</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>LastChange</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>A_ARG_TYPE_Result</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>A_ARG_TYPE_ObjectID</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>A_ARG_TYPE_BrowseFlag</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>A_ARG_TYPE_Filter</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>A_ARG_TYPE_SortCriteria</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>A_ARG_TYPE_Index</name><dataType>ui4</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>A_ARG_TYPE_Count</name><dataType>ui4</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>A_ARG_TYPE_UpdateID</name><dataType>ui4</dataType></stateVariable>
  </serviceStateTable>
</scpd>
''';

  static const _connectionManagerScpd = '''
<?xml version="1.0" encoding="utf-8"?>
<scpd xmlns="urn:schemas-upnp-org:service-1-0">
  <specVersion><major>1</major><minor>0</minor></specVersion>
  <actionList>
    <action>
      <name>GetProtocolInfo</name>
      <argumentList>
        <argument><name>Source</name><direction>out</direction><relatedStateVariable>SourceProtocolInfo</relatedStateVariable></argument>
        <argument><name>Sink</name><direction>out</direction><relatedStateVariable>SinkProtocolInfo</relatedStateVariable></argument>
      </argumentList>
    </action>
    <action>
      <name>GetCurrentConnectionIDs</name>
      <argumentList>
        <argument><name>ConnectionIDs</name><direction>out</direction><relatedStateVariable>CurrentConnectionIDs</relatedStateVariable></argument>
      </argumentList>
    </action>
  </actionList>
  <serviceStateTable>
    <stateVariable sendEvents="no"><name>SourceProtocolInfo</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="no"><name>SinkProtocolInfo</name><dataType>string</dataType></stateVariable>
    <stateVariable sendEvents="yes"><name>CurrentConnectionIDs</name><dataType>string</dataType></stateVariable>
  </serviceStateTable>
</scpd>
''';

  /// Answers the ContentDirectory `Browse` and ConnectionManager calls that a
  /// strict DLNA client makes before it will play anything.
  ///
  /// The 65" screen walks here first: it browses the root, sees one still
  /// image, and only then accepts a SetAVTransportURI for it. Serving this
  /// is what makes the black frame work on that screen; the 55" never asks.
  Future<void> _handleControl(HttpRequest request, HttpResponse res) async {
    final body = await utf8.decoder.bind(request).join();
    final action = RegExp(r'"#([A-Za-z]+)"').firstMatch(
            request.headers.value('SOAPACTION') ?? '')?.group(1) ??
        (RegExp(r'<u:(\w+)\s').firstMatch(body)?.group(1) ?? '');
    _lastSoapAction = action;
    if (action == 'Browse') _browseCalls++;
    final envelope = _soapEnvelope.replaceAll('%BODY%', '');
    String inner;
    switch (action) {
      case 'Browse':
        final self = await resolveLocalAddress();
        final uri = '$self:$port/tv.jpg?v=$_revision';
        final didl = '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"'
            ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
            ' xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
            '<item id="0" parentID="0" restricted="1">'
            '<dc:title>PlayZone</dc:title>'
            '<dc:creator>PlayZone</dc:creator>'
            '<upnp:class>object.item.imageItem.photo</upnp:class>'
            '<res protocolInfo="http-get:*:image/png:DLNA.ORG_OP=01;'
            'DLNA.ORG_CI=0" size="${_imageBytes}">$uri</res>'
            '</item></DIDL-Lite>';
        inner = '<u:BrowseResponse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1">'
            '<Result>${_escapeXml(didl)}</Result>'
            '<NumberReturned>1</NumberReturned>'
            '<TotalMatches>1</TotalMatches>'
            '<UpdateID>1</UpdateID>'
            '</u:BrowseResponse>';
      case 'GetProtocolInfo':
        inner = '<u:GetProtocolInfoResponse xmlns:u="urn:schemas-upnp-org:service:ConnectionManager:1">'
            '<Source></Source>'
            '<Sink>http-get:*:image/png:*,http-get:*:image/jpeg:*</Sink>'
            '</u:GetProtocolInfoResponse>';
      case 'GetSearchCapabilities':
        inner = '<u:GetSearchCapabilitiesResponse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1">'
            '<SearchCapabilities></SearchCapabilities></u:GetSearchCapabilitiesResponse>';
      case 'GetSortCapabilities':
        inner = '<u:GetSortCapabilitiesResponse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1">'
            '<SortCapabilities></SortCapabilities></u:GetSortCapabilitiesResponse>';
      default:
        res.statusCode = HttpStatus.badRequest;
        res.headers.contentType = ContentType('text', 'xml', charset: 'utf-8');
        res.write(envelope.replaceAll(
            '</s:Body>',
            '<u:actionFailure xmlns:u="urn:schemas-upnp-org:service-ContentDirectory:1">'
                '<errorCode>401</errorCode><errorDescription>Unsupported</errorDescription>'
                '</u:actionFailure></s:Body>'));
        await res.close();
        return;
    }
    res.statusCode = HttpStatus.ok;
    res.headers.contentType = ContentType('text', 'xml', charset: 'utf-8');
    res.headers.set('SOAPACTION', '"urn:schemas-upnp-org:service:ContentDirectory:1#Browse"');
    res.write(envelope.replaceAll('</s:Body>', '$inner</s:Body>'));
    await res.close();
  }

  String? _lastSoapAction;
  String? get lastSoapAction => _lastSoapAction;
  int _browseCalls = 0;

  /// Serves the current image; answers HEAD (headers only) and GET.
  /// Also exposes /status so a problem can be diagnosed without the UI,
  /// and /desc.xml so the SSDP announcement points at something real.
  Future<void> _handleRequest(HttpRequest request) async {
    final res = request.response;
    if (request.uri.path == '/status') {
      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
      res.write('running=$isRunning\n'
          'announced=$_announced\n'
          'pushing=${_timer != null}\n'
          'blanked=$_blanked\n'
          'hasControlUrl=${_controlCache.isNotEmpty}\n'
          'imageBytes=$_imageBytes\n'
          'lastCaptureError=${_lastCaptureError ?? "none"}\n'
          'lastPush=${_lastPushAt?.toIso8601String() ?? "never"}\n'
          'tvFetched=$_tvFetched\n'
          'lastFetch=${_lastFetchAt?.toIso8601String() ?? "never"}\n'
          'imagesServed=$_imagesServed\n'
          'localAddress=${localAddress ?? "unknown"}\n'
          'lastSoapError=${_lastError ?? "none"}\n'
          '--- power ---\n'
          'powerLastCommand=${TvPowerService.instance.lastCommandAt?.toIso8601String() ?? "never"}\n'
          'powerResult=${TvPowerService.instance.lastResult ?? "none"}\n'
          'powerTookMs=${TvPowerService.instance.lastTookMs ?? "-"}\n'
          'powerPaired=${TvPowerService.instance.isPaired}\n'
          'ssdpDatagrams=$_ssdpDatagrams\n'
          'ssdpLocations=$_lastLocations\n'
          'ssdpSample=$_lastSsdpSample\n'
          'browseCalls=$_browseCalls\n'
          '--- screens ---\n'
          'config=${configSummary()}\n'
          'known=$controlSummary\n'
          'suspect=${_suspect.join(",")}\n'
          'refusesDlna=${_dlnaRefused.keys.where(refusesDlna).join(",")}\n'
          'controlUrl=${_controlCache.values.isEmpty ? "none" : _controlCache.values.first.$1}\n');
      await res.close();
      return;
    }
    if (request.uri.path == '/desc.xml' || request.uri.path == '/') {
      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType('text', 'xml', charset: 'utf-8');
      // A real ContentDirectory, not a stand-in. The 55UP7760PVB plays what
      // we shove at it, but the 65UP7500PVG browses the server first and
      // refuses anything that is not a proper DMS — hence the SCPD and the
      // Browse endpoint below.
      res.write('''
<?xml version="1.0" encoding="utf-8"?>
<root xmlns="urn:schemas-upnp-org:device-1-0">
  <specVersion><major>1</major><minor>0</minor></specVersion>
  <device>
    <deviceType>urn:schemas-upnp-org:device:MediaServer:1</deviceType>
    <friendlyName>PlayZone</friendlyName>
    <manufacturer>PlayZone</manufacturer>
    <manufacturerURL>http://192.168.1.8</manufacturerURL>
    <modelDescription>PlayZone wall screen</modelDescription>
    <modelName>PlayZone Wall Screen</modelName>
    <modelNumber>1.0</modelNumber>
    <modelURL>http://192.168.1.8</modelURL>
    <UDN>uuid:playzone-wall-screen-1</UDN>
    <serviceList>
      <service>
        <serviceType>urn:schemas-upnp-org:service:ContentDirectory:1</serviceType>
        <serviceId>urn:upnp-org:serviceId:ContentDirectory:1</serviceId>
        <SCPDURL>/cds.xml</SCPDURL>
        <controlURL>/control</controlURL>
        <eventSubURL>/event</eventSubURL>
      </service>
      <service>
        <serviceType>urn:schemas-upnp-org:service:ConnectionManager:1</serviceType>
        <serviceId>urn:upnp-org:serviceId:ConnectionManager:1</serviceId>
        <SCPDURL>/cms.xml</SCPDURL>
        <controlURL>/control</controlURL>
        <eventSubURL>/event</eventSubURL>
      </service>
    </serviceList>
  </device>
</root>
''');
      await res.close();
      return;
    }
    if (request.uri.path == '/cds.xml') {
      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType('text', 'xml', charset: 'utf-8');
      res.write(_contentDirectoryScpd);
      await res.close();
      return;
    }
    if (request.uri.path == '/cms.xml') {
      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType('text', 'xml', charset: 'utf-8');
      res.write(_connectionManagerScpd);
      await res.close();
      return;
    }
    if (request.uri.path == '/control' && request.method == 'POST') {
      await _handleControl(request, res);
      return;
    }
    if (request.uri.path != '/tv.jpg' || _image == null) {
      res.statusCode = HttpStatus.notFound;
      res.headers.set('X-PlayZone-Reason',
          _image == null ? 'no-image-yet' : 'wrong-path');
      await res.close();
      return;
    }
    res.statusCode = HttpStatus.ok;
    res.headers.contentType = ContentType('image', 'png');
    res.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate');
    res.headers.set('Accept-Ranges', 'none');
    res.headers.contentLength = _imageBytes;
    if (request.method == 'HEAD') {
      await res.close();
      return;
    }
    res.add(_image!);
    await res.close();
    _imagesServed++;
    _tvFetched = true;
    _lastFetchAt = DateTime.now();
  }

  /// Set by the broadcaster when a capture throws, so the status endpoint
  /// can explain a blank TV.
  void noteCaptureError(Object error) => _lastCaptureError = '$error';
  String? _lastCaptureError;
  int _imagesServed = 0;

  /// A short description of the configured screens, injected by the shell
  /// because the config layer lives in the feature folder. Without it the
  /// status page cannot tell "no screen matched" from "screen unreachable".
  static String Function() configSummary = () => 'unknown';

  /// Known control endpoints, for the status page.
  String get controlSummary => _controlCache.entries
      .map((e) => '${e.key} -> ${e.value.$1.split('/AVTransport/').first}')
      .join(' , ');

  void dispose() {
    stopPushing();
    _controller.close();
  }
}
