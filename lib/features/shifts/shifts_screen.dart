import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/shift_repository.dart';
import '../shell/shift_close_dialog.dart';

/// Shifts — history of shift-close snapshots (opening/expected/actual
/// cash and the difference), plus a button to close the current shift.
class ShiftsScreen extends ConsumerWidget {
  const ShiftsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shiftsAsync = ref.watch(recentShiftsProvider);
    final employeesAsync = ref.watch(activeEmployeesProvider);
    final names = {
      for (final e in employeesAsync.value ?? const []) e.id: e.name,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الشيفتات', style: AppTypography.sectionTitle),
                  SizedBox(height: 2),
                  Text('سجل إقفال الخزنة والفرق في كل شيفت',
                      style: AppTypography.secondary),
                ],
              ),
            ),
            SizedBox(
              width: 180,
              child: PrimaryButton(
                label: 'إقفال شيفت',
                icon: Icons.lock_clock_rounded,
                expand: true,
                onPressed: () => showShiftCloseDialog(context, ref),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: shiftsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (shifts) {
              if (shifts.isEmpty) {
                return const Center(
                  child: Text('لا يوجد شيفتات مقفولة بعد',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return ListView.separated(
                itemCount: shifts.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) =>
                    _ShiftRow(shift: shifts[i], employeeName: names[shifts[i].employeeId]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ShiftRow extends StatelessWidget {
  const _ShiftRow({required this.shift, this.employeeName});
  final ShiftRow shift;
  final String? employeeName;

  @override
  Widget build(BuildContext context) {
    final diff = shift.difference;
    final diffColor = diff.abs() < 0.005
        ? AppColors.statusAvailable
        : diff > 0
            ? AppColors.warning
            : AppColors.danger;

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_clock_rounded,
                  size: 18, color: AppColors.accentSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(employeeName ?? 'غير محدد',
                    style: AppTypography.cardTitle),
              ),
              Text(_fmtDateTime(shift.closedAt),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(child: _money('افتتاحي', shift.openingCash)),
              Expanded(child: _money('متوقع', shift.expectedCash)),
              Expanded(child: _money('فعلي', shift.actualCash)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الفرق',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                    const SizedBox(height: 2),
                    Text(
                      '${diff > 0 ? '+' : ''}EGP ${diff.toStringAsFixed(0)}',
                      style: TextStyle(
                          fontSize: 14,
                          color: diffColor,
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((shift.notes ?? '').isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(shift.notes!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _money(String label, double value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text('EGP ${value.toStringAsFixed(0)}',
            style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

String _fmtDateTime(DateTime d) =>
    '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:'
    '${d.minute.toString().padLeft(2, '0')}';
