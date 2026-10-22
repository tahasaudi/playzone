import 'dart:io';
import 'dart:typed_data';

/// What a video file actually contains, read from its own header.
///
/// The questions this answers are the two the wall always raises: *why is
/// there black down both sides of the screen?* and *is this file any good?*
/// Both are answered by the file's own dimensions, and neither is answered by
/// anything the program sends — the television pulls the file byte for byte,
/// so the picture on the wall is exactly the picture in the file.
///
/// Reading the header is enough; no part of the movie is decoded, so this
/// costs a few kilobytes and answers immediately, before the film is even
/// handed to the screen.
class VideoInfo {
  const VideoInfo({
    required this.width,
    required this.height,
    required this.container,
  });

  final int width;
  final int height;

  /// 'mp4' for an ISO base media file, 'mpeg' for an MPEG program stream.
  final String container;

  /// Width over height.
  double get aspect => height == 0 ? 0 : width / height;

  /// True when the picture is wider than 16:9 by a useful margin — the shape
  /// that fills a wall with no bars at all.
  bool get isFullWidth => aspect >= 1.68;

  /// True for the old 4:3 shape, which is what puts a black band down each
  /// side of a widescreen television.
  bool get isFourThree => aspect > 0 && aspect < 1.55;

  /// A short, honest description for the screen: `1280×720 (16:9)`.
  String get label => '$width×$height (${_ratioName(aspect)})';

  static String _ratioName(double a) {
    if (a <= 0) return '؟';
    if (a >= 1.95) return 'فائض';
    if (a >= 1.76) return '16:9';
    if (a >= 1.6) return '16:10';
    if (a >= 1.45) return '3:2';
    if (a >= 1.2) return '4:3';
    return 'مربع';
  }
}

/// Reads the dimensions out of a video file's header.
///
/// Returns null when the file is not a container this understands — an
/// unknown file is not an error, it just means we have nothing to say about
/// its shape.
Future<VideoInfo?> probeVideo(File file) async {
  try {
    final ext = file.path.split('.').last.toLowerCase();
    if (ext == 'mp4' || ext == 'm4v' || ext == 'mov') {
      return await _probeIso(file);
    }
    if (ext == 'mpg' || ext == 'mpeg' || ext == 'ts') {
      return await _probeMpegPs(file);
    }
    return null;
  } catch (_) {
    return null;
  }
}

/// ISO base media (MP4/M4V/MOV): the picture size lives in the track header.
Future<VideoInfo?> _probeIso(File file) async {
  final raf = await file.open();
  try {
    // The track header is inside `moov`, which is normally at the end of the
    // file for a file written on a phone or a TV, and at the front for one
    // written by a desktop encoder. Both are walked.
    final size = await raf.length();
    for (final chunk in <int>[0, (size - 4 * 1024 * 1024).clamp(0, size)]) {
      final info = await _scanIsoAt(raf, chunk, size);
      if (info != null) return info;
    }    return null;
  } finally {
    await raf.close();
  }
}

Future<VideoInfo?> _scanIsoAt(RandomAccessFile raf, int from, int total) async {
  await raf.setPosition(from);
  var offset = from;
  while (offset < total) {
    final header = await raf.read(8);
    if (header.length < 8) return null;
    final size = ByteData.sublistView(header).getUint32(0);
    final type = String.fromCharCodes(header.sublist(4, 8));
    var boxSize = size;
    var headerSize = 8;
    if (size == 1) {
      final ext = await raf.read(8);
      if (ext.length < 8) return null;
      boxSize = ByteData.sublistView(ext).getUint64(0);
      headerSize = 16;
    } else if (size == 0) {
      boxSize = total - offset;
    }
    if (boxSize < headerSize) return null;
    if (type == 'moov') {
      final body = await raf.read(boxSize - headerSize);
      final found = _findTkhd(body);
      if (found != null) {
        return VideoInfo(width: found.$1, height: found.$2, container: 'mp4');
      }
      return null;
    }
    // Skip this box. `mdat` is the movie itself and can be enormous, so it is
    // jumped over rather than read.
    await raf.setPosition(offset + boxSize);
    offset += boxSize;
  }
  return null;
}

/// Finds the picture size in the track headers of a `moov` box.
(int, int)? _findTkhd(Uint8List moov) {
  final data = ByteData.sublistView(moov);
  var best = (0, 0);
  var i = 0;
  while (i + 8 <= moov.length) {
    final size = data.getUint32(i);
    final type = String.fromCharCodes(moov.sublist(i + 4, i + 8));
    var boxSize = size;
    var headerSize = 8;
    if (size == 1) {
      if (i + 16 > moov.length) break;
      boxSize = data.getUint64(i + 8);
      headerSize = 16;
    } else if (size == 0) {
      boxSize = moov.length - i;
    }
    if (boxSize < headerSize) break;
    if (type == 'trak') {
      final trak = moov.sublist(i + headerSize, i + boxSize);
      final found = _tkhdSize(trak);
      if (found != null && found.$1 > 0 && found.$2 > 0) {
        if (found.$1 * found.$2 > best.$1 * best.$2) best = found;
      }
    }
    i += boxSize;
  }
  return best.$1 > 0 ? best : null;
}

/// The picture size is the last eight bytes of a track header: two 16.16
/// fixed point numbers.
///
/// The tag sits four bytes into the box, so the version byte follows the tag
/// and the size sits at the very end of the box.
(int, int)? _tkhdSize(Uint8List trak) {
  final index = _indexOf(trak, 'tkhd');
  if (index < 0 || index + 8 > trak.length) return null;
  final data = ByteData.sublistView(trak);
  final version = trak[index + 4];
  final base = index + 8 + (version == 1 ? 32 : 20) + 16 + 36;
  if (base + 8 > trak.length) return null;
  final width = data.getUint32(base) >> 16;
  final height = data.getUint32(base + 4) >> 16;
  return (width, height);
}

int _indexOf(Uint8List data, String tag) {
  for (var i = 0; i + 4 <= data.length; i++) {
    if (data[i] == tag.codeUnitAt(0) &&
        data[i + 1] == tag.codeUnitAt(1) &&
        data[i + 2] == tag.codeUnitAt(2) &&
        data[i + 3] == tag.codeUnitAt(3)) {
      return i;
    }
  }
  return -1;
}

/// MPEG program stream (.mpg/.mpeg): the size is in the sequence header.
Future<VideoInfo?> _probeMpegPs(File file) async {
  final raf = await file.open();
  try {
    final chunkSize = 256 * 1024;
    var carry = Uint8List(0);
    var scanned = 0;
    while (scanned < 16 * 1024 * 1024) {
      final chunk = await raf.read(chunkSize);
      if (chunk.isEmpty) break;
      scanned += chunk.length;
      final buffer = Uint8List(carry.length + chunk.length)
        ..setRange(0, carry.length, carry)
        ..setRange(carry.length, carry.length + chunk.length, chunk);
      final found = _findSequenceHeader(buffer);
      if (found != null) return found;
      carry = buffer.sublist(buffer.length - 8 < 0 ? 0 : buffer.length - 8);
    }
    return null;
  } finally {
    await raf.close();
  }
}

VideoInfo? _findSequenceHeader(Uint8List data) {
  for (var i = 0; i + 9 < data.length; i++) {
    if (data[i] == 0x00 &&
        data[i + 1] == 0x00 &&
        data[i + 2] == 0x01 &&
        data[i + 3] == 0xB3) {
      final b0 = data[i + 4];
      final b1 = data[i + 5];
      final b2 = data[i + 6];
      final width = (b0 << 4) | (b1 >> 4);
      final height = ((b1 & 0x0F) << 8) | b2;
      if (width > 16 && height > 16) {
        return VideoInfo(width: width, height: height, container: 'mpeg');
      }
    }
  }
  return null;
}
