import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';
import '../theme/app_theme.dart';

/// The base surface used across the app: sidebar, content cards, panels,
/// modals. A clean solid panel with a refined hairline border, soft
/// layered shadow and a gentle lift + violet border on hover.
///
/// Not every element should be a card — use this deliberately for
/// panels/cards, not for every single row or label (see spec section 4).
class GlassCard extends StatefulWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.borderRadius,
    this.hoverable = false,
    this.onTap,
    this.borderColor,
    this.glowOnHover = false,
  });

  final Widget child;
  final EdgeInsets padding;
  final BorderRadius? borderRadius;
  final bool hoverable;
  final VoidCallback? onTap;
  final Color? borderColor;
  final bool glowOnHover;

  @override
  State<GlassCard> createState() => _GlassCardState();
}

class _GlassCardState extends State<GlassCard> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ?? AppRadius.largeR;
    final isHot = widget.hoverable && _hovering;

    return MouseRegion(
      cursor: widget.onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.hoverDuration,
          curve: Curves.easeOut,
          transform: isHot
              ? (Matrix4.identity()..translate(0.0, -2.0))
              : Matrix4.identity(),
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: isHot
                ? (widget.glowOnHover
                    ? AppShadows.cardHoverGlow
                    : AppShadows.cardHover)
                : AppShadows.card,
          ),
          child: AnimatedContainer(
            duration: AppTheme.hoverDuration,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: isHot ? AppColors.glassFillStrong : AppColors.glassFill,
              borderRadius: radius,
              border: Border.all(
                color: widget.borderColor ??
                    (isHot
                        ? AppColors.glassBorderPurple
                        : AppColors.glassBorder),
                width: 1,
              ),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
