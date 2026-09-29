import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';

/// Large summary card at the top of the dashboard.
/// NOTE: revenue figures here are placeholder/mock data for the UI phase —
/// real numbers come from the shift/session data layer later.
class HeroPerformanceCard extends StatelessWidget {
  const HeroPerformanceCard({
    super.key,
    required this.totalRevenue,
    required this.percentChange,
  });

  final String totalRevenue;
  final double percentChange;

  @override
  Widget build(BuildContext context) {
    final positive = percentChange >= 0;
    return GlassCard(
      borderRadius: AppRadius.heroR,
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('أداء اليوم',
                    style: TextStyle(
                        fontSize: 15, color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.sm),
                Text(totalRevenue, style: AppTypography_numberHero),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Icon(
                      positive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 16,
                      color: positive ? AppColors.success : AppColors.danger,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${positive ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: positive ? AppColors.success : AppColors.danger,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('مقارنة بالأمس',
                        style: TextStyle(
                            fontSize: 12, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
          // Placeholder mini-chart area — replaced with real chart later.
          Container(
            width: 160,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: AppRadius.mediumR,
            ),
            child: const Icon(Icons.show_chart_rounded,
                color: AppColors.accentSecondary, size: 32),
          ),
        ],
      ),
    );
  }
}

const TextStyle AppTypography_numberHero = TextStyle(
  fontSize: 42,
  fontWeight: FontWeight.w700,
  color: AppColors.textPrimary,
  height: 1.1,
);

/// Compact KPI stat card — icon, label, big number, small supporting info.
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor = AppColors.accentSecondary,
    this.supportingText,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color iconColor;
  final String? supportingText;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      hoverable: true,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.15),
                  borderRadius: AppRadius.smallR,
                ),
                child: Icon(icon, size: 16, color: iconColor),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(value, style: AppTypography.numberLarge.copyWith(fontSize: 24)),
          if (supportingText != null) ...[
            const SizedBox(height: 2),
            Text(supportingText!,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary)),
          ],
        ],
      ),
    );
  }
}
