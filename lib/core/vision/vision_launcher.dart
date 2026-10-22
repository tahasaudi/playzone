import 'dart:io';

import 'package:path/path.dart' as p;

/// نتيجة محاولة تشغيل نافذة كاميرات المحل.
class VisionLaunchResult {
  const VisionLaunchResult._(this.ok, this.message);

  const VisionLaunchResult.ok(this.message) : ok = true;
  const VisionLaunchResult.error(this.message) : ok = false;

  final bool ok;
  final String message;
}

/// بيشغّل نافذة كاميرات المحل (نفس خدمة الرؤية بالبايثون: الموديل شغال على
/// كل كاميرا) كعملية منفصلة، عشان البرنامج يفضل شغال حتى لو النافذة اتقفلت.
///
/// بيدوّر على مجلد `vision_service` جنب البرنامج الأول، وبعدها في مجلد
/// بيانات PlayZone. لو ملقاهوش بيرجّع رسالة واضحة للمستخدم بدل ما يفشل بصمت.
class VisionLauncher {
  VisionLauncher._();

  static String? _serviceDir() {
    final exeDir = p.dirname(Platform.resolvedExecutable);
    final appData = Platform.environment['APPDATA'];
    final localAppData = Platform.environment['LOCALAPPDATA'];

    final candidates = <String>[
      p.join(exeDir, 'vision_service'),
      if (appData != null) p.join(appData, 'PlayZone', 'vision_service'),
      if (localAppData != null)
        p.join(localAppData, 'PlayZone', 'vision_service'),
    ];

    for (final dir in candidates) {
      if (File(p.join(dir, 'demo.py')).existsSync()) return dir;
    }
    return null;
  }

  static String? _python(String dir) {
    final localAppData = Platform.environment['LOCALAPPDATA'];
    final candidates = <String>[
      p.join(dir, '.venv', 'Scripts', 'python.exe'),
      if (localAppData != null)
        p.join(localAppData, 'Programs', 'Python', 'Python311', 'python.exe'),
    ];
    for (final exe in candidates) {
      if (File(exe).existsSync()) return exe;
    }
    return null;
  }

  static Future<VisionLaunchResult> openShopCameras() async {
    final dir = _serviceDir();
    if (dir == null) {
      return const VisionLaunchResult.error(
        'مجلد vision_service مش موجود جنب البرنامج.\n'
        'شغّل خدمة الرؤية مرة واحدة من فولدر التثبيت وبعدها جرّب تاني.',
      );
    }

    final python = _python(dir);
    if (python == null) {
      return const VisionLaunchResult.error(
        'مش لاقي Python بتاع خدمة الرؤية (.venv).\n'
        'اتأكد إن مجلد vision_service منسوخ كامل مع التثبيت.',
      );
    }

    if (!File(p.join(dir, 'config.yaml')).existsSync()) {
      return const VisionLaunchResult.error(
        'ملف إعدادات الكاميرات (config.yaml) مش موجود.\n'
        'ظبط الكاميرات الأول وبعدها جرّب تاني.',
      );
    }

    try {
      await Process.start(
        python,
        const ['demo.py', '--shop'],
        workingDirectory: dir,
        mode: ProcessStartMode.detached,
      );
      return const VisionLaunchResult.ok(
        'كاميرات المحل بتفتح في نافذة منفصلة — الموديل شغال عليها.',
      );
    } catch (error) {
      return VisionLaunchResult.error('تعذر تشغيل الكاميرات: $error');
    }
  }
}
