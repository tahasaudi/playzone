import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import 'device_card.dart';

/// Slides in from the side when an active device is tapped.
/// Shows the full session breakdown + quick actions. Orders and time
/// splice into the total so the panel always matches the checkout.
class SessionDetailsPanel extends StatelessWidget {
  const SessionDetailsPanel({
    super.key,
    required this.device,
    required this.onClose,
    this.onCheckout,
    this.onOrder,
    this.onSwitchMode,
  });

  final DeviceUiModel device;
  final VoidCallback onClose;
  final VoidCallback? onCheckout;
  final VoidCallback? onOrder;
  final VoidCallback? onSwitchMode;

  static double _parseEgp(String? s) =>
      double.tryParse((s ?? '').replaceFirst('EGP ', '').trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final timeCost = _parseEgp(device.timeCost);
    final ordersCost = _parseEgp(device.ordersCost);
    final total = timeCost + ordersCost;

    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          // Was 380 wide and unconstrained in height — it overflowed on
          // shorter windows (the yellow/black Flutter overflow stripes)
          // and its unclipped content bled past the rounded corners (the
          // white smudge). Now: narrower, height-capped, clipped, and
          // scrollable so nothing can ever spill out.
          width: 320,
          constraints: const BoxConstraints(maxHeight: 520),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: AppRadius.largeR,
            border: Border.all(color: AppColors.glassBorderPurple),
            boxShadow: AppShadows.cardHover,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text('${device.type.labelAr} — ${device.name}',
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.cardTitle),
                    ),
                    GestureDetector(
                      onTap: onClose,
                      child: const Icon(Icons.close_rounded,
                          size: 18, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Center(
                  child: FittedBox(
                    child: Text(device.elapsed ?? '00:00:00',
                        style: AppTypography.timer.copyWith(fontSize: 32)),
                  ),
                ),
                if (device.remaining != null) ...[
                  const SizedBox(height: 2),
                  Center(
                    child: Text('فاضل ${device.remaining}',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.warning)),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                _row('العميل', device.customerName ?? '—'),
                _row('الوضع الحالي', device.mode ?? '—'),
                const Divider(color: AppColors.glassBorder, height: AppSpacing.md),
                _row('تكلفة الوقت', device.timeCost ?? 'EGP 0'),
                _row('الطلبات', device.ordersCost ?? 'EGP 0'),
                _row('الخصم', 'EGP 0'),
                const Divider(color: AppColors.glassBorder, height: AppSpacing.md),
                _row('الإجمالي', 'EGP ${total.toStringAsFixed(2)}',
                    emphasize: true),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: SecondaryButton(
                          label: 'تحويل',
                          icon: Icons.swap_horiz_rounded,
                          onPressed: onSwitchMode),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SecondaryButton(
                          label: 'طلب',
                          icon: Icons.add_rounded,
                          onPressed: onOrder),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                PrimaryButton(
                  label: 'تحصيل الجلسة',
                  icon: Icons.point_of_sale_rounded,
                  expand: true,
                  onPressed: onCheckout,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool emphasize = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: emphasize ? 15 : 13,
                    fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
                    color: emphasize
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: emphasize ? 18 : 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
