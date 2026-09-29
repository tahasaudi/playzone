import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import 'locked_pin_dialog.dart';

/// One of the dashboard's protected metric buttons. The metric is ONLY
/// rendered by the caller when the current employee's permission set
/// includes the matching AppFeature; this button additionally hides the
/// number behind the custom PIN from Settings → الأزرار المحمية. Tap →
/// PIN → number.
class LockedMetricButton extends StatefulWidget {
  const LockedMetricButton({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = AppColors.accentSecondary,
    this.supportingText,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final String? supportingText;

  @override
  State<LockedMetricButton> createState() => _LockedMetricButtonState();
}

class _LockedMetricButtonState extends State<LockedMetricButton> {
  bool _unlocked = false;

  Future<void> _reveal() async {
    if (_unlocked) return;
    final ok = await showLockedPinDialog(context);
    if (ok && mounted) setState(() => _unlocked = true);
  }

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      hoverable: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: GestureDetector(
        onTap: _reveal,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.iconColor.withOpacity(0.15),
                    borderRadius: AppRadius.smallR,
                  ),
                  child: Icon(widget.icon, size: 16, color: widget.iconColor),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(widget.label,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
                Icon(
                  _unlocked
                      ? Icons.visibility_rounded
                      : Icons.lock_rounded,
                  size: 15,
                  color: _unlocked
                      ? AppColors.success
                      : AppColors.textTertiary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _unlocked ? widget.value : '••••••',
              style: AppTypography.numberLarge.copyWith(fontSize: 24),
            ),
            if (widget.supportingText != null) ...[
              const SizedBox(height: 2),
              Text(widget.supportingText!,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ],
        ),
      ),
    );
  }
}