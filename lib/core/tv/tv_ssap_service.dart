import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

/// Where the pairing keys are kept.
///
/// It is the little bit of the shop's settings this service needs, and
/// nothing more, so that the service can be exercised — and a key repaired —
/// without opening the whole shop.
abstract class TvSsapKeyStore {
  Future<String?> getValue(String key);
  Future<void> setValue(String key, String value);
}

/// Talks to an LG webOS television over SSAP, the protocol on the TV's own
/// control socket.
///
/// LG's webOS televisions refuse every DLNA `RenderingControl` action with
/// "606 Action not authorized" — the screen's own volume simply cannot be
/// moved over DLNA. The only network path left is SSAP: a WebSocket on port
/// 3001 where the television asks the shop for permission once, hands over a
/// key, and every later command carries that key.
///
/// The television's certificate is self-signed and names no host, so it is
/// accepted as-is: the connection is on the café's own LAN and the key that
/// matters is the one the television itself issues.
class TvSsapService {
  TvSsapService._();

  static final TvSsapService instance = TvSsapService._();

  /// The port webOS keeps its control socket on.
  static const int port = 3001;

  /// Where the pairing keys are kept, as a JSON object of address to key.
  static const String keysSettingKey = 'tv_ssap_keys';

  /// How long the television is given to answer a command.
  static const Duration timeout = Duration(seconds: 8);

  /// How long a sound command may take before the screen is given up on.
  ///
  /// Short, because a person is standing there waiting for the wall to
  /// answer. A television that is awake answers in a fraction of a second, so
  /// three seconds of silence already means something is wrong — and a
  /// button that hangs for eight seconds is a button nobody presses twice.
  static const Duration commandTimeout = Duration(seconds: 3);

  /// How long an already-paired screen is given to answer.
  ///
  /// It knows this program already, so the answer comes straight back — but
  /// it does not come back at once on every television, and a button that
  /// waits eight seconds for a screen that has already said hello is a
  /// button nobody presses.
  static const Duration knownTimeout = Duration(seconds: 4);

  /// How long the television is given to show its approval prompt.
  static const Duration consentTimeout = Duration(seconds: 90);

  /// The keys this program holds, one per television.
  final Map<String, String> _keys = <String, String>{};

  TvSsapKeyStore? _store;
  bool _loaded = false;

  /// The key this program holds for a screen, if the screen has given it one.
  String? keyFor(String ip) {
    final key = _keys[ip.trim()];
    return (key == null || key.isEmpty) ? null : key;
  }

  /// Whether this screen has already been let in.
  bool isPaired(String ip) => keyFor(ip) != null;

  /// Reads the saved keys. Safe to call more than once.
  Future<void> load(TvSsapKeyStore store) async {
    if (_loaded) return;
    _loaded = true;
    _store = store;
    final raw = await store.getValue(keysSettingKey);
    if (raw == null || raw.isEmpty) return;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        decoded.forEach((address, key) {
          if (address is String && key is String && key.isNotEmpty) {
            _keys[address.trim()] = key;
          }
        });
      }
    } catch (_) {
      // A damaged setting must never stop the program from starting; the
      // screens simply have to be let in again.
    }
  }

  Future<void> _persist() async {
    final store = _store;
    if (store == null) return;
    await store.setValue(keysSettingKey, jsonEncode(_keys));
  }

  /// Forgets a screen's key, so the next command asks the television again.
  Future<void> forget(String ip) async {
    final address = ip.trim();
    // The connection was opened with a key the television no longer knows, so
    // it is shut rather than left open and useless.
    await _closeSession(address);
    _levels.remove(address);
    _levelsAt.remove(address);
    if (_keys.remove(address) == null) return;
    await _persist();
  }

  // ---------------------------------------------------------------------
  // Pairing
  // ---------------------------------------------------------------------

  /// Asks a television to let this program in.
  ///
  /// The television shows an approval prompt of its own and the staff presses
  /// OK on the remote; some firmware instead asks for the PIN that is written
  /// on the screen, which is why [askForPin] exists and why [TvSsapPairResult]
  /// can come back saying it needs one.
  ///
  /// The PIN is asked for while the same connection is still open, because the
  /// number on the television's screen belongs to that one request — opening a
  /// second connection would show a different number and the staff would be
  /// left typing in the wrong one.
  Future<TvSsapPairResult> pair(
    String ip, {
    String? pin,
    Future<String?> Function()? askForPin,
  }) async {
    final address = ip.trim();
    if (address.isEmpty) {
      return const TvSsapPairResult.failed('no address');
    }
    final existing = keyFor(address);
    _SsapSession? session;
    try {
      session = await _SsapSession.open(address, clientKey: existing);
      final outcome = await session.register(pin: pin, askForPin: askForPin);
      if (outcome.clientKey != null) {
        _keys[address] = outcome.clientKey!;
        await _persist();
      }
      return outcome;
    } catch (error) {
      return TvSsapPairResult.failed(_reason(error));
    } finally {
      await session?.close();
    }
  }

  // ---------------------------------------------------------------------
  // Sound
  // ---------------------------------------------------------------------

  /// The level each screen last reported, and how the last word went.
  ///
  /// Kept per screen, never in one shared place: the whole point of the
  /// buttons is that each wall answers for itself, so one screen's silence
  /// must never be mistaken for another's.
  final Map<String, int> _levels = <String, int>{};
  final Map<String, String> _outcomes = <String, String>{};

  /// When each screen last reported its level.
  ///
  /// A number is only worth keeping for as long as it is true. A level read
  /// half a minute ago may well have been changed with the television's own
  /// remote, so after that the screen is asked again rather than trusted.
  final Map<String, DateTime> _levelsAt = <String, DateTime>{};

  /// The level a screen last reported, if it has reported one.
  int? levelFor(String ip) => _levels[ip.trim()];

  /// How the last word from a screen went.
  String? outcomeFor(String ip) => _outcomes[ip.trim()];

  /// Every screen's sound, as a line for a report.
  String soundReport() {
    final addresses = <String>{..._levels.keys, ..._outcomes.keys}.toList()
      ..sort();
    if (addresses.isEmpty) return 'sound=none';
    return addresses
        .map((ip) =>
            '$ip level=${_levels[ip] ?? "?"} last=${_outcomes[ip] ?? "none"}')
        .join(' | ');
  }

  void _note(String ip, int? level, String outcome) {
    final address = ip.trim();
    if (level != null) {
      _levels[address] = level;
      _levelsAt[address] = DateTime.now();
    }
    _outcomes[address] = outcome;
  }

  /// Opens the screen's control socket and registers on it, ready to be told
  /// things.
  ///
  /// The registration is not a formality: a television only answers commands
  /// from a client it has registered, so a socket that skipped it would sit
  /// there while the television ignored everything sent down it.
  Future<_SsapSession?> _openReady(String ip, String clientKey) async {
    final session = await _SsapSession.open(ip, clientKey: clientKey);
    final outcome = await session.register(wait: knownTimeout);
    if (outcome.paired) return session;
    await session.close();
    // A key the television no longer knows is worse than no key at all: it
    // would ask for permission again and again. So it is put away — but only
    // when the screen actually said so.
    //
    // Silence is not a refusal. A screen in standby, a screen whose controller
    // is busy coming up, a screen on the far side of a bad cable — none of
    // them answer, and none of them have forgotten the key. Forgetting on
    // silence is what loses a shop's pairing overnight and makes the staff go
    // round five screens with a remote in the morning, so silence keeps the
    // key and the next press tries again.
    if (outcome.needsPin) await forget(ip);
    return null;
  }

  /// The open connection to a screen, ready to be told things.
  ///
  /// The connection is KEPT. Opening it costs a secure handshake with the
  /// television and a permission handshake on top of that, and together they
  /// are most of the time a button press used to take — so a screen that has
  /// already said hello is spoken to over the connection it already has, and
  /// the answer comes back in a fraction of a second.
  ///
  /// Each screen has its own connection. Nothing is shared between them, so
  /// one screen that is slow or silent can never hold up another.
  Future<_SsapSession?> _sessionFor(String ip) async {
    final address = ip.trim();
    final key = keyFor(address);
    if (key == null) return null;
    final open = _sessions[address];
    if (open != null && open.isOpen) return open;
    await _closeSession(address);
    final session = await _openReady(address, key);
    if (session == null) return null;
    _sessions[address] = session;
    return session;
  }

  /// The open connection to each screen.
  final Map<String, _SsapSession> _sessions = {};

  /// Closes and forgets one screen's connection.
  Future<void> _closeSession(String ip) async {
    final session = _sessions.remove(ip.trim());
    await session?.close();
  }

  /// Closes every open connection.
  ///
  /// Used when the program is shutting down, and by the tools that measure
  /// the buttons — an open socket keeps the program alive, so a tool that
  /// forgot to close it would never finish.
  Future<void> closeAll() async {
    final addresses = _sessions.keys.toList();
    for (final address in addresses) {
      await _closeSession(address);
    }
  }

  /// Asks a screen one thing, opening a fresh connection if the old one has
  /// gone stale.
  ///
  /// A television that has been idle may close the socket; the answer then
  /// comes back as nothing at all. That is not a refusal, it is a door that
  /// shut, so the door is opened again and the question asked one more time.
  Future<Map<String, dynamic>?> _ask(
    String ip,
    String uri, [
    Map<String, dynamic>? body,
  ]) async {
    final address = ip.trim();
    var session = await _sessionFor(address);
    if (session == null) return null;
    var answer = await session.request(uri, body);
    if (answer != null) return answer;
    await _closeSession(address);
    session = await _sessionFor(address);
    if (session == null) return null;
    return session.request(uri, body);
  }

  /// The screen's own volume, as the screen reports it.
  ///
  /// Null when the screen is not reachable, has not been let in, or is in
  /// standby — the caller cannot tell those apart and does not need to.
  Future<int?> getVolume(String ip) async {
    final address = ip.trim();
    if (keyFor(address) == null) {
      _note(address, null, 'not let in');
      return null;
    }
    try {
      final answer = await _ask(address, 'ssap://audio/getVolume');
      final level = _volumeOf(answer);
      _note(address, level, level == null ? 'no answer' : 'read');
      return level;
    } catch (error) {
      _note(address, null, _reason(error));
      return null;
    }
  }

  /// Moves the screen's volume up or down and returns the level it settled on.
  ///
  /// The step is in points out of a hundred, so five is a change you can
  /// hear from across the room. The level is read first and written back, so
  /// the number shown next to the button is the screen's own number and never
  /// a guess kept from the last time something was pressed.
  ///
  /// The level is read only when it is not already fresh. A number read a
  /// moment ago is as true as one read now, and asking again would turn a
  /// single press into two round trips to the television for nothing.
  Future<int?> changeVolume(String ip, int step) async {
    final address = ip.trim();
    if (keyFor(address) == null) {
      _note(address, null, 'not let in');
      return null;
    }
    if (step == 0) return null;
    try {
      var current = _freshLevel(address);
      if (current == null) {
        current = _volumeOf(await _ask(address, 'ssap://audio/getVolume'));
        if (current == null) {
          _note(address, null, 'no answer');
          return null;
        }
      }
      final target = (current + step).clamp(0, 100);
      final ok = await _ask(address, 'ssap://audio/setVolume', {'volume': target});
      if (ok != null) {
        _note(address, target, 'set');
        return target;
      }

      // Some screens are routed through an amplifier, and those refuse a
      // direct level. The step buttons still work there, so they are pressed
      // the same number of times instead.
      final button = step > 0 ? 'ssap://audio/volumeUp' : 'ssap://audio/volumeDown';
      for (var i = 0; i < step.abs(); i++) {
        await _ask(address, button);
      }
      final settled = _volumeOf(await _ask(address, 'ssap://audio/getVolume'));
      _note(address, settled, 'stepped');
      return settled;
    } catch (error) {
      _note(address, null, _reason(error));
      return null;
    }
  }

  /// The service that last answered a screen's own screen command.
  ///
  /// Two names exist for the same thing, one per firmware generation, and
  /// asking the wrong one first costs a round trip and a 404. Once a screen
  /// has answered on one of them, that is the one it is asked on.
  final Map<String, String> _screenService = {};

  static const _screenServices = [
    'ssap://com.webos.service.tvpower/power',
    'ssap://com.webos.service.tv.power',
  ];

  /// Puts the panel itself to sleep, and wakes it again, without switching the
  /// television off.
  ///
  /// This is LG's own "Screen Off": the sound keeps playing, the console keeps
  /// its handshake, and the picture comes back in the same blink it went away
  /// in. It is one sentence on a socket that is already open, answered in
  /// milliseconds — nothing like handing the screen a black photograph over
  /// DLNA, which makes the television leave what it was showing, find our
  /// picture, and fetch it.
  ///
  /// Two service names exist and which one answers depends on the firmware:
  /// `tvpower/power/…` on webOS 5 and later, `tv.power/…` on 4.x. Both are
  /// tried, and whichever answers is the one that worked.
  ///
  /// Returns whether the screen did it. A screen that has not been let in says
  /// nothing at all, and the caller falls back to the photograph.
  Future<bool> setScreenOn(String ip, bool on) async {
    final address = ip.trim();
    if (keyFor(address) == null) {
      _note(address, null, 'not let in');
      return false;
    }
    final action = on ? 'turnOnScreen' : 'turnOffScreen';
    final known = _screenService[address];
    final order = [
      if (known != null) known,
      ..._screenServices.where((service) => service != known),
    ];
    for (final service in order) {
      final short = service.contains('tvpower') ? 'tvpower' : 'tv.power';
      // Asked twice, because these sockets sometimes answer nothing at all on
      // the first try — the same silence that makes a volume command look
      // refused. A wrong service, on the other hand, answers with an empty
      // payload, and asking it again would only waste a round trip. On an
      // open socket a second ask costs a few milliseconds; the photograph it
      // saves us from costs seconds.
      for (var attempt = 0; attempt < 2; attempt++) {
        Map<String, dynamic>? answer;
        try {
          answer = await _ask(
              address, '$service/$action', const {'standbyMode': 'active'});
        } catch (error) {
          // A socket that will not even open is not a service that does not
          // exist: no other name for the command would reach the screen
          // either, and trying it would spend another turn of the wheel on
          // the same silence.
          _note(address, null, 'screen $short: ${_reason(error)}');
          return false;
        }
        if (answer == null) {
          // Nothing at all came back, so the screen is asleep or gone. That is
          // not this service's fault and not the other name's job: the button
          // takes the other road now instead of waiting twice.
          _note(address, null, 'screen $short: no answer');
          return false;
        }
          final code = '${answer['errorCode'] ?? ''}';
          final state = '${answer['state'] ?? ''}';
          // The state in the answer is the truth, whatever the answer says
          // about having done the work.
          //
          // A screen that is asked to go dark and answers
          // `{"returnValue":false,"state":"Screen Off","errorCode":"-101",
          // "errorText":"The current state must be 'Active'"}` is not
          // refusing: it is already dark. LG calls that a failed state
          // transition because the transition was never needed; the cashier
          // calls it the screen going dark, which is what was asked for. It is
          // read as the screen being dark and not as a refusal — refusing it
          // sent the whole command down the slow road to arrive at the same
          // darkness seconds later.
          //
          // Coming back on is the one answer this firmware gets wrong in the
          // other direction: the first wake after a sleep reports "unknown
          // error" and turns the screen on anyway, so that is believed too.
          // "Active" is deliberately NOT taken as proof of being awake, because
          // an older service name reports it even while the panel is dark — a
          // wall reported as lit while it is black is worse than one slow
          // command.
          final ok = answer['returnValue'] == true ||
              (!on && state == 'Screen Off') ||
              (on && code == 'POWER_ERROR_0005');
          if (ok) {
            _screenService[address] = service;
            _note(address, null, on ? 'screen: on' : 'screen: off');
            // The television drops the control socket when its panel changes
            // state, so the next press would pay for the whole secure
            // handshake again — measured at up to two seconds, which is
            // exactly the press that feels broken. It is reopened now, while
            // nobody is waiting for it.
            unawaited(_rewarm(address));
            return true;
          }
          final why = code.isNotEmpty
              ? code
              : (answer.isEmpty ? 'empty' : 'no returnValue');
          _note(address, null, 'screen $short: $why');
          // An empty payload is this firmware saying "no such service", so
          // the other name is the answer — not another go at this one.
          if (answer.isEmpty) break;
      }
    }
    return false;
  }

  /// Opens every paired screen's control socket before anyone presses
  /// anything.
  ///
  /// The first command on a cold socket pays for the secure handshake, and on
  /// this shop's walls that has been measured at close to two seconds on a
  /// television that was busy with something else. Two seconds of a button
  /// doing nothing is the difference between a program that works and a
  /// program the staff distrust. Opening the sockets in the background at
  /// startup moves that cost to a moment when nobody is waiting for it.
  ///
  /// One at a time, and slowly: five handshakes at once on a shop network is
  /// exactly the crowd that makes a handshake take two seconds.
  Future<void> warmUp() async {
    for (final address in _keys.keys.toList()) {
      try {
        await _sessionFor(address);
      } catch (_) {
        // A screen that is off has no socket to warm. Its own button deals
        // with that when it is pressed.
      }
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
  }

  /// Opens a screen's socket again a moment after its panel changed state.
  ///
  /// The socket is only touched when it is actually shut, and it is left alone
  /// long enough for the panel to finish moving — a press that arrives in the
  /// meantime finds the socket it already had.
  Future<void> _rewarm(String ip) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final open = _sessions[ip.trim()];
    if (open != null && open.isOpen) return;
    try {
      await _sessionFor(ip);
    } catch (_) {
      // The panel may still be coming up. The next press will try again.
    }
  }

  /// Sends one command and hands back whatever the screen says, word for
  /// word.
  ///
  /// Meant for the tools and for diagnosing a screen whose answers do not fit
  /// the named methods. The program's own paths keep their own methods, so
  /// that what a button does is written down in one place.
  Future<Map<String, dynamic>?> askRaw(String ip, String uri,
          [Map<String, dynamic>? body]) =>
      _ask(ip, uri, body);

  /// The level last heard from a screen, if it was heard recently.
  int? _freshLevel(String ip) {
    final level = _levels[ip.trim()];
    final at = _levelsAt[ip.trim()];
    if (level == null || at == null) return null;
    if (DateTime.now().difference(at) > const Duration(seconds: 30)) return null;
    return level;
  }

  /// Pulls the level out of the television's answer.
  ///
  /// The answer moved shape between firmware versions: some send `volume`
  /// flat, some bury it inside `volumeStatus`.
  static int? _volumeOf(Map<String, dynamic>? answer) {
    if (answer == null) return null;
    final flat = answer['volume'];
    if (flat is num) return flat.round();
    final status = answer['volumeStatus'];
    if (status is Map) {
      final nested = status['volume'];
      if (nested is num) return nested.round();
    }
    return null;
  }

  static String _reason(Object error) {
    final text = error.toString();
    if (text.contains('TimeoutException')) return 'no answer';
    if (text.contains('HandshakeException')) return 'no control socket';
    if (text.contains('SocketException') || text.contains('Failed host lookup')) {
      return 'not reachable';
    }
    return text;
  }
}

/// What asking a television to let this program in came back with.
class TvSsapPairResult {
  const TvSsapPairResult.paired(this.clientKey)
      : needsPin = false,
        error = null;

  const TvSsapPairResult.needsPin()
      : clientKey = null,
        needsPin = true,
        error = null;

  const TvSsapPairResult.failed(this.error)
      : clientKey = null,
        needsPin = false;

  /// The key the television issued, when it let this program in.
  final String? clientKey;

  /// True when the television wants a PIN typed in before it will answer.
  final bool needsPin;

  /// Why the request failed, in words a shop can act on.
  final String? error;

  bool get paired => clientKey != null;
}

/// One conversation with a television: a socket, and the key that speaks for
/// this program on it.
class _SsapSession {
  _SsapSession._(this._socket, this._client, this.clientKey) {
    // A WebSocket is a single-subscription stream, so one listener has to
    // serve every command sent over it.
    _subscription = _socket.listen(
      _onMessage,
      onError: (Object error) {
        _registration?.complete(TvSsapPairResult.failed(error.toString()));
        for (final waiter in _pending.values) {
          if (!waiter.isCompleted) waiter.complete(null);
        }
        _pending.clear();
      },
      onDone: () {
        _registration?.complete(
          const TvSsapPairResult.failed('the screen closed the connection'),
        );
        for (final waiter in _pending.values) {
          if (!waiter.isCompleted) waiter.complete(null);
        }
        _pending.clear();
      },
    );
  }

  final WebSocket _socket;
  final HttpClient _client;

  /// Whether the connection is still good.
  ///
  /// A television that has been idle may shut the door; the socket says so
  /// and the next command opens a new one instead of talking to a wall.
  bool get isOpen => _socket.readyState == WebSocket.open;

  /// The key this program already holds for this television, if any.
  final String? clientKey;

  late final StreamSubscription<dynamic> _subscription;

  /// The commands waiting for their answers, by the id they were sent with.
  final Map<String, Completer<Map<String, dynamic>?>> _pending =
      <String, Completer<Map<String, dynamic>?>>{};

  /// The registration waiting for the television to let this program in.
  Completer<TvSsapPairResult>? _registration;

  /// The id the registration was sent with.
  String? _registrationId;

  /// The PIN to hand over when the television asks for one.
  String? _pin;

  /// Asked for the PIN when the television wants one and none was given.
  Future<String?> Function()? _askForPin;

  /// Opens the control socket. Registration is a separate step, because the
  /// television may answer "I need a PIN" and that is not the same as failing.
  static Future<_SsapSession> open(String ip, {String? clientKey}) async {
    final client = HttpClient()
      // The television signs itself and names no host; the permission that
      // matters is the key it hands out, not the paper on the certificate.
      ..badCertificateCallback = (cert, host, port) => true;
    WebSocket? socket;
    try {
      socket = await WebSocket.connect('wss://$ip:${TvSsapService.port}',
              customClient: client)
          // A handshake on the shop's own network is a fraction of a second.
          // Ten seconds was a wall of blank waiting on a screen whose
          // controller is off — long enough to look like the program had
          // died, and long enough to be the whole of the cashier's patience.
          .timeout(const Duration(seconds: 3));
    } catch (_) {
      client.close(force: true);
      rethrow;
    }
    return _SsapSession._(socket, client, clientKey);
  }

  /// Sends the registration and waits for the television's answer.
  ///
  /// A television that already knows this program answers with the key at
  /// once. One that does not shows an approval prompt, or asks for a PIN, and
  /// answers with the key only after the staff has acted on the screen.
  Future<TvSsapPairResult> register({
    String? pin,
    Future<String?> Function()? askForPin,
    Duration? wait,
  }) async {
    final completer = Completer<TvSsapPairResult>();
    _registration = completer;
    _pin = pin;
    _askForPin = askForPin;
    final id = _newId();
    _registrationId = id;
    _send({
      'type': 'register',
      'id': id,
      'payload': _registrationPayload(clientKey),
    });
    return completer.future.timeout(
      wait ?? TvSsapService.consentTimeout,
      onTimeout: () => const TvSsapPairResult.failed('no answer'),
    );
  }

  /// Reads one answer off the socket and gives it to whoever is waiting.
  void _onMessage(dynamic raw) {
    Map<String, dynamic> message;
    try {
      message = jsonDecode(raw as String) as Map<String, dynamic>;
    } catch (_) {
      return;
    }
    final payload = message['payload'];
    final id = message['id'];

    // The key can come back on any of the ids this conversation used, so it is
    // looked for wherever it turns up.
    if (payload is Map) {
      final key = payload['client-key'];
      if (key is String && key.isNotEmpty) {
        final registration = _registration;
        if (registration != null && !registration.isCompleted) {
          registration.complete(TvSsapPairResult.paired(key));
        }
        return;
      }
    }

    // The television saying no is an answer too, and it saves waiting out
    // the whole prompt for a request that was turned down at the start.
    if (message['type'] == 'error' && id == _registrationId) {
      final registration = _registration;
      if (registration != null && !registration.isCompleted) {
        registration.complete(
          TvSsapPairResult.failed('${message['error'] ?? 'turned down'}'),
        );
      }
      return;
    }

    // The television asking for a PIN is the one case that needs answering
    // mid-conversation.
    if (id == _registrationId && payload is Map) {
      final pairingType = '${payload['pairingType'] ?? ''}'.toUpperCase();
      if (pairingType == 'PIN') {
        final pin = _pin;
        if (pin != null && pin.isNotEmpty) {
          _sendPin(pin);
        } else {
          final provider = _askForPin;
          if (provider != null) {
            // The number belongs to this one request, so it is asked for and
            // handed over without letting go of the connection.
            provider().then((typed) {
              if (typed == null || typed.isEmpty) {
                final registration = _registration;
                if (registration != null && !registration.isCompleted) {
                  registration.complete(
                    const TvSsapPairResult.failed('the number was not typed'),
                  );
                }
                return;
              }
              _sendPin(typed);
            });
          } else {
            final registration = _registration;
            if (registration != null && !registration.isCompleted) {
              registration.complete(const TvSsapPairResult.needsPin());
            }
          }
        }
        return;
      }
    }

    if (id is String) {
      final waiter = _pending.remove(id);
      if (waiter != null && !waiter.isCompleted) {
        waiter.complete(payload is Map<String, dynamic> ? payload : null);
      }
    }
  }

  /// Hands the number the television asked for over to it.
  void _sendPin(String pin) {
    _send({
      'type': 'request',
      'id': _newId(),
      'uri': 'ssap://pairing/setPin',
      'payload': {'pin': pin},
    });
  }

  /// Sends a command and waits for the answer that belongs to it.
  Future<Map<String, dynamic>?> request(
    String uri, [
    Map<String, dynamic>? body,
  ]) async {
    final id = _newId();
    final completer = Completer<Map<String, dynamic>?>();
    _pending[id] = completer;
    _send({
      'type': 'request',
      'id': id,
      'uri': uri,
      if (body != null) 'payload': body,
    });
    return completer.future.timeout(
      TvSsapService.commandTimeout,
      onTimeout: () {
        _pending.remove(id);
        return null;
      },
    );
  }

  /// Writes a level, and says whether the screen took it.
  Future<bool> setVolume(int level) async {
    final answer = await request('ssap://audio/setVolume', {'volume': level});
    if (answer == null) return false;
    final returned = answer['returnValue'];
    return returned is bool ? returned : true;
  }

  void _send(Map<String, dynamic> message) {
    try {
      _socket.add(jsonEncode(message));
    } catch (_) {
      // The socket is gone; the caller sees the timeout.
    }
  }

  Future<void> close() async {
    await _subscription.cancel();
    try {
      await _socket.close().timeout(const Duration(seconds: 2));
    } catch (_) {
      // Already gone.
    }
    _client.close(force: true);
  }

  static String _newId() {
    final random = Random();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}'
        '-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  /// The registration the television expects.
  ///
  /// The manifest asks for the permissions a remote control needs, and the
  /// signature is the one LG's own remote ships with — a television only lets
  /// in a client it recognises as a remote.
  static Map<String, dynamic> _registrationPayload(String? clientKey) {
    final payload = <String, dynamic>{
      'manifest': {
        'manifestVersion': 1,
        'appVersion': '1.1',
        'signed': {
          'created': '20140509',
          'appId': 'com.lge.test',
          'vendorId': 'com.lge',
          'localizedAppNames': {
            '': 'LG Remote App',
            'ko-KR': '\ub9ac\ubaa8\ucee8 \uc571',
            'zxx-XX': '\u041b\u0413 \u0420\u044d\u043c\u043e\u0442\u044d \u0410\u041f\u041f',
          },
          'localizedVendorNames': {'': 'LG Electronics'},
          'permissions': const [
            'TEST_SECURE',
            'CONTROL_INPUT_TEXT',
            'CONTROL_MOUSE_AND_KEYBOARD',
            'READ_INSTALLED_APPS',
            'READ_LGE_SDX',
            'READ_NOTIFICATIONS',
            'SEARCH',
            'WRITE_SETTINGS',
            'WRITE_NOTIFICATION_ALERT',
            'CONTROL_POWER',
            'READ_CURRENT_CHANNEL',
            'READ_RUNNING_APPS',
            'READ_UPDATE_INFO',
            'UPDATE_FROM_REMOTE_APP',
            'READ_LGE_TV_INPUT_EVENTS',
            'READ_TV_CURRENT_TIME',
          ],
          'serial': '2f930e2d2cfe083771f68e4fe7bb07',
        },
        'permissions': const [
          'LAUNCH',
          'LAUNCH_WEBAPP',
          'APP_TO_APP',
          'CLOSE',
          'TEST_OPEN',
          'TEST_PROTECTED',
          'CONTROL_AUDIO',
          'CONTROL_DISPLAY',
          'CONTROL_INPUT_JOYSTICK',
          'CONTROL_INPUT_MEDIA_RECORDING',
          'CONTROL_INPUT_MEDIA_PLAYBACK',
          'CONTROL_INPUT_TV',
          'CONTROL_MOUSE_AND_KEYBOARD',
          'CONTROL_INPUT_TEXT',
          'CONTROL_POWER',
          'READ_APP_STATUS',
          'READ_CURRENT_CHANNEL',
          'READ_INPUT_DEVICE_LIST',
          'READ_NETWORK_STATE',
          'READ_RUNNING_APPS',
          'READ_TV_CHANNEL_LIST',
          'WRITE_NOTIFICATION_TOAST',
          'READ_POWER_STATE',
          'READ_COUNTRY_INFO',
          'READ_SETTINGS',
          'CONTROL_TV_SCREEN',
          'CONTROL_TV_STANBY',
          'CONTROL_FAVORITE_GROUP',
          'CONTROL_USER_INFO',
          'CHECK_BLUETOOTH_DEVICE',
          'CONTROL_BLUETOOTH',
          'CONTROL_TIMER_INFO',
          'STB_INTERNAL_CONNECTION',
          'CONTROL_RECORDING',
          'READ_RECORDING_STATE',
          'WRITE_RECORDING_LIST',
          'READ_RECORDING_LIST',
          'READ_RECORDING_SCHEDULE',
          'WRITE_RECORDING_SCHEDULE',
        ],
        'signatures': [
          {
            'signatureVersion': 1,
            'signature': _signature,
          },
        ],
      },
      'pairingType': 'PROMPT',
      'forcePairing': clientKey == null,
    };
    if (clientKey != null) payload['client-key'] = clientKey;
    return payload;
  }

  /// The signature LG's own remote application ships with.
  static const String _signature =
      'eyJhbGdvcml0aG0iOiJSU0EtU0hBMjU2Iiwia2V5SWQiOiJ0ZXN0LXNpZ25pbmctY2VydCIsInNpZ25hdHVyZVZlcnNpb24iOjF9.hrVRgjCwXVvE2OOSpDZ58hR+59aFNwYDyjQgKk3auukd7pcegmE2CzPCa0bJ0ZsRAcKkCTJrWo5iDzNhMBWRyaMOv5zWSrthlf7G128qvIlpMT0YNY+n/FaOHE73uLrS/g7swl3/qH/BGFG2Hu4RlL48eb3lLKqTt2xKHdCs6Cd4RMfJPYnzgvI4BNrFUKsjkcu+WD4OO2A27Pq1n50cMchmcaXadJhGrOqH5YmHdOCj5NSHzJYrsW0HPlpuAx/ECMeIZYDh6RMqaFM2DXzdKX9NmmyqzJ3o/0lkk/N97gfVRLW5hA29yeAwaCViZNCP8iC9aO0q9fQojoa7NQnAtw==';
}
