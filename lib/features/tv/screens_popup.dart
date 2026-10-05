import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/device_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/tv/tv_display_service.dart';
import '../../core/tv/tv_power_service.dart';
import '../../core/tv/tv_screen_report.dart';
import '../../data/repositories/device_repository.dart';
import 'tv_mode_screen.dart';

/// Opens the screens panel: every wall, in the café's walk order, with the one
/// command each needs.
///
/// It exists because the question it answers comes up at the wrong moment. The
/// screens page is a configuration page: it is where a wall is bound to a
/// machine, named and diagnosed, and it reads as work. But the thing staff
/// actually want at closing time is much smaller — *which screen is still on,
/// and turn it off* — and getting that meant walking through the whole page to
/// find one panel.
///
/// So this is the same list, the same words and the same commands, over the
/// board instead of behind a menu.
Future<void> showScreensPopup(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black54,
    builder: (_) => const _ScreensPopup(),
  );
}

class _ScreensPopup extends ConsumerStatefulWidget {
  const _ScreensPopup();

  @override
  ConsumerState<_ScreensPopup> createState() => _ScreensPopupState();
}

class _ScreensPopupState extends ConsumerState<_ScreensPopup> {
  final TextEditingController _query = TextEditingController();

  /// True while the whole-room sweep is running, so the button can say so
  /// instead of looking broken for ten seconds.
  bool _sweeping = false;

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Screens in the café's walk order — the order the board reads, so a person
  /// with a remote in one hand is matching the same numbers they see all day.
  /// Slots with nothing bound go to the bottom, and the storage index settles
  /// ties so the list cannot shuffle itself while it is being read.
  List<TvScreenSlot> _inRoomOrder(
    List<TvScreenSlot> slots,
    Map<int, String> deviceNameById,
  ) {
    final ordered = List.of(slots);
    ordered.sort((a, b) {
      final rank = compareDeviceNumbers(
        deviceNameById[a.deviceId] ?? '',
        deviceNameById[b.deviceId] ?? '',
      );
      return rank != 0 ? rank : a.index.compareTo(b.index);
    });
    return ordered;
  }

  /// Whether [slot] is what the cashier typed.
  ///
  /// Matched on everything they might know the screen by — the name on the
  /// wall, the machine behind it, the number of either, or the address — so
  /// "3" finds the third machine whether they thought of it as a machine, a
  /// screen or an IP. Digits are also matched against the machine number
  /// alone, because "1" must not light up screen 11.
  bool _matches(TvScreenSlot slot, String q, String deviceName) {
    if (q.isEmpty) return true;
    final needle = q.toLowerCase();
    final ip = slot.ip.trim();
    if (slot.name.toLowerCase().contains(needle)) return true;
    if (ip.toLowerCase().contains(needle)) return true;
    if (deviceName.toLowerCase().contains(needle)) return true;
    return _hasNumber(deviceName, needle) || _hasNumber(slot.name, needle);
  }

  /// Whole-number hit, so "1" means machine 1 and never machine 11.
  bool _hasNumber(String source, String needle) {
    if (needle.isEmpty || int.tryParse(needle) == null) return false;
    return RegExp(r'\d+').allMatches(source).any((m) => m.group(0) == needle);
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ));
  }

  /// Opens one wall. Deliberately NOT a toggle: the button says what it will
  /// do, and it does that. A single switch per screen would mean pressing
  /// "افتح" on a screen that was already on switched it off — and the moment
  /// that happens nobody trusts the button again.
  void _open(String ip, String name) {
    TvPowerService.instance.turnOn(ip);
    _say('بنفتح $name');
    setState(() {});
  }

  void _close(String ip, String name) {
    TvPowerService.instance.turnOff(ip);
    _say('بنقفل $name');
    setState(() {});
  }

  /// Looks for every screen at once — the case where the whole room has to be
  /// found again after the router or the café power came back, which is
  /// exactly when nobody wants to press the same button five times.
  void _findAll(List<TvScreenSlot> slots) {
    if (_sweeping) return;
    setState(() => _sweeping = true);
    _say('بندوّر على كل الشاشات… استنى ثانية');
    for (final slot in slots) {
      final ip = slot.ip.trim();
      if (ip.isNotEmpty) TvDisplayService.instance.rediscover(ip);
    }
    // A sweep is the best part of ten seconds. Saying so is the honest thing to
    // do; a button that goes quiet looks broken and gets pressed again.
    Future<void>.delayed(const Duration(seconds: 12), () {
      if (!mounted) return;
      setState(() => _sweeping = false);
      _say('خلصنا البحث عن كل الشاشات');
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(tvConfigProvider);
    final reports = ref.watch(tvScreenReportsProvider).valueOrNull ??
        TvDisplayService.instance.reports();
    final devices = List.of(ref.watch(devicesWithTypeProvider).valueOrNull ??
        const <DeviceWithType>[])
      ..sort((a, b) => compareDeviceNumbers(a.device.name, b.device.name));
    final deviceNameById = {
      for (final d in devices) d.device.id: d.device.name,
    };

    final all = _inRoomOrder(config.slots, deviceNameById);
    final q = _query.text.trim();
    final visible = <TvScreenSlot>[
      for (final slot in all)
        if (_matches(slot, q, deviceNameById[slot.deviceId] ?? '')) slot,
    ];

    return Dialog(
      backgroundColor: AppColors.glassFill,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.heroR,
        side: const BorderSide(color: AppColors.glassBorder),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 620, maxHeight: 620),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(all.length, visible.length),
              const SizedBox(height: AppSpacing.md),
              _searchField(),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: all.isEmpty
                    ? _empty('لسه مفيش شاشات متسجله')
                    : visible.isEmpty
                        ? _empty('مفيش شاشة اسمها «$_query»')
                        : ListView.separated(
                            shrinkWrap: true,
                            itemCount: visible.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (_, i) {
                              final slot = visible[i];
                              return _ScreenRow(
                                ip: slot.ip.trim(),
                                report: _findReport(reports, slot.ip.trim()),
                                deviceName: deviceNameById[slot.deviceId] ?? '',
                                onOpen: () => _open(
                                  slot.ip.trim(),
                                  _labelFor(slot, deviceNameById),
                                ),
                                onClose: () => _close(
                                  slot.ip.trim(),
                                  _labelFor(slot, deviceNameById),
                                ),
                              );
                            },
                          ),
              ),
              const SizedBox(height: AppSpacing.md),
              _footer(all),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(int total, int shown) {
    return Row(
      children: [
        const Icon(Icons.tv_rounded,
            size: 20, color: AppColors.accentSecondary),
        const SizedBox(width: AppSpacing.sm),
        const Expanded(
          child: Text('الشاشات',
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ),
        Text('$shown من $total', style: AppTypography.secondary),
        const SizedBox(width: AppSpacing.sm),
        _pillButton(
          icon: Icons.close_rounded,
          tooltip: 'إغلاق',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _searchField() {
    return TextField(
      controller: _query,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
      cursorColor: AppColors.accentPrimary,
      decoration: InputDecoration(
        isDense: true,
        hintText: 'دور على شاشة بالاسم أو الرقم',
        hintStyle: AppTypography.secondary,
        prefixIcon: const Icon(Icons.search_rounded,
            size: 18, color: AppColors.textTertiary),
        suffixIcon: _query.text.isEmpty
            ? null
            : IconButton(
                icon: const Icon(Icons.backspace_rounded,
                    size: 16, color: AppColors.textTertiary),
                onPressed: () => setState(_query.clear),
              ),
        filled: true,
        fillColor: AppColors.glassFillStrong,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mediumR,
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumR,
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumR,
          borderSide: const BorderSide(color: AppColors.glassBorderPurple),
        ),
      ),
    );
  }

  /// Bottom bar. The room-wide search sits bottom-LEFT, the way the whole app
  /// puts its one global action there, so the muscle memory holds.
  ///
  /// It always sweeps the whole room, whatever the filter above is showing.
  /// The button says "all the screens", and a button that quietly means "the
  /// one you filtered to" is how you end up hunting one wall while the other
  /// four are still up.
  Widget _footer(List<TvScreenSlot> all) {
    return Row(
      children: [
        _pillButton(
          icon: _sweeping
              ? Icons.hourglass_top_rounded
              : Icons.travel_explore_rounded,
          label: _sweeping ? 'بندوّر…' : 'دور على كل الشاشات',
          busy: _sweeping,
          onTap: () => _findAll(all),
        ),
        const Spacer(),
        _pillButton(
          label: 'إغلاق',
          onTap: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _empty(String message) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
        child: Center(child: Text(message, style: AppTypography.secondary)),
      );

  String _labelFor(TvScreenSlot slot, Map<int, String> deviceNameById) {
    final name = slot.name.trim();
    if (name.isNotEmpty) return name;
    final device = deviceNameById[slot.deviceId] ?? '';
    return device.isEmpty ? slot.ip.trim() : device;
  }

  TvScreenReport? _findReport(List<TvScreenReport> reports, String ip) {
    for (final r in reports) {
      if (r.identity.ip == ip) return r;
    }
    return null;
  }
}

/// One wall, with the two commands that move it.
class _ScreenRow extends StatelessWidget {
  const _ScreenRow({
    required this.ip,
    required this.report,
    required this.deviceName,
    required this.onOpen,
    required this.onClose,
  });

  final String ip;
  final TvScreenReport? report;
  final String deviceName;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final name = (r?.identity.name ?? '').trim();
    final title =
        name.isNotEmpty ? name : (deviceName.isNotEmpty ? deviceName : ip);
    final state = r?.label ?? 'مش معروف';
    final dark = TvPowerService.instance.isScreenDark(ip);
    final tone = _toneFor(r);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm + 2),
      decoration: BoxDecoration(
        color: AppColors.glassFillStrong.withOpacity(0.55),
        borderRadius: AppRadius.mediumR,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: tone.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_iconFor(r), size: 18, color: tone),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary)),
                    ),
                    if (deviceName.isNotEmpty && name.isNotEmpty) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Text('· $deviceName', style: AppTypography.secondary),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  ip.isEmpty ? 'من غير عنوان' : '$ip  ·  $state',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (ip.isEmpty)
            const Text('مفيش عنوان', style: AppTypography.secondary)
          else ...[
            _commandButton(
              label: 'افتح',
              icon: Icons.power_settings_new_rounded,
              tone: AppColors.success,
              filled: dark,
              onTap: onOpen,
            ),
            const SizedBox(width: AppSpacing.sm),
            _commandButton(
              label: 'غمض',
              icon: Icons.nightlight_round,
              tone: AppColors.textSecondary,
              filled: !dark,
              onTap: onClose,
            ),
          ],
        ],
      ),
    );
  }

  static Color _toneFor(TvScreenReport? r) => switch (r?.severity) {
        TvSeverity.bad => AppColors.danger,
        TvSeverity.warn => AppColors.warning,
        _ => AppColors.success,
      };

  static IconData _iconFor(TvScreenReport? r) => switch (r?.state) {
        TvScreenState.unreachable => Icons.nightlight_round,
        TvScreenState.unbound => Icons.link_off_rounded,
        TvScreenState.noAddress => Icons.wifi_off_rounded,
        TvScreenState.disabled => Icons.toggle_off_rounded,
        TvScreenState.loading => Icons.hourglass_top_rounded,
        _ => Icons.tv_rounded,
      };

  /// The command the pressed button represents, drawn in its own colour only
  /// when it is the one that matches the wall right now — so the lit button is
  /// always the honest answer to "what is it doing", and never decoration.
  Widget _commandButton({
    required String label,
    required IconData icon,
    required Color tone,
    required bool filled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Ink(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: filled ? tone.withOpacity(0.18) : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: filled ? tone.withOpacity(0.7) : AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15, color: filled ? tone : AppColors.textTertiary),
              const SizedBox(width: 5),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: filled ? tone : AppColors.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}

/// The small square button the header and the footer share.
Widget _pillButton({
  IconData? icon,
  String? label,
  String? tooltip,
  bool busy = false,
  required VoidCallback onTap,
}) {
  final child = Container(
    height: 34,
    padding: EdgeInsets.symmetric(horizontal: label == null ? 8 : 12),
    decoration: BoxDecoration(
      color: AppColors.glassFillStrong,
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: AppColors.textSecondary),
          if (label != null) const SizedBox(width: 6),
        ],
        if (label != null)
          Text(label,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
      ],
    ),
  );
  final button = Material(
    color: Colors.transparent,
    child: InkWell(
      borderRadius: BorderRadius.circular(9),
      onTap: busy ? null : onTap,
      child: Ink(decoration: child.decoration!, child: child),
    ),
  );
  return tooltip == null ? button : Tooltip(message: tooltip, child: button);
}
