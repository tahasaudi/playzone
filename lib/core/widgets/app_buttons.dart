import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

/// Purple gradient, white text, soft glow. For the single most important
/// action on a screen (Checkout, Start Session, Confirm).
class PrimaryButton extends StatefulWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  /// على كارت الجهاز المضغوط (3 أزرار في صف) المساحة ضيقة جدًا، فبنشيل
  /// الأيقونة ونصغّر الحشو والخط — عشان كلمة «تحصيل» تظهر كاملة مش مقطوعة.
  final bool compact;

  @override
  State<PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<PrimaryButton> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;

    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.pressDuration,
          width: widget.expand ? double.infinity : null,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 4 : AppSpacing.sm,
            vertical: widget.compact ? 10 : 14,
          ),
          decoration: BoxDecoration(
            gradient: disabled ? null : AppColors.primaryButtonGradient,
            color: disabled ? AppColors.glassFill : null,
            borderRadius: AppRadius.mediumR,
            boxShadow: disabled || !_hovering
                ? []
                : [
                    BoxShadow(
                      color: AppColors.accentPrimary.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
          ),
          transform: _pressed
              ? (Matrix4.identity()..scale(0.98))
              : Matrix4.identity(),
          transformAlignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null && !widget.compact) ...[
                Icon(widget.icon,
                    size: 18,
                    color: disabled ? AppColors.textTertiary : Colors.white),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: disabled ? AppColors.textTertiary : Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: widget.compact ? 12 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Transparent glass with subtle border. For secondary actions.
class SecondaryButton extends StatefulWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// نفس فكرة PrimaryButton.compact: مساحة ضيقة على الكارت المصغّر.
  final bool compact;

  @override
  State<SecondaryButton> createState() => _SecondaryButtonState();
}

class _SecondaryButtonState extends State<SecondaryButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;
    return MouseRegion(
      cursor: disabled ? SystemMouseCursors.basic : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppTheme.hoverDuration,
          padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 4 : AppSpacing.sm,
            vertical: widget.compact ? 10 : 12,
          ),
          decoration: BoxDecoration(
            color: _hovering ? AppColors.glassFillStrong : AppColors.glassFill,
            borderRadius: AppRadius.mediumR,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null && !widget.compact) ...[
                Icon(widget.icon, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    widget.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: widget.compact ? 12 : 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
