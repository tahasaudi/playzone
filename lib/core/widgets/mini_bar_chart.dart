import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

/// A minimal bar chart built with plain Containers — avoids pulling in a
/// charting package for a mock-data UI phase. Bars scale relative to the
/// largest value in the series. Matches the dark-purple visual language
/// (spec section 27: "avoid excessive chart colors").
class MiniBarChart extends StatelessWidget {
  const MiniBarChart({
    super.key,
    required this.data, // label -> value
    this.height = 140,
    this.barColor = AppColors.accentPrimary,
    this.valuePrefix = '',
  });

  final Map<String, double> data;
  final double height;
  final Color barColor;
  final String valuePrefix;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return const SizedBox.shrink();
    final maxValue = data.values.reduce((a, b) => a > b ? a : b);

    return SizedBox(
      height: height,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.entries.map((entry) {
          final fraction = maxValue == 0 ? 0.0 : entry.value / maxValue;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    '$valuePrefix${entry.value.toStringAsFixed(0)}',
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: 4),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: (height - 40) * fraction.clamp(0.03, 1.0),
                    decoration: BoxDecoration(
                      color: barColor.withOpacity(0.75),
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(AppRadius.small)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [barColor, barColor.withOpacity(0.4)],
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    entry.key,
                    style: const TextStyle(
                        fontSize: 10, color: AppColors.textSecondary),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// A simple two-value horizontal comparison bar (e.g. Gaming vs Café).
class ComparisonBar extends StatelessWidget {
  const ComparisonBar({
    super.key,
    required this.labelA,
    required this.valueA,
    required this.colorA,
    required this.labelB,
    required this.valueB,
    required this.colorB,
  });

  final String labelA;
  final double valueA;
  final Color colorA;
  final String labelB;
  final double valueB;
  final Color colorB;

  @override
  Widget build(BuildContext context) {
    final total = valueA + valueB;
    final fractionA = total == 0 ? 0.5 : valueA / total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _legend(labelA, valueA, colorA),
            _legend(labelB, valueB, colorB),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.smallR,
          child: SizedBox(
            height: 12,
            child: Row(
              children: [
                Expanded(
                    flex: (fractionA * 1000).round().clamp(1, 999),
                    child: Container(color: colorA)),
                Expanded(
                    flex: ((1 - fractionA) * 1000).round().clamp(1, 999),
                    child: Container(color: colorB)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _legend(String label, double value, Color color) {
    return Row(
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text('$label — EGP ${value.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
