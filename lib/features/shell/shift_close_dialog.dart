import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/shift_repository.dart';

/// Shift close flow — spec §27/28, simplified (no separate "open shift"
/// step yet). Shows what the system EXPECTS in the register (today's
/// cash sales minus today's expenses) and asks the cashier to count the
/// drawer, never hiding the calculation (spec §24: "Never hide the
/// calculation").
Future<void> showShiftCloseDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (context) => const _ShiftCloseDialog(),
  );
}

class _ShiftCloseDialog extends ConsumerStatefulWidget {
  const _ShiftCloseDialog();

  @override
  ConsumerState<_ShiftCloseDialog> createState() => _ShiftCloseDialogState();
}

class _ShiftCloseDialogState extends ConsumerState<_ShiftCloseDialog> {
  final _actualCashController = TextEditingController();
  final _openingCashController = TextEditingController(text: '0');

  @override
  void dispose() {
    _actualCashController.dispose();
    _openingCashController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(todayInvoicesProvider);
    final expensesAsync = ref.watch(todayExpensesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
        ),
        child: invoicesAsync.when(
          loading: () => const SizedBox(
              height: 120, child: Center(child: CircularProgressIndicator())),
          error: (e, _) => Text('خطأ: $e', style: const TextStyle(color: AppColors.danger)),
          data: (invoices) {
            final expenses = expensesAsync.value ?? const [];
            // Cash in the drawer is the tender actually handed over as
            // cash — for a mixed payment that's paidCash, not the total.
            final cashRevenue =
                invoices.fold<double>(0, (sum, i) => sum + i.paidCash);
            final totalExpenses = expenses.fold<double>(0, (sum, e) => sum + e.amount);
            final openingCash = double.tryParse(_openingCashController.text) ?? 0;
            final expectedCash = openingCash + cashRevenue - totalExpenses;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إقفال الشيفت', style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.lg),
                _row('الكاش الافتتاحي', openingCash),
                _row('مبيعات كاش اليوم', cashRevenue),
                _row('المصروفات اليوم', -totalExpenses),
                const Divider(color: AppColors.glassBorder, height: AppSpacing.xl),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('الكاش المتوقع',
                        style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                    Text('EGP ${expectedCash.toStringAsFixed(0)}',
                        style: AppTypography.numberLarge.copyWith(fontSize: 24)),
                  ],
                ),
                const SizedBox(height: AppSpacing.lg),
                const Text('الكاش الفعلي بعد العد', style: AppTypography.body),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _actualCashController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: InputDecoration(
                    prefixText: 'EGP ',
                    filled: true,
                    fillColor: AppColors.glassFill,
                    border: OutlineInputBorder(
                        borderRadius: AppRadius.smallR,
                        borderSide: const BorderSide(color: AppColors.glassBorder)),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
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
                        label: 'تأكيد الإقفال',
                        icon: Icons.check_circle_rounded,
                        expand: true,
                        onPressed: () async {
                          final actualCash = double.tryParse(_actualCashController.text) ?? 0;
                          final employee = ref.read(currentEmployeeProvider);
                          await ref.read(shiftRepositoryProvider).closeShift(
                                employeeId: employee?.id,
                                openingCash: openingCash,
                                expectedCash: expectedCash,
                                actualCash: actualCash,
                              );
                          if (context.mounted) Navigator.of(context).pop();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _row(String label, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          Text('EGP ${value.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
        ],
      ),
    );
  }
}
