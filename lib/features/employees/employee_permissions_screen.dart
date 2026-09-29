import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/app_database.dart';
import '../../core/permissions/app_feature.dart';
import '../../core/auth/role_provider.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/employee_feature_repository.dart';

/// "صلاحيات الموظفين" — spec: a comprehensive group covering literally
/// everything in the app, admin can show/hide each detail per employee.
/// Left: employee picker. Right: every AppFeature, grouped, each with a
/// three-state control (Default / Show / Hide) against that employee's
/// role baseline.
class EmployeePermissionsScreen extends ConsumerStatefulWidget {
  const EmployeePermissionsScreen({super.key});

  @override
  ConsumerState<EmployeePermissionsScreen> createState() =>
      _EmployeePermissionsScreenState();
}

class _EmployeePermissionsScreenState extends ConsumerState<EmployeePermissionsScreen> {
  int? _selectedEmployeeId;

  static const _screenFeatures = [
    AppFeature.dashboard, AppFeature.pos, AppFeature.devicesScreen,
    AppFeature.sessionsScreen, AppFeature.customersScreen, AppFeature.productsScreen,
    AppFeature.inventoryScreen, AppFeature.employeesScreen, AppFeature.shiftsScreen,
    AppFeature.reportsScreen, AppFeature.auditScreen, AppFeature.accountingScreen,
    AppFeature.expensesScreen, AppFeature.expenseLogScreen, AppFeature.refundsScreen,
    AppFeature.stockCountScreen, AppFeature.namesManagerScreen,
    AppFeature.settingsScreen, AppFeature.backupScreen,
    AppFeature.employeePermissionsScreen,
  ];

  static const _actionFeatures = [
    AppFeature.changePrice, AppFeature.applyDiscount, AppFeature.refund,
    AppFeature.cancelInvoice, AppFeature.adjustStock, AppFeature.manageEmployees,
    AppFeature.closeShift, AppFeature.backupRestore, AppFeature.viewProductCost,
  ];

  static const _dashboardFeatures = [
    AppFeature.viewPerformance, AppFeature.viewDailyRevenue,
    AppFeature.viewDailyExpenses, AppFeature.viewDailyProfit,
    AppFeature.viewGamingRevenue, AppFeature.viewSessionCount,
    AppFeature.viewEmployeeRevenueBreakdown,
  ];

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(activeEmployeesProvider);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 240,
          child: GlassCard(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              children: [
                const Text('الموظفين', style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.sm),
                if (ref.watch(permissionServiceProvider).canManageUsers)
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(
                      label: 'إضافة موظف',
                      icon: Icons.person_add_rounded,
                      expand: true,
                      onPressed: () async {
                        final newId = await showAddEmployeeDialog(context);
                        if (newId != null && mounted) {
                          setState(() => _selectedEmployeeId = newId);
                        }
                      },
                    ),
                  ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(
                  child: employeesAsync.when(
                    loading: () =>
                        const Center(child: CircularProgressIndicator()),
                    error: (e, _) => Text('$e',
                        style: const TextStyle(color: AppColors.danger)),
                    data: (employees) => Column(
                      children: employees.map((e) {
                        final selected = e.id == _selectedEmployeeId;
                        return GestureDetector(
                          onTap: () =>
                              setState(() => _selectedEmployeeId = e.id),
                          child: Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.sm, vertical: 12),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.accentPrimary.withOpacity(0.18)
                                  : Colors.transparent,
                              borderRadius: AppRadius.mediumR,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(e.name,
                                    style: TextStyle(
                                        color: selected
                                            ? AppColors.textPrimary
                                            : AppColors.textSecondary,
                                        fontWeight: selected
                                            ? FontWeight.w600
                                            : FontWeight.w400)),
                                Text(_roleLabel(e.role),
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textTertiary)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _selectedEmployeeId == null
              ? const Center(
                  child: Text('اختر موظف من القائمة عشان تعدّل صلاحياته',
                      style: TextStyle(color: AppColors.textTertiary)))
              : _PermissionMatrix(
                  employeeId: _selectedEmployeeId!,
                  screenFeatures: _screenFeatures,
                  actionFeatures: _actionFeatures,
                  dashboardFeatures: _dashboardFeatures,
                ),
        ),
      ],
    );
  }

  String _roleLabel(String role) {
    switch (role) {
      case 'admin':
        return UserRole.admin.labelAr;
      case 'shiftSupervisor':
        return UserRole.shiftSupervisor.labelAr;
      default:
        return UserRole.cashier.labelAr;
    }
  }
}

/// Add-employee dialog (name/phone/role/PIN). Returns the new id so the
/// permissions panel can select it immediately.
Future<int?> showAddEmployeeDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (_) => const _AddEmployeeDialog(),
  );
}

class _AddEmployeeDialog extends ConsumerStatefulWidget {
  const _AddEmployeeDialog();

  @override
  ConsumerState<_AddEmployeeDialog> createState() => _AddEmployeeDialogState();
}

class _AddEmployeeDialogState extends ConsumerState<_AddEmployeeDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _pin = TextEditingController();
  String _role = 'cashier';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    final pin = _pin.text.trim();
    if (name.isEmpty || phone.isEmpty || pin.length < 4) {
      setState(() => _error = 'الاسم ورقم الموبايل مطلوبين والرقم السري 4 أرقام على الأقل');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final id = await ref.read(employeeRepositoryProvider).addEmployee(
            name: name,
            phone: phone,
            role: _role,
            pin: pin,
          );
      if (mounted) Navigator.of(context).pop(id);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('موظف جديد', style: AppTypography.sectionTitle),
            const SizedBox(height: 2),
            const Text('الموظف بيسجل دخوله بالرقم السري، وصلاحياته من الجدول اللي على الشمال',
                style: AppTypography.secondary),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'الاسم'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'رقم الموبايل'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _pin,
              obscureText: true,
              keyboardType: TextInputType.number,
              maxLength: 10,
              decoration: const InputDecoration(labelText: 'الرقم السري (4 أرقام على الأقل)'),
            ),
            const SizedBox(height: AppSpacing.sm),
            const Text('الوظيفة', style: AppTypography.body),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: AppRadius.smallR,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _role,
                  isExpanded: true,
                  dropdownColor: AppColors.bgElevated,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 13),
                  items: [
                    for (final role in UserRole.values)
                      DropdownMenuItem(
                        value: role.name,
                        child: Text(role.labelAr),
                      ),
                  ],
                  onChanged: (v) => setState(() => _role = v ?? 'cashier'),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 13)),
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
                    label: _saving ? 'جارٍ الإضافة...' : 'إضافة',
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

class _PermissionMatrix extends ConsumerWidget {
  const _PermissionMatrix({
    required this.employeeId,
    required this.screenFeatures,
    required this.actionFeatures,
    required this.dashboardFeatures,
  });

  final int employeeId;
  final List<AppFeature> screenFeatures;
  final List<AppFeature> actionFeatures;
  final List<AppFeature> dashboardFeatures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(activeEmployeesProvider);
    // Watches feature overrides for the SELECTED employee (not
    // necessarily whoever is currently signed in at the terminal).
    final overrideStream = ref.watch(_employeeOverridesProvider(employeeId));

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Text('$e'),
      data: (employees) {
        final employee = employees.where((e) => e.id == employeeId).firstOrNull;
        if (employee == null) return const SizedBox.shrink();

        final role = employee.role == 'admin'
            ? UserRole.admin
            : employee.role == 'shiftSupervisor'
                ? UserRole.shiftSupervisor
                : UserRole.cashier;
        final defaults = AppFeature.defaultsForRole(role);
        final overrides = overrideStream.value ?? const [];
        final overrideMap = {for (final o in overrides) o.featureKey: o.visible};

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('صلاحيات ${employee.name}', style: AppTypography.sectionTitle),
              const SizedBox(height: 2),
              const Text('دوس على أي عنصر عشان تظهره أو تخفيه لهذا الموظف بالذات',
                  style: AppTypography.secondary),
              const SizedBox(height: AppSpacing.lg),
              _section('الشاشات', screenFeatures, defaults, overrideMap),
              const SizedBox(height: AppSpacing.lg),
              _section('العمليات الحساسة', actionFeatures, defaults, overrideMap),
              const SizedBox(height: AppSpacing.lg),
              _section('تفاصيل الداشبورد', dashboardFeatures, defaults, overrideMap),
            ],
          ),
        );
      },
    );
  }

  Widget _section(String title, List<AppFeature> features, Set<AppFeature> defaults,
      Map<String, bool> overrideMap) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        GlassCard(
          child: Column(
            children: [
              for (final feature in features) ...[
                _featureRow(feature, defaults, overrideMap),
                if (feature != features.last)
                  const Divider(color: AppColors.glassBorder, height: AppSpacing.md),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _featureRow(AppFeature feature, Set<AppFeature> defaults, Map<String, bool> overrideMap) {
    final hasOverride = overrideMap.containsKey(feature.key);
    final effectiveVisible = hasOverride ? overrideMap[feature.key]! : defaults.contains(feature);

    return Consumer(builder: (context, ref, _) {
      final repo = ref.read(employeeFeatureRepositoryProvider);
      return Row(
        children: [
          Expanded(
            child: Text(feature.labelAr,
                style: TextStyle(
                    fontSize: 13,
                    color: effectiveVisible ? AppColors.textPrimary : AppColors.textTertiary)),
          ),
          if (hasOverride)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: GestureDetector(
                onTap: () => repo.resetToDefault(employeeId, feature),
                child: const Text('رجوع للافتراضي',
                    style: TextStyle(fontSize: 11, color: AppColors.accentSecondary)),
              ),
            ),
          const SizedBox(width: AppSpacing.sm),
          Switch(
            value: effectiveVisible,
            activeThumbColor: AppColors.accentPrimary,
            onChanged: (value) => repo.setOverride(employeeId, feature, value),
          ),
        ],
      );
    });
  }
}

/// Watches feature overrides for an ARBITRARY employee id (not
/// necessarily the one currently signed in) — used only by this admin
/// screen, kept separate from employee_feature_repository.dart's
/// "current employee" providers to avoid mixing the two concerns.
final _employeeOverridesProvider =
    StreamProvider.family<List<EmployeeFeatureOverrideRow>, int>((ref, employeeId) {
  return ref.watch(employeeFeatureRepositoryProvider).watchForEmployee(employeeId);
});

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
