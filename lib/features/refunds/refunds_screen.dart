import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/refund_repository.dart';
import '../../data/repositories/invoice_repository.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _fmt(DateTime d) {
  final now = DateTime.now();
  final sameDay = d.year == now.year && d.month == now.month && d.day == now.day;
  return sameDay
      ? 'اليوم ${_two(d.hour)}:${_two(d.minute)}'
      : '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}';
}

/// Refunds ("المرتجعات"). Every refund posts the money back to the
/// refunds account and can optionally reverse the product quantities
/// into stock. Creating one requires the refund permission and is
/// audit-logged.
class RefundsScreen extends ConsumerWidget {
  const RefundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refundsAsync = ref.watch(recentRefundsProvider);
    final canRefund = ref.watch(permissionServiceProvider).canRefund;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المرتجعات', style: AppTypography.sectionTitle),
                  SizedBox(height: 2),
                  Text('استرداد مبالغ من فواتير سابقة',
                      style: AppTypography.secondary),
                ],
              ),
            ),
            if (canRefund)
              SizedBox(
                width: 170,
                child: PrimaryButton(
                  label: 'تسجيل مرتجع',
                  icon: Icons.assignment_return_rounded,
                  expand: true,
                  onPressed: () => showAddRefundDialog(context, ref),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: refundsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (refunds) {
              if (refunds.isEmpty) {
                return const Center(
                  child: Text('لا توجد مرتجعات مسجلة',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return ListView.separated(
                itemCount: refunds.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final r = refunds[i];
                  return GlassCard(
                    child: Row(
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
                              Text(
                                'فاتورة #${r.invoiceId}'
                                '${r.reason?.isNotEmpty == true ? ' — ${r.reason}' : ''}',
                                style: AppTypography.cardTitle,
                              ),
                              const SizedBox(height: 2),
                              Text(_fmt(r.createdAt),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ],
                          ),
                        ),
                        if (r.restocked) ...[
                          const SizedBox(width: AppSpacing.md),
                          const Icon(Icons.inventory_2_rounded,
                              size: 18, color: AppColors.statusAvailable),
                          const SizedBox(width: 4),
                          const Text('رجع للمخزون',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.statusAvailable)),
                        ],
                        const SizedBox(width: AppSpacing.md),
                        Text('EGP ${r.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppColors.danger)),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

Future<void> showAddRefundDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (_) => const _AddRefundDialog(),
  );
}

class _AddRefundDialog extends ConsumerStatefulWidget {
  const _AddRefundDialog();

  @override
  ConsumerState<_AddRefundDialog> createState() => _AddRefundDialogState();
}

class _AddRefundDialogState extends ConsumerState<_AddRefundDialog> {
  int? _invoiceId;
  final _amount = TextEditingController();
  final _reason = TextEditingController();
  bool _restock = true;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    super.dispose();
  }

  double _invoiceTotal(List<InvoiceRow> invoices) {
    final match = invoices.where((i) => i.id == _invoiceId).firstOrNull;
    return match?.total ?? 0;
  }

  Future<void> _save() async {
    final amount = double.tryParse(_amount.text.trim());
    if (_invoiceId == null || amount == null || amount <= 0) {
      setState(() => _error = 'اختر الفاتورة واكتب مبلغ صحيح');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final employee = ref.read(currentEmployeeProvider);
    try {
      await ref.read(refundRepositoryProvider).createRefund(
            invoiceId: _invoiceId!,
            amount: amount,
            reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
            employeeId: employee?.id,
            restock: _restock,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم تسجيل المرتجع')));
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(recentInvoicesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('تسجيل مرتجع', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            const Text('الفاتورة', style: AppTypography.body),
            const SizedBox(height: 6),
            invoicesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) =>
                  Text('$e', style: const TextStyle(color: AppColors.danger)),
              data: (invoices) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: AppRadius.smallR,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int?>(
                    value: _invoiceId,
                    isExpanded: true,
                    hint: const Text('اختر الفاتورة',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 13)),
                    dropdownColor: AppColors.bgElevated,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    items: [
                      for (final i in invoices)
                        DropdownMenuItem(
                          value: i.id,
                          child: Text(
                              'فاتورة #${i.id} — EGP ${i.total.toStringAsFixed(0)}'),
                        ),
                    ],
                    onChanged: (v) {
                      setState(() {
                        _invoiceId = v;
                        _amount.text =
                            _invoiceTotal(invoices).toStringAsFixed(0);
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ المسترجع (EGP)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _reason,
              decoration: const InputDecoration(labelText: 'السبب (اختياري)'),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Text('إرجاع الكميات للمخزون',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                const Spacer(),
                Switch(
                  value: _restock,
                  activeThumbColor: AppColors.accentSecondary,
                  onChanged: (v) => setState(() => _restock = v),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!,
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
            const SizedBox(height: AppSpacing.xl),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'إلغاء',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: PrimaryButton(
                    label: _saving ? 'جارٍ الحفظ...' : 'تسجيل',
                    icon: Icons.check_rounded,
                    expand: true,
                    onPressed: _saving ? null : _save,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}