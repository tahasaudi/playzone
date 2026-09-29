import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/device_dao.dart';
import '../../core/database/daos/session_dao.dart';
import '../../core/database/daos/package_dao.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/offer_repository.dart';
import '../../data/repositories/package_repository.dart';
import '../../core/utils/esc_handler_provider.dart';
import '../../core/ir/ir_box_repository.dart';
import '../../core/tv/tv_power_service.dart';
import '../../core/tv/tv_display_service.dart';
import '../tv/tv_mode_screen.dart';
import '../devices/device_card.dart';
import '../devices/session_details_panel.dart';
import '../devices/checkout_modal.dart';
import '../devices/session_order_modal.dart';

/// Dashboard screen. Devices AND their live sessions come from the real
/// database; the timer/cost update every second, billed per second, and
/// a session's mode (single/multi) can be flipped mid-session any
/// number of times (spec §8-9 of the latest request).
class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  SessionBoardEntry? _selectedEntry;

  /// Sum of café invoices grouped by session (sessionId → total).
  Map<int, double> _currentOrdersBySession() {
    final invs = ref.read(todayInvoicesProvider).value ?? const [];
    final map = <int, double>{};
    for (final inv in invs) {
      if (inv.sessionId == null) continue;
      map[inv.sessionId!] = (map[inv.sessionId!] ?? 0) + inv.total;
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(devicesWithTypeProvider);
    final sessionsAsync = ref.watch(activeSessionsProvider);
    // Force a rebuild every second so the live timer/cost stay current.
    ref.watch(oneSecondTickerProvider);
    // Background watchdog: flips timed sessions to 'timeup' by themselves
    // the moment their minutes run out, releasing the device.
    ref.watch(timeUpWatcherProvider);
    // Device id → when its last session finished (FIFO for the waiting row).
    final lastFinished = ref.watch(lastFinishedByDeviceProvider).valueOrNull ??
        const <int, DateTime>{};

    // Café invoices linked to each live session — powers the real
    // "الطلبات" row on device cards, the session panel and checkout.
    final ordersBySession = _currentOrdersBySession();

    return Stack(
      children: [
        SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSpacing.sm),
              devicesAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                      child: Text('خطأ في تحميل الأجهزة: $e',
                          style: const TextStyle(color: AppColors.danger))),
                ),
                data: (devices) => _deviceSections(
                    devices, sessionsAsync.value ?? [], ordersBySession,
                    lastFinished),
              ),
            ],
          ),
        ),
        if (_selectedEntry != null)
          SessionDetailsPanel(
            device: _toUiModel(
              _selectedEntry!.device,
              _selectedEntry!.type,
              _selectedEntry!,
              ordersBySession,
            ),
            onClose: _closeSelectedEntry,
            onCheckout: () => _checkout(_selectedEntry!),
            onSwitchMode: () => _switchMode(_selectedEntry!),
            onOrder: () => _openOrderModal(_selectedEntry!),
          ),
      ],
    );
  }

  /// Three compact rows: running, waiting, maintenance. The waiting row is
  /// sorted by when each device's last session FINISHED, so two machines
  /// that ran out together get served in the order they actually ended.
  Widget _deviceSections(
    List<DeviceWithType> devices,
    List<SessionBoardEntry> sessions,
    Map<int, double> ordersBySession,
    Map<int, DateTime> lastFinished,
  ) {
    if (devices.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(
            child: Text('لا توجد أجهزة مضافة بعد',
                style: TextStyle(color: AppColors.textTertiary))),
      );
    }

    final sessionByDevice = {for (final s in sessions) s.device.id: s};
    final running = <DeviceWithType>[];
    final waiting = <DeviceWithType>[];
    final maintenance = <DeviceWithType>[];

    for (final d in devices) {
      final session = sessionByDevice[d.device.id];
      final status = session?.session.status ?? d.device.status;
      if (status == 'maintenance') {
        maintenance.add(d);
      } else if (session != null && (status == 'active' || status == 'paused')) {
        running.add(d);
      } else {
        waiting.add(d);
      }
    }

    // The roster always reads 1→2→3… (DeviceDao sorts it), and the
    // sections keep the running machines on top, so a device that starts
    // a session visibly moves up. `lastFinished` only feeds the "منذ …"
    // hint, so whoever has been waiting longest is still obvious.
    waiting.sort((a, b) =>
        compareDeviceNumbers(a.device.name, b.device.name));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section(
          'شغّال',
          AppColors.statusActive,
          devices: running,
          sessions: sessions,
          ordersBySession: ordersBySession,
          sessionByDevice: sessionByDevice,
        ),
        _section(
          'انتظار',
          AppColors.statusAvailable,
          devices: waiting,
          sessions: sessions,
          ordersBySession: ordersBySession,
          sessionByDevice: sessionByDevice,
          lastFinished: lastFinished,
        ),
        _section(
          'صيانة',
          AppColors.statusMaintenance,
          devices: maintenance,
          sessions: sessions,
          ordersBySession: ordersBySession,
          sessionByDevice: sessionByDevice,
        ),
      ],
    );
  }

  Widget _section(
    String title,
    Color color, {
    required List<DeviceWithType> devices,
    required List<SessionBoardEntry> sessions,
    required Map<int, double> ordersBySession,
    required Map<int, SessionBoardEntry> sessionByDevice,
    Map<int, DateTime>? lastFinished,
  }) {
    if (devices.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 8, height: 8,
                  decoration: BoxDecoration(
                      color: color, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: AppSpacing.sm),
              Text(title, style: AppTypography.cardTitle),
              const SizedBox(width: 6),
              Text('${devices.length}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
              if (title == 'انتظار') ...[
                const SizedBox(width: AppSpacing.md),
                const Text('الأولوية: اللي خلص وقتها الأول',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth > 1400
                ? 6
                : constraints.maxWidth > 1100
                    ? 5
                    : constraints.maxWidth > 800
                        ? 4
                        : 3;
            return GridView.count(
              crossAxisCount: columns,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: AppSpacing.sm,
              crossAxisSpacing: AppSpacing.sm,
              // Taller than wide so the card breathes: header, the
              // minutes + price row and the start button each get their
              // own space. Six machines still fit on one screen.
              childAspectRatio: 0.78,
              children: devices.map((d) {
                final session = sessionByDevice[d.device.id];
                final model = _toUiModel(
                    d.device, d.type, session, ordersBySession);
                final endedAt = lastFinished?[d.device.id];
                final deviceMinutes = durationForDevice(ref, d.device.id);
                return GestureDetector(
                  onTap: session != null ? () => _selectEntry(session) : null,
                  child: DeviceCard(
                    compact: true,
                    device: model,
                    queuedSince: endedAt,
                    selectedMinutes: deviceMinutes,
                    hourlyRate: d.effectiveHourlyRate,
                    onSelectDuration: (minutes) => _setDeviceDuration(
                        d.device.id, minutes),
                    onSelectOpenTime: (open) => _setDeviceDuration(
                        d.device.id, open ? 0 : defaultSessionMinutes),
                    onMinutesChanged: (minutes) => _setDeviceDuration(
                        d.device.id, minutes < 0 ? 0 : minutes),
                    onStart: () => _startSession(d.device.id),
                    onStartPackage:
                        session == null && d.device.status == 'available'
                            ? () => _startFromPackage(d)
                            : null,
                    onPause: session == null ? null : () => _pause(session),
                    onResume: session == null ? null : () => _resume(session),
                    onOrder:
                        session == null ? null : () => _openOrderModal(session),
                    onCheckout:
                        session == null ? null : () => _checkout(session),
                    onSwitchMode: session == null ||
                            session.session.status != 'active'
                        ? null
                        : () => _switchMode(session),
                    onExtend: session == null || !session.isTimeUp
                        ? null
                        : () => _extend(session),
                  ),
                );
              }).toList(),
            );
          }),
        ],
      ),
    );
  }

  Future<void> _openOrderModal(SessionBoardEntry entry) async {
    await showSessionOrderModal(
      context,
      sessionId: entry.session.id,
      customerId: entry.session.customerId,
      employeeId: ref.read(currentEmployeeProvider)?.id,
      deviceTitle: '${entry.type.name} — ${entry.device.name}',
    );
  }

  /// Starts a session using the duration picked ON THAT DEVICE (falling
  /// back to the top bar's default of 60).
  ///
  /// Also wakes the wall screen for this device: the TV powers on with the
  /// session and sleeps again when it is collected. The console itself
  /// follows through HDMI-CEC when the TV is the one that wakes it (PS5),
  /// and via the ESP32 IR box when one is linked.
  Future<void> _startSession(int deviceId) async {
    final employee = ref.read(currentEmployeeProvider);
    await ref.read(sessionRepositoryProvider).start(
          deviceId: deviceId,
          employeeId: employee?.id,
          plannedMinutes: durationForDevice(ref, deviceId),
        );
    _irCommand(deviceId, 'power');
    _wakeWallScreen(deviceId);
  }

  /// Turns the wall screen on and hands it back to the console, so the
  /// players see their game on the big screen while the session runs.
  ///
  /// Only the screen bound to this machine may be steered. Without that
  /// guard every checkout in the café fires at every TV, so collecting
  /// machine 2 blanks the screen out from under the players on machine 4.
  void _wakeWallScreen(int deviceId) {
    final ip = ref.read(tvConfigProvider).screenFor(deviceId);
    if (ip == null) return;
    TvPowerService.instance.turnOn(ip);
  }

  /// Remembers a duration for one machine only. 0 = وقت مفتوح.
  void _setDeviceDuration(int deviceId, int minutes) {
    ref.read(deviceDurationsProvider.notifier).state = {
      ...ref.read(deviceDurationsProvider),
      deviceId: minutes,
    };
  }

  /// Time is up but the players want to keep going: push the deadline out
  /// by that machine's own duration and put the device back to work.
  /// An open-ended device falls back to the café default (60 min).
  Future<void> _extend(SessionBoardEntry entry) async {
    final minutes = durationForDevice(ref, entry.device.id) ??
        defaultSessionMinutes;
    await ref.read(sessionRepositoryProvider).extend(entry, minutes);
    _irCommand(entry.device.id, 'power');
    _wakeWallScreen(entry.device.id);
  }

  /// Session collected: the console goes to sleep and the wall screen goes
  /// black. This TV refuses a network power-off, so "off" is a black frame —
  /// one push, no polling, so the screen darkens straight away.
  ///
  /// Same ownership rule as `_wakeWallScreen`: collecting any other machine
  /// must never touch this screen.
  void _sleepWallScreen(int deviceId) {
    final ip = ref.read(tvConfigProvider).screenFor(deviceId);
    if (ip == null) return;
    TvPowerService.instance.turnOff(ip);
    // A screen that will not take the command has to be told, or the
    // cashier walks away thinking the TV is off when it is still lit.
    Future<void>.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final message = TvPowerService.instance.lastResult;
      if (message == null || !message.contains('الريموت')) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        duration: const Duration(seconds: 4),
      ));
    });
  }

  /// "بدء بباقة" — shows the active packages that apply to this device's
  /// type, and starts a flat-price session for the chosen one.
  Future<void> _startFromPackage(DeviceWithType device) async {
    final packages =
        (ref.read(activePackagesProvider).valueOrNull ?? const [])
            .where((p) => p.package.deviceTypeId == device.type.id)
            .toList();
    if (packages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('مفيش باقات متاحة لنوع الجهاز ده')));
      return;
    }
    final chosen = await showDialog<PackageWithType>(
      context: context,
      builder: (_) => _PackagePickerDialog(
        deviceName: '${device.type.name} — ${device.device.name}',
        packages: packages,
      ),
    );
    if (chosen == null) return;
    final employee = ref.read(currentEmployeeProvider);
    await ref.read(sessionRepositoryProvider).start(
          deviceId: device.device.id,
          employeeId: employee?.id,
          packageId: chosen.package.id,
          fixedPrice: chosen.package.fixedPrice,
        );
    _irCommand(device.device.id, 'power');
  }

  Future<void> _pause(SessionBoardEntry entry) async {
    await ref.read(sessionRepositoryProvider).pause(entry);
  }

  Future<void> _resume(SessionBoardEntry entry) async {
    await ref.read(sessionRepositoryProvider).resume(entry);
  }

  Future<void> _switchMode(SessionBoardEntry entry) async {
    final newMode = entry.session.mode == 'multi' ? 'single' : 'multi';
    await ref.read(sessionRepositoryProvider).switchMode(entry, newMode);
  }

  Future<void> _checkout(SessionBoardEntry entry) async {
    // A live happy-hour offer pre-fills the discount (percentage only;
    // fixed offers are applied as an explicit EGP discount by staff).
    final offer = ref.read(currentActiveOfferProvider).valueOrNull;
    final discountRate =
        offer != null && offer.active && offer.discountType == 'percentage'
            ? offer.discountValue
            : 0.0;
    // Freeze the amount at the moment the modal opens — the clock keeps
    // ticking, but the customer was quoted this price. The repository
    // uses this same frozen value for the final bill.
    final baseCost = entry.liveCost;

    await showCheckoutModal(
      context,
      _toUiModel(entry.device, entry.type, entry, _currentOrdersBySession()),
      timeCost: baseCost,
      customerId: entry.session.customerId,
      customerPoints: entry.customer?.loyaltyPoints ?? 0,
      discountRate: discountRate,
      onConfirm: (result) async {
        await ref.read(sessionRepositoryProvider).checkout(
              entry,
              ref.read(appDatabaseProvider).invoiceDao,
              discount: result.discount,
              redeemedPoints: result.redeemedPoints,
              paidCash: result.paidCash,
              paidCard: result.paidCard,
              collectedTimeCost: baseCost,
            );
        // The bill is saved, so the screen can go dark immediately. Both
        // commands are fire-and-forget: the cashier must never wait on the
        // network, and the invoice is already written either way.
        _irCommand(entry.device.id, 'power');
        _sleepWallScreen(entry.device.id);
      },
    );
    if (mounted) _closeSelectedEntry();
  }

  /// يبعت أمر IR للبورد الخاص بالستارة (لو مربوط). سلوك "صوت المهمة":
  /// في بدء الجلسة "power" بتشغل الشاشة → البلايستيشن يفيق (CEC)،
  /// وبعد التحصيل نفس الصوت بيطفيها. مفيش صوت مرتبط = نتجاهل بهدوء.
  Future<void> _irCommand(int deviceId, String slot) async {
    final links = ref.read(irBoxLinksProvider);
    final box = ref.read(irBoxRepositoryProvider).boxFor(deviceId, links);
    if (box == null) return;
    final ok = await box.send(slot);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('تعذّر إرسال أمر IR — تأكد من اتصال البورد بالشبكة')));
    }
  }

  /// Opens the session panel AND registers it with the global ESC
  /// handler, so pressing Escape closes it just like a real dialog
  /// would — even though it's a Stack overlay, not a Navigator route.
  void _selectEntry(SessionBoardEntry entry) {
    setState(() => _selectedEntry = entry);
    ref.read(escCloseHandlerProvider.notifier).state = _closeSelectedEntry;
  }

  void _closeSelectedEntry() {
    setState(() => _selectedEntry = null);
    ref.read(escCloseHandlerProvider.notifier).state = null;
  }

  DeviceUiModel _toUiModel(DeviceRow device, DeviceTypeRow type,
    SessionBoardEntry? session, Map<int, double> ordersBySession) {
    final ordersTotal =
        session == null ? 0.0 : (ordersBySession[session.session.id] ?? 0.0);
    return DeviceUiModel(
      name: device.name,
      type: _mapType(type.name),
      status: _mapStatus(session?.session.status ?? device.status),
      customerName: session?.customer?.name,
      elapsed: session == null ? null : _formatDuration(session.elapsedActiveMinutes),
      remaining: session == null ? null : _formatRemaining(session.remainingMinutes),
      mode: session == null ? null : (session.session.mode == 'multi' ? 'مالتي' : 'فردي'),
      timeCost: session == null ? null : 'EGP ${session.liveCost.toStringAsFixed(2)}',
      ordersCost: session == null
          ? null
          : 'EGP ${ordersTotal.toStringAsFixed(2)}',
    );
  }

  /// Countdown on a fixed-duration session: "MM:SS" (or "HH:MM:SS" past an
  /// hour). Null for open-ended / package sessions.
  String? _formatRemaining(double? minutes) {
    if (minutes == null) return null;
    final totalSeconds = (minutes * 60).round();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    return h > 0
        ? '$h:$mm:$ss'
        : '$mm:$ss';
  }

  String _formatDuration(double minutes) {
    final totalSeconds = (minutes * 60).round();
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  DeviceType _mapType(String typeName) {
    switch (typeName) {
      case 'PS4':
        return DeviceType.ps4;
      case 'PS5':
        return DeviceType.ps5;
      case 'بلياردو':
        return DeviceType.billiards;
      case 'VIP':
        return DeviceType.vip;
      default:
        return DeviceType.ps5;
    }
  }

  DeviceStatus _mapStatus(String status) {
    switch (status) {
      case 'active':
        return DeviceStatus.active;
      case 'paused':
        return DeviceStatus.paused;
      case 'timeup':
        return DeviceStatus.timeup;
      case 'maintenance':
        return DeviceStatus.maintenance;
      case 'available':
      case 'reserved':
      default:
        return DeviceStatus.available;
    }
  }
}

/// Small picker for "بدء بباقة": lists the active packages for a device
/// type and returns the chosen one.
class _PackagePickerDialog extends StatelessWidget {
  const _PackagePickerDialog({required this.deviceName, required this.packages});
  final String deviceName;
  final List<PackageWithType> packages;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر باقة', style: AppTypography.sectionTitle),
            const SizedBox(height: 2),
            Text(deviceName, style: AppTypography.secondary),
            const SizedBox(height: AppSpacing.lg),
            for (final p in packages) ...[
              GestureDetector(
                onTap: () => Navigator.of(context).pop(p),
                child: GlassCard(
                  hoverable: true,
                  child: Row(
                    children: [
                      const Icon(Icons.card_giftcard_rounded,
                          size: 20, color: AppColors.accentSecondary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.package.name,
                                style: AppTypography.cardTitle),
                            const SizedBox(height: 2),
                            Text('${p.package.durationMinutes} دقيقة',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary)),
                          ],
                        ),
                      ),
                      Text('EGP ${p.package.fixedPrice.toStringAsFixed(0)}',
                          style: AppTypography.cardTitle),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}
