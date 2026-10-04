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
    this.isMultiMode = false,
    this.timeCost,
    this.ordersCost,
    this.orderLines = const <String>[],
  });

  final String name;
  final DeviceType type;
  final DeviceStatus status;
  final String? customerName;
  final String? elapsed; // formatted HH:MM:SS
  final String? remaining; // MM:SS left on a fixed-duration session
  final String? mode; // "Single" / "Multi"

  /// Whether the live session is running on the "مالتي" rate, kept beside
  /// [mode] so a card can light the right chip without having to match the
  /// Arabic label back to a rate.
  final bool isMultiMode;
  final String? timeCost;
  final String? ordersCost;

  /// What the customer actually ordered, one line per item —
  /// "مياه ×2 — 40.00", already formatted and summed per product.
  ///
  /// A sum alone answers "how much", which is the question the cashier asks
  /// while they are charging. It does not answer "ordered what", which is the
  /// question they ask when the customer says they did not, and that is the
  /// one worth being able to answer without opening the till.
  final List<String> orderLines;
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
    this.onAmountChanged,
    this.onSelectMode,
    this.selectedAmount,
    this.selectedMode = 'single',
    this.hourlyRate = 0,
    this.multiHourlyRate = 0,
    this.onStart,
    this.onStartPackage,
    this.onOrder,
    this.onPause,
    this.onResume,
    this.onCheckout,
    this.onSwitchMode,
    this.onSwitchModeTo,
    this.onExtend,
    this.onExtendCustom,
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

  /// Fired when the cashier types an amount of money — the card walks it
  /// back to minutes at this machine's rate (type EGP, read the time).
  final ValueChanged<double?>? onAmountChanged;

  /// Fired when the cashier picks "فردي" or "مالتي" — changes which hourly
  /// rate prices the time/money.
  final ValueChanged<String>? onSelectMode;

  /// The amount last typed for this machine (EGP) — mirrors the minutes
  /// the cashier already chose, so the money field never lies.
  final double? selectedAmount;

  /// "single" | "multi" — decides which rate the card prices with.
  final String selectedMode;

  /// This machine's effective hourly rate — used to price those minutes
  /// instantly (rate ÷ 60 × minutes).
  final double hourlyRate;

  /// The "مالتي" rate (falls back to [hourlyRate] when never priced).
  final double multiHourlyRate;

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

  /// The two chips on a RUNNING card, each one naming the mode it moves the
  /// live session to — "فردي" and "مالتي", rather than a single badge that
  /// flips whichever way it happens to be.
  ///
  /// Named apart from [onSwitchMode] on purpose: this one is a choice, that
  /// one is a coin toss, and a cashier who is not sure which mode the machine
  /// is on should be able to say so with one tap instead of tapping and
  /// checking. Null unless the session is actually running.
  final ValueChanged<String>? onSwitchModeTo;

  /// Time is up but the players want to keep playing — pushes the
  /// deadline out and puts the device back to work.
  final VoidCallback? onExtend;

  /// "＋ وقت" on a RUNNING card: opens the custom top-up dialog (type
  /// minutes OR money), no need to wait for the clock to hit zero.
  final VoidCallback? onExtendCustom;

  EdgeInsets get _pad => compact
      ? const EdgeInsets.all(AppSpacing.sm)
      : const EdgeInsets.all(AppSpacing.lg);

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
    // Vertical breathing room between every block on the card. The "بدء
    // جلسة" button is pinned to the card's bottom via the Spacer, so it
    // always sits at the end with fresh clearance under it.
    final gap = compact ? AppSpacing.md : AppSpacing.lg;
    return GlassCard(
      hoverable: true,
      padding: _pad,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary))
          else
            const Text('الجهاز متاح دلوقتي',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          SizedBox(height: gap),
          // This machine's own mode (single or multi). The cashier picks
          // it right on the card, and it prices everything below.
          if (onSelectMode != null) ...[
            _modeToggles(
              activeMode: selectedMode,
              onPick: (mode) => onSelectMode?.call(mode),
            ),
            SizedBox(height: gap),
          ],
          // This machine's own time. Each card keeps its own choice, so
          // one tap on the card is all it takes to start it.
          if (onSelectDuration != null) ...[
            _durationChips(),
            SizedBox(height: gap),
          ],
          // Type the money, read the time: the price of [selectedMinutes]
          // lives in the money field, and typing EGP walks back to minutes.
          if (onAmountChanged != null) ...[
            _moneyAndTime(),
            SizedBox(height: gap),
          ],
          // Twin flexible spacers (above AND below the start button) center it
          // vertically in the middle of the leftover card space — half the
          // room between the money field and the card's bottom margin sits
          // above it, half below. It never crowds the money field.
          const Spacer(),
          // The start button is big (full card width).
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
          // The other half of the leftover space sits under the button,
          // relaxing it toward the card's bottom margin.
          const Spacer(),
        ],
      ),
    );
  }

  /// فردي / مالتي toggle — sits right on the card like the time chips,
  /// and decides which hourly rate prices everything below it.
  ///
  /// One widget for both cards on purpose. The empty card and the running
  /// card offer the same two choices, and a card that measured them twice
  /// would be a card whose chips sat at a different height depending on
  /// whether a customer happened to be sitting there.
  Widget _modeToggles({
    required String activeMode,
    required ValueChanged<String> onPick,
  }) {
    final isMulti = activeMode == 'multi';
    Widget toggle(String label, {required String mode, required bool active}) {
      return Expanded(
        child: GestureDetector(
          onTap: () => onPick(mode),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: compact ? 5 : 8),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accentPrimary.withOpacity(0.25)
                  : AppColors.glassFill,
              borderRadius: AppRadius.smallR,
              border: Border.all(
                color: active
                    ? AppColors.glassBorderPurple
                    : AppColors.glassBorder,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: compact ? 12 : 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        toggle('فردي', mode: 'single', active: !isMulti),
        const SizedBox(width: 4),
        toggle('مالتي', mode: 'multi', active: isMulti),
      ],
    );
  }

  /// The rate this card prices with — multi takes over when it is priced
  /// and the cashier picked it, else the single hourly rate.
  double get _rateForMode => selectedMode == 'multi' && multiHourlyRate > 0
      ? multiHourlyRate
      : hourlyRate;

  /// The money←→time control, inverted from the old minutes box: type the
  /// EGP on the right, the card turns it into minutes under the current
  /// rate, and the frame always shows the time that money buys. Flipping
  /// to "وقت مفتوح" lives inside the same frame as before.
  Widget _moneyAndTime() {
    final open = selectedMinutes == null || selectedMinutes! <= 0;

    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.smallR,
        border: Border.all(
          color: open ? AppColors.glassBorderPurple : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.payments_rounded,
              size: 15, color: AppColors.textTertiary),
          const SizedBox(width: 4),
          _MoneyField(
            amount: selectedAmount,
            onChanged: onAmountChanged,
          ),
          _innerDivider(),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                open
                    ? 'وقت مفتوح · ${_rateForMode.round()}/ساعة'
                    : '$selectedMinutes دقيقة',
                maxLines: 1,
                style: TextStyle(
                  fontSize: open ? 11 : 15,
                  fontWeight: open ? FontWeight.w500 : FontWeight.w800,
                  color:
                      open ? AppColors.accentSecondary : AppColors.textPrimary,
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

  /// 60 / 30 / 15 minutes, sized to stay inside the compact card.
  Widget _durationChips() {
    const chips = [60, 30, 15];
    return Row(
      children: [
        for (var i = 0; i < chips.length; i++) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onSelectDuration!(chips[i]),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: compact ? 5 : 8),
                decoration: BoxDecoration(
                  color: selectedMinutes == chips[i]
                      ? AppColors.accentPrimary.withOpacity(0.25)
                      : AppColors.glassFill,
                  borderRadius: AppRadius.smallR,
                  border: Border.all(
                    color: selectedMinutes == chips[i]
                        ? AppColors.glassBorderPurple
                        : AppColors.glassBorder,
                  ),
                ),
                child: Text(
                  '${chips[i]}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: compact ? 12 : 14,
                    fontWeight: selectedMinutes == chips[i]
                        ? FontWeight.w700
                        : FontWeight.w400,
                    color: selectedMinutes == chips[i]
                        ? AppColors.textPrimary
                        : AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
          if (i != chips.length - 1) const SizedBox(width: 4),
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
          // Top-up while the session is still running: "＋ وقت" opens the
          // dialog where the cashier types minutes OR money.
          if (compact && onExtendCustom != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: GestureDetector(
                onTap: onExtendCustom,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentPrimary.withOpacity(0.15),
                    borderRadius: AppRadius.smallR,
                    border: Border.all(color: AppColors.glassBorderPurple),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.more_time_rounded,
                          size: 13, color: AppColors.accentSecondary),
                      SizedBox(width: 4),
                      Text('＋ وقت',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.accentSecondary,
                              fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ),
          ],
          if (device.mode != null && onSwitchModeTo != null) ...[
            const SizedBox(height: AppSpacing.xs),
            // Two chips, not one badge that flips whichever way it happens to
            // be: the cashier says which mode they want, instead of tapping and
            // then reading the card to find out whether they guessed right.
            // Measured by [_modeToggles], so they sit exactly where the empty
            // card's chips sit and the card grows by one row, not by a redesign.
            _modeToggles(
              activeMode: device.isMultiMode ? 'multi' : 'single',
              onPick: onSwitchModeTo!,
            ),
          ] else if (device.mode != null) ...[
            // Nothing running to move: read the mode and leave it alone.
            const SizedBox(height: 4),
            Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.15),
                  borderRadius: AppRadius.smallR,
                ),
                child: Text(device.mode!,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.accentSecondary,
                        fontWeight: FontWeight.w600)),
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

  /// "الإجمالي" on a card: what the customer owes, which is the play
  /// time AND everything they ordered from the counter. Those are two
  /// different things and both of them are owed.
  ///
  /// It used to print the time alone, so a customer who had eaten and
  /// drunk saw a total that was short of what the till was about to ask
  /// for, and the correction had to happen at the checkout - in front of
  /// the customer.
  String _sumCost() {
    final time = _egp(device.timeCost);
    final orders = _egp(device.ordersCost);
    if (time == null && orders == null) return '-';
    return 'EGP ${((time ?? 0) + (orders ?? 0)).toStringAsFixed(2)}';
  }

  static double? _egp(String? s) =>
      double.tryParse((s ?? '').replaceFirst('EGP ', '').trim());
}

/// The free-form "money" box on a device card. It owns its controller so
/// typing is never interrupted by a rebuild, and mirrors the amount when
/// a duration chip or the open-time toggle changes it from outside. An
/// empty box means "وقت مفتوح" (reported to the parent as null).
class _MoneyField extends StatefulWidget {
  const _MoneyField({required this.amount, this.onChanged});

  final double? amount;
  final ValueChanged<double?>? onChanged;

  @override
  State<_MoneyField> createState() => _MoneyFieldState();
}

class _MoneyFieldState extends State<_MoneyField> {
  late final TextEditingController _controller =
      TextEditingController(text: _textFor(widget.amount));
  final FocusNode _focus = FocusNode();

  static String _textFor(double? amount) =>
      amount == null ? '' : amount.round().toString();

  @override
  void didUpdateWidget(covariant _MoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Never clobber the cashier's keystrokes: only mirror the value from
    // outside (chips, open-toggle, mode switch) while the field is idle.
    if (!_focus.hasFocus) {
      final text = _textFor(widget.amount);
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
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 38,
      child: TextField(
        controller: _controller,
        focusNode: _focus,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: (raw) => widget.onChanged?.call(double.tryParse(raw.trim())),
        style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()]),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: EdgeInsets.zero,
          hintText: 'EGP',
          hintStyle:
              const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          filled: false,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
