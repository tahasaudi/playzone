import 'dart:io';

import 'package:playzone/core/tv/video_probe.dart';

void main(List<String> args) async {
  for (final dir in args) {
    final d = Directory(dir);
    if (!d.existsSync()) {
      print('DIR MISSING: $dir');
      continue;
    }
    print('--- $dir ---');
    final files = d
        .listSync()
        .whereType<File>()
        .where((f) {
          final p = f.path.toLowerCase();
          return p.endsWith('.mpg') ||
              p.endsWith('.mp4') ||
              p.endsWith('.mpeg') ||
              p.endsWith('.m4v');
        })
        .toList();
    for (final f in files) {
      final len = await f.length();
      final info = await probeVideo(f);
      print('${f.path.split(RegExp(r'[\/\\]')).last} | '
          '${(len / 1048576).toStringAsFixed(1)}MB | '
          '${info?.label ?? "unknown"} | wide=${info?.isFullWidth} | 4:3=${info?.isFourThree}');
    }
  }
}
