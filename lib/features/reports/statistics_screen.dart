import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/app_database.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import 'report_period_selector.dart';

/// Statistics — the numbers-only dashboard for the selected period:
/// revenue, ticket size, tender split, expenses, profit (revenue minus
/// expenses, never revenue alone), and the best-selling lines.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final invoicesAsync = ref.watch(invoicesInRangeProvider);
    final itemsAsync = ref.watch(invoiceItemsInRangeProvider);
    final expensesAsync = ref.watch(allExpensesProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الإحصائيات', style: AppTypography.sectionTitle),
          const SizedBox(height: 2),
          const Text('ملخص الإيرادات والمصروفات والأرباح',
              style: AppTypography.secondary),
          const SizedBox(height: AppSpacing.md),
          const ReportPeriodSelector(),
          const SizedBox(height: AppSpacing.lg),
          invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('خطأ: $e',
                style: const TextStyle(color: AppColors.danger)),
            data: (invoices) {
              final range = currentReportRange(period);
              final expenses = (expensesAsync.value ?? const <ExpenseRow>[])
                  .where((e) =>
                      !e.createdAt.isBefore(range.from) &&
                      e.createdAt.isBefore(range.to))
                  .toList();
              final items = itemsAsync.value ?? const <InvoiceItemRow>[];

              final revenue =
                  invoices.fold<double>(0, (s, i) => s + i.total);
              final discounts =
                  invoices.fold<double>(0, (s, i) => s + i.discount);
              final cash = invoices.fold<double>(0, (s, i) => s + i.paidCash);
              final card = invoices.fold<double>(0, (s, i) => s + i.paidCard);
              final totalExpenses =
                  expenses.fold<double>(0, (s, e) => s + e.amount);
              final profit = revenue - totalExpenses;
              final avg = invoices.isEmpty ? 0.0 : revenue / invoices.length;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _KpiCard(
                        label: 'الإيرادات',
                        value: 'EGP ${revenue.toStringAsFixed(0)}',
                        icon: Icons.trending_up_rounded,
                        color: AppColors.statusAvailable,
                      ),
                      _KpiCard(
                        label: 'صافي الربح',
                        value: 'EGP ${profit.toStringAsFixed(0)}',
                        icon: Icons.savings_rounded,
                        color: profit >= 0
                            ? AppColors.accentSecondary
                            : AppColors.danger,
                      ),
                      _KpiCard(
                        label: 'المصروفات',
                        value: 'EGP ${totalExpenses.toStringAsFixed(0)}',
                        icon: Icons.receipt_rounded,
                        color: AppColors.warning,
                      ),
                      _KpiCard(
                        label: 'عدد الفواتير',
                        value: '${invoices.length}',
                        icon: Icons.confirmation_number_rounded,
                        color: AppColors.accentPrimary,
                      ),
                      _KpiCard(
                        label: 'متوسط الفاتورة',
                        value: 'EGP ${avg.toStringAsFixed(0)}',
                        icon: Icons.calculate_rounded,
                        color: AppColors.accentSecondary,
                      ),
                      _KpiCard(
                        label: 'الخصومات',
                        value: 'EGP ${discounts.toStringAsFixed(0)}',
                        icon: Icons.local_offer_rounded,
                        color: AppColors.warning,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  GlassCard(
                    child: Row(
                      children: [
                        Expanded(
                          child: _TenderBar(
                            label: 'كاش',
                            value: cash,
                            total: cash + card,
                            color: AppColors.statusAvailable,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.lg),
                        Expanded(
                          child: _TenderBar(
                            label: 'كارت',
                            value: card,
                            total: cash + card,
                            color: AppColors.accentSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  const Text('الأكثر مبيعًا', style: AppTypography.cardTitle),
                  const SizedBox(height: AppSpacing.sm),
                  _TopProducts(items: items),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 210,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: AppSpacing.sm),
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Text(value,
                style: AppTypography.numberLarge.copyWith(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}

class _TenderBar extends StatelessWidget {
  const _TenderBar({
    required this.label,
    required this.value,
    required this.total,
    required this.color,
  });
  final String label;
  final double value;
  final double total;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final ratio = total <= 0 ? 0.0 : (value / total).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: AppTypography.cardTitle),
            ),
            Text('EGP ${value.toStringAsFixed(0)}',
                style: AppTypography.cardTitle),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        ClipRRect(
          borderRadius: AppRadius.smallR,
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: AppColors.glassFill,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }
}

class _TopProducts extends StatelessWidget {
  const _TopProducts({required this.items});
  final List<InvoiceItemRow> items;

  @override
  Widget build(BuildContext context) {
    final totals = <String, _ItemAgg>{};
    for (final i in items) {
      final agg = totals.putIfAbsent(i.description, () => _ItemAgg());
      agg.quantity += i.quantity;
      agg.revenue += i.total;
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));
    final top = ranked.take(10).toList();

    if (top.isEmpty) {
      return const GlassCard(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: Center(
            child: Text('مفيش مبيعات في الفترة دي',
                style: TextStyle(color: AppColors.textTertiary)),
          ),
        ),
      );
    }
    final max = top.first.value.revenue;
    return GlassCard(
      child: Column(
        children: [
          for (final e in top) ...[
            _TopRow(description: e.key, agg: e.value, maxRevenue: max),
            if (e != top.last)
              const Divider(color: AppColors.glassBorder, height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _ItemAgg {
  int quantity = 0;
  double revenue = 0;
}

class _TopRow extends StatelessWidget {
  const _TopRow({
    required this.description,
    required this.agg,
    required this.maxRevenue,
  });
  final String description;
  final _ItemAgg agg;
  final double maxRevenue;

  @override
  Widget build(BuildContext context) {
    final ratio = maxRevenue <= 0 ? 0.0 : agg.revenue / maxRevenue;
    return Row(
      children: [
        SizedBox(
          width: 200,
          child: Text(description,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.body),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: ClipRRect(
            borderRadius: AppRadius.smallR,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.glassFill,
              valueColor:
                  const AlwaysStoppedAnimation(AppColors.accentPrimary),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        SizedBox(
          width: 60,
          child: Text('×${agg.quantity}',
              textAlign: TextAlign.end,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
        SizedBox(
          width: 90,
          child: Text('EGP ${agg.revenue.toStringAsFixed(0)}',
              textAlign: TextAlign.end,
              style: AppTypography.cardTitle),
        ),
      ],
    );
  }
}
