// PlayZone wall-screen app — the picture the wall shows, painted natively.
//
// v1: pull the current frame from the till's picture server every couple of
// seconds and show it full-screen. This is exactly the picture the DLNA push
// hands the TV today — same server, same per-screen token — but served over
// one plain HTTP poll instead of discovery + Stop + SetAVTransportURI, and
// with no renderer state to "refuse".
//
// The app never guesses anything about its own screen: the till decides what
// the wall shows (board, cards, dim, identify label) and this viewer renders
// whatever arrives. Later versions read a small /state endpoint so the dim
// comes from the app itself instead of a black frame.

import 'dart:async';
import 'dart:html' as html;
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';

void main() {
  runApp(const PlayZoneTvApp());
}

/// Where the till lives on the LAN. Written per install: the till's address
/// is stable in this café (its own PB boots it), and a settings screen is a
/// later addition — one hardcoded address is what keeps v1 simple.
const String kTillIp = '192.168.1.109';

/// This wall's token. The picture server associates a fetch with a screen
/// through this tag (`/tv.jpg?s=...`), which is how the till's report stays
/// honest about which panel is actually pulling. One value per television.
const String kScreenToken = 'ps46';

Uri _frameUri(int fetch) => Uri(
      scheme: 'http',
      host: kTillIp,
      port: 41777,
      path: '/tv.jpg',
      // The random tail is what stops the TV's HTTP cache from answering with
      // yesterday's picture.
      queryParameters: {'s': kScreenToken, 'r': '$fetch'},
    );

class PlayZoneTvApp extends StatelessWidget {
  const PlayZoneTvApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const BoardPage(),
    );
  }
}

class BoardPage extends StatefulWidget {
  const BoardPage({super.key});

  @override
  State<BoardPage> createState() => _BoardPageState();
}

class _BoardPageState extends State<BoardPage> {
  Uint8List? _frame;
  DateTime? _lastOkAt;
  int _fetch = 0;
  Timer? _poll;
  String? _error;

  @override
  void initState() {
    super.initState();
    _pollEvery(const Duration(seconds: 2));
  }

  void _pollEvery(Duration interval) {
    _poll?.cancel();
    _poll = Timer.periodic(interval, (_) => _fetchFrame());
    unawaited(_fetchFrame());
  }

  Future<void> _fetchFrame() async {
    final fetch = _fetch++;
    try {
      final response = await html.HttpRequest.request(
        _frameUri(fetch).toString(),
        responseType: 'arrayBuffer',
      );
      final bytes = Uint8List.view(response.response as ByteBuffer);
      if (!mounted) return;
      setState(() {
        _frame = bytes;
        _lastOkAt = DateTime.now();
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'مفيش اتصال بالكاشير');
    }
  }

  /// The wall is never "blank": a missed poll keeps the last picture and just
  /// says so in the corner, because a screen the staff trust must never be the
  /// one thing in the room that went dark without explanation.
  bool get _connectionLost =>
      _lastOkAt == null ||
      DateTime.now().difference(_lastOkAt!).compareTo(const Duration(seconds: 8)) > 0;

  String get _heartbeat {
    final t = _lastOkAt;
    if (t == null) return 'بيبص للكاشير…';
    final m = DateTime.now().difference(t).inMilliseconds;
    return 'متصل (${(m / 1000).round()}s ago)';
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final frame = _frame;
    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (frame != null)
            // gaplessPlayback keeps the old frame on screen until the new one
            // is decoded, so a busy evening never shows a flicker between
            // frames.
            Image.memory(frame, gaplessPlayback: true, fit: BoxFit.contain)
          else
            const Center(
              child: Text(
                'PlayZone',
                style: TextStyle(
                  fontSize: 72,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFB39DDB),
                ),
              ),
            ),
          Positioned(
            bottom: 24,
            left: 32,
            child: AnimatedOpacity(
              // The heartbeat fades away when everything is healthy; it comes
              // back, in red, the moment the wall stops hearing from the till.
              opacity: _connectionLost ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 400),
              child: Text(
                _connectionLost ? (_error ?? 'انقطع الاتصال') : _heartbeat,
                style: TextStyle(
                  fontSize: 26,
                  color: _connectionLost ? Colors.redAccent : Colors.white54,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
