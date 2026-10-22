import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../database/app_database.dart';

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

  /// How long the television is given to show its approval prompt.
  static const Duration consentTimeout = Duration(seconds: 90);

  /// The keys this program holds, one per television.
  final Map<String, String> _keys = <String, String>{};

  AppDatabase? _db;
  bool _loaded = false;

  /// The key this program holds for a screen, if the screen has given it one.
  String? keyFor(String ip) {
    final key = _keys[ip.trim()];
    return (key == null || key.isEmpty) ? null : key;
  }

  /// Whether this screen has already been let in.
  bool isPaired(String ip) => keyFor(ip) != null;

  /// Reads the saved keys. Safe to call more than once.
  Future<void> load(AppDatabase db) async {
    if (_loaded) return;
    _loaded = true;
    _db = db;
    final raw = await db.settingsDao.getValue(keysSettingKey);
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
    final db = _db;
    if (db == null) return;
    await db.settingsDao.setValue(keysSettingKey, jsonEncode(_keys));
  }

  /// Forgets a screen's key, so the next command asks the television again.
  Future<void> forget(String ip) async {
    if (_keys.remove(ip.trim()) == null) return;
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

  /// The screen's own volume, as the screen reports it.
  ///
  /// Null when the screen is not reachable, has not been let in, or is in
  /// standby — the caller cannot tell those apart and does not need to.
  Future<int?> getVolume(String ip) async {
    final address = ip.trim();
    final key = keyFor(address);
    if (key == null) return null;
    _SsapSession? session;
    try {
      session = await _SsapSession.open(address, clientKey: key);
      final answer = await session.request('ssap://audio/getVolume');
      return _volumeOf(answer);
    } catch (_) {
      return null;
    } finally {
      await session?.close();
    }
  }

  /// Moves the screen's volume up or down and returns the level it settled on.
  ///
  /// The step is in points out of a hundred, so five is a change you can
  /// hear from across the room. The level is read first and written back, so
  /// the number shown next to the button is the screen's own number and never
  /// a guess kept from the last time something was pressed.
  Future<int?> changeVolume(String ip, int step) async {
    final address = ip.trim();
    final key = keyFor(address);
    if (key == null) return null;
    if (step == 0) return null;
    _SsapSession? session;
    try {
      session = await _SsapSession.open(address, clientKey: key);
      final current = _volumeOf(
        await session.request('ssap://audio/getVolume'),
      );
      if (current == null) return null;
      final target = (current + step).clamp(0, 100);
      final ok = await session.setVolume(target);
      if (ok) return target;

      // Some screens are routed through an amplifier, and those refuse a
      // direct level. The step buttons still work there, so they are pressed
      // the same number of times instead.
      final button = step > 0 ? 'ssap://audio/volumeUp' : 'ssap://audio/volumeDown';
      for (var i = 0; i < step.abs(); i++) {
        await session.request(button);
      }
      return _volumeOf(await session.request('ssap://audio/getVolume'));
    } catch (_) {
      return null;
    } finally {
      await session?.close();
    }
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
          .timeout(const Duration(seconds: 10));
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
      TvSsapService.consentTimeout,
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
      TvSsapService.timeout,
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
