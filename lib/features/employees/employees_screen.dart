import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/auth/role_provider.dart';
import '../../core/database/app_database.dart';
import '../../data/repositories/employee_repository.dart';

/// Employees — read-only roster (name, phone, role, active). Editing
/// PINs and per-feature permissions lives on the Employee Permissions
/// screen, which the sidebar links to separately.
class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(activeEmployeesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الموظفين', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('فريق العمل المسجّل على النظام',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: employeesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (employees) {
              if (employees.isEmpty) {
                return const Center(
                  child: Text('لا يوجد موظفين مسجلين',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return ListView.separated(
                itemCount: employees.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _EmployeeRow(employee: employees[i]),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.employee});
  final EmployeeRow employee;

  @override
  Widget build(BuildContext context) {
    final role = UserRole.values.firstWhere(
      (r) => r.name == employee.role,
      orElse: () => UserRole.cashier,
    );
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
            child: const Icon(Icons.badge_rounded,
                color: AppColors.accentSecondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(employee.name, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(employee.phone,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.15),
              borderRadius: AppRadius.smallR,
            ),
            child: Text(role.labelAr,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accentSecondary,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}