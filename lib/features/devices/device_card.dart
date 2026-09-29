import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/status_badge.dart';
import '../../core/widgets/app_buttons.dart';

enum DeviceType { ps4, ps5, billiards, vip }

extension DeviceTypeX on DeviceType {
  String get labelAr {
    switch (this) {
      case DeviceType.ps4:
        return 'PS4';
      case DeviceType.ps5:
        return 'PS5';
      case DeviceType.billiards:
        return 'بلياردو';
      case DeviceType.vip:
        return 'VIP';
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceType.ps4:
      case DeviceType.ps5:
        return Icons.sports_esports_rounded;
      case DeviceType.billiards:
        return Icons.sports_bar_rounded; // placeholder cue-sport icon
      case DeviceType.vip:
        return Icons.star_rounded;
    }
  }
}

/// Mock data model for the UI phase. The real Device model (with Drift
/// table + live session pricing calc) is built in the data-layer phase.
class DeviceUiModel {
  DeviceUiModel({
    required this.name,
    required this.type,
    required this.status,
    this.customerName,
    this.elapsed,
    this.remaining,
    this.mode,
    this.timeCost,
    this.ordersCost,
  });

  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final String? customerName;
  final String? elapsed; // formatted HH:MM:SS
  final String? remaining; // MM:SS left on a fixed-duration session
  final String? mode; // "Single" / "Multi"
  final String? timeCost;
  final String? ordersCost;
}

class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.device,
    this.compact = false,
    this.queuedSince,
    this.selectedMinutes,
    this.onSelectDuration,
    this.onSelectOpenTime,
    this.onMinutesChanged,
    this.hourlyRate = 0,
    this.onStart,
    this.onStartPackage,
    this.onOrder,
    this.onPause,
    this.onResume,
    this.onCheckout,
    this.onSwitchMode,
    this.onExtend,
  });

  final DeviceUiModel device;

  /// Compact layout for the Dashboard rows: smaller paddings, smaller
  /// timer, actions collapsed to icons — six machines fit on one screen.
  final bool compact;

  /// When this waiting device's last session finished — rendered as
  /// "منذ 12 دقيقة" so the FIFO order in the row is obvious.
  final DateTime? queuedSince;

  /// This machine's own session length (60/30/15/7), highlighted in the
  /// card's own duration chips.
  final int? selectedMinutes;

  /// Picking a duration on THIS card — each machine remembers its own.
  final ValueChanged<int>? onSelectDuration;

  /// Toggles "وقت مفتوح" (open-ended): no cap, billed per minute.
  final ValueChanged<bool>? onSelectOpenTime;

  /// Fired when the cashier types their own number of minutes (35, 90…).
  final ValueChanged<int>? onMinutesChanged;

  /// This machine's effective hourly rate — used to price those minutes
  /// instantly (rate ÷ 60 × minutes).
  final double hourlyRate;

  final VoidCallback? onStart;

  /// Starts the session as a fixed-price PACKAGE instead of per-minute
  /// billing. Only offered while the device is available.
  final VoidCallback? onStartPackage;
  final VoidCallback? onOrder;
  final VoidCallback? onPause;
  final VoidCallback? onResume;
  final VoidCallback? onCheckout;

  /// Tapping the mode badge calls this to flip single↔multi mid-session.
  /// Only relevant while active (spec: switch mode, and be able to
  /// switch it back, within the same session).
  final VoidCallback? onSwitchMode;

  /// Time is up but the players want to keep playing — pushes the
  /// deadline out and puts the device back to work.
  final VoidCallback? onExtend;

  EdgeInsets get _pad =>
      compact ? const EdgeInsets.all(AppSpacing.sm) : const EdgeInsets.all(AppSpacing.lg);

  @override
  Widget build(BuildContext context) {
    switch (device.status) {
      case DeviceStatus.available:
        return _buildAvailable();
      case DeviceStatus.active:
        return _buildActive();
      case DeviceStatus.paused:
        return _buildPaused();
      case DeviceStatus.maintenance:
        return _buildMaintenance();
      case DeviceStatus.timeup:
        return _buildTimeUp();
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Icon(device.type.icon,
            size: compact ? 14 : 18, color: AppColors.accentSecondary),
        SizedBox(width: compact ? 4 : 6),
        Flexible(
          child: Text('${device.type.labelAr} — ${device.name}',
              overflow: TextOverflow.ellipsis,
              style: compact
                  ? const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)
                  : AppTypography.cardTitle),
        ),
        const Spacer(),
        StatusBadge(status: device.status, compact: true),
      ],
    );
  }

  Widget _buildAvailable() {
    return GlassCard(
      hoverable: true,
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeader(),
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.lg),
          if (compact)
            if (queuedSince != null)
              Text('منذ ${_sinceLabel(queuedSince!)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary))
            else
              const Text('لسه ما اشتغلتش النهارده',
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textTertiary))
          else
            const Text('الجهاز متاح دلوقتي',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
          // This machine's own time. Each card keeps its own choice, so
          // one tap on the card is all it takes to start it.
          if (onSelectDuration != null) ...[
            _durationChips(),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          ],
          // Type any number of minutes (35, 90, …) and the price of that
          // time is worked out instantly from this machine's hourly rate.
          if (onMinutesChanged != null) ...[
            _minutesAndPrice(),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          ],
          if (onStartPackage != null && !compact) ...[
            Row(
              children: [
                Expanded(
                    child: SecondaryButton(
                        label: 'بباقة',
                        icon: Icons.card_giftcard_rounded,
                        onPressed: onStartPackage)),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryButton(
                      label: 'بدء جلسة',
                      icon: Icons.play_arrow_rounded,
                      onPressed: onStart,
                      expand: true),
                ),
              ],
            ),
          ] else
            PrimaryButton(
                label: compact
                    ? (selectedMinutes == null
                        ? 'بدء مفتوح'
                        : 'بدء $selectedMinutes د')
                    : 'بدء جلسة',
                icon: Icons.play_arrow_rounded,
                onPressed: onStart,
                expand: true),
        ],
      ),
    );
  }

  /// The minutes box and its price are ONE control, not three loose
  /// boxes: type the minutes on the right, read the money on the left,
  /// and flip to "وقت مفتوح" from inside the same frame.
  Widget _minutesAndPrice() {
    final open = selectedMinutes == null;
    final price = open ? 0.0 : (hourlyRate / 60) * selectedMinutes!;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.smallR,
        border: Border.all(
          color: open
              ? AppColors.glassBorderPurple
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded,
              size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          _MinutesField(
            minutes: selectedMinutes,
            borderless: true,
            onChanged: onMinutesChanged,
          ),
          _innerDivider(),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                open
                    ? 'وقت مفتوح · ${hourlyRate.toStringAsFixed(0)}/ساعة'
                    : 'EGP ${price.toStringAsFixed(2)}',
                maxLines: 1,
                style: TextStyle(
                  fontSize: open ? 11 : 15,
                  fontWeight: open ? FontWeight.w500 : FontWeight.w800,
                  color: open
                      ? AppColors.accentSecondary
                      : AppColors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          _innerDivider(),
          GestureDetector(
            onTap: () => onSelectOpenTime?.call(!open),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: open
                    ? AppColors.accentPrimary.withOpacity(0.22)
                    : Colors.transparent,
                borderRadius: AppRadius.smallR,
              ),
              child: Text('مفتوح',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: open ? FontWeight.w700 : FontWeight.w400,
                      color: open
                          ? AppColors.textPrimary
                          : AppColors.textSecondary)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _innerDivider() => Container(
        width: 1,
        height: 20,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: AppColors.glassBorder,
      );

  /// 60 / 30 / 15 / 7 minutes, sized to stay inside the compact card.
  Widget _durationChips() {
    return Row(
      children: [
        for (final minutes in const [60, 30, 15, 7]) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelectDuration!(minutes),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: compact ? 5 : 8),
                decoration: BoxDecoration(
                  color: selectedMinutes == minutes
                      ? AppColors.accentPrimary.withOpacity(0.25)
                      : AppColors.glassFill,
                  borderRadius: AppRadius.smallR,
                  border: Border.all(
                    color: selectedMinutes == minutes
                        ? AppColors.glassBorderPurple
                        : AppColors.glassBorder,
                  ),
                ),
                child: Text(
                  '$minutes',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: selectedMinutes == minutes
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: selectedMinutes == minutes
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          if (minutes != 7) const SizedBox(width: 4),
        ],
      ],
    );
  }

  /// The paid minutes are over: the device is already free (it sits in
  Widget _buildTimeUp() {
    return GlassCard(
      hoverable: true,
      padding: _pad,
      borderColor: AppColors.warning.withOpacity(0.45),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeader(),
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          Text(
            compact ? 'انتهى الوقت' : 'انتهى الوقت — اتحصّل',
            style: TextStyle(
                fontSize: compact ? 11 : 13, color: AppColors.warning),
          ),
          if (device.customerName != null)
            Text(device.customerName!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          Text(device.timeCost ?? 'EGP 0',
              style: compact
                  ? const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)
                  : AppTypography.cardTitle),
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: PrimaryButton(
                    label: compact ? 'تحصيل' : 'تحصيل',
                    icon: Icons.point_of_sale_rounded,
                    expand: true,
                    onPressed: onCheckout),
              ),
              if (onExtend != null) ...[
                const SizedBox(width: 6),
                Expanded(
                  child: SecondaryButton(
                      label: compact ? '＋ وقت' : 'كمّل وقت',
                      icon: Icons.more_time_rounded,
                      onPressed: onExtend),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  static String _sinceLabel(DateTime at) {
    final mins = DateTime.now().difference(at).inMinutes;
    if (mins < 1) return 'شوية';
    if (mins < 60) return '$mins دقيقة';
    return '${mins ~/ 60} ساعة';
  }

  Widget _buildActive() {
    return GlassCard(
      hoverable: true,
      borderColor: device.remaining == null
          ? AppColors.statusActive.withOpacity(0.4)
          : AppColors.warning.withOpacity(0.5),
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeader(),
          if (!compact) const SizedBox(height: AppSpacing.xs),
          if (device.customerName != null)
            Text(device.customerName!,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: compact ? 11 : 13)),
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          // The timer is the visual focal point (spec section 50).
          Center(
            child: FittedBox(
              child: Text(device.elapsed ?? '00:00:00',
                  style: compact
                      ? AppTypography.timer.copyWith(fontSize: 24)
                      : AppTypography.timer),
            ),
          ),
          // On a fixed-duration session the countdown is what the cashier
          // actually watches — red-ish when the last minutes are running.
          if (device.remaining != null)
            Center(
              child: Text('فاضل ${device.remaining}',
                  style: TextStyle(
                      fontSize: compact ? 11 : 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning)),
            ),
          if (device.mode != null && !compact) ...[
            const SizedBox(height: 4),
            Center(
              child: GestureDetector(
                onTap: onSwitchMode,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withOpacity(0.15),
                    borderRadius: AppRadius.smallR,
                    border: onSwitchMode != null
                        ? Border.all(color: AppColors.glassBorderPurple)
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(device.mode!,
                          style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.accentSecondary,
                              fontWeight: FontWeight.w600)),
                      if (onSwitchMode != null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.swap_horiz_rounded,
                            size: 12, color: AppColors.accentSecondary),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (compact) ...[
            const SizedBox(height: AppSpacing.xs),
            _costRow('الوقت', device.timeCost ?? '—'),
            _costRow('الإجمالي', _sumCost(), emphasize: true),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            _costRow('الوقت', device.timeCost ?? '—'),
            _costRow('الطلبات', device.ordersCost ?? '—'),
            const Divider(height: AppSpacing.md, color: AppColors.glassBorder),
            _costRow(
              'الإجمالي',
              _sumCost(),
              emphasize: true,
            ),
          ],
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          Row(
            children: [
              Expanded(
                  child: SecondaryButton(
                      label: compact ? 'طلب' : 'طلب',
                      icon: Icons.add_shopping_cart_rounded,
                      onPressed: onOrder)),
              const SizedBox(width: 6),
              Expanded(
                  child: SecondaryButton(
                      label: compact ? 'إيقاف' : 'إيقاف',
                      icon: Icons.pause_rounded,
                      onPressed: onPause)),
              const SizedBox(width: 6),
              Expanded(
                  child: PrimaryButton(
                      label: compact ? 'تحصيل' : 'تحصيل',
                      expand: true,
                      onPressed: onCheckout)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaused() {
    return GlassCard(
      hoverable: true,
      borderColor: AppColors.statusPaused.withOpacity(0.4),
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildHeader(),
          const SizedBox(height: AppSpacing.sm),
          if (device.customerName != null)
            Text(device.customerName!,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 13)),
          SizedBox(height: compact ? AppSpacing.xs : AppSpacing.md),
          Center(
            child: FittedBox(
              child: Text(device.elapsed ?? '00:00:00',
                  style: (compact
                          ? AppTypography.timer.copyWith(fontSize: 24)
                          : AppTypography.timer)
                      .copyWith(color: AppColors.textTertiary)),
            ),
          ),
          if (device.remaining != null)
            Center(
              child: Text('فاضل ${device.remaining}',
                  style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.warning)),
            ),
          if (!compact) ...[
            const SizedBox(height: 4),
            const Center(
              child: Text('الوقت متجمّد — الجلسة موقّفة',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.statusPaused)),
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          PrimaryButton(
              label: compact ? 'استئناف' : 'استئناف',
              icon: Icons.play_arrow_rounded,
              onPressed: onResume,
              expand: true),
        ],
      ),
    );
  }

  Widget _buildMaintenance() {
    return Opacity(
      opacity: 0.6,
      child: GlassCard(
        padding: _pad,
        borderColor: AppColors.statusMaintenance.withOpacity(0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildHeader(),
            const SizedBox(height: AppSpacing.sm),
            const Row(
              children: [
                Icon(Icons.build_rounded,
                    size: 16, color: AppColors.statusMaintenance),
                SizedBox(width: 6),
                Flexible(
                  child: Text('تحت الصيانة',
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: AppColors.textTertiary, fontSize: 13)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _costRow(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: compact ? 1 : 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: emphasize ? 14 : 12,
                    fontWeight: emphasize ? FontWeight.w600 : FontWeight.w400,
                    color: emphasize
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
          ),
          const SizedBox(width: 6),
          Text(value,
              style: TextStyle(
                  fontSize: emphasize ? 18 : 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
        ],
      ),
    );
  }

  // Placeholder sum for UI display only — real total comes from the
  // pricing engine built in the data-layer phase (admin-configured prices).
  String _sumCost() => device.timeCost ?? '—';
}

/// The free-form "minutes" box on a device card. It owns its controller
/// so typing is never interrupted by a rebuild, and mirrors the value when
/// a duration chip or the open-time toggle changes it from outside.
/// An empty box means "وقت مفتوح" (reported to the parent as -1).
class _MinutesField extends StatefulWidget {
  const _MinutesField({
    required this.minutes,
    this.onChanged,
    this.borderless = false,
  });

  final int? minutes;
  final ValueChanged<int>? onChanged;

  /// Sits INSIDE the unified time/price frame, so it draws no box of its
  /// own — the frame around it is the border.
  final bool borderless;

  @override
  State<_MinutesField> createState() => _MinutesFieldState();
}

class _MinutesFieldState extends State<_MinutesField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.minutes?.toString() ?? '');

  @override
  void didUpdateWidget(covariant _MinutesField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.minutes != widget.minutes) {
      final text = widget.minutes?.toString() ?? '';
      if (_controller.text != text) {
        _controller.value = TextEditingValue(
          text: text,
          selection: TextSelection.collapsed(offset: text.length),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final borderless = widget.borderless;
    return SizedBox(
      width: 46,
      height: 38,
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: (raw) {
          final minutes = int.tryParse(raw.trim());
          // -1 == "the cashier cleared the box" → back to open-ended.
          widget.onChanged?.call(minutes ?? -1);
        },
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: 'دقيقة',
          hintStyle: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          filled: !borderless,
          fillColor: AppColors.glassFillStrong,
          border: borderless
              ? InputBorder.none
              : OutlineInputBorder(
                  borderRadius: AppRadius.smallR,
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
          enabledBorder: borderless
              ? InputBorder.none
              : OutlineInputBorder(
                  borderRadius: AppRadius.smallR,
                  borderSide: const BorderSide(color: AppColors.glassBorder),
                ),
          focusedBorder: borderless
              ? InputBorder.none
              : OutlineInputBorder(
                  borderRadius: AppRadius.smallR,
                  borderSide:
                      const BorderSide(color: AppColors.glassBorderPurple),
                ),
        ),
      ),
    );
  }
}
