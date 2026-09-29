import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/settings_repository.dart';
import 'esp32_ir_command_box.dart';
import 'ir_command_box.dart';

/// يربط كل جهاز (deviceId) بعنوان الصندوق الخاص بستارته.
/// التخزين داخل إعدادات التطبيق كنص JSON — بدون أي تغيير على قاعدة
/// البيانات أو ترحيل.
class IrBoxRepository {
  IrBoxRepository(this._settings);
  final SettingsRepository _settings;

  /// مفتاح النص بصندوق: {"deviceId": "http://192.168.1.x"}
  static const linkKey = 'ir_box_link_map';

  Map<int, String> parse(String? raw) {
    if (raw == null || raw.isEmpty) return const {};
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      return {
        for (final e in obj.entries) int.parse(e.key): e.value as String,
      };
    } catch (_) {
      return const {};
    }
  }

  Future<Map<int, String>> links() async =>
      parse(await _settings.getValue(linkKey));

  Future<void> setLink(int deviceId, String url) async {
    final map = await links();
    map[deviceId] = url.trim();
    await _settings.setValue(linkKey, jsonEncode(map));
  }

  Future<void> removeLink(int deviceId) async {
    final map = await links();
    if (map.remove(deviceId) == null) return;
    await _settings.setValue(linkKey, jsonEncode(map));
  }

  /// يبني [IrCommandBox] لجهاز لو موجود له عنوان، وإلا null.
  IrCommandBox? boxFor(int deviceId, Map<int, String> links) {
    final url = links[deviceId];
    if (url == null || url.trim().isEmpty) return null;
    return Esp32IrCommandBox(url);
  }
}

final irBoxRepositoryProvider = Provider<IrBoxRepository>((ref) {
  return IrBoxRepository(ref.watch(settingsRepositoryProvider));
});

/// خريطة الجهاز ← عنوان الصندوق، حية وتتحدث تلقائياً عند أي تغيير.
final irBoxLinksProvider = Provider<Map<int, String>>((ref) {
  final raw =
      ref.watch(appSettingsProvider).valueOrNull?[IrBoxRepository.linkKey];
  return ref.watch(irBoxRepositoryProvider).parse(raw);
});