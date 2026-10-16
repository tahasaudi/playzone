import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/refund_dao.dart';
import '../../data/repositories/refund_repository.dart';
import '../../data/repositories/invoice_repository.dart';

String _money(double v) => 'EGP ${v.toStringAsFixed(2)}';

String _fmt(DateTime d) {
  final now = DateTime.now();
  final sameDay =
      d.year == now.year && d.month == now.month && d.day == now.day;
  return sameDay ? 'اليوم ${clockOf(d)}' : '${stampOf(d)} ${clockOf(d)}';
}

bool _isToday(DateTime d, DateTime now) =>
    d.year == now.year && d.month == now.month && d.day == now.day;

/// Refund report ("تقرير المرتجعات") — its own page, kept apart from the
/// refund-creation screen. Shows every refund with what actually came back on
/// it (which products, how many, for how much) plus headline totals for the
/// day and all time.
class RefundReportScreen extends ConsumerWidget {
  const RefundReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundsAsync = ref.watch(recentRefundsProvider);
    final refundedTotals = ref.watch(refundedTotalsProvider);
    final invoices =
        ref.watch(searchableInvoicesProvider).valueOrNull ?? const [];
    final invoiceTotals = <int, double>{
      for (final e in invoices) e.invoice.id: e.invoice.total,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('تقرير المرتجعات', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('كل المرتجعات المسجّلة وبنودها وإجمالي المبالغ',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: refundsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('خطأ: $e',
                  style: const TextStyle(color: AppColors.danger)),
            ),
            data: (refunds) => _ReportBody(
              refunds: refunds,
              invoiceTotals: invoiceTotals,
              refundedTotals: refundedTotals,
            ),
          ),
        ),
      ],
    );
  }
}

class _ReportBody extends StatelessWidget {
  const _ReportBody({
    required this.refunds,
    required this.invoiceTotals,
    required this.refundedTotals,
  });
  final List<RefundRow> refunds;
  final Map<int, double> invoiceTotals;
  final Map<int, double> refundedTotals;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final total = refunds.fold<double>(0, (s, r) => s + r.amount);
    final today = refunds.where((r) => _isToday(r.createdAt, now)).toList();
    final todayTotal = today.fold<double>(0, (s, r) => s + r.amount);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'عدد المرتجعات',
                value: '${refunds.length}',
                icon: Icons.assignment_return_rounded,
                color: AppColors.accentSecondary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                label: 'إجمالي المبالغ المستردة',
                value: _money(total),
                icon: Icons.payments_rounded,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                label: 'مرتجعات النهاردة',
                value: _money(todayTotal),
                icon: Icons.today_rounded,
                color: AppColors.accentPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (refunds.isEmpty)
          const Expanded(
            child: Center(
              child: Text('لا توجد مرتجعات مسجلة',
                  style: TextStyle(color: AppColors.textTertiary)),
            ),
          )
        else
          Expanded(
            child: ListView.separated(
              itemCount: refunds.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (_, i) {
                final r = refunds[i];
                return _RefundReportCard(
                  refund: r,
                  invoiceTotal: invoiceTotals[r.invoiceId],
                  invoiceRefunded: refundedTotals[r.invoiceId] ?? r.amount,
                );
              },
            ),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: AppRadius.smallR,
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text(value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// One refund in the report: header, meta, and — the point of this page — the
/// exact lines that came back on it.
class _RefundReportCard extends ConsumerWidget {
  const _RefundReportCard({
    required this.refund,
    required this.invoiceTotal,
    required this.invoiceRefunded,
  });
  final RefundRow refund;

  /// The invoice's original value, when we can still see the invoice.
  final double? invoiceTotal;

  /// Everything refunded off this invoice so far (not just this refund).
  final double invoiceRefunded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = refund;
    final linesAsync = ref.watch(refundLinesProvider(r.id));
    final total = invoiceTotal;
    final net = total == null
        ? null
        : (total - invoiceRefunded) < 0
            ? 0.0
            : total - invoiceRefunded;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.15),
                  borderRadius: AppRadius.smallR,
                ),
                child: const Icon(Icons.assignment_return_rounded,
                    size: 18, color: AppColors.danger),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('فاتورة #${r.invoiceId}',
                        style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(_fmt(r.createdAt),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(_money(r.amount),
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.danger)),
            ],
          ),
          if (total != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.bgBase.withOpacity(0.35),
                borderRadius: AppRadius.smallR,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Column(
                children: [
                  _kv('قيمة الفاتورة الأصلية', _money(total)),
                  const SizedBox(height: 2),
                  _kv('إجمالي المرتجع من الفاتورة', _money(invoiceRefunded),
                      color: AppColors.danger),
                  const Divider(height: AppSpacing.md),
                  _kv('المتبقي من الفاتورة', _money(net ?? 0),
                      color: AppColors.accentSecondary, bold: true),
                ],
              ),
            ),
          ],
          if (r.restocked) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: const [
                Icon(Icons.inventory_2_rounded,
                    size: 14, color: AppColors.statusAvailable),
                SizedBox(width: 4),
                Text('رجع للمخزون',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.statusAvailable)),
              ],
            ),
          ],
          if (r.reason?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Text('السبب: ${r.reason}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
          ],
          const SizedBox(height: AppSpacing.sm),
          linesAsync.when(
            loading: () => const SizedBox(
              height: 18,
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2)),
              ),
            ),
            error: (_, __) => const SizedBox.shrink(),
            data: (lines) {
              if (lines.isEmpty) {
                return const Text('مفيش بنود مسجلة للمرتجع ده (مبلغ يدوي)',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textTertiary));
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: AppSpacing.lg),
                  ...lines.map((l) => _RefundLineRow(line: l)),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value,
      {Color color = AppColors.textPrimary, bool bold = false}) {
    return Row(
      children: [
        Expanded(
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                color: color)),
      ],
    );
  }
}

class _RefundLineRow extends StatelessWidget {
  const _RefundLineRow({required this.line});
  final RefundLineView line;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          const Icon(Icons.circle, size: 6, color: AppColors.textTertiary),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('${line.description} ×${line.quantity}',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textPrimary)),
          ),
          Text(_money(line.amount),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
