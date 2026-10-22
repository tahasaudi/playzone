// Measures how long the two commands the cashier waits on actually take:
// darkening a screen and waking it again.
//
//   dart run tool/dim_speed.dart
//
// It talks to the program's own loopback-only port, so nothing off this
// machine can drive the screens, and it never touches a screen that is not
// on this list.
import 'dart:convert';
import 'dart:io';

const screens = [
  '192.168.1.4',
  '192.168.1.5',
  '192.168.1.7',
  '192.168.1.3',
  '192.168.1.11',
];

Future<void> main(List<String> args) async {
  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 20)
    ..idleTimeout = const Duration(seconds: 30);

  final rounds = args.isEmpty ? 2 : int.tryParse(args.first) ?? 2;
  for (var round = 1; round <= rounds; round++) {
    print('--- round $round ---');
    for (final ip in screens) {
      for (final action in const ['dim', 'open']) {
        final started = DateTime.now();
        String body;
        try {
          final req = await client.getUrl(
              Uri.parse('http://127.0.0.1:41778/$action?ip=$ip'));
          final res = await req.close();
          body = await res.transform(utf8.decoder).join();
        } catch (error) {
          body = 'ERROR $error';
        }
        final ms = DateTime.now().difference(started).inMilliseconds;
        final took = RegExp(r'tookMs=(\d+)').firstMatch(body)?.group(1) ?? '?';
        final ok = RegExp(r'ok=(\w+)').firstMatch(body)?.group(1) ?? '?';
        print('$ip  $action  ${ms}ms (inside $took)  ok=$ok');
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
  }
  client.close(force: true);
}
