import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/invoice_repository.dart';

/// Shared report-window switcher (today / 7 days / month) driven by
/// [reportPeriodProvider] — used by every analytics screen so the
/// selected period is consistent when moving between them.
class ReportPeriodSelector extends ConsumerWidget {
  const ReportPeriodSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(reportPeriodProvider);
    const labels = {
      ReportPeriod.today: 'النهاردة',
      ReportPeriod.week: 'آخر 7 أيام',
      ReportPeriod.month: 'الشهر',
    };
    return Row(
      children: [
        for (final entry in labels.entries) ...[
          GestureDetector(
            onTap: () =>
                ref.read(reportPeriodProvider.notifier).state = entry.key,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected == entry.key
                    ? AppColors.accentPrimary.withOpacity(0.2)
                    : AppColors.glassFill,
                borderRadius: AppRadius.smallR,
                border: Border.all(
                    color: selected == entry.key
                        ? AppColors.glassBorderPurple
                        : AppColors.glassBorder),
              ),
              child: Text(entry.value,
                  style: TextStyle(
                      fontSize: 13,
                      color: selected == entry.key
                          ? AppColors.textPrimary
                          : AppColors.textSecondary)),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
      ],
    );
  }
}
