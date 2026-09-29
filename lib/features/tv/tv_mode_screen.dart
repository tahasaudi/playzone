import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/device_dao.dart';
import '../../core/database/daos/session_dao.dart';
import '../../core/database/database_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/tv/tv_display_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/session_repository.dart';
import 'tv_cards.dart';

/// Settings for the wall screens, persisted in the app's settings table.
///
/// The café has two: a 55" by the PS4 corner and a 65" by the PS5 corner.
/// Each is bound to one machine, so a checkout anywhere else in the shop
/// never touches it.
class TvConfig {
  const TvConfig({
    this.ip = '192.168.1.22',
    this.enabled = true,
    this.mirror = true,
    this.showCards = false,
    this.deviceId,
    this.secondIp = '',
    this.secondDeviceId,
  });

  final String ip;
  final bool enabled;

  /// Also show a "cast me" hint (Windows Win+K) — the guaranteed path.
  final bool mirror;

  /// Show the session cards ON the TV. Off by default: the wall screen is
  /// used as a power switch (it wakes with the session and sleeps when it
  /// ends), not as a customer-facing timer.
  final bool showCards;

  /// Which device this wall screen belongs to. Null = show every running
  /// session. When set (e.g. PS4 #2), the TV keeps showing THAT machine
  /// only — running or idle, so a screen in the PS4 corner belongs to a
  /// single console.
  final int? deviceId;

  /// The second wall screen, same idea. An empty [secondIp] disables it.
  final String secondIp;
  final int? secondDeviceId;

  bool get hasSecond => secondIp.trim().isNotEmpty;

  /// The address of the screen that follows [deviceId], or null when no
  /// screen is bound to that machine.
  String? screenFor(int deviceId) {
    if (!enabled) return null;
    if (this.deviceId != null && this.deviceId == deviceId) {
      return ip.trim().isEmpty ? null : ip;
    }
    if (hasSecond && secondDeviceId == deviceId) return secondIp;
    return null;
  }

  /// Every address we may need to talk to, for eager discovery.
  Iterable<String> get addresses => [
        if (enabled && ip.trim().isNotEmpty) ip,
        if (enabled && hasSecond) secondIp,
      ];

  TvConfig copyWith({
    String? ip,
    bool? enabled,
    bool? mirror,
    bool? showCards,
    int? deviceId,
    String? secondIp,
    int? secondDeviceId,
    bool clearDevice = false,
    bool clearSecondDevice = false,
  }) =>
      TvConfig(
        ip: ip ?? this.ip,
        enabled: enabled ?? this.enabled,
        mirror: mirror ?? this.mirror,
        showCards: showCards ?? this.showCards,
        deviceId: clearDevice ? null : (deviceId ?? this.deviceId),
        secondIp: secondIp ?? this.secondIp,
        secondDeviceId: clearSecondDevice
            ? null
            : (secondDeviceId ?? this.secondDeviceId),
      );
}

class TvConfigNotifier extends StateNotifier<TvConfig> {
  TvConfigNotifier(this._db) : super(const TvConfig());

  final AppDatabase _db;

  static const ipKey = 'tv_ip';
  static const enabledKey = 'tv_enabled';
  static const deviceKey = 'tv_device_id';
  static const cardsKey = 'tv_show_cards';
  static const secondIpKey = 'tv_ip_2';
  static const secondDeviceKey = 'tv_device_id_2';

  Future<void> load() async {
    final ip = await _db.settingsDao.getValue(ipKey);
    final enabled = await _db.settingsDao.getValue(enabledKey);
    final device = await _db.settingsDao.getValue(deviceKey);
    final cards = await _db.settingsDao.getValue(cardsKey);
    final ip2 = await _db.settingsDao.getValue(secondIpKey);
    final device2 = await _db.settingsDao.getValue(secondDeviceKey);
    if (ip != null && ip.isNotEmpty) {
      state = state.copyWith(
        ip: ip,
        enabled: enabled != '0',
        showCards: cards == '1',
        deviceId: _parseDevice(device),
        secondIp: ip2 ?? '',
        secondDeviceId: _parseDevice(device2),
      );
    } else {
      // First run: remember the detected TV so the push starts on its own.
      setIp(state.ip);
      setEnabled(true);
    }
  }

  static int? _parseDevice(String? raw) =>
      (raw == null || raw.isEmpty || raw == 'all') ? null : int.tryParse(raw);

  /// Show the session cards on the TV itself (off = it is only a power
  /// switch for the wall screen).
  void setShowCards(bool value) {
    state = state.copyWith(showCards: value);
    _db.settingsDao.setValue(cardsKey, value ? '1' : '0');
  }

  /// Binds the first wall screen to one device (null = every session).
  void setDevice(int? deviceId) {
    state = state.copyWith(
      deviceId: deviceId,
      clearDevice: deviceId == null,
    );
    _db.settingsDao.setValue(deviceKey, deviceId?.toString() ?? 'all');
  }

  /// Binds the second wall screen to one device.
  void setSecondDevice(int? deviceId) {
    state = state.copyWith(
      secondDeviceId: deviceId,
      clearSecondDevice: deviceId == null,
    );
    _db.settingsDao.setValue(secondDeviceKey, deviceId?.toString() ?? 'all');
  }

  void setSecondIp(String value) {
    final clean = value.trim();
    state = state.copyWith(secondIp: clean);
    _db.settingsDao.setValue(secondIpKey, clean);
  }

  void setIp(String value) {
    final clean = value.trim();
    state = state.copyWith(ip: clean);
    _db.settingsDao.setValue(ipKey, clean);
  }

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
    _db.settingsDao.setValue(enabledKey, value ? '1' : '0');
  }
}

final tvConfigProvider = StateNotifierProvider<TvConfigNotifier, TvConfig>((ref) {
  final notifier = TvConfigNotifier(ref.watch(appDatabaseProvider));
  // Without this the notifier keeps its in-memory defaults forever, so the
  // saved screen bindings are ignored and no screen ever matches a machine.
  unawaited(notifier.load());
  return notifier;
});

/// Toggles the bare, fullscreen board used when the PC is being cast to
/// the wall TV (Win+K) — nothing but the cards on screen.
final fullscreenTvProvider = StateProvider<bool>((ref) => false);

/// Live snapshot for the status line.
final tvPushStatusProvider = StreamProvider<TvStatus>((ref) async* {  final service = TvDisplayService.instance;
  while (true) {
    yield TvStatus(
      running: service.isRunning,
      fetched: service.tvFetched,
      lastPush: service.lastPushAt,
      error: service.lastError,
      localAddress: service.localAddress,
      imageBytes: service.lastImageBytes,
      imagesServed: service.imagesServed,
    );
    await Future<void>.delayed(const Duration(seconds: 2));
  }
});

class TvStatus {
  const TvStatus({
    required this.running,
    required this.fetched,
    required this.lastPush,
    required this.error,
    required this.localAddress,
    this.imageBytes = 0,
    this.imagesServed = 0,
  });

  final bool running;
  final bool fetched;
  final DateTime? lastPush;
  final String? error;
  final String? localAddress;
  final int imageBytes;
  final int imagesServed;
}

/// The customer-facing screen: a clean card per running session, big
/// enough to read from across the room, and mirrored to the LG TV every
/// second (DLNA push) or by Windows screen casting.
class TvModeScreen extends ConsumerStatefulWidget {
  const TvModeScreen({super.key, this.fullscreen = false, this.onExit});

  /// Fullscreen = nothing but the cards, so a wall TV (via Win+K) shows a
  /// clean board with no app chrome.
  final bool fullscreen;
  final VoidCallback? onExit;

  @override
  ConsumerState<TvModeScreen> createState() => _TvModeScreenState();
}

class _TvModeScreenState extends ConsumerState<TvModeScreen> {
  final GlobalKey _captureKey = GlobalKey();
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Capture right AFTER a frame is painted — the only safe moment for
    // toImage(), and it repeats about once a second.
    _schedule();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    TvDisplayService.instance.stopPushing();
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

  /// Snapshots the visible board and hands it to the TV service.
  Future<void> _tick() async {
    final service = TvDisplayService.instance;
    if (!service.isRunning || !mounted) return;
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

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(tvConfigProvider);
    final sessionsAsync = ref.watch(activeSessionsProvider);
    final statusAsync = ref.watch(tvPushStatusProvider);
    // The board itself ticks every second, so the timer on the wall moves.
    ref.watch(oneSecondTickerProvider);

    // Keep the pusher aligned with the config.
    final service = TvDisplayService.instance;
    if (config.enabled && config.ip.isNotEmpty) {
      if (!service.isRunning) service.startServer();
      service.startPushing(tvIp: config.ip);
    } else {
      service.stopPushing();
    }

    return sessionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e')),
      data: (sessions) {
        // The wall screen can be bound to ONE machine: then it always shows
        // that device (running card or a calm idle card), which is what you
        // want for a screen hanging in the PS4 corner.
        final devices = ref.watch(devicesWithTypeProvider).valueOrNull ??
            const <DeviceWithType>[];
        final boundId = config.deviceId;
        final boundDevice = boundId == null
            ? null
            : devices.where((d) => d.device.id == boundId).firstOrNull;
        final boundSession = boundId == null
            ? null
            : sessions.where((s) => s.device.id == boundId).firstOrNull;
        final boundName = boundDevice == null
            ? null
            : '${boundDevice.type.name} — ${boundDevice.device.name}';

        final body = boundId != null
            ? Center(
                child: SizedBox(
                  width: 640,
                  height: 420,
                  child: boundSession != null
                      ? TvSessionCard(entry: boundSession)
                      : _idleCard(boundName),
                ),
              )
            : sessions.isEmpty
                ? _idleCard(null)
                : _grid(sessions);

        return _shell(
          statusAsync.valueOrNull,
          Column(
            children: [
              _devicePicker(sessions, devices, boundId, (id) =>
                  ref.read(tvConfigProvider.notifier).setDevice(id)),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: RepaintBoundary(
                  key: _captureKey,
                  child: body,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// What the wall screen shows when its machine is free.
  Widget _idleCard(String? deviceName) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.heroR,
        border: Border.all(color: AppColors.glassBorder, width: 2),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(deviceName ?? 'PlayZone',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            const Text('الجهاز متاح — في انتظار لاعب',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 26, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }

  Widget _shell(TvStatus? status, Widget child) {
    if (widget.fullscreen) {
      return Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: child,
            ),
          ),
          if (widget.onExit != null)
            Positioned(
              top: AppSpacing.md,
              right: AppSpacing.md,
              child: Opacity(
                opacity: 0.35,
                child: SecondaryButton(
                  label: 'خروج',
                  icon: Icons.close_rounded,
                  onPressed: widget.onExit,
                ),
              ),
            ),
        ],
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Text('شاشة التلفزيون',
                  style: AppTypography.sectionTitle),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _statusPill(status)),
              const SizedBox(width: AppSpacing.md),
              SecondaryButton(
                label: 'ملء الشاشة',
                icon: Icons.fullscreen_rounded,
                onPressed: () => ref.read(fullscreenTvProvider.notifier).state = true,
              ),
              const SizedBox(width: AppSpacing.sm),
              SecondaryButton(
                label: 'بثّ الآن (Win+K)',
                icon: Icons.cast_rounded,
                onPressed: () => _showCastHint(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(child: child),
        ],
      ),
    );
  }

  void _showCastHint(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      duration: Duration(seconds: 6),
      content: Text(
          'دوس Win+K (أو Cast) → اختار التلفزيون → اختار "الجهاز". الشاشة دي هتبان على التلفزيون.'),
    ));
  }

  Widget _statusPill(TvStatus? status) {
    final ok = status?.fetched == true;
    final noImage = (status?.imageBytes ?? 0) == 0;
    final color = ok
        ? AppColors.statusAvailable
        : (status?.error != null || noImage
            ? AppColors.warning
            : AppColors.textTertiary);
    final label = ok
        ? 'التلفزيون بيبثّ دلوقتي'
        : noImage
            ? 'افتح شاشة التلفزيون لبثّ الصورة'
            : (status?.error ?? 'في انتظار أول بثّ…');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.smallR,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ok ? Icons.tv_rounded : Icons.tv_off_rounded,
              size: 15, color: color),
          const SizedBox(width: 6),
          Text(label,
              style: TextStyle(fontSize: 12, color: color)),
        ],
      ),
    );
  }

  /// The picker writes straight to the saved config, so the binding
  /// survives restarts: this screen belongs to that machine for good.
  Widget _devicePicker(
    List<SessionBoardEntry> sessions,
    List<DeviceWithType> devices,
    int? focus,
    ValueChanged<int?> onPick,
  ) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        _pickerChip('كل الأجهزة', focus == null, () => onPick(null)),
        for (final d in devices)
          _pickerChip('${d.type.name} — ${d.device.name}', focus == d.device.id,
              () => onPick(d.device.id)),
        // Machines that are free right now still need to be pickable, and
        // they are already covered by `devices`; running ones are implied.
        if (devices.isEmpty)
          for (final s in sessions)
            _pickerChip('${s.type.name} — ${s.device.name}', focus == s.device.id,
                () => onPick(s.device.id)),
      ],
    );
  }

  Widget _pickerChip(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? AppColors.accentPrimary.withOpacity(0.2)
              : AppColors.glassFill,
          borderRadius: AppRadius.smallR,
          border: Border.all(
              color:
                  active ? AppColors.glassBorderPurple : AppColors.glassBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                color: active
                    ? AppColors.textPrimary
                    : AppColors.textSecondary)),
      ),
    );
  }

  Widget _grid(List<SessionBoardEntry> sessions) {
    return LayoutBuilder(builder: (context, c) {
      final columns = c.maxWidth > 1100
          ? 3
          : c.maxWidth > 700
              ? 2
              : 1;
      return GridView.count(
        crossAxisCount: columns,
        mainAxisSpacing: AppSpacing.lg,
        crossAxisSpacing: AppSpacing.lg,
        childAspectRatio: 1.5,
        children: sessions.map((e) => TvSessionCard(entry: e)).toList(),
      );
    });
  }
}

