import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/app_database.dart';
import '../../data/repositories/audit_log_repository.dart';

/// Audit log — spec §33. A read-only, newest-first feed of every
/// sensitive operation (price changes, stock adjustments, refunds …)
/// with who did it and when. There is no edit/delete path by design.
class AuditLogScreen extends ConsumerStatefulWidget {
  const AuditLogScreen({super.key});

  @override
  ConsumerState<AuditLogScreen> createState() => _AuditLogScreenState();
}

class _AuditLogScreenState extends ConsumerState<AuditLogScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(recentAuditLogsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('سجل العمليات', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('كل عملية حساسة مسجّلة بالفاعل والوقت',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: 360,
          child: TextField(
            controller: _search,
            onChanged: (v) => setState(() => _query = v.trim()),
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'بحث بالعملية أو النوع أو الدور',
              hintStyle: const TextStyle(color: AppColors.textTertiary),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.textTertiary),
              filled: true,
              fillColor: AppColors.glassFill,
              border: OutlineInputBorder(
                  borderRadius: AppRadius.smallR,
                  borderSide: const BorderSide(color: AppColors.glassBorder)),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: logsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (logs) {
              final filtered = _query.isEmpty
                  ? logs
                  : logs.where((l) {
                      final q = _query.toLowerCase();
                      return l.action.toLowerCase().contains(q) ||
                          l.entityType.toLowerCase().contains(q) ||
                          l.performedByRole.toLowerCase().contains(q);
                    }).toList();
              if (filtered.isEmpty) {
                return const Center(
                  child: Text('لا توجد عمليات مسجّلة',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return ListView.separated(
                itemCount: filtered.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _LogRow(log: filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _LogRow extends StatelessWidget {
  const _LogRow({required this.log});
  final AuditLogRow log;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.15),
              borderRadius: AppRadius.mediumR,
            ),
            child: Icon(_iconFor(log.action),
                size: 18, color: AppColors.accentSecondary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_actionLabel(log.action), style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                    '${log.entityType}${log.entityId == null ? '' : ' #${log.entityId}'}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          if (log.oldValue != null || log.newValue != null)
            Expanded(
              flex: 3,
              child: Text(
                '${log.oldValue ?? '—'} ← ${log.newValue ?? '—'}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(log.performedByRole,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          SizedBox(
            width: 130,
            child: Text(_fmtDateTime(log.createdAt),
                textAlign: TextAlign.end,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
          ),
        ],
      ),
    );
  }

  static IconData _iconFor(String action) {
    if (action.contains('price')) return Icons.attach_money_rounded;
    if (action.contains('stock')) return Icons.inventory_2_rounded;
    if (action.contains('refund')) return Icons.replay_rounded;
    if (action.contains('cancel')) return Icons.cancel_rounded;
    if (action.contains('discount')) return Icons.local_offer_rounded;
    return Icons.history_rounded;
  }

  static String _actionLabel(String action) {
    switch (action) {
      case 'price_changed':
        return 'تغيير سعر';
      case 'stock_adjusted':
        return 'تعديل مخزون';
      case 'discount_applied':
        return 'تطبيق خصم';
      case 'refund':
        return 'استرجاع';
      case 'invoice_cancelled':
        return 'إلغاء فاتورة';
      case 'shift_closed':
        return 'إقفال شيفت';
      default:
        return action;
    }
  }
}

String _fmtDateTime(DateTime d) => '${shortDayOf(d)} ${clockOf(d)}';
