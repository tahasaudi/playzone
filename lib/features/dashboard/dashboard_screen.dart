import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
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

  /// Sessions already auto-darkened at their deadline — so the moment a
  /// session flips to "timeup" the matching screen is put out exactly
  /// once, and nobody has to touch anything.
  final Set<int> _timeUpHandledSessionIds = {};
  bool _seenInitialTimeUp = false;

  /// Watches the live session board for the instant a fixed-duration
  /// session runs out, and blanks that device's screen on its own —
  /// fire-and-forget, silent, through the same TV/IR gates the rest of
  /// the app uses (on this machine those gates are off: no bytes leave).
  void _onSessionsChanged(List<SessionBoardEntry> sessions) {
    final nowTimeUp =
        sessions.where((s) => s.session.status == 'timeup').toList();
    // On first load, sessions that were ALREADY time-up are left alone —
    // their screens are already dark, re-firing could toggle one back on.
    if (!_seenInitialTimeUp) {
      _seenInitialTimeUp = true;
      _timeUpHandledSessionIds.addAll(nowTimeUp.map((s) => s.session.id));
      return;
    }
    for (final s in nowTimeUp) {
      if (!_timeUpHandledSessionIds.add(s.session.id)) continue;
      _autoDarkenScreen(s.device.id);
    }
  }

  /// "وقت انتهى → الشاشة تطفي" — same owner-gate as checkout: only a
  /// screen bound to this machine is steered (TvPowerService), plus a
  /// linked IR box if any. Silent by design, no snackbar, fire & forget.
  void _autoDarkenScreen(int deviceId) {
    final ip = ref.read(tvConfigProvider).screenFor(deviceId);
    if (ip != null) TvPowerService.instance.turnOff(ip);
    final links = ref.read(irBoxLinksProvider);
    final box = ref.read(irBoxRepositoryProvider).boxFor(deviceId, links);
    if (box != null) box.send('power'); // ignore result on purpose
  }

  /// The café's roster reads in this order (device numbers): 1, 2, 4, 5, 6
  /// then 3 — the machines' physical layout at the counter. Any device
  /// outside the list keeps its natural number order after them.
  static const _rosterPriority = [1, 2, 4, 5, 6, 3];

  int _rosterRank(DeviceWithType d) {
    final n = deviceNumberOf(d.device.name);
    if (n == null) return 500;
    final i = _rosterPriority.indexOf(n);
    return i == -1 ? 400 : i;
  }

  int _rosterCompare(DeviceWithType a, DeviceWithType b) {
    final rank = _rosterRank(a).compareTo(_rosterRank(b));
    return rank != 0
        ? rank
        : compareDeviceNumbers(a.device.name, b.device.name);
  }

  double _rateFor(DeviceWithType d, String mode) =>
      mode == 'multi' && d.effectiveHourlyRateMulti > 0
          ? d.effectiveHourlyRateMulti
          : d.effectiveHourlyRate;

  String _modeForDevice(int deviceId) =>
      ref.read(deviceModesProvider)[deviceId] ?? 'single';

  /// Money (EGP) → the minutes it buys at [rate], or null (open-ended).
  int? _minutesFromAmount(double? amount, double rate) {
    if (amount == null || amount <= 0 || rate <= 0) return null;
    final m = (amount * 60 / rate).floor();
    return m < 1 ? null : m;
  }

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

  /// What one live session ordered, one line per product — "مياه ×2 — 40.00".
  ///
  /// Merged by description rather than listed line by line, because the till
  /// writes a fresh invoice line per tap: a customer who asked for three waters
  /// gets three lines, and the panel would then say the same thing three times
  /// while looking longer than it is. Quantity is folded into the label and
  /// the money is summed, so the panel shows what was ordered rather than how
  /// many times the cashier touched the screen.
  List<String> _orderLinesFor(SessionBoardEntry entry) {
    final rows =
        ref.watch(sessionOrderLinesProvider(entry.session.id)).valueOrNull ??
            const <InvoiceItemRow>[];
    final qty = <String, int>{};
    final money = <String, double>{};
    final order = <String>[];
    for (final r in rows) {
      final key = r.description.trim();
      if (key.isEmpty) continue;
      if (!qty.containsKey(key)) order.add(key);
      qty[key] = (qty[key] ?? 0) + r.quantity;
      money[key] = (money[key] ?? 0) + r.total;
    }
    return [
      for (final key in order)
        '${qty[key]! > 1 ? '${qty[key]}× ' : ''}$key — '
            '${(money[key] ?? 0).toStringAsFixed(2)}',
    ];
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
    // When a session's clock hits zero, darken its screen without anyone
    // touching a button.
    ref.listen<AsyncValue<List<SessionBoardEntry>>>(activeSessionsProvider,
        (_, next) {
      final list = next.valueOrNull;
      if (list != null) _onSessionsChanged(list);
    });
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
                data: (devices) => _deviceSections(devices,
                    sessionsAsync.value ?? [], ordersBySession, lastFinished),
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
              orderLines: _orderLinesFor(_selectedEntry!),
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

    // The roster always reads in the café's own order (1→2→4→5→6→3), then
    // the devices sort themselves into running/waiting/maintenance rows.
    final ordered = List.of(devices)..sort(_rosterCompare);

    for (final d in ordered) {
      final session = sessionByDevice[d.device.id];
      final status = session?.session.status ?? d.device.status;
      if (status == 'maintenance') {
        maintenance.add(d);
      } else if (session != null &&
          (status == 'active' || status == 'paused')) {
        running.add(d);
      } else {
        waiting.add(d);
      }
    }

    // The roster always reads in the café's own order (the [Dashboard]
    // rank above), and the sections keep the running machines on top, so
    // a device that starts a session visibly moves up. `lastFinished`
    // only feeds the "منذ …" hint, so whoever has been waiting longest is
    // still obvious.
    waiting.sort(_rosterCompare);

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
              Container(
                  width: 8,
                  height: 8,
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
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textTertiary)),
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
// Taller than wide so the card breathes: header, mode
              // toggles, the minutes + money row and the start button
              // each get their own space.
              //
              // 0.65 rather than 0.7: a RUNNING card now carries the same two mode
              // chips an empty card does, which is one row taller. The chips were
              // not squeezed or restyled to make it fit - the row was given the room it
              // needs, because a card that measures its own controls differently
              // depending on whether somebody is playing is worse than a card that
              // is a few pixels taller.
              childAspectRatio: 0.65,
              children: devices.map((d) {
                final session = sessionByDevice[d.device.id];
                final model =
                    _toUiModel(d.device, d.type, session, ordersBySession);
                final endedAt = lastFinished?[d.device.id];
                final deviceMinutes = durationForDevice(ref, d.device.id);
                final deviceAmount =
                    ref.read(deviceAmountsProvider)[d.device.id];
                final deviceMode = _modeForDevice(d.device.id);
                return GestureDetector(
                  onTap: session != null ? () => _selectEntry(session) : null,
                  child: DeviceCard(
                    compact: true,
                    device: model,
                    queuedSince: endedAt,
                    selectedMinutes: deviceMinutes,
                    selectedAmount: deviceAmount,
                    selectedMode: deviceMode,
                    hourlyRate: d.effectiveHourlyRate,
                    multiHourlyRate: d.effectiveHourlyRateMulti,
                    onSelectMode: (mode) => _setDeviceMode(d, mode),
                    onSelectDuration: (minutes) =>
                        _setDeviceDuration(d, minutes),
                    onSelectOpenTime: (open) =>
                        _setDeviceDuration(d, open ? 0 : defaultSessionMinutes),
                    onAmountChanged: (amount) => _setDeviceAmount(d, amount),
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
                    onSwitchMode:
                        session == null || session.session.status != 'active'
                            ? null
                            : () => _switchMode(session),
                    onSwitchModeTo:
                        session == null || session.session.status != 'active'
                            ? null
                            : (mode) => _switchModeTo(session, mode),
                    onToggleScreen: session == null
                        ? null
                        : () => _toggleWallScreen(session),
                    onExtend: session == null || !session.isTimeUp
                        ? null
                        : () => _openExtendDialog(session),
                    onExtendCustom:
                        session == null || session.session.status != 'active'
                            ? null
                            : () => _openExtendDialog(session),
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
          mode: _modeForDevice(deviceId),
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

  /// Remembers a duration for one machine only. 0 = وقت مفتوح. The money
  /// field mirrors what that time costs, so the two never disagree.
  void _setDeviceDuration(DeviceWithType d, int minutes) {
    final mode = _modeForDevice(d.device.id);
    final rate = _rateFor(d, mode);
    ref.read(deviceDurationsProvider.notifier).state = {
      ...ref.read(deviceDurationsProvider),
      d.device.id: minutes,
    };
    final amounts = {...ref.read(deviceAmountsProvider)};
    if (minutes <= 0) {
      amounts.remove(d.device.id);
    } else {
      amounts[d.device.id] = (rate / 60) * minutes;
    }
    ref.read(deviceAmountsProvider.notifier).state = amounts;
  }

  /// The cashier typed money: keep the amount, and work the minutes back
  /// from it at this machine's mode rate. An empty box means "وقت مفتوح".
  void _setDeviceAmount(DeviceWithType d, double? amount) {
    final mode = _modeForDevice(d.device.id);
    final rate = _rateFor(d, mode);
    final minutes = _minutesFromAmount(amount, rate);
    final durations = {...ref.read(deviceDurationsProvider)};
    if (minutes == null) {
      durations.remove(d.device.id);
    } else {
      durations[d.device.id] = minutes;
    }
    ref.read(deviceDurationsProvider.notifier).state = durations;
    final amounts = {...ref.read(deviceAmountsProvider)};
    if (amount == null || amount <= 0) {
      amounts.remove(d.device.id);
    } else {
      amounts[d.device.id] = amount;
    }
    ref.read(deviceAmountsProvider.notifier).state = amounts;
  }

  /// فردي ↔ مالتي: the same money is re-priced at the other rate, so the
  /// time shown on the card follows immediately.
  void _setDeviceMode(DeviceWithType d, String mode) {
    ref.read(deviceModesProvider.notifier).state = {
      ...ref.read(deviceModesProvider),
      d.device.id: mode,
    };
    final amount = ref.read(deviceAmountsProvider)[d.device.id];
    if (amount != null && amount > 0) _setDeviceAmount(d, amount);
  }

  /// "＋ وقت": the cashier types minutes OR money and the session gets
  /// that much time, at the session's current mode rate. Reached from the
  /// run-time card (mid-session) AND from the time-up card — the popup
  /// never skips the cashier's choice.
  Future<void> _openExtendDialog(SessionBoardEntry entry) async {
    final minutes = await showDialog<int>(
      context: context,
      builder: (_) => _ExtendTimeDialog(
        sessionTitle: '${entry.type.name} — ${entry.device.name}',
        modeLabel: entry.session.mode == 'multi' ? 'مالتي' : 'فردي',
        rate: _sessionRateFor(entry),
      ),
    );
    if (minutes == null || minutes <= 0) return;
    await ref.read(sessionRepositoryProvider).extend(entry, minutes);
    _timeUpHandledSessionIds.remove(entry.session.id);
    // If it came in from a time-up card the screen must come back on;
    // a running session leaves its screen alone either way.
    if (entry.session.status == 'timeup') {
      _irCommand(entry.device.id, 'power');
      _wakeWallScreen(entry.device.id);
    }
  }

  /// The rate the given session bills at right now (its own mode).
  double _sessionRateFor(SessionBoardEntry e) {
    final multi =
        e.device.customHourlyRateMulti ?? e.type.defaultHourlyRateMulti;
    final single = e.device.customHourlyRate ?? e.type.defaultHourlyRate;
    if (e.session.mode == 'multi' && multi > 0) return multi;
    return single;
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
    final packages = (ref.read(activePackagesProvider).valueOrNull ?? const [])
        .where((p) => p.package.deviceTypeId == device.type.id)
        .toList();
    if (packages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مفيش باقات متاحة لنوع الجهاز ده')));
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

  /// The machine's own wall switch, one button for both directions.
  ///
  /// Whatever the previous press on this card did, this one undoes. The
  /// cashier never has to remember which way round the button goes, and
  /// nothing has to be read before pressing it.
  void _toggleWallScreen(SessionBoardEntry entry) {
    final ip = ref.read(tvConfigProvider).screenFor(entry.device.id);
    if (ip == null) return;
    final power = TvPowerService.instance;
    if (power.isScreenDark(ip)) {
      power.turnOn(ip);
    } else {
      power.turnOff(ip);
    }
  }

  /// Stopping the clock stops the machines too.
  ///
  /// Players walk away for a smoke and the billiard table keeps running, the
  /// console keeps playing and someone walks in and plays. Pausing the time is
  /// exactly the moment to close the wall, and resuming is the moment to open
  /// it — which is why this one button's two halves are wired to the same two
  /// buttons the card already has.
  Future<void> _pause(SessionBoardEntry entry) async {
    await ref.read(sessionRepositoryProvider).pause(entry);
    final ip = ref.read(tvConfigProvider).screenFor(entry.device.id);
    if (ip != null) TvPowerService.instance.turnOff(ip);
  }

  Future<void> _resume(SessionBoardEntry entry) async {
    await ref.read(sessionRepositoryProvider).resume(entry);
    final ip = ref.read(tvConfigProvider).screenFor(entry.device.id);
    if (ip != null) TvPowerService.instance.turnOn(ip);
  }

  Future<void> _switchMode(SessionBoardEntry entry) async {
    final newMode = entry.session.mode == 'multi' ? 'single' : 'multi';
    await ref.read(sessionRepositoryProvider).switchMode(entry, newMode);
  }

  /// The card's two chips name the mode they move to, so this is the honest
  /// form of [\_switchMode]: tapping "فردي" on a session already on "فردي"
  /// asks for the mode it is already in, and doing nothing is the correct
  /// answer to that — not a write that would re-cut the segment and re-price
  /// the minutes the players have already served.
  Future<void> _switchModeTo(SessionBoardEntry entry, String mode) async {
    if (entry.session.mode == mode) return;
    await ref.read(sessionRepositoryProvider).switchMode(entry, mode);
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

  DeviceUiModel _toUiModel(
    DeviceRow device,
    DeviceTypeRow type,
    SessionBoardEntry? session,
    Map<int, double> ordersBySession, {
    List<String> orderLines = const <String>[],
  }) {
    final ordersTotal =
        session == null ? 0.0 : (ordersBySession[session.session.id] ?? 0.0);
    final ip = ref.read(tvConfigProvider).screenFor(device.id);
    return DeviceUiModel(
      name: device.name,
      type: _mapType(type.name),
      status: _mapStatus(session?.session.status ?? device.status),
      customerName: session?.customer?.name,
      elapsed: session == null
          ? null
          : _formatDuration(session.elapsedActiveMinutes),
      remaining:
          session == null ? null : _formatRemaining(session.remainingMinutes),
      mode: session == null
          ? null
          : (session.session.mode == 'multi' ? 'مالتي' : 'فردي'),
      isMultiMode: session?.session.mode == 'multi',
      timeCost:
          session == null ? null : 'EGP ${session.liveCost.toStringAsFixed(2)}',
      ordersCost:
          session == null ? null : 'EGP ${ordersTotal.toStringAsFixed(2)}',
      orderLines: orderLines,
      wallScreenDark: ip != null && TvPowerService.instance.isScreenDark(ip),
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
    return h > 0 ? '$h:$mm:$ss' : '$mm:$ss';
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

/// "＋ وقت" dialog on a running device card: the cashier types minutes OR
/// money — the two fields mirror each other at the session's current mode
/// rate — and confirming pushes the deadline out by that much time.
class _ExtendTimeDialog extends StatefulWidget {
  const _ExtendTimeDialog({
    required this.sessionTitle,
    required this.modeLabel,
    required this.rate,
  });

  final String sessionTitle;
  final String modeLabel;
  final double rate;

  @override
  State<_ExtendTimeDialog> createState() => _ExtendTimeDialogState();
}

class _ExtendTimeDialogState extends State<_ExtendTimeDialog> {
  final _minutesCtrl = TextEditingController();
  final _moneyCtrl = TextEditingController();
  final _minutesFocus = FocusNode();
  final _moneyFocus = FocusNode();
  int _resultMinutes = 0;

  @override
  void dispose() {
    _minutesCtrl.dispose();
    _moneyCtrl.dispose();
    _minutesFocus.dispose();
    _moneyFocus.dispose();
    super.dispose();
  }

  void _onMinutes(String raw) {
    final m = int.tryParse(raw.trim());
    _resultMinutes = m == null || m <= 0 ? 0 : m;
    if (_resultMinutes > 0 && !_moneyFocus.hasFocus) {
      final money = (_resultMinutes * widget.rate / 60).round();
      _moneyCtrl.value = TextEditingValue(
        text: money.toString(),
        selection: TextSelection.collapsed(offset: money.toString().length),
      );
    }
    setState(() {});
  }

  void _onMoney(String raw) {
    final amount = double.tryParse(raw.trim());
    var m =
        amount == null || amount <= 0 ? 0 : (amount * 60 / widget.rate).floor();
    if (m < 1) m = 0;
    _resultMinutes = m;
    if (m > 0 && !_minutesFocus.hasFocus) {
      _minutesCtrl.value = TextEditingValue(
        text: m.toString(),
        selection: TextSelection.collapsed(offset: m.toString().length),
      );
    }
    setState(() {});
  }

  Widget _field({
    required bool money,
    required FocusNode focus,
    required TextEditingController ctrl,
    required String hint,
    required ValueChanged<String> onChanged,
  }) {
    return TextField(
      controller: ctrl,
      focusNode: focus,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.center,
      onChanged: onChanged,
      style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
        filled: true,
        fillColor: AppColors.glassFill,
        border: OutlineInputBorder(
          borderRadius: AppRadius.smallR,
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallR,
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.smallR,
          borderSide: const BorderSide(color: AppColors.glassBorderPurple),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
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
            const Text('إضافة وقت للجلسة', style: AppTypography.sectionTitle),
            const SizedBox(height: 2),
            Text(widget.sessionTitle, style: AppTypography.secondary),
            const SizedBox(height: AppSpacing.md),
            Text(
              'السعر الحالي: EGP ${widget.rate.round()}/ساعة'
              ' (${widget.modeLabel}) · الدقيقة ≈ '
              '${(widget.rate / 60).toStringAsFixed(1)}',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('الدقائق', style: AppTypography.secondary),
                      const SizedBox(height: 6),
                      _field(
                        money: false,
                        focus: _minutesFocus,
                        ctrl: _minutesCtrl,
                        hint: '30',
                        onChanged: _onMinutes,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('المبلغ (EGP)',
                          style: AppTypography.secondary),
                      const SizedBox(height: 6),
                      _field(
                        money: true,
                        focus: _moneyFocus,
                        ctrl: _moneyCtrl,
                        hint: '50',
                        onChanged: _onMoney,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'اكتب أي واحد منهما — التاني بيتظبط لوحده',
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'إلغاء',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: 'إضافة',
                    icon: Icons.add_rounded,
                    expand: true,
                    onPressed: _resultMinutes > 0
                        ? () => Navigator.of(context).pop(_resultMinutes)
                        : null,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small picker for "بدء بباقة": lists the active packages for a device
/// type and returns the chosen one.
class _PackagePickerDialog extends StatelessWidget {
  const _PackagePickerDialog(
      {required this.deviceName, required this.packages});
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
