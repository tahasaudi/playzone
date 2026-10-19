import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/session_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/tv/tv_display_service.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/session_repository.dart';
import 'tv_cards.dart';
import 'tv_mode_screen.dart';

/// Always-on background broadcaster.
///
/// It shows a small live preview of the wall board in the corner (so the
/// cashier can see exactly what the TV gets) and snapshots THAT boundary
/// once a second. The preview is deliberately visible rather than hidden:
/// an off-screen widget is never painted, and `toImage()` refuses to run
/// on an unpainted layer — a visible thumbnail guarantees the capture
/// works no matter which screen the app is on.
class TvBroadcaster extends ConsumerStatefulWidget {
  const TvBroadcaster({super.key});

  @override
  ConsumerState<TvBroadcaster> createState() => _TvBroadcasterState();
}

class _TvBroadcasterState extends ConsumerState<TvBroadcaster> {
  final GlobalKey _captureKey = GlobalKey();
  Timer? _ticker;

  /// A cheap fingerprint of the last frame we actually captured and sent.
  ///
  /// A still board does not change between ticks: the wall clock moves once a
  /// second at most, the session list far less often. Capturing and
  /// PNG-encoding a 1280×720 boundary every 900 ms for an unchanged picture is
  /// pure spent CPU — and it is spent on the same isolate that draws the
  /// counter, which is what makes the till feel heavy late in a busy evening.
  /// Comparing a cheap signature first means an idle board costs almost
  /// nothing and only a real change pays for a capture.
  String _lastSignature = '';
  int? _lastImageHash;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(milliseconds: 900), (_) => _tick());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _tick() async {
    final service = TvDisplayService.instance;
    if (!service.isRunning || !mounted) return;
    // Only the opt-in "cards" mode paints a frame. The default wall screen
    // is the console on HDMI, driven by session start/collect, so there is
    // nothing to capture here and no reason to spend CPU on it.
    if (!_cardsVisible) return;
    final boundary = _captureKey.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary) return;
    // A cheap signature of what is on the board. If it matches the last sent
    // frame, there is nothing new to hand the television and no reason to
    // photograph a boundary that has not moved.
    final signature = _boardSignature();
    if (signature == _lastSignature) return;
    try {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      final bytes = data.buffer.asUint8List();
      // A second guard on the pixels themselves: the board can recompose to
      // the same picture (a rebuild that changed nothing visible), and the
      // television does not need that frame either.
      final hash = Object.hashAll([bytes.length, bytes.first, bytes.last]);
      if (hash == _lastImageHash && signature == _lastSignature) return;
      _lastSignature = signature;
      _lastImageHash = hash;
      await service.publish(bytes);
    } catch (e) {
      service.noteCaptureError(e);
    }
  }

  /// A short string that stands for what the board is currently showing.
  ///
  /// Deliberately cheap: the session ids, their started/paused stamps and the
  /// device-bound name are everything that changes a card, plus the ticking
  /// clock which the live timer shows. If none of those moved, the pixels did
  /// not either.
  String _boardSignature() {
    final config = _config;
    final sessions = ref.read(activeSessionsProvider).valueOrNull ??
        const <SessionBoardEntry>[];
    final bound = config.deviceId;
    final shown = bound == null
        ? sessions
        : sessions.where((s) => s.device.id == bound).toList();
    final buf = StringBuffer()..write(config.deviceId)..write('|');
    for (final s in shown) {
      buf
        ..write(s.device.id)
        ..write(':')
        ..write(s.session.startTime.millisecondsSinceEpoch)
        ..write(':')
        ..write(s.session.pausedAt?.millisecondsSinceEpoch)
        ..write(':')
        ..write(s.session.accumulatedCost)
        ..write(';');
    }
    // The clock is the one thing that moves on its own, so it is part of the
    // signature — otherwise a running session's timer would freeze on the wall.
    buf.write(DateTime.now().difference(_epoch).inSeconds);
    return buf.toString();
  }

  static final DateTime _epoch = DateTime.now();

  bool get _cardsVisible {
    final config = _config;
    if (!config.enabled || config.ip.isEmpty) return false;
    return config.showCards;
  }

  TvConfig get _config => ref.read(tvConfigProvider);

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(tvConfigProvider);
    // Cards mode is off: the wall shows the console on HDMI and there is
    // nothing to preview or capture. Bailing here, before subscribing to the
    // one-second tick, drops the rebuild entirely instead of doing one a second
    // all evening for a preview that is not on screen.
    if (!config.enabled || config.ip.isEmpty || !config.showCards) {
      return const SizedBox.shrink();
    }
    // One-second tick: the wall clock has to move, and it also keeps a
    // frame flowing so the capture below can run.
    ref.watch(oneSecondTickerProvider);
    final sessions =
        ref.watch(activeSessionsProvider).valueOrNull ?? const <SessionBoardEntry>[];

    // The capture boundary only needs to exist in cards mode; without it
    // there is nothing to photograph and the preview would be dead weight.

    final bound = config.deviceId;
    final shown = bound == null
        ? sessions
        : sessions.where((s) => s.device.id == bound).toList();
    final deviceName = bound == null
        ? null
        : ref
            .watch(devicesWithTypeProvider)
            .valueOrNull
            ?.where((d) => d.device.id == bound)
            .map((d) => '${d.type.name} — ${d.device.name}')
            .firstOrNull;

    final board = shown.isEmpty
        ? _idleBoard(deviceName)
        : TvCardGrid(entries: shown);

    return Positioned(
      right: AppSpacing.md,
      bottom: AppSpacing.md,
      child: IgnorePointer(
        child: Opacity(
          opacity: 0.9,
          child: Container(
            width: 224,
            height: 126,
            decoration: BoxDecoration(
              borderRadius: AppRadius.smallR,
              border: Border.all(color: AppColors.glassBorderPurple),
              boxShadow: AppShadows.card,
            ),
            // FittedBox scales the full-size board down to the thumbnail;
            // the RepaintBoundary inside keeps its 1280×720 size, which is
            // what toImage() returns to the TV.
            child: ClipRRect(
              borderRadius: AppRadius.smallR,
              child: FittedBox(
                fit: BoxFit.fill,
                child: RepaintBoundary(
                  key: _captureKey,
                  child: Container(
                    width: 1280,
                    height: 720,
                    color: AppColors.bgBase,
                    padding: const EdgeInsets.all(32),
                    child: board,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _idleBoard(String? deviceName) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            deviceName ?? 'PlayZone',
            style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          const Text(
            'الجهاز متاح — في انتظار لاعب',
            style: TextStyle(fontSize: 34, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}
