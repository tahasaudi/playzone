import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/app_database.dart';
import '../../data/repositories/invoice_repository.dart';

/// Invoices — a read-only ledger of recent sales (sessions + POS).
/// Search jumps here when a staff member looks up an invoice number.
class InvoicesScreen extends ConsumerWidget {
  const InvoicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(recentInvoicesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الفواتير', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('آخر عمليات البيع من الجلسات والكاشير',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (invoices) {
              if (invoices.isEmpty) {
                return const Center(
                  child: Text('لا توجد فواتير بعد',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return ListView.separated(
                itemCount: invoices.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _InvoiceRow(invoice: invoices[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _InvoiceRow extends StatelessWidget {
  const _InvoiceRow({required this.invoice});
  final InvoiceRow invoice;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.15),
              borderRadius: AppRadius.mediumR,
            ),
            child: const Icon(Icons.receipt_long_rounded,
                color: AppColors.accentSecondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('فاتورة #${invoice.id}',
                    style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(_formatDate(invoice.createdAt),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          _paymentChip(invoice),
          const SizedBox(width: AppSpacing.md),
          Text('EGP ${invoice.total.toStringAsFixed(2)}',
              style: AppTypography.cardTitle),
        ],
      ),
    );
  }

  Widget _paymentChip(InvoiceRow invoice) {
    final (label, color) = switch (invoice.paymentMethod) {
      'card' => ('كارت', AppColors.accentSecondary),
      'mixed' => ('مختلط', AppColors.warning),
      _ => ('كاش', AppColors.success),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.smallR,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }

  String _formatDate(DateTime d) =>
      '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
}