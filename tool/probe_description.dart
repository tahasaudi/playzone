// Reads a screen's description the way the program does, and says where the
// reading goes wrong.
//
//   dart run tool/probe_description.dart 192.168.1.7
import 'dart:convert';
import 'dart:io';

Future<void> main(List<String> args) async {
  final targets = args.isEmpty
      ? <String>[
          'http://192.168.1.7:1306/',
          'http://192.168.1.3:1695/',
          'http://192.168.1.4:1388/',
          'http://192.168.1.11:1602/',
        ]
      : args;

  final client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5)
    ..idleTimeout = const Duration(seconds: 15)
    ..maxConnectionsPerHost = 8;

  for (final target in targets) {
    final started = DateTime.now();
    try {
      final req = await client.getUrl(Uri.parse(target));
      final res = await req.close();
      final body = await res.transform(utf8.decoder).join().timeout(const Duration(seconds: 5));
      final ms = DateTime.now().difference(started).inMilliseconds;
      print('$target  status=${res.statusCode}  len=${body.length}  ${ms}ms');
      print('    av     = ${_controlUrl(body, 'AVTransport') ?? "NOT FOUND"}');
      print('    render = ${_controlUrl(body, 'RenderingControl') ?? "NOT FOUND"}');
      if (args.contains('--body')) {
        print('--- body ---');
        print(body);
        print('--- end body ---');
      }
    } catch (error) {
      final ms = DateTime.now().difference(started).inMilliseconds;
      print('$target  ERROR after ${ms}ms: $error');
    }
  }
  client.close(force: true);
}

/// The controlURL of one service inside a device description.
///
/// NOT a raw string: the service name has to be woven into the pattern, and
/// a raw string takes the "$service" as the literal text "$service".
String? _controlUrl(String body, String service) {
  final match = RegExp(
          '<serviceType>\\s*urn:schemas-upnp-org:service:$service:1\\s*</serviceType>(?:(?!</service>).)*?<controlURL>\\s*([^<]+?)\\s*</controlURL>',
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
