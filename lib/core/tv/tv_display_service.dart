import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;

import '../window/window_state.dart';
import 'hard_lock.dart';
import 'tv_power_service.dart';
import 'tv_screen_report.dart';
import 'video_probe.dart';

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

  static const _soapEnvelope = '<?xml version="1.0" encoding="utf-8"?>'
      '<s:Envelope xmlns:s="http://schemas.xmlsoap.org/soap/envelope/" '
      's:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><s:Body>'
      '%BODY%</s:Body></s:Envelope>';

  HttpServer? _server;
  Uint8List? _image;
  int _imageBytes = 0;

  /// Video being played on a specific screen (pulled by that TV only).
  final Map<String, File> _videoFiles = {};
  final Map<String, String> _videoUrls = {};
  final Set<String> _videoScreens = {};
  final Map<String, String> _videoContentTypes = {};

  /// The shape of each playing file, read from its own header.
  final Map<String, VideoInfo> _videoInfo = {};

  /// One counter **per screen**, each seeded from the clock so a restarted
  /// program never re-offers an address a panel has already cached.
  ///
  /// This used to be a single shared number, and that is what made the walls
  /// move together. The number is baked into the picture URL
  /// (`.../tv.jpg?s=<token>-<revision>`), so bumping it for one screen made
  /// the URL "new" for *every* screen — the other panels saw a changed address
  /// and re-fetched the frame, which reads on the wall as every screen
  /// flickering or changing at once, when only one was asked to. Keying the
  /// counter by address means pushing to screen A cannot invalidate screen B's
  /// URL, so a command lands on exactly the screen it was sent to.
  ///
  /// Seeding from the clock matters for the same reason it always did: the
  /// television caches the address it was given, and a counter that restarted
  /// at zero would hand it an address it already holds, so it would answer
  /// from its own cache and never ask us for the file — a picture nobody
  /// downloaded being a picture we cannot use to prove the command worked.
  final Map<String, int> _revisions = {};
  int _revisionFor(String tvIp) =>
      _revisions.putIfAbsent(tvIp.trim(), () => DateTime.now().millisecondsSinceEpoch);
  String? _lastError;
  DateTime? _lastPushAt;
  bool _tvFetched = false;
  DateTime? _lastFetchAt;
  DateTime? get lastFetchAt => _lastFetchAt;

  /// One refresh timer per screen, so starting the cards on one wall cannot
  /// cancel the other's. Replaces the single `_timer` that used to be shared.
  final Map<String, Timer> _pushTimers = {};

  /// Screens with a push in flight. A set, not a flag: the café has two and
  /// one must never cancel the other.
  final Set<String> _pushing = {};

  /// One history per screen, so "which screen is broken" is a lookup instead
  /// of a guess. Everything that used to be a single shared counter or flag
  /// lives here now, keyed by address — two TVs writing to one `lastError`
  /// meant the panel could only ever describe whichever spoke last.
  final Map<String, TvScreenLog> _screens = {};

  TvScreenLog _log(String tvIp) =>
      _screens.putIfAbsent(tvIp.trim(), () => TvScreenLog(tvIp.trim()));

  /// A short opaque name for each screen, so a picture URL can say who asked
  /// for the picture without carrying the address.
  final Map<String, String> _tokens = {};
  final Map<String, String> _tokenOwner = {};

  /// The name this screen is known by inside picture URLs.
  ///
  /// It exists because the panel refuses a picture URL carrying more than one
  /// query parameter, so the address and the cache-busting revision cannot both
  /// ride in the query. Rather than give up naming the screen — which is what
  /// makes "which panel took the picture?" answerable for one wall at a time —
  /// both pieces are packed into the single parameter the panel tolerates. The
  /// token is only meaningful to this process, which is all it has to be: the
  /// app re-offers the URL on every push, so a token from a previous run is
  /// never one a screen can be holding.
  String _tokenFor(String tvIp) => _tokens.putIfAbsent(tvIp.trim(), () {
        final t = _random.nextInt(0x7fffffff).toRadixString(16).padLeft(7, '0');
        _tokenOwner[t] = tvIp.trim();
        return t;
      });

  static final Random _random = Random();

  /// The screen a picture request belongs to, from the token in its URL.
  ///
  /// Empty when the token is unknown, which is the honest answer: a request
  /// carrying something this process never issued cannot be credited to a wall.
  String _screenForTag(String tag) {
    if (tag.isEmpty) return '';
    final cut = tag.lastIndexOf('-');
    final token = cut > 0 ? tag.substring(0, cut) : tag;
    return _tokenOwner[token] ?? '';
  }

  /// Who each screen is, injected by the shell because the names and the
  /// device bindings live in the settings tables, not here.
  static List<TvScreenIdentity> screenIdentities = const <TvScreenIdentity>[];

  /// Whether the TV feature is switched on at all — a screen cannot be
  /// blamed for being dark when the whole feature is off.
  ///
  /// Starts on, because the shell overwrites it from the saved settings on its
  /// first build and a wall that waits for that to say "on" is a wall that
  /// spends the first moments of the morning in whatever state it was left in.
  /// Whether *this machine* may touch a screen at all is a different question,
  /// and it is answered by [tvAllowed] — which is what has to be closed.
  static bool featureEnabled = true;

  /// Set once at startup from the `PLAYZONE_TV` environment variable.
  ///
  /// The reason this exists is a room with two machines in it. The code is
  /// edited on one and the till runs on the other, both on the same café
  /// network, and a program that starts for a quick look will happily find the
  /// five wall screens, push a black frame at them and hand them back — which
  /// means a television the moment a developer opened the app is a television a
  /// customer is watching go dark. No setting inside the program can prevent
  /// that, because the settings say the screens are live; they are live. Only
  /// something outside the program, that the machine's owner sets once, can say
  /// "this machine is not allowed to touch a television".
  ///
  /// So: `PLAYZONE_TV=off` makes this program physically unable to reach a
  /// screen. Not "does not by default" — unable. The picture server is never
  /// opened, every push and every release returns false without leaving the
  /// process, and discovery never starts. Deliberately an environment variable
  /// rather than a button, because a button in the settings is one stray tap
  /// away from being wrong, and a variable set on the machine is not.
  static final bool _allowedByEnvironment = _readTvSwitch();

  static bool _readTvSwitch() {
    // A missing variable means allowed, because the till must work with nothing
    // set at all. Only an explicit "off" closes it - a typo should not silently
    // take the screens down in a full cafe.
    final fromEnv = Platform.environment['PLAYZONE_TV'];
    return !(fromEnv != null && fromEnv.trim().toLowerCase() == 'off');
  }

  /// Whether this machine is allowed to touch a screen at all.
  ///
  /// Every command path checks this before doing anything, so that turning it
  /// off means the whole feature is inert rather than merely hidden from the
  /// settings page.
  static bool get tvAllowed => _allowedByEnvironment;

  /// A snapshot of every screen, judged and described in plain Arabic.
  ///
  /// Falls back to whatever addresses we have touched when the shell has not
  /// injected the identities yet, so this is never empty and never throws.
  List<TvScreenReport> reports() {
    final identities = screenIdentities.isNotEmpty
        ? screenIdentities
        : _screens.keys
            .map((ip) => TvScreenIdentity(ip: ip))
            .toList(growable: false);
    final out = <TvScreenReport>[];
    for (final identity in identities) {
      final ip = identity.ip.trim();
      final bound = identity.deviceId;
      out.add(judgeTvScreen(
        identity: identity,
        log: _screens.putIfAbsent(ip, () => TvScreenLog(ip)),
        featureEnabled: featureEnabled,
        endpointKnown: hasControlUrlFor(ip),
        boundDeviceId: bound,
      ));
    }
    // Worst first, so a page full of screens leads with the one that needs
    // attention rather than burying it under two healthy panels.
    out.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      return bySeverity != 0 ? bySeverity : a.ip.compareTo(b.ip);
    });
    return out;
  }

  /// Records what we asked a screen to do and how it went. Every command
  /// funnels through here so no screen can be silent.
  void noteCommand(
    String tvIp,
    String command,
    String result, {
    bool ok = true,
    int? tookMs,
  }) {
    final log = _log(tvIp);
    log.lastCommand = command;
    log.lastCommandAt = DateTime.now();
    log.lastResult = result;
    log.lastOk = ok;
    log.lastTookMs = tookMs;
    log.note('$command → $result${tookMs == null ? '' : ' (${tookMs}ms)'}',
        ok: ok);
  }

  /// Marks a screen as having spoken to us at least once.
  ///
  /// One method for every "it answered" moment, because the difference
  /// between a screen we have never reached and one that has just gone quiet
  /// is the difference between an open question and a fault — and that
  /// difference is invisible unless a single place records it.
  void markReached(String tvIp, {String? state}) {
    final log = _log(tvIp);
    log.reachable = true;
    log.everReached = true;
    if (state != null) {
      // Only move the "since" mark when the reported state actually changes.
      // If it moved on every read we would be timing our own polling, and a
      // screen that has been stuck since opening would be filed as one that
      // has only just started.
      if (log.transportState != state) log.stateSince = DateTime.now();
      log.transportState = state;
      log.stateReadAt = DateTime.now();
    }
  }

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
    if (!tvAllowed) return false;
    if (_server != null) return true;
    try {
      _server =
          await HttpServer.bind(InternetAddress.anyIPv4, port, shared: false);
      _server!.listen(_handleRequest, onError: (_) {});
      await _startSelfTest();
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
      // Resolve our own LAN address here, where we can await it, so the
      // settings footer can name the address the screens must dial from the
      // first time it is shown rather than "…".
      await resolveLocalAddress();
      return true;
    } catch (e) {
      // Two copies of this program are the one fault that used to show up as
      // nonsense: the second copy cannot bind the picture port, could not say
      // so anywhere the staff could see, and then blackened a wall while the
      // first copy handed the same wall back. The panels ended up flipping
      // between two owners and the counter saw a screen that worked and did not
      // work at the same time. A bind failure here is almost never a firewall
      // or a port range problem - it is another copy of this program, already
      // running and already serving the same screens.
      _anotherCopy = true;
      _lastError = 'في نسخة تانية من البرنامج شغالة دلوقتي';
      return false;
    }
  }

  /// True when this program could not open the picture port because another copy
  /// of itself already holds it.
  ///
  /// Worth telling the staff rather than logging quietly: the copy that is
  /// actually running is the one in control of the walls, and this one is a
  /// passenger that will look like it is working while doing nothing.
  bool get anotherCopyRunning => _anotherCopy;

  bool _anotherCopy = false;

  /// A second, loopback-only port that can black a wall and hand it straight
  /// back.
  ///
  /// It is a separate server rather than a route on the picture server because
  /// the picture server is deliberately reachable from the whole café — the
  /// screens have to reach it — and a request that interrupts what a customer is
  /// watching must not be reachable from the same place. Binding to
  /// `loopbackIPv4` is what guarantees that: no password, no token and nothing
  /// to guess, because nothing off this machine can open the port at all.
  ///
  /// Failing to open it costs nothing and is not reported as an error: the
  /// screens do not use it, and the app runs perfectly well without it.
  Future<void> _startSelfTest() async {
    try {
      _testServer ??= await HttpServer.bind(
          InternetAddress.loopbackIPv4, port + 1,
          shared: false);
      _testServer!.listen(_handleSelfTest, onError: (_) {});
    } catch (_) {
      _testServer = null;
    }
  }

  /// Fetch counts as of the previous probe, per screen, so "is it really showing
  /// our picture" can be answered as a change rather than as an assertion.
  final Map<String, int> _servedAtProbe = {};

  HttpServer? _testServer;

  Future<void> _handleSelfTest(HttpRequest request) async {
    final res = request.response;
    final want = request.uri.queryParameters['ip']?.trim() ?? '';
    try {
      if (request.uri.path != '/blank') {
        res.statusCode = HttpStatus.notFound;
        await res.close();
        return;
      }
      if (want.isEmpty) {
        res.statusCode = HttpStatus.badRequest;
        res.write('which screen? add ?ip=<address>\n');
        await res.close();
        return;
      }
      // The frames this screen pulled before it was asked, so the answer is
      // about what this test caused rather than about everything it has ever
      // fetched. A renderer loops on a still image, so an absolute count would
      // happily report a working screen - or a broken one - from traffic that
      // belonged to an earlier push.
      final before = _log(want).imagesServed;
      final pushed = await _pushOnce(want);
      // Handed straight back, on every path out and including when the push
      // failed. A wall left dark because a test came out inconclusive is a
      // worse outcome than the test, and the console is what the customer
      // paid for.
      final released = await releaseToInput(want, force: true);
      res.statusCode = HttpStatus.ok;
      // Judged on the picture arriving, never on the panel's answer. These
      // screens return 500 while working correctly, so the only trustworthy
      // proof is the screen asking for the frame.
      final log = _log(want);
      final fetched = log.imagesServed - before;
      res.write('screen=$want pushed=$pushed released=$released\n'
          'fetched=$fetched (total ${log.imagesServed})\n'
          'black=${fetched > 0 ? "yes" : "no"}\n'
          'lastResult=${log.lastResult ?? "none"}\n'
          'lastPushedUri=${log.lastPushedUri.isEmpty ? "none" : log.lastPushedUri}\n');
    } catch (e) {
      res.statusCode = HttpStatus.internalServerError;
      res.write('$e\n');
    }
    await res.close();
  }

  Future<void> stopServer() async {
    stopPushing();
    await _testServer?.close(force: true);
    _testServer = null;
    await _server?.close(force: true);
    _server = null;
  }

  /// This machine's LAN address (what the TV must dial).
  ///
  /// Synchronous, and honest about it: it can only ever return an address that
  /// [resolveLocalAddress] or [_detectLocalAddress] has already cached. On the
  /// very first call — before either has run — it returns null, and callers
  /// that can await should use [resolveLocalAddress] instead.
  String? get localAddress => _localAddress;
  String? _localAddress;

  /// True for adapter ranges no café television can ever reach.
  ///
  /// This laptop hands back a Wi-Fi Direct / "hosted network" adapter on
  /// 192.168.137.x *before* the real Wi-Fi card, so "the first 192.168.*"
  /// named an address outside the café LAN. The image URL then pointed at that
  /// dead adapter and every wall stayed black while nothing reported a fault.
  /// Link-local (169.254.*) is dead for the same reason.
  static bool _isVirtualRange(String ip) =>
      ip.startsWith('192.168.137.') || ip.startsWith('169.254.');

  /// Resolves and caches this machine's LAN address.
  ///
  /// It used to fire `NetworkInterface.list()` and return before the answer
  /// arrived, so the first caller always got null and the cache filled in on
  /// some later, unrelated call — a race that made "we could not find our own
  /// address" a coin flip at startup. Awaiting the list fixes that, and the
  /// 10.* / 192.168.* preference with the 172.16-31 fallback is unchanged.
  Future<String?> _detectLocalAddress() async {
    try {
      final ifaces = await NetworkInterface.list(type: InternetAddressType.IPv4);
      String? tenDot;
      for (final iface in ifaces) {
        for (final addr in iface.addresses) {
          if (addr.isLoopback) continue;
          final ip = addr.address;
          if (_isVirtualRange(ip)) continue;
          if (ip.startsWith('192.168.') || ip.startsWith('10.')) {
            _localAddress ??= ip;
          } else if (RegExp(r'^172\.(1[6-9]|2\d|3[01])\.').hasMatch(ip)) {
            tenDot ??= ip;
          }
        }
      }
      // tenDot is returned rather than cached: it is a 172.16-31 address, the
      // one range that is *sometimes* the café LAN and sometimes not, so it is
      // offered as an answer without claiming to be the one we settled on.
      return _localAddress ?? tenDot;
    } catch (_) {
      return null;
    }
  }

  /// Resolves the LAN address once, asynchronously, and caches it.
  ///
  /// When [forHost] is a screen's address, an address on that screen's own /24
  /// wins: this machine carries several IPv4 addresses, and only the one on
  /// the café LAN can actually be reached by the television.
  Future<String?> resolveLocalAddress({String? forHost}) async {
    if (forHost != null && forHost.contains('.')) {
      final prefix = '${forHost.split('.').take(3).join('.')}.';
      try {
        final list =
            await NetworkInterface.list(type: InternetAddressType.IPv4);
        for (final iface in list) {
          for (final addr in iface.addresses) {
            if (!addr.isLoopback && addr.address.startsWith(prefix)) {
              return addr.address;
            }
          }
        }
      } catch (_) {}
    }
    if (_localAddress != null) return _localAddress;
    return _detectLocalAddress();
  }

  /// Replaces the image being displayed and (re)tries the push.
  Future<void> publish(Uint8List pngBytes) async {
    _image = pngBytes;
    _imageBytes = pngBytes.length;
    _tvFetchedScreens.clear();
    _tvFetched = false;
    // A real frame from the broadcaster always wins over the blank one, so
    // the screen comes back to life the moment a session starts again. This is
    // board-wide — every wall shows this same frame — so every screen's dark
    // mark is cleared here, not just one address's.
    _blankedScreens.clear();
    _blanked = false;
    _tvFetchedScreens.clear();
    _tvFetched = false;
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

  /// Per-screen frames that stand in for the shared board.
  ///
  /// Right now this holds one thing: the "عرّفني" label. It exists so a
  /// single screen can be shown something *without* the whole wall seeing it.
  /// The alternative — swapping the shared image for twelve seconds — meant a
  /// screen that fetched during that window was handed another screen's name.
  final Map<String, Uint8List> _overrides = {};

  /// Serves a solid black frame instead of the session cards.
  ///
  /// [tvIp] is the screen being blacked out. Its own counter is bumped so that
  /// screen re-fetches the black frame; leaving it out (an internal call with
  /// no single screen in mind) bumps nobody, since handing every panel a new
  /// address is the "all the walls move at once" fault this file no longer
  /// has.
  Future<void> blank({String? tvIp}) async {
    if (_image == null) {
      _black ??= await _buildBlackFrame();
      _image = _black;
    }
    _imageBytes = _image!.length;
    // Recorded per screen: "is this wall dark?" has to be answerable for one
    // panel at a time, and one blanket flag made a screen that had just been
    // blacked out look dark even after a different one was woken back up.
    if (tvIp != null && tvIp.trim().isNotEmpty) {
      _blankedScreens.add(tvIp.trim());
      _tvFetchedScreens.remove(tvIp.trim());
      _revisions[tvIp.trim()] = _revisionFor(tvIp) + 1;
    }
    _blanked = _blankedScreens.isNotEmpty;
    _tvFetched = _tvFetchedScreens.isNotEmpty;
  }

  /// Back to normal: the next capture from the broadcaster is shown again.
  ///
  /// [tvIp] names the screen being woken, so only that panel is marked as no
  /// longer dark. Without an address (an internal "everything is live again"
  /// call) there is no single screen to clear, so nothing is cleared.
  void unblank({String? tvIp}) {
    if (tvIp != null && tvIp.trim().isNotEmpty) {
      _blankedScreens.remove(tvIp.trim());
    }
    _blanked = _blankedScreens.isNotEmpty;
  }

  /// The screens currently showing our black frame, by address.
  final Set<String> _blankedScreens = {};

  /// The screens that have pulled a frame from us, by address.
  final Set<String> _tvFetchedScreens = {};

  final Set<String> _closedScreens = closedScreenLedger();

  /// Is this screen closed, i.e. meant to be dark until the next session?
  bool isScreenClosed(String tvIp) => _closedScreens.contains(tvIp);

  /// Marks a screen closed straight away, without pushing anything.
  void markScreenClosed(String tvIp) => _closedScreens.add(tvIp);

  /// Marks the screen as live again — a session has started, so the console
  /// is what the wall should be showing.
  void markScreenOpen(String tvIp) => _closedScreens.remove(tvIp);

  /// Hands every screen we know about back to its console, in parallel.
  ///
  /// Called when the program is closing. Without it, each wall is left
  /// sitting on a renderer that is fetching a picture from a server that is
  /// about to stop existing — and these panels do not recover from that on
  /// their own. They sit in a half-finished change, ignore every later
  /// command, and the next thing anyone learns about it is that the screen
  /// "refuses" whatever it is sent, which is the one conclusion that sends
  /// someone off to rewire a television that is perfectly fine.
  ///
  /// Best effort and deliberately unhurried about its own failure: a screen
  /// that cannot be reached now is a screen that was already off, which is
  /// where it needed to be anyway.
  Future<void> releaseAllScreens() async {
    // Gated on the machine's switch, not on `featureEnabled`.
    //
    // `featureEnabled` mirrors the in-program setting and is false until the
    // shell first builds, so gating on it means a wall can be left black: the
    // one thing this method exists to prevent. Releasing a screen is the safe
    // direction anyway — it hands the television back to the console — so the
    // only thing that should be able to stop it is a machine that is not
    // allowed to touch a television at all.
    if (!tvAllowed) return;
    final known = _controlCache.keys.toList(growable: false);
    if (known.isEmpty) return;
    for (final ip in known) {
      try {
        // Forced: closing the program is exactly the moment a closed screen
        // is no longer meant to stay dark, and this is the only caller allowed
        // to overrule that.
        await releaseToInput(ip, force: true);
      } catch (_) {
        // Nothing useful to do while shutting down, and a failure here must
        // never be the reason the program refuses to close.
      }
    }
  }

  /// Hands the TV at [tvIp] back to whatever it was watching — in practice
  /// HDMI 1, the console — by ending our playback.
  ///
  /// This is the "show the game" state. It is a single SOAP `Stop` against
  /// an endpoint we already discovered and cached, so it lands in well under
  /// a second. Verified on a 55UP7760PVB: the renderer's transport goes
  /// PLAYING → STOPPED and the panel returns to the HDMI input.
  ///
  /// Refuses a screen that is closed, unless [force]. A closed screen has been
  /// paid for and must stay dark, and the one command that would undo that is
  /// this one.
  Future<bool> releaseToInput(String tvIp, {bool force = false}) async {
    if (!tvAllowed) return false;
    if (!force && _closedScreens.contains(tvIp)) {
      noteCommand(
        tvIp,
        'فتح',
        'الشاشة مقفولة من تحصيل — مش هنرجّعها',
        ok: true,
      );
      return false;
    }
    _closedScreens.remove(tvIp);
    // This screen is going back to its console, so it is no longer dark —
    // cleared for this address only, so a different wall that is still
    // blacked out keeps saying so.
    _blankedScreens.remove(tvIp.trim());
    _blanked = _blankedScreens.isNotEmpty;
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
    final watch = Stopwatch()..start();
    var ok = await _soap(hit.$1, 'Stop', '<InstanceID>0</InstanceID>');
    if (!ok) {
      // The panel moved its renderer to another port, or it was restarted and
      // came back somewhere else. The cached address is dead, so wait for the
      // background re-look that the failed command started and try once more.
      // This does not start a look of its own: at the till a screen that is
      // simply off must not turn into a 7,000-port sweep.
      final fresh =
          await _refreshControlUrl(tvIp, startLookup: false, timeoutMs: 1500);
      if (fresh != null) {
        ok = await _soap(fresh, 'Stop', '<InstanceID>0</InstanceID>');
      }
    }
    watch.stop();
    if (ok) {
      _lastPushAt = DateTime.now();
      // A release that landed means the panel is talking to us, and it means
      // we are no longer the source — which is the answer to "what is the
      // screen showing" for as long as it lasts.
      markReached(tvIp, state: 'STOPPED');
    } else {
      // Do NOT keep a stale "reachable" true here. A screen that has stopped
      // answering has to stop being reported as reachable, or the panel keeps
      // insisting everything is fine long after it stopped talking.
      _log(tvIp).reachable = false;
    }
    noteCommand(
      tvIp,
      'فتح الجلسة',
      ok ? 'رجعت للبلايستيشن' : 'الأمر ما وصلش',
      ok: ok,
      tookMs: watch.elapsedMilliseconds,
    );
    return ok;
  }

  // ── Sound ──────────────────────────────────────────────────────────────────

  /// The endpoint that moves the sound of a screen.
  ///
  /// It sits in the same device description as the picture endpoint, so it is
  /// normally known already and the volume of a wall costs no extra searching.
  /// A screen that was described before this part existed is read once more.
  Future<String?> _renderingUrl(String tvIp) async {
    final key = tvIp.trim();
    final cached = _renderingCache[key];
    if (cached != null &&
        DateTime.now().difference(cached.$2) < const Duration(minutes: 30)) {
      return cached.$1;
    }
    // Not known yet. The picture endpoint comes first, because that is what
    // knows the port; the description is then read from that same port for the
    // sound endpoint.
    final av = await _findControlUrl(key);
    if (av == null) return null;
    final hit = _renderingCache[key];
    if (hit != null) return hit.$1;
    final origin = Uri.tryParse(av)?.origin;
    if (origin == null) return null;
    for (final path in const [
      // LG's televisions serve their description at the root of the port, not
      // at a named file, so the root is tried first.
      '/',
      '/desc.xml',
      '/rootDesc.xml',
      '/xml/device_description.xml',
    ]) {
      final found = await _servicesFrom('$origin$path');
      final render = found?.render;
      if (render != null) {
        _renderingCache[key] = (render, DateTime.now());
        return render;
      }
    }
    return null;
  }

  /// The sound level of a screen, 0 to 100. Null when the screen will not say.
  Future<int?> getVolume(String tvIp) async {
    final url = await _renderingUrl(tvIp);
    if (url == null) return null;
    final (status, payload, _) = await _soapRaw(
      url,
      'GetVolume',
      '<Channel>Master</Channel>',
      service: 'urn:schemas-upnp-org:service:RenderingControl:1',
    );
    if (status == null || status >= 400) return null;
    final value = RegExp(r'<CurrentVolume>\s*(-?\d+)\s*</CurrentVolume>')
        .firstMatch(payload)
        ?.group(1);
    final level = int.tryParse(value ?? '');
    if (level == null) return null;
    return level.clamp(0, 100);
  }

  /// Sets the sound level of a screen, 0 to 100.
  Future<bool> setVolume(String tvIp, int level) async {
    final url = await _renderingUrl(tvIp);
    if (url == null) {
      _lastError = 'الشاشة ${tvIp.trim()} مش راد على التحكم في الصوت';
      return false;
    }
    final want = level.clamp(0, 100);
    return _soap(
      url,
      'SetVolume',
      '<Channel>Master</Channel><DesiredVolume>$want</DesiredVolume>',
      service: 'urn:schemas-upnp-org:service:RenderingControl:1',
    );
  }

  /// Turns the sound up or down and says what the level is now.
  ///
  /// The new level is worked out from what the screen itself reports, so two
  /// people pressing the button at once do not send two different numbers.
  Future<int?> changeVolume(String tvIp, int step) async {
    final current = await getVolume(tvIp);
    if (current == null) return null;
    final want = (current + step).clamp(0, 100);
    final ok = await setVolume(tvIp, want);
    return ok ? want : null;
  }

  /// Whether a screen is silent.
  Future<bool?> isMuted(String tvIp) async {
    final url = await _renderingUrl(tvIp);
    if (url == null) return null;
    final (status, payload, _) = await _soapRaw(
      url,
      'GetMute',
      '<Channel>Master</Channel>',
      service: 'urn:schemas-upnp-org:service:RenderingControl:1',
    );
    if (status == null || status >= 400) return null;
    final value = RegExp(r'<CurrentMute>\s*(\d)\s*</CurrentMute>')
        .firstMatch(payload)
        ?.group(1);
    return value == null ? null : value == '1';
  }

  /// Silences a screen, or gives it its sound back.
  Future<bool> setMute(String tvIp, bool muted) async {
    final url = await _renderingUrl(tvIp);
    if (url == null) {
      _lastError = 'الشاشة ${tvIp.trim()} مش راد على التحكم في الصوت';
      return false;
    }
    return _soap(
      url,
      'SetMute',
      '<Channel>Master</Channel><DesiredMute>${muted ? 1 : 0}</DesiredMute>',
      service: 'urn:schemas-upnp-org:service:RenderingControl:1',
    );
  }

  /// Paints the screen at [tvIp] black — our stand-in for "off", since this
  /// TV refuses a real network power-off. One push, no loop, so it is
  /// immediate.
  Future<bool> pushBlack(String tvIp) async {
    if (!tvAllowed) return false;
    // Claimed before anything else happens, including the blank. From this
    // moment the wall is paid for and dark, and any release already in flight
    // is no longer allowed to take it back.
    _closedScreens.add(tvIp);
    if (!_controlCache.containsKey(tvIp)) {
      // Nothing known yet — kick discovery off in the background and say so
      // rather than making checkout wait for a port sweep.
      if (!_warming.contains(tvIp)) unawaited(warmUp(tvIp: tvIp));
      await blank(tvIp: tvIp);
      return false;
    }
    await announce(tvIp: tvIp);
    await blank(tvIp: tvIp);
    final watch = Stopwatch()..start();
    final ok = await _pushOnce(tvIp);
    watch.stop();
    if (ok) {
      markReached(tvIp);
      noteCommand(tvIp, 'التحصيل', 'اتغمّضت (سودا)',
          tookMs: watch.elapsedMilliseconds);
    }
    return ok;
  }

  /// Shows a one-off "this is me" label on one screen.
  ///
  /// The room's screens are addressed by IP, and a wall that is just showing
  /// its console says nothing about which address it is. Pressing this paints
  /// that screen's own name and address across the television, so a person can
  /// stand in front of it and rename exactly the right entry instead of
  /// guessing. It takes itself down, so nobody has to remember to.
  Future<bool> identify(
    String tvIp, {
    required String name,
    String? mac,
  }) async {
    if (!tvAllowed) return false;
    final png = await _buildIdentifyFrame(name, tvIp, mac);
    // The frame belongs to THIS screen, not to the shared board. It is parked
    // in `_overrides` under the screen's address so the picture server hands
    // it out only when that panel asks — the other walls keep seeing the board
    // they were already showing.
    final key = tvIp.trim();
    _overrides[key] = png;
    // Its own address changes, so it comes back for the new frame instead of
    // answering from its cache.
    _revisions[key] = _revisionFor(tvIp) + 1;
    final ok = await _pushOnce(tvIp);
    _identifyTimers[tvIp]?.cancel();
    _identifyTimers[tvIp] = Timer(const Duration(seconds: 12), () {
      unawaited(_endIdentify(tvIp));
    });
    return ok;
  }

  final Map<String, Timer> _identifyTimers = {};

  /// Puts a screen back the way `identify` found it.
  Future<void> _endIdentify(String tvIp) async {
    _identifyTimers.remove(tvIp)?.cancel();
    // Drop the label first, so the next fetch on this screen gets the board
    // again. Nothing was ever taken away from the other screens.
    _overrides.remove(tvIp.trim());
    // A screen that is paid for stays dark; anything else goes back to its
    // console, which is what the normal flow would leave it doing.
    if (_closedScreens.contains(tvIp)) {
      await blank(tvIp: tvIp);
      await _pushOnce(tvIp);
    } else {
      await releaseToInput(tvIp);
    }
  }

  /// The shape the wall is drawn at, and served in.
  ///
  /// 1920×1080 is what these panels are built for. A 1280×720 frame upscaled
  /// onto one of them comes out soft, and soft on a wall of this size reads as
  /// "cheap" from across the room — so the picture is drawn at the size the
  /// television can actually show, and the panel gets it as it is.
  static const double boardWidth = 1920;
  static const double boardHeight = 1080;

  /// A frame naming one screen, for the "عرّفني" button.
  static Future<Uint8List> _buildIdentifyFrame(
      String name, String ip, String? mac) async {
    const double w = boardWidth, h = boardHeight;
    // The layout was drawn for a 1280×720 frame; the frame is now 1920×1080,
    // so everything on it is scaled by the same factor and the text lands
    // exactly where it used to, only sharper.
    const double k = w / 1280;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, const ui.Rect.fromLTWH(0, 0, w, h));
    // A colour no wall normally shows, so it reads as "somebody asked for
    // this" rather than as a broken or swapped screen.
    canvas.drawRect(const ui.Rect.fromLTWH(0, 0, w, h),
        ui.Paint()..color = const ui.Color(0xFF130B33));

    void line(String text, double y, double size, ui.Color color) {
      final builder = ui.ParagraphBuilder(ui.ParagraphStyle(
        textAlign: ui.TextAlign.center,
        fontSize: size * k,
        fontWeight: ui.FontWeight.w700,
      ))
        ..pushStyle(ui.TextStyle(
            color: color, fontSize: size * k, fontWeight: ui.FontWeight.w700))
        ..addText(text);
      final paragraph = builder.build()
        ..layout(const ui.ParagraphConstraints(width: w));
      canvas.drawParagraph(paragraph, ui.Offset(0, y * k));
    }

    line(name, 120, 82, const ui.Color(0xFFFFFFFF));
    line('أنت الشاشة دي', 250, 34, const ui.Color(0xFFB9AEE8));
    line(ip, 360, 64, const ui.Color(0xFF6FE3B0));
    if (mac != null && mac.isNotEmpty) {
      line('MAC:  $mac', 480, 40, const ui.Color(0xFFCFC6F2));
    }
    line('PlayZone', 600, 28, const ui.Color(0xFF8A82B0));

    final image = await recorder.endRecording().toImage(w.toInt(), h.toInt());
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    return data!.buffer.asUint8List();
  }

  /// A single SOAP push, for callers that manage their own timing.
  Future<bool> pushOnceNow() async {
    if (kHardLockWallNetwork) return false;
    return _pushOnce(_currentTvIp);
  }

  /// Remembers where the TV lives so `pushOnceNow()` works without being
  /// handed the address every time.
  void useTv(String ip) => _currentTvIp = ip;

  String _currentTvIp = '';

  /// The picture URL handed to one specific screen.
  ///
  /// ONE query parameter, never two. An LG webOS panel answers `SetAVTransportURI`
  /// with HTTP 500 "Invalid Args" the moment the picture URL carries a second
  /// parameter, and it says the same thing for a bad InstanceID and a metadata
  /// block it cannot parse — so a rejected push reads exactly like a panel that
  /// has been told not to play anything, and no amount of retrying helps. This
  /// was measured across both walls: `?v=`, `?s=` and no query at all are
  /// accepted; anything with an `&` is refused. Do not add a parameter here.
  ///
  /// The single parameter carries the screen's token and its **own** revision
  /// together, so the screen is still named on every fetch — without it
  /// `imagesServed` was one number shared by every TV, which is why "is the
  /// picture reaching the screen?" could not be answered for one panel at a
  /// time — and so a push aimed at one screen cannot invalidate another's URL.
  String _imageUriFor(String self, String tvIp) =>
      'http://$self:$port/tv.jpg?s=${_tokenFor(tvIp)}-${_revisionFor(tvIp)}';

  String _videoUriFor(String self, String tvIp) =>
      'http://$self:$port/video?s=${_tokenFor(tvIp)}-${_revisionFor(tvIp)}';

  /// Finds (and remembers) the TV's control endpoint ahead of time.
  ///
  /// Runs in the background and keeps retrying, because the renderer port
  /// moves on every TV restart and a screen that is off answers nothing on
  /// the first try. Stops once the endpoint is known.
  Future<void> warmUp({required String tvIp, bool force = false}) async {
    if (!tvAllowed) return;
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
        await announce(tvIp: tvIp);
        if (await _findControlUrl(tvIp) != null) {
          _suspect.remove(tvIp);
          if (force) _lastError = null;
          return;
        }
        if (refusesDlna(tvIp)) return;
        await Future<void>.delayed(const Duration(seconds: 2));
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
    // Drop the stale address from this screen's own history as well, so the
    // settings page does not keep pointing at an endpoint we just abandoned.
    final log = _screens[tvIp];
    if (log != null) {
      log.controlUrl = null;
      log.discoveredAt = null;
      log.refusedAt = null;
      log.transportState = null;
      log.stateReadAt = null;
      log.reachable = false;
      log.probing = false;
      log.note('طلبنا بحث جديد عن الشاشة');
    }
    unawaited(warmUp(tvIp: tvIp, force: true));
  }

  /// Looks for this screen once, right now, and reports whether it answered.
  ///
  /// The per-screen "ابحث عن الشاشة" button used to fire the background
  /// warm-up and then announce "خلصنا البحث" on a fixed timer, so it always
  /// looked like it had worked. Now the button's answer is the real result.
  Future<bool> searchNow(String tvIp) async {
    if (!tvAllowed) return false;
    _currentTvIp = tvIp;
    _lastDiscoveryAt.remove(tvIp);
    _controlCache.remove(tvIp);
    _dlnaRefused.remove(tvIp);
    _suspect.remove(tvIp);
    _targetHost = tvIp;
    final found = await _findControlUrl(tvIp);
    // Off right now? Keep the slow background retries going, so it still comes
    // good by itself when the panel wakes up.
    if (found == null) unawaited(warmUp(tvIp: tvIp));
    return found != null;
  }

  final Set<String> _warming = {};

  /// A black PNG the size of the wall, built once and reused for the whole
  /// "off" state.
  static Uint8List? _black;

  static Future<Uint8List> _buildBlackFrame() async {
    const rect = ui.Rect.fromLTWH(0, 0, boardWidth, boardHeight);
    final recorder = ui.PictureRecorder();
    ui.Canvas(recorder, rect)
        .drawRect(rect, ui.Paint()..color = const ui.Color(0xFF000000));
    final picture = recorder.endRecording();
    final image = await picture.toImage(boardWidth.toInt(), boardHeight.toInt());
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
  ///
  /// One timer **per screen**. There used to be a single timer, so starting
  /// the cards on a second screen cancelled the first one's refresh — the
  /// first wall then stopped being re-asserted and could drift. Each screen
  /// now owns its own loop, and they cannot stop each other.
  void startPushing(
      {required String tvIp, Duration every = const Duration(seconds: 2)}) {
    if (kHardLockWallNetwork) return;
    if (tvIp.isEmpty) return;
    final key = tvIp.trim();
    _pushTimers.remove(key)?.cancel();
    _currentTvIp = tvIp;
    unawaited(announce(tvIp: tvIp));
    var tick = 0;
    _pushTimers[key] = Timer.periodic(every, (_) {
      tick++;
      // The TV only renders media from a device it has "met" on SSDP, so we
      // re-announce periodically (and immediately after the first push).
      if (tick % 10 == 0) unawaited(announce(tvIp: tvIp));
      unawaited(_pushOnce(tvIp));
    });
    // Fire immediately so the screen lights up without waiting a cycle.
    unawaited(_pushOnce(tvIp));
  }

  /// SSDP alive announcement. Without it an LG renderer answers Play with
  /// HTTP 500 because it never saw this PC on the network.
  ///
  /// [tvIp] is the screen this announcement is for. It is passed in rather than
  /// read from the shared `_currentTvIp` because that single field was
  /// whichever screen spoke last: with two walls live, the periodic re-announce
  /// for one was resolved against the other's address. On one LAN the local
  /// address comes out the same either way, but naming the screen keeps the
  /// call honest about who it is for.
  Future<void> announce({String? tvIp}) async {
    if (kHardLockWallNetwork) return;
    final host = (tvIp ?? _currentTvIp).trim();
    final self =
        await resolveLocalAddress(forHost: host.isEmpty ? null : host);
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

  /// Stops every screen's refresh loop.
  ///
  /// Called when the wall hands back to the consoles (session start / collect),
  /// where every screen should stop polling rather than one being singled out.
  void stopPushing() {
    for (final t in _pushTimers.values) {
      t.cancel();
    }
    _pushTimers.clear();
  }

  /// Stops the refresh loop for one screen only, leaving the others running.
  void stopPushingScreen(String tvIp) {
    _pushTimers.remove(tvIp.trim())?.cancel();
  }

  /// Whether this screen is currently playing a video file.
  bool isPlayingVideo(String tvIp) => _videoScreens.contains(tvIp.trim());

  /// What is playing on this screen, as read from the file's own header.
  VideoInfo? videoInfoFor(String tvIp) => _videoInfo[tvIp.trim()];

  /// Screens that were showing the session cards when their film started.
  ///
  /// Starting a film tears the card loop down for that wall, so by the time
  /// "ارجع للعبة" is pressed the answer to "what was it showing before?" is
  /// no longer in the timers. It is written down here instead, because the way
  /// back is not the same for both kinds of wall: a wall that was showing the
  /// cards goes back to the cards, and a wall that was handed to a console
  /// goes back to the console.
  final Map<String, bool> _videoWasPushing = {};

  /// Play a local video file on a single screen. Returns true if the command
  /// was accepted. The TV pulls the file directly from this PC over LAN.
  Future<bool> playVideoFile(String tvIp, File file, {String? contentType}) async {
    if (!tvAllowed) return false;
    final key = tvIp.trim();
    if (key.isEmpty) return false;
    final self = await resolveLocalAddress(forHost: key);
    if (self == null) {
      _lastError = 'ما قدرتش أعرف IP الجهاز على الشبكة';
      return false;
    }
    final ctl = await _findControlUrl(key);
    if (ctl == null) {
      _lastError = 'التلفزيون $key مش راد على استعلام DLNA';
      return false;
    }
    // Remember what this wall was showing before the film took it over.
    _videoWasPushing[key] = _pushTimers.containsKey(key);
    _videoFiles[key] = file;
    _videoUrls.remove(key);
    _videoContentTypes[key] = contentType ?? _contentTypeForFile(file.path);
    final info = await probeVideo(file);
    if (info != null) _videoInfo[key] = info;
    _videoScreens.add(key);
    stopPushingScreen(key);
    _overrides.remove(key);
    unblank(tvIp: key);

    final uri = _videoUriFor(self, key);
    final proto = _videoProtocolFor(_videoContentTypes[key]!);
    final ext = file.path.split('.').last.toLowerCase();
    final klass = ext == 'mpg' || ext == 'mpeg'
        ? 'object.item.videoItem.movie'
        : 'object.item.videoItem';
    final didl =
        '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"'
        ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
        ' xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
        '<item id="0" parentID="-1" restricted="1">'
        '<dc:title>PlayZone Video</dc:title>'
        '<upnp:class>$klass</upnp:class>'
        '<res protocolInfo="$proto" size="${await file.length()}">$uri</res>'
        '</item></DIDL-Lite>';

    _log(key).lastPushedUri = uri;

    final (okPlay, okSet) = await _startPlayback(ctl, key, uri, didl);

    _lastPushAt = DateTime.now();
    markReached(key, state: okPlay ? 'PLAYING' : 'UNKNOWN');
    noteCommand(key, 'تشغيل فيلم', okPlay ? 'بيلعب الآن' : 'تم الإرسال', ok: okPlay);
    return okPlay || okSet;
  }
  /// Play a direct video URL on a single screen.
  Future<bool> playVideoUrl(String tvIp, String url, {String? contentType}) async {
    if (!tvAllowed) return false;
    final key = tvIp.trim();
    if (key.isEmpty || url.trim().isEmpty) return false;
    final self = await resolveLocalAddress(forHost: key);
    if (self == null) {
      _lastError = 'ما قدرتش أعرف IP الجهاز على الشبكة';
      return false;
    }
    final ctl = await _findControlUrl(key);
    if (ctl == null) {
      _lastError = 'التلفزيون $key مش راد على استعلام DLNA';
      return false;
    }
    _videoFiles.remove(key);
    _videoUrls[key] = url.trim();
    _videoContentTypes[key] = contentType ?? 'video/mp4';
    _videoScreens.add(key);
    stopPushingScreen(key);
    _overrides.remove(key);
    unblank(tvIp: key);

    final uri = _videoUriFor(self, key);
    final proto = _videoProtocolFor(_videoContentTypes[key]!);
    final didl =
        '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"'
        ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
        ' xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
        '<item id="0" parentID="-1" restricted="1">'
        '<dc:title>PlayZone Video</dc:title>'
        '<upnp:class>object.item.videoItem</upnp:class>'
        '<res protocolInfo="$proto">$uri</res>'
        '</item></DIDL-Lite>';

    _log(key).lastPushedUri = uri;

    final (okPlay, okSet) = await _startPlayback(ctl, key, uri, didl);

    _lastPushAt = DateTime.now();
    markReached(key, state: okPlay ? 'PLAYING' : 'UNKNOWN');
    noteCommand(key, 'تشغيل فيلم (لينك)', okPlay ? 'بيلعب الآن' : 'تم الإرسال', ok: okPlay);
    return okPlay || okSet;
  }

  /// Hands a URI to the renderer and gets it moving.
  ///
  /// The panel answers `Play` with "transition not available" while it is
  /// still busy with the URI it was given a moment earlier. Asking again a
  /// second later is enough to get it going, and the URI stays where it is,
  /// so there is no need to set it twice. Only when that fails as well do we
  /// start the whole thing over from a stopped panel.
  Future<(bool okPlay, bool okSet)> _startPlayback(
    String ctl,
    String key,
    String uri,
    String didl,
  ) async {
    // Put the renderer in a state it will accept a new URI from.
    await _soap(ctl, 'Stop', '<InstanceID>0</InstanceID>');
    await _settle(ctl, key, 1500);
    await Future<void>.delayed(const Duration(milliseconds: 250));

    var okSet = await _soap(
        ctl,
        'SetAVTransportURI',
        '<InstanceID>0</InstanceID><CurrentURI>${_escapeXml(uri)}</CurrentURI>'
            '<CurrentURIMetaData>${_escapeXml(didl)}</CurrentURIMetaData>');
    await Future<void>.delayed(const Duration(milliseconds: 200));

    var okPlay = await _soap(
        ctl, 'Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
    if (!okPlay) {
      // The panel is still moving to the URI it was just handed. Wait it out
      // and ask again — same URI, same metadata, just a fresh ask.
      for (var attempt = 0; attempt < 4 && !okPlay; attempt++) {
        await Future<void>.delayed(const Duration(milliseconds: 1200));
        okPlay = await _soap(
            ctl, 'Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
      }
    }
    if (!okPlay) {
      // Still refused: start over from a panel that is fully stopped.
      await _soap(ctl, 'Stop', '<InstanceID>0</InstanceID>');
      await _settle(ctl, key, 1800);
      await Future<void>.delayed(const Duration(milliseconds: 400));
      okSet = await _soap(
          ctl,
          'SetAVTransportURI',
          '<InstanceID>0</InstanceID><CurrentURI>${_escapeXml(uri)}</CurrentURI>'
              '<CurrentURIMetaData>${_escapeXml(didl)}</CurrentURIMetaData>');
      await Future<void>.delayed(const Duration(milliseconds: 300));
      okPlay = await _soap(
          ctl, 'Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
    }
    return (okPlay, okSet);
  }

  /// Stops the film and hands this wall back to whatever it was showing.
  ///
  /// Two ways back, and the wall decides which one it gets. A wall that was
  /// showing the session cards goes back to the cards; a wall that had been
  /// handed to a console goes back to the console, which is the game. Which
  /// of the two it was is remembered when the film starts, because starting
  /// the film is what tore the card loop down.
  ///
  /// The stop is sent, then the panel is asked where it is, and it is asked
  /// again after a pause — a renderer that is still moving refuses the stop
  /// with UPnP 701 and keeps the film running, and a wall that keeps running
  /// a film is the exact thing this button exists to undo. The answer comes
  /// from the television, not from the fact that we sent a command: a command
  /// that was refused has to be reported as a refusal.
  Future<bool> stopVideo(String tvIp) async {
    final key = tvIp.trim();
    if (key.isEmpty) return false;
    final wasShowingCards = _videoWasPushing.remove(key) ?? false;
    _videoFiles.remove(key);
    _videoUrls.remove(key);
    _videoContentTypes.remove(key);
    _videoInfo.remove(key);
    _videoScreens.remove(key);

    var ctl = await _findControlUrl(key);
    if (ctl == null) {
      noteCommand(
        key,
        'ارجع للعبة',
        'ما عرفناش الشاشة — دووس «ابحث عن الشاشة»',
        ok: false,
      );
      return false;
    }

    var stopped = await _soap(ctl, 'Stop', '<InstanceID>0</InstanceID>');
    if (!stopped) {
      // The panel may have moved its renderer to another port. Look for the
      // new address and stop it there, otherwise the film keeps running.
      final fresh = await _refreshControlUrl(key);
      if (fresh != null) {
        ctl = fresh;
        stopped = await _soap(ctl, 'Stop', '<InstanceID>0</InstanceID>');
      }
    }
    // Give the panel room to come to rest, then ask it where it is. The
    // answer is what decides whether the film is really over.
    await _settle(ctl, key, 1500);
    var state = await _transportState(ctl);
    if (state != null && !state.contains('STOPPED')) {
      // Still moving, or still playing: stop it again and wait it out.
      await _soap(ctl, 'Stop', '<InstanceID>0</InstanceID>');
      await _settle(ctl, key, 1800);
      state = await _transportState(ctl);
    }
    final reallyStopped = state == null ? stopped : state.contains('STOPPED');
    if (!reallyStopped) {
      noteCommand(
        key,
        'ارجع للعبة',
        'الشاشة رفضت وقف الفيلم',
        ok: false,
      );
      return false;
    }
    markReached(key, state: 'STOPPED');

    if (wasShowingCards) {
      // The cards were what this wall was showing before the film; put them
      // back rather than handing the wall to a console that is not playing.
      startPushing(tvIp: key);
      noteCommand(key, 'ارجع للعبة', 'رجعنا لبطاقات اللعب', ok: true);
      return true;
    }
    // The console. A stop is what hands the panel back to its input, which is
    // the game on the HDMI cable.
    await releaseToInput(key, force: true);
    noteCommand(key, 'ارجع للعبة', 'رجعت للبلايستيشن', ok: true);
    return true;
  }

  /// Waits for a screen's renderer address to be looked up again, after a
  /// command to it failed.
  ///
  /// The port a television serves its renderer on is picked fresh on every
  /// boot, so a screen that rebooted looks exactly like a screen that is off:
  /// every command to the old address is lost. A failed command has to be
  /// followed by a fresh look, not by a retry on the same dead door.
  ///
  /// [startLookup] decides whether this asks for the look itself. It is on
  /// for an explicit action on the screen, and off where a slow 7,000-port
  /// sweep would land on the till: there the background look is already
  /// running, and this only waits for it.
  Future<String?> _refreshControlUrl(
    String tvIp, {
    bool startLookup = true,
    int timeoutMs = 4000,
  }) async {
    if (startLookup && !_warming.contains(tvIp)) {
      // A re-look must not be held back by the discovery cooldown: the whole
      // point is that the address we have is wrong.
      unawaited(warmUp(tvIp: tvIp, force: true));
    }
    final deadline = DateTime.now().add(Duration(milliseconds: timeoutMs));
    while (DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 150));
      // A screen that is still flagged is still holding the address that just
      // failed, so it is not an answer yet.
      if (_suspect.contains(tvIp)) continue;
      final now = _controlCache[tvIp]?.$1;
      if (now != null) return now;
    }
    return null;
  }

  /// Asks a renderer where it is right now. Null when it will not say.
  Future<String?> _transportState(String controlUrl) async {    final (status, payload, _) =
        await _soapRaw(controlUrl, 'GetTransportInfo', '');
    if (status == null || status >= 400) return null;
    return RegExp(r'<CurrentTransportState>([^<]*)</CurrentTransportState>')
            .firstMatch(payload)
            ?.group(1)
            ?.trim()
            .toUpperCase();
  }

  String _contentTypeForFile(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'mp4':
      case 'm4v':
        return 'video/mp4';
      case 'mpg':
      case 'mpeg':
        return 'video/mpeg';
      case 'mkv':
        return 'video/x-matroska';
      case 'avi':
        return 'video/x-msvideo';
      case 'webm':
        return 'video/webm';
      default:
        return 'video/mp4';
    }
  }

  String _videoProtocolFor(String ct) {
    if (ct.contains('mpeg')) return 'http-get:*:video/mpeg:DLNA.ORG_OP=01;DLNA.ORG_CI=0';
    if (ct.contains('x-msvideo')) return 'http-get:*:video/x-msvideo:DLNA.ORG_OP=01;DLNA.ORG_CI=0';
    if (ct.contains('x-matroska')) return 'http-get:*:video/x-matroska:DLNA.ORG_OP=01;DLNA.ORG_CI=0';
    if (ct.contains('webm')) return 'http-get:*:video/webm:DLNA.ORG_OP=01;DLNA.ORG_CI=0';
    return 'http-get:*:video/mp4:DLNA.ORG_OP=01;DLNA.ORG_CI=0';
  }

  Future<bool> _pushOnce(String tvIp) async {
    // A wall that is playing a film is not a wall that wants a still picture.
    // Pushing one would cut the film off mid-scene, and the film is the thing
    // the customer asked for. The wall gets its picture back when the film is
    // stopped.
    if (_videoScreens.contains(tvIp.trim())) return false;
    // The guard is per screen and covers the WHOLE cycle (discovery
    // included), otherwise every tick would kick off a full port scan and
    // one screen's push would cancel the other's.
    if (_pushing.contains(tvIp)) return false;
    _pushing.add(tvIp);
    try {
      final self = await resolveLocalAddress(forHost: tvIp);
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
      // cached copy of the same URL. Bumped for **this screen only**, so the
      // other panels' addresses stay exactly as they were and they have no
      // reason to fetch again.
      _revisions[tvIp.trim()] = _revisionFor(tvIp) + 1;
      final uri = _imageUriFor(self, tvIp);
      // Written down the moment we decide to show it, before anything is
      // sent. If this screen then refuses, the one fact worth having is the
      // address it was handed, and there is no way to recover it afterwards
      // from a television that will only say "no".
      _log(tvIp).lastPushedUri = uri;
      // LG renderers REJECT the play request with HTTP 500 when
      // CurrentURIMetaData is empty — the DIDL-Lite descriptor is what
      // tells the TV this is a still image it can display. (Verified
      // against a 55UP7760PVB: empty metadata → 500, DIDL → works.)
      final didl =
          '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"'
          ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
          ' xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
          '<item id="0" parentID="-1" restricted="1">'
          '<dc:title>PlayZone</dc:title>'
          '<upnp:class>object.item.imageItem.photo</upnp:class>'
          '<res protocolInfo="http-get:*:image/png:DLNA.ORG_OP=01;'
          'DLNA.ORG_CI=0">$uri</res>'
          '</item></DIDL-Lite>';
      final meta = _escapeXml(didl);

      // What this screen had pulled before we asked, so we can tell whether
      // the picture actually landed.
      final before = _log(tvIp).imagesServed;

      // Set, play — and `Play` goes out whether or not `Set` said yes.
      //
      // These panels answer `SetAVTransportURI` with HTTP 500 and an empty
      // body while going on to fetch and play the image perfectly well.
      // Gating `Play` on that status is what kept the wall from ever going
      // black: the set "failed", so the play was never sent, so the
      // television sat on whatever it already had. `Set` only points at the
      // picture; `Play` is what puts it on the wall, and a picture nothing
      // asked to be shown is not shown however contented the reply was.
      //
      // NO `Stop` FIRST. That was the cause of a wall going dark on payment
      // and springing back to the game a second later: `Stop` is the command
      // that hands the screen to the console, so opening with it and then
      // failing left the wall showing the game at exactly the moment it was
      // supposed to be black. Measured on a 65UP7500PVG: `Set`+`Play` alone
      // was taken and the picture fetched, while `Stop` then `Set`+`Play` was
      // not. A screen part-way through a change is the only case that still
      // needs the stop, and that is what the retry is for.
      //
      // `Play` is sent on the same flight as `Set` rather than after a fixed
      // 200 ms pause: the panel queues both, and the pause was only ever
      // there to let the set settle. `_awaitFetch` below is what actually
      // decides whether the picture landed, so the pause bought nothing an
      // already-guaranteed ordering did not.
      final setFuture = _soap(
          ctl,
          'SetAVTransportURI',
          '<InstanceID>0</InstanceID><CurrentURI>$uri</CurrentURI>'
              '<CurrentURIMetaData>$meta</CurrentURIMetaData>');
      final playFuture = _soap(ctl, 'Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
      await Future.wait([setFuture, playFuture]);
      if (await _awaitFetch(tvIp, before, 900)) {
        _lastPushAt = DateTime.now();
        markReached(tvIp);
        final log = _log(tvIp);
        log.refusedAt = null;
        _dlnaRefused.remove(tvIp);
        log.lastOk = true;
        log.lastCommandAt = DateTime.now();
        log.lastCommand = 'عرض الصورة';
        log.lastResult = 'الصورة اتبعتت';
        return true;
      }

      // Nothing arrived, so this is a real failure and a second try is owed.
      // The retry is the only place a `Stop` is sent, because that is the one
      // situation where the screen is genuinely holding on to something else
      // and needs to be let go of before it can be given something else. It is
      // also the only situation where the stop is worth its risk, because by
      // now the first attempt has already failed — so the worst the stop can do
      // is leave the screen as it already found it.
      await _soap(ctl, 'Stop', '<InstanceID>0</InstanceID>');
      await _settle(ctl, tvIp, 1200);
      await _soap(
          ctl,
          'SetAVTransportURI',
          '<InstanceID>0</InstanceID><CurrentURI>$uri</CurrentURI>'
              '<CurrentURIMetaData>$meta</CurrentURIMetaData>');
      await _soap(ctl, 'Play', '<InstanceID>0</InstanceID><Speed>1</Speed>');
      if (await _awaitFetch(tvIp, before, 900)) {
        _lastPushAt = DateTime.now();
        markReached(tvIp);
        final log = _log(tvIp);
        log.refusedAt = null;
        _dlnaRefused.remove(tvIp);
        log.lastOk = true;
        log.lastCommandAt = DateTime.now();
        log.lastCommand = 'عرض الصورة';
        log.lastResult = 'الصورة اتبعتت (محاولة تانية)';
        return true;
      }

      final log = _log(tvIp);
      log.lastOk = false;
      log.lastCommandAt = DateTime.now();
      log.lastCommand = 'عرض الصورة';
      log.lastResult = 'الشاشة ما جابتش الصورة';
      log.note('الشاشة ما جابتش الصورة', ok: false);
      return false;
    } finally {
      _pushing.remove(tvIp);
    }
  }

  /// Waits for a part-way renderer to come to rest before we hand it a new
  /// picture.
  ///
  /// A panel that is mid-change will not take one. It ignores both the set
  /// and the play, and the only symptom is a refusal that looks exactly like
  /// a television refusing to cooperate. Stopping first is not enough on its
  /// own, because the stop is accepted while the panel is still moving and
  /// the picture is then offered to something that is not listening yet. So
  /// this asks the panel where it actually is, rather than assuming a fixed
  /// pause is long enough.
  ///
  /// Bounded, and a timeout is not a verdict: the caller carries on and the
  /// fetch check still decides whether the picture landed.
  Future<bool> _settle(String ctl, String tvIp, int budgetMs) async {
    const rest = [
      'STOPPED',
      'NO_MEDIA_PRESENT',
    ];
    // A silent renderer is not a busy one. These panels answer
    // `GetTransportInfo` with an empty 500 while playing perfectly happily,
    // so an unanswered question is not evidence that anything is still
    // moving — and sitting out the whole budget waiting for an answer that is
    // never coming would add a dead pause to every single push.
    var askedOnce = false;
    for (var waited = 0; waited < budgetMs; waited += 300) {
      final (status, payload, _) = await _soapRaw(ctl, 'GetTransportInfo', '');
      if (status != null && status < 400) {
        askedOnce = true;
        final state =
            RegExp(r'<CurrentTransportState>([^<]*)</CurrentTransportState>')
                    .firstMatch(payload)
                    ?.group(1)
                    ?.trim()
                    .toUpperCase() ??
                '';
        markReached(tvIp, state: state);
        if (state.isEmpty || rest.any(state.contains)) return true;
      } else if (!askedOnce && waited >= 600) {
        // It will not tell us where it is, so stop asking and let the stop
        // settle on its own. The fetch check still decides the outcome.
        return false;
      }
      await Future<void>.delayed(const Duration(milliseconds: 300));
    }
    return false;
  }

  /// Waits briefly to see whether [tvIp] pulls the frame, and says so.
  ///
  /// Bounded and short on purpose: the fetch usually lands in well under a
  /// second, and this runs off the command path in the background, so the
  /// person at the till is not waiting on it. Returning on the first sighting
  /// keeps the common case instant instead of always paying the full wait.
  Future<bool> _awaitFetch(String tvIp, int before,
      [int budgetMs = 1400]) async {
    final log = _log(tvIp);
    if (log.imagesServed > before) return true;
    for (var waited = 0; waited < budgetMs; waited += 200) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      if (log.imagesServed > before) return true;
    }
    return false;
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
      // Expire the mirror on the per-screen log too, or the settings page
      // would keep showing a refusal that we have already forgiven.
      _log(tvIp).refusedAt = null;
      return false;
    }
    return true;
  }

  void noteDlnaRefused(String tvIp) {
    _dlnaRefused[tvIp] = DateTime.now();
    final log = _log(tvIp);
    // Only stamp the first time: a retry storm must not keep pushing the
    // "refused since" clock forward and make a ten-minute-old fault look new.
    log.refusedAt ??= DateTime.now();
  }

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
    // Re-use the endpoint we already found — unless a command against it has
    // already failed. A suspect address must be re-checked, never handed back:
    // returning it here is what kept a screen whose port had moved failing for
    // the full thirty minutes of the cache, one slow timeout at a time, while
    // the re-discovery meant to fix it kept "succeeding" by finding the very
    // entry that was dead.
    final cached = _controlCache[tvIp];
    final usable = cached != null && !_suspect.contains(tvIp);
    final fresh = usable &&
        DateTime.now().difference(cached.$2) < const Duration(minutes: 30);
    if (fresh) return cached.$1;
    // The cooldown is PER TV. A single shared timestamp would let the first
    // screen's discovery throttle the second one's, leaving it unreachable
    // for as long as the app ran.
    final last = _lastDiscoveryAt[tvIp];
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 30)) {
      // Still cooling down: hand back the last known address only when it is
      // not the one that just failed.
      return usable ? cached.$1 : null;
    }
    _lastDiscoveryAt[tvIp] = DateTime.now();

    // Answer the question from the television itself, before guessing.
    //
    // SSDP is asked FIRST now, not last. A panel announces its own renderer
    // address in its reply, so this returns the port the screen is listening on
    // right now — the one thing the guessed list and the sweep can only hope to
    // stumble onto. Measured on this network, a reply arrives in well under a
    // second and named ports (1602, 1684, 1685, 1593, 1502, 1470) that were in
    // neither the cached list nor the sweep's range, which is exactly why the
    // walls sat unreachable while they were open and answering.
    _targetHost = tvIp;
    final announced = await _ssdpSearch(tvIp);
    if (announced.isNotEmpty) {
      final control = await _firstControlUrl(tvIp, announced);
      if (control != null) return control;
    }

    // Every port either wall screen has served its renderer on, across
    // restarts. Checked second because it costs nothing, and it is the
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
        // Ports these panels were actually announcing when the walls went
        // unreachable — recorded so the next boot that happens to reuse one
        // lights up without waiting for a reply at all.
        1470, 1502, 1593, 1602, 1684, 1685,
      ])
        'http://$tvIp:$port/',
    ];
    if (await _hasControlUrl(tvIp, candidates)) return _controlCache[tvIp]!.$1;

    // The sweep is the last resort: it is the heaviest thing this program does
    // to the café network and it can only find a port inside its range, so it
    // runs only after the screen has failed to name its own address.
    final scanned = await _scanLocations(tvIp);
    if (scanned != null) return scanned;
    return null;
  }

  /// Returns the first AVTransport endpoint among [locations], caching it.
  Future<String?> _firstControlUrl(String tvIp, List<String> locations) async {
    for (final location in locations) {
      final found = await _servicesFrom(location);
      if (found != null) {
        _rememberEndpoint(tvIp, found.av, render: found.render);
        return found.av;
      }
    }
    return null;
  }

  /// Records where a screen answers, and when we found it out.
  ///
  /// The timestamp is what lets the settings page say "we've known this
  /// address for twenty minutes" — the difference between a screen that has
  /// been reachable all along and one that needs looking at.
  void _rememberEndpoint(String tvIp, String control, {String? render}) {
    _controlCache[tvIp] = (control, DateTime.now());
    if (render != null && render.isNotEmpty) {
      _renderingCache[tvIp] = (render, DateTime.now());
    }
    // A freshly found endpoint is proof the screen is answering again, so drop
    // any "needs another look" verdict from the attempt that failed before it.
    _suspect.remove(tvIp);
    final log = _log(tvIp);
    if (log.controlUrl != control) {
      log.controlUrl = control;
      log.note(
          'اتعرفنا على الشاشة: ${Uri.tryParse(control)?.origin ?? control}');
    }
    log.discoveredAt ??= DateTime.now();
  }

  /// Tries a list of known device-description URLs in parallel and caches
  /// the first AVTransport endpoint among them.
  Future<bool> _hasControlUrl(String tvIp, List<String> candidates) async {
    final found =
        await Future.wait(candidates.map(_servicesFrom), eagerError: false);
    for (final services in found) {
      if (services != null) {
        _rememberEndpoint(tvIp, services.av, render: services.render);
        _lastLocations = 'known ports';
        return true;
      }
    }
    return false;
  }

  final Map<String, (String, DateTime)> _controlCache = {};

  /// The sound endpoint of each screen, read from the same device description
  /// as the picture one — so the volume of a wall costs no extra searching.
  final Map<String, (String, DateTime)> _renderingCache = {};
  final Map<String, DateTime> _lastDiscoveryAt = {};

  int _ssdpDatagrams = 0;
  String _lastSsdpSample = '';
  String _lastLocations = '';
  bool _sweeping = false;

  /// Sweeps the port range LG uses for its DLNA services and returns the first
  /// AVTransport endpoint it finds, or null when the screen answers nothing.
  ///
  /// This is the method that actually works: the TV picks a fresh renderer
  /// port on every boot, so a cached list is always behind. Two things keep it
  /// fast now —
  ///  * a wide batch (512 sockets in flight instead of 96), because the OS
  ///    multiplexes them and a closed port on a reachable host rejects at
  ///    once; and
  ///  * it stops the moment one of the open ports answers with an AVTransport
  ///    endpoint, instead of testing all 2,100 ports first and only then
  ///    reading them.
  /// What used to be "about ten seconds" is now usually under two, and often
  /// well under one when the screen is live.
  ///
  /// Only one sweep may run at a time across the whole process. Two or three
  /// screens each firing 512 sockets at once is the single heaviest thing this
  /// program does to the café network, and it lands exactly when several
  /// panels are asleep — which is also when every other command is waiting on
  /// that same network. A screen that finds the sweep busy waits for the one
  /// in flight (and is then served its answer, if any) rather than piling on.
  Future<String?> _scanLocations(String tvIp) async {
    if (_sweeping) {
      // Another screen is already sweeping. Wait for it to finish, then do a
      // cheap cached lookup instead of starting a second full scan — by then
      // a fresh endpoint very likely exists for this screen too.
      for (var i = 0; i < 40 && _sweeping; i++) {
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
      final cached = _controlCache[tvIp];
      if (cached != null && !_suspect.contains(tvIp)) return cached.$1;
      return null;
    }
    _sweeping = true;
    try {
      return await _sweepPorts(tvIp);
    } finally {
      _sweeping = false;
    }
  }

  Future<String?> _sweepPorts(String tvIp) async {
    const batch = 512;
    // The floor to the ceiling of the range LG hands its renderer. Widened past
    // the old 1000..3100 after ports in the 4000s and 5000s were seen on these
    // panels: a range that stops at 3100 can miss the one port that matters and
    // then report "no screen" for a wall that is wide awake.
    const from = 1000;
    const to = 8000;
    const total = to - from + 1; // ports 1000..8000 inclusive
    var scanned = 0;
    final found = <String>[];
    try {
      for (var start = from; start <= to; start += batch) {
        final ports = [
          for (var p = start; p <= to && p < start + batch; p++) p,
        ];
        final results = await Future.wait(ports.map(_isPortOpen));
        scanned += ports.length;
        final open = <String>[
          for (var j = 0; j < ports.length; j++)
            if (results[j] == true) 'http://$tvIp:${ports[j]}/',
        ];
        found.addAll(open);
        _lastLocations = 'scanned $scanned/$total, open: ${found.length}';
        if (open.isNotEmpty) {
          final control = await _firstControlUrl(tvIp, open);
          if (control != null) return control;
        }
      }
    } catch (e) {
      // Keep whatever we found before the trouble — a partial answer still
      // beats none, and the renderer's port could well be in it.
      _lastError = 'فحص المنافذ: $e';
    }
    _lastLocations = 'scanned $scanned/$total, open: ${found.length}'
        '${found.isEmpty ? '' : ' -> ${found.map((u) => Uri.parse(u).port).join(',')}'}';
    return null;
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
        // Long enough for the café's Wi-Fi, which is the actual problem here.
        // Measured against a live panel: the first connect to a real renderer
        // port took 532 ms, so the old 300 ms budget hung up on the correct
        // port before it ever answered — discovery then reported "no screen"
        // for a panel that was open and waiting. A closed port still rejects
        // immediately, so this costs nothing on the ports that are shut.
        timeout: const Duration(milliseconds: 1800),
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
        final match = RegExp(r'^LOCATION:\s*(\S+)',
                multiLine: true, caseSensitive: false)
            .firstMatch(text);
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
        await Future<void>.delayed(const Duration(milliseconds: 50));
      }
      await Future<void>.delayed(const Duration(milliseconds: 2500));
    } catch (e) {
      _lastError = 'SSDP search: $e';
    } finally {
      socket?.close();
    }
    _lastLocations = locations.join(' , ');
    return locations.toList();
  }

  /// Fetches one device description and extracts the two endpoints this
  /// program needs: the one that moves the picture (AVTransport) and the one
  /// that moves the sound (RenderingControl).
  ///
  /// Both come out of the same document, so the description is read once and
  /// both are taken from it.
  ///
  /// Uses the shared [HttpClient] for the same reason the SOAP path does, and
  /// bounds the body read as well as the connect: a panel that starts
  /// answering and then stalls mid-body used to hang this call with no
  /// timeout on the read at all, which is a screen that looks unreachable
  /// while it is merely slow.
  Future<({String av, String? render})?> _servicesFrom(String location) async {
    try {
      final req = await _http.getUrl(Uri.parse(location));
      final res = await req.close();
      if (res.statusCode != 200) return null;
      final body =
          await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 2));
      final av = _serviceControlUrl(body, 'AVTransport');
      if (av == null) return null;
      final render = _serviceControlUrl(body, 'RenderingControl');
      final base = Uri.parse(location);
      return (av: base.resolve(av).toString(), render: render == null ? null : base.resolve(render).toString());
    } catch (_) {
      return null;
    }
  }

  /// The controlURL of one service inside a device description.
  ///
  /// A service block names its type and then its own address, so the type is
  /// looked for first and the address is taken from the same block after it.
  static String? _serviceControlUrl(String body, String service) {
    final match = RegExp(
            r'<serviceType>\s*urn:schemas-upnp-org:service:$service:1\s*</serviceType>(?:(?!</service>).)*?<controlURL>\s*([^<]+?)\s*</controlURL>',
            dotAll: true,
            caseSensitive: false)
        .firstMatch(body);
    if (match == null) return null;
    final url = match.group(1)!.trim();
    if (url.isEmpty) return null;
    final resolved = Uri.tryParse(url);
    if (resolved == null || resolved.path.isEmpty || resolved.path == '/') {
      return null;
    }
    return url;
  }

  /// The UPnP fault number inside a SOAP error, if the panel sent one.
  ///
  /// 701 "transition not available" and 716 "resource not found" look
  /// identical from the outside — both are HTTP 500 — and they mean opposite
  /// things, so the number is what the log needs to carry.
  static String? _upnpErrorCode(String soapBody) {
    final m = RegExp(r'<errorCode>(\d+)</errorCode>').firstMatch(soapBody);
    if (m == null) return null;
    final d = RegExp(r'<errorDescription>([^<]*)</errorDescription>')
        .firstMatch(soapBody);
    final desc = d?.group(1)?.trim();
    return desc == null || desc.isEmpty ? m.group(1) : '${m.group(1)} $desc';
  }

  /// One HTTP client for the whole program, kept alive across commands.
  ///
  /// Every push, release and status read used to build its own [HttpClient]
  /// and tear it down (`close(force: true)`) when it was done. That throws
  /// away the TCP connection to the panel with it, so the next command paid
  /// for a fresh handshake — and a fresh handshake is exactly the kind of
  /// fixed cost that turns "instant" into "a noticeable beat" when a cashier
  /// is pressing a button. One long-lived client reuses the connection, so
  /// the second command onward lands on an already-open socket.
  ///
  /// The connection timeout is deliberately short: a screen that has gone
  /// away must fail fast rather than hold the button.
  static final HttpClient _http = HttpClient()
    ..connectionTimeout = const Duration(seconds: 2)
    ..idleTimeout = const Duration(seconds: 30)
    ..maxConnectionsPerHost = 6;

  /// Fires one SOAP action and hands back the panel's HTTP status and body.
  ///
  /// A null status means the call never completed — the TV holds a SOAP call
  /// open while it loads, so that is not by itself a failure, which is why
  /// [reached] separates "we got no answer" from "we could not even connect".
  /// The two need opposite handling: a silent panel is usually asleep, while
  /// a refused connection means the address itself is suspect.
  Future<(int?, String, bool)> _soapRaw(
      String controlUrl, String action, String body,
      {String service = 'urn:schemas-upnp-org:service:AVTransport:1'}) async {
    final xml = _soapEnvelope.replaceAll('%BODY%',
        '<u:$action xmlns:u="$service"><InstanceID>0</InstanceID>$body</u:$action>');
    try {
      final req = await _http.postUrl(Uri.parse(controlUrl));
      req.headers
          .set(HttpHeaders.contentTypeHeader, 'text/xml; charset="utf-8"');
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
      return (res.statusCode, payload, true);
    } on TimeoutException {
      return (null, '', true);
    } catch (_) {
      return (null, '', false);
    }
  }

  Future<bool> _soap(String controlUrl, String action, String body,
      {String service = 'urn:schemas-upnp-org:service:AVTransport:1'}) async {
    final (status, payload, reached) =
        await _soapRaw(controlUrl, action, body, service: service);
    final host = Uri.tryParse(controlUrl)?.host ?? '';
    if (reached && host.isNotEmpty) markReached(host);
    if (status == null) {
      // The TV holds the call while it loads the image — treat as fine. But an
      // endpoint we could not even reach is almost always a panel that moved
      // or went away, so that is a failure and is flagged for a re-check rather
      // than silently reported as a success that never happened. `reached`
      // separates "the panel said nothing" (fine) from "we never got a socket
      // to it" (not fine).
      if (!reached) {
        _noteSuspect(controlUrl);
        return false;
      }
      return true;
    }
    if (status >= 400) {
      final code = _upnpErrorCode(payload);
      _lastError = code == null
          ? '$action -> HTTP $status'
          : '$action -> HTTP $status (UPnP $code)';
      if (host.isNotEmpty) {
        final log = _log(host);
        log.fault = _lastError;
        log.faultAt = DateTime.now();
        log.note(_lastError!, ok: false);
      }
      // A 404 almost always means the TV rebooted into a different renderer
      // port. Mark the endpoint as needing a re-check rather than deleting
      // it: a sweep costs 2,100 ports, while re-trying the address we have
      // costs one request and is right again the moment the panel is up.
      if (status == 404) {
        _noteSuspect(controlUrl);
      }
      // LG answers 500 when it will not take media from us — most often
      // because it could not fetch the image (UPnP error 716), which is a
      // network problem on our side as often as it is the TV saying no.
      // Remember it so we stop hammering the screen, but only for as long
      // as the verdict is worth anything.
      if (status >= 500 && host.isNotEmpty) {
        noteDlnaRefused(host);
      }
      return false;
    }
    _lastError = null;
    return true;
  }

  /// Asks one screen, right now, what it is actually doing — and how long the
  /// answer took.
  ///
  /// This is the only trustworthy answer to "is the screen working?", because
  /// it is the panel talking, not our cache. Never discovers unless asked to:
  /// a status check must not put a 2,100-port sweep on the network, which is
  /// the very thing that made the whole app feel slow.
  Future<bool> probeTransport(String tvIp, {bool discover = false}) async {
    if (!tvAllowed) return false;
    final log = _log(tvIp);
    if (log.probing) return log.reachable;
    log.probing = true;
    final watch = Stopwatch()..start();
    try {
      var ctl = _controlCache[tvIp]?.$1;
      if (ctl == null) {
        if (!discover) {
          watch.stop();
          log.pingMs = watch.elapsedMilliseconds;
          log.reachable = false;
          return false;
        }
        await warmUp(tvIp: tvIp, force: true);
        ctl = _controlCache[tvIp]?.$1;
      }
      if (ctl == null) {
        watch.stop();
        log.pingMs = watch.elapsedMilliseconds;
        log.reachable = false;
        log.fault = 'مفيش عنوان للشاشة دي على الشبكة';
        log.faultAt = DateTime.now();
        return false;
      }
      final (status, payload, reached) =
          await _soapRaw(ctl, 'GetTransportInfo', '');
      watch.stop();
      log.pingMs = watch.elapsedMilliseconds;
      if (status == null || status >= 400) {
        log.reachable = false;
        final code = status == null ? null : _upnpErrorCode(payload);
        log.fault = status == null
            ? (reached ? 'الشاشة مش بتجاوب' : 'مش قادرين نوصل للشاشة')
            : 'الحالة: HTTP $status${code == null ? '' : ' (UPnP $code)'}';
        log.faultAt = DateTime.now();
        return false;
      }
      final state =
          RegExp(r'<CurrentTransportState>([^<]*)</CurrentTransportState>')
              .firstMatch(payload)
              ?.group(1)
              ?.trim();
      // Sample the fetch count so the panel's claim can be checked against
      // something that happened rather than something it said. The first probe
      // has nothing to compare against and is recorded as unknown, which is the
      // honest answer and keeps a fresh screen from being reported as not
      // playing our picture when nobody has looked twice yet.
      final served = log.imagesServed;
      final seenBefore = _servedAtProbe[tvIp];
      if (seenBefore != null) {
        log.fetchedSinceLastProbe = served - seenBefore;
        log.showingOurs = log.fetchedSinceLastProbe > 0;
      }
      _servedAtProbe[tvIp] = served;
      if (state != null &&
          state.toUpperCase().contains('PLAYING') &&
          log.showingOurs == false &&
          // A wall playing a film is *supposed* to be pulling something other
          // than our picture. Saying "nobody fetched our picture" about it
          // every fifteen seconds is noise, not a fault.
          !isPlayingVideo(tvIp)) {
        log.note(
          'الشاشة بتقول إنها شغالة بس ماحدش جاب الصورة بتاعتنا',
        );
      }
      // The panel answered, which is worth recording even when the answer is
      // an unhelpful one — an open question about it is now answered.
      markReached(tvIp, state: state);
      log.lastOk = true;
      return true;
    } finally {
      log.probing = false;
    }
  }

  /// Probes every configured screen in parallel. Cheap enough to sit on a
  /// timer while the settings page is open, and the reason nobody ever has to
  /// open a terminal to find out what a screen is doing.
  Future<void> probeAll(List<String> addresses, {bool discover = false}) async {
    if (kHardLockWallNetwork) return;
    await Future.wait(
        addresses
            .where((ip) => ip.trim().isNotEmpty)
            .map((ip) => probeTransport(ip, discover: discover)),
        eagerError: false);
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
    final log = _log(host);
    // "The last thing we tried did not land" is its own fact, kept apart from
    // the transport state: a screen can be perfectly reachable and still have
    // refused the last command, and those need different fixes.
    if (log.lastOk) log.note('محتاجة بحث — العنوان القديم مش ماشي', ok: false);
    log.lastOk = false;
    log.reachable = false;
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
    final action = RegExp(r'"#([A-Za-z]+)"')
            .firstMatch(request.headers.value('SOAPACTION') ?? '')
            ?.group(1) ??
        (RegExp(r'<u:(\w+)\s').firstMatch(body)?.group(1) ?? '');
    _lastSoapAction = action;
    if (action == 'Browse') _browseCalls++;
    final envelope = _soapEnvelope.replaceAll('%BODY%', '');
    String inner;
    switch (action) {
      case 'Browse':
        final caller = request.connectionInfo?.remoteAddress.address;
        final self = await resolveLocalAddress(forHost: caller);
        // A browse response carries the full absolute URL. Left without the
        // scheme it reads as a file name, so a panel that browses and then plays
        // what it found has nothing to dial - and the failure surfaces later as
        // a renderer that accepts the play and never fetches.
        //
        // The revision is the *caller's* own, keyed by the address the browse
        // came from, so answering one panel does not hand every other panel a
        // new address to re-fetch.
        final uri = 'http://$self:$port/tv.jpg?v=${_revisionFor(caller ?? '')}';
        // The size advertised has to be the size of the frame this panel will
        // actually be handed — its own override if it has one, otherwise the
        // shared board. A wrong `size` makes the panel distrust the resource.
        final served =
            _overrides[_screenForTag(_tokenFor(caller ?? ''))] ?? _image;
        final didl =
            '<DIDL-Lite xmlns="urn:schemas-upnp-org:metadata-1-0/DIDL-Lite/"'
            ' xmlns:dc="http://purl.org/dc/elements/1.1/"'
            ' xmlns:upnp="urn:schemas-upnp-org:metadata-1-0/upnp/">'
            '<item id="0" parentID="0" restricted="1">'
            '<dc:title>PlayZone</dc:title>'
            '<dc:creator>PlayZone</dc:creator>'
            '<upnp:class>object.item.imageItem.photo</upnp:class>'
            '<res protocolInfo="http-get:*:image/png:DLNA.ORG_OP=01;'
            'DLNA.ORG_CI=0" size="${served?.length ?? _imageBytes}">$uri</res>'
            '</item></DIDL-Lite>';
        inner =
            '<u:BrowseResponse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1">'
            '<Result>${_escapeXml(didl)}</Result>'
            '<NumberReturned>1</NumberReturned>'
            '<TotalMatches>1</TotalMatches>'
            '<UpdateID>1</UpdateID>'
            '</u:BrowseResponse>';
      case 'GetProtocolInfo':
        inner =
            '<u:GetProtocolInfoResponse xmlns:u="urn:schemas-upnp-org:service:ConnectionManager:1">'
            '<Source></Source>'
            '<Sink>http-get:*:image/png:*,http-get:*:image/jpeg:*</Sink>'
            '</u:GetProtocolInfoResponse>';
      case 'GetSearchCapabilities':
        inner =
            '<u:GetSearchCapabilitiesResponse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1">'
            '<SearchCapabilities></SearchCapabilities></u:GetSearchCapabilitiesResponse>';
      case 'GetSortCapabilities':
        inner =
            '<u:GetSortCapabilitiesResponse xmlns:u="urn:schemas-upnp-org:service:ContentDirectory:1">'
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
    res.headers.set('SOAPACTION',
        '"urn:schemas-upnp-org:service:ContentDirectory:1#Browse"');
    res.write(envelope.replaceAll('</s:Body>', '$inner</s:Body>'));
    await res.close();
  }

  String? _lastSoapAction;
  String? get lastSoapAction => _lastSoapAction;
  int _browseCalls = 0;

  /// Everything `/status` prints, gathered in one place.
  ///
  /// Its own method so the handler can wrap it. A throw while building this
  /// does not fail the request, it abandons it — and the one page written to
  /// explain a fault would be the thing that stops answering.
  String _statusBody() => 'running=$isRunning\n'
      'announced=$_announced\n'
      'pushing=${_pushTimers.isNotEmpty}\n'
      'blanked=$_blanked\n'
      'fullscreen=${WindowState.fullScreen}\n'
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
      'anotherCopy=${_anotherCopy ? "YES <<<" : "no"}\n'
      'known=$controlSummary\n'
      'suspect=${List<String>.of(_suspect).join(",")}\n'
      // Read through a copy. `refusesDlna` expires entries as a side effect of
      // being called, which deletes from the very map being iterated - and a
      // map cannot be iterated and modified at once. Discovery writes to these
      // maps in the background, so this is not a rare race: it fires exactly
      // when a screen is being looked for, which is when the answer is wanted.
      // A throw here does not fail the request, it abandons it, so the whole
      // page went missing with no error shown anywhere.
      'refusesDlna=${(List<String>.of(_dlnaRefused.keys)).where(refusesDlna).join(",")}\n'
      'controlUrl=${_controlCache.values.isEmpty ? "none" : _controlCache.values.first.$1}\n'
      // One block per screen, by name, so a terminal can answer the same
      // questions the settings page answers — and cannot confuse the two
      // panels, which a single shared set of counters never could.
      '${reports().map(_reportBlock).join()}';

  /// Serves the current image; answers HEAD (headers only) and GET.
  /// Also exposes /status so a problem can be diagnosed without the UI,
  /// and /desc.xml so the SSDP announcement points at something real.
  Future<void> _handleRequest(HttpRequest request) async {
    final res = request.response;
    if (request.uri.path == '/status') {
      // Wrapped, because a throw inside this handler does not fail the request
      // — it abandons it. The response is never closed, so the client waits
      // forever and the one page that exists to explain a fault is the thing
      // that stops answering. That is how a report can be the cause of the
      // problem it was written to describe.
      String body;
      try {
        body = _statusBody();
      } catch (e, st) {
        body = 'status failed to build\n$e\n$st';
      }
      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
      res.write(body);
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
    if (request.uri.path == '/tv.jpg') {
      if (_image == null) {
        res.statusCode = HttpStatus.notFound;
        res.headers.set('X-PlayZone-Reason', 'no-image-yet');
        await res.close();
        return;
      }
      // A screen that has been singled out (the "عرّفني" label) is served its
      // own frame instead of the shared board. This is what keeps one screen's
      // label from painting itself onto every other wall for the twelve seconds
      // it is up: the override belongs to that address, and nobody else asks for
      // it.
      final who = _screenForTag(request.uri.queryParameters['s']?.trim() ?? '');
      final frame = _overrides[who] ?? _image!;
      res.statusCode = HttpStatus.ok;
      res.headers.contentType = ContentType('image', 'png');
      res.headers.set('Cache-Control', 'no-store, no-cache, must-revalidate');
      res.headers.set('Accept-Ranges', 'none');
      res.headers.contentLength = frame.length;
      // The screen fetches back the exact URL we handed it, and that URL carries
      // the screen's token — so the fetch is attributed to a real panel instead of
      // to a shared counter. A `HEAD` first is normal (the TV sizes the image
      // before pulling it), and counting it separately is what proves the TV got
      // as far as asking. An unrecognised token is credited to nobody: a request
      // this process did not ask for is not proof about any wall in particular.
      if (request.method == 'HEAD') {
        if (who.isNotEmpty) _log(who).headRequests++;
        await res.close();
        return;
      }
      res.add(frame);
      await res.close();
      _imagesServed++;
      _lastFetchAt = DateTime.now();
      if (who.isNotEmpty) {
        // Which screens have pulled a frame, by address. The blanket `_tvFetched`
        // flag could only ever say "some screen somewhere is being served", which
        // is the wrong answer when one wall is fetching and another is not.
        _tvFetchedScreens.add(who);
        _tvFetched = true;
        final log = _log(who);
        log.imagesServed++;
        log.lastFetchAt = _lastFetchAt;
        // Pulling the frame is the strongest possible proof that this panel is
        // alive and showing us, so record it as the state it demonstrates
        // instead of leaving it to be inferred later.
        markReached(who, state: 'PLAYING');
        log.lastOk = true;
        log.note('جابت الصورة (${log.imagesServed} مرة)');
      }
      return;
    }

    // Video streaming — local file or proxied URL. Served with Range support.
    if (request.uri.path == '/video' || request.uri.path.startsWith('/video/')) {
      await _handleVideoRequest(request, res);
      return;
    }

    res.statusCode = HttpStatus.notFound;
    res.headers.set('X-PlayZone-Reason', 'wrong-path');
    await res.close();
  }

  Future<void> _handleVideoRequest(HttpRequest request, HttpResponse res) async {
    final tag = request.uri.queryParameters['s']?.trim() ?? '';
    final who = _screenForTag(tag);
    File? file = who.isNotEmpty ? _videoFiles[who] : null;
    String? url = who.isNotEmpty ? _videoUrls[who] : null;
    if (file == null && url == null && _videoFiles.isNotEmpty) {
      // fallback to first video if tag unknown
      final k = _videoFiles.keys.first;
      file = _videoFiles[k];
      url = _videoUrls[k];
      who.isEmpty ? null : null;
    }
    if (file == null && url == null) {
      res.statusCode = HttpStatus.notFound;
      res.headers.set('X-PlayZone-Reason', 'no-video');
      await res.close();
      return;
    }

    String contentType = 'video/mp4';
    if (who.isNotEmpty) {
      final ct = _videoContentTypes[who];
      if (ct != null && ct.isNotEmpty) contentType = ct;
    }

    res.headers.set('Cache-Control', 'no-store');
    res.headers.set('Accept-Ranges', 'bytes');
    res.headers.contentType = ContentType.parse(contentType);

    if (url != null && file == null) {
      try {
        final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
        final up = await client.getUrl(Uri.parse(url));
        final range = request.headers.value('range');
        if (range != null) up.headers.set('Range', range);
        up.headers.set('User-Agent', 'Mozilla/5.0');
        final down = await up.close();
        res.statusCode = down.statusCode;
        down.headers.forEach((k, v) => res.headers.set(k, v.join(', ')));
        if (request.method == 'HEAD') {
          await res.close();
          client.close(force: true);
          return;
        }
        await res.addStream(down);
        await res.close();
        client.close(force: true);
        if (who.isNotEmpty) {
          _tvFetchedScreens.add(who);
          _tvFetched = true;
          final log = _log(who);
          log.lastFetchAt = DateTime.now();
          markReached(who, state: 'PLAYING');
        }
        return;
      } catch (e) {
        res.statusCode = HttpStatus.badGateway;
        res.write('$e');
        await res.close();
        return;
      }
    }

    if (file != null && await file.exists()) {
      final length = await file.length();
      final range = request.headers.value('range');
      if (request.method == 'HEAD') {
        res.statusCode = HttpStatus.ok;
        res.headers.contentLength = length;
        await res.close();
        if (who.isNotEmpty) _log(who).headRequests++;
        return;
      }
      if (range != null) {
        final m = RegExp(r'bytes=(\d+)-(\d*)').firstMatch(range);
        if (m != null) {
          var start = int.parse(m.group(1)!);
          var end = m.group(2)!.isNotEmpty ? int.parse(m.group(2)!) : length - 1;
          if (end >= length) end = length - 1;
          if (start < 0) start = 0;
          final raf = await file.open();
          await raf.setPosition(start);
          final slice = await raf.read(end - start + 1);
          await raf.close();
          res.statusCode = HttpStatus.partialContent;
          res.headers.set('Content-Range', 'bytes $start-$end/$length');
          res.headers.contentLength = slice.length;
          res.add(slice);
          await res.close();
          if (who.isNotEmpty) {
            _tvFetchedScreens.add(who);
            _tvFetched = true;
            final log = _log(who);
            log.imagesServed++;
            log.lastFetchAt = DateTime.now();
            markReached(who, state: 'PLAYING');
            log.lastOk = true;
          }
          return;
        }
      }
      res.statusCode = HttpStatus.ok;
      res.headers.contentLength = length;
      await res.addStream(file.openRead());
      await res.close();
      if (who.isNotEmpty) {
        _tvFetchedScreens.add(who);
        _tvFetched = true;
        final log = _log(who);
        log.imagesServed++;
        log.lastFetchAt = DateTime.now();
        markReached(who, state: 'PLAYING');
        log.lastOk = true;
      }
      return;
    }

    res.statusCode = HttpStatus.notFound;
    res.headers.set('X-PlayZone-Reason', 'video-missing');
    await res.close();
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

  /// One screen, spelled out for `/status`.
  String _reportBlock(TvScreenReport r) =>
      '--- screen ${r.ip} | ${r.name} | ${r.label} '
      '(${r.severity.name}) ---\n'
      '  device=${r.deviceId ?? "UNBOUND"}'
      '${r.deviceName == null ? '' : ' (${r.deviceName})'}\n'
      '  session=${r.identity.sessionRunning ? "running" : "idle"}\n'
      '  endpoint=${r.endpoint.isEmpty ? "none" : r.endpoint}\n'
      '  transport=${r.transportState ?? "?"}'
      '${r.pingMs == null ? '' : ' (${r.pingMs}ms)'}\n'
      '  showingOurs=${r.showingOurs?.toString() ?? "unknown"}'
      ' (+${r.fetchedSinceLastProbe})\n'
      '  reachable=${r.reachable}\n'
      '  everReached=${r.everReached}\n'
      '  headRequests=${r.headRequests}\n'
      '  pushedUri=${r.lastPushedUri.isEmpty ? "none" : r.lastPushedUri}\n'
      '  imagesServed=${r.imagesServed}\n'
      '  lastFetch=${r.lastFetchAt?.toIso8601String() ?? "never"}\n'
      '  lastCommand=${r.lastCommand ?? "none"}'
      '${r.lastCommandAt == null ? '' : ' @ ${r.lastCommandAt!.toIso8601String()}'}\n'
      '  lastResult=${r.lastResult ?? "none"}\n'
      '  lastTookMs=${r.lastTookMs ?? "-"}\n'
      '  fault=${r.fault ?? "none"}\n'
      '  remedy=${r.remedy.isEmpty ? "none" : r.remedy}\n'
      // The whole history of this one screen, newest first. Printed because
      // "what did it do when I started that session" is the question nobody
      // can answer from a current reading, and a list of readings taken after
      // the fact is not history at all.
      '${r.events.isEmpty ? '' : r.events.map((e) => '  * ${e.at.toIso8601String()} [${e.ok ? "ok" : "FAIL"}] ${e.text}\n').join()}'
      '--- end ${r.ip} ---\n';

  /// Known control endpoints, for the status page.
  ///
  /// Copied before it is read. `_controlCache` is written by every discovery,
  /// and a discovery is exactly what is running when someone asks the status
  /// page why a screen cannot be found.
  String get controlSummary =>
      List<MapEntry<String, (String, DateTime)>>.of(_controlCache.entries)
          .map((e) => '${e.key} -> ${e.value.$1.split('/AVTransport/').first}')
          .join(' , ');

  void dispose() {
    stopPushing();
    _controller.close();
  }
}
