import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/device_dao.dart';
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

  @override
  void initState() {
    super.initState();
    _schedule();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _schedule() {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _tick();
      if (mounted) {
        _ticker = Timer(const Duration(milliseconds: 900), _schedule);
      }
    });
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
    try {
      final image = await boundary.toImage(pixelRatio: 1);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) return;
      await service.publish(data.buffer.asUint8List());
    } catch (e) {
      service.noteCaptureError(e);
    }
  }

  bool get _cardsVisible {
    final config = _config;
    if (!config.enabled || config.ip.isEmpty) return false;
    return config.showCards;
  }

  TvConfig get _config => ref.read(tvConfigProvider);
  bool get _hasRunningSession {
    final bound = _config.deviceId;
    if (bound == null) return true; // unbound: any session counts
    return ref
            .read(activeSessionsProvider)
            .valueOrNull
            ?.any((s) => s.device.id == bound) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(tvConfigProvider);
    // One-second tick: the wall clock has to move, and it also keeps a
    // frame flowing so the capture below can run.
    ref.watch(oneSecondTickerProvider);
    final sessions =
        ref.watch(activeSessionsProvider).valueOrNull ?? const <SessionBoardEntry>[];

    // The capture boundary only needs to exist in cards mode; without it
    // there is nothing to photograph and the preview would be dead weight.
    if (!config.enabled || config.ip.isEmpty || !config.showCards) {
      return const SizedBox.shrink();
    }

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
