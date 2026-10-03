import 'dart:io';

import '../tv/hard_lock.dart';
import 'ir_command_box.dart';

/// تنفيذ [IrCommandBox] للبورد "PlayZone IR Box" (ESP32).
/// يتكلم معه عبر HTTP خام (بدون أي package خارجي) على الشبكة المحلية.
class Esp32IrCommandBox implements IrCommandBox {
  Esp32IrCommandBox(String baseUrl) : _base = _normalize(baseUrl);

  final String _base;

  static String _normalize(String url) {
    var u = url.trim();
    if (!u.contains('://')) u = 'http://$u';
    while (u.endsWith('/')) {
      u = u.substring(0, u.length - 1);
    }
    return u;
  }

  static const _timeout = Duration(seconds: 3);

  Future<HttpClientResponse> _get(String path,
      [Map<String, String>? qs]) async {
    final client = HttpClient()..connectionTimeout = _timeout;
    try {
      final uri = Uri.parse('$_base$path').replace(queryParameters: qs);
      final req = await client.getUrl(uri);
      return await req.close().timeout(_timeout);
    } finally {
      client.close(force: true);
    }
  }

  @override
  Future<bool> isReachable() async {
    if (kHardLockWallNetwork) return false;
    try {
      final res = await _get('/api/liveness');
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<bool> send(String slot) async {
    if (kHardLockWallNetwork) return false;
    try {
      final res = await _get('/api/send', {'slot': slot});
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
