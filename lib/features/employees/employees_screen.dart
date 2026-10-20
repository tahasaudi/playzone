import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/auth/role_provider.dart';
import '../../core/database/app_database.dart';
import '../../core/permissions/permission_service.dart';
import '../../core/utils/time_format.dart';
import '../../data/repositories/employee_repository.dart';

/// الموظفين — the roster and its two ledgers (حضور / مسحوبات).
///
/// This screen is about **employees**, and only employees. The owners
/// (طه ونادر) are partners of the business, not staff: they live on the
/// الشراكة screen with their profit share and withdrawals, and are neither
/// listed nor managed here. Their `isPartner` flag stays in the database —
/// the partnership math still reads it — but the roster filters them out so
/// the two concerns never mix in the UI.
///
/// Three tabs, one per question the counter asks:
///  * الفريق — who works here, and every admin action on an account.
///  * الحضور — who is on the floor right now, and the punch history.
///  * المسحوبات — money movements for staff (a normal employee's debt), which
///    is deliberately separate from a *partner's* withdrawals on الشراكة.
class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الموظفين', style: AppTypography.sectionTitle),
                    SizedBox(height: 2),
                    Text('فريق العمل المسجّل على النظام',
                        style: AppTypography.secondary),
                  ],
                ),
              ),
              if (ref.watch(permissionServiceProvider).canManageUsers)
                PrimaryButton(
                  label: 'إضافة موظف',
                  icon: Icons.person_add_rounded,
                  onPressed: () => showAddEmployeeDialog(context),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const _RosterTabs(),
          const SizedBox(height: AppSpacing.sm),
          const Expanded(
            child: TabBarView(
              children: [
                _TeamTab(),
                _AttendanceTab(),
                _WithdrawalsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The three-way switch at the top of the roster.
///
/// A left-aligned, pill-shaped TabBar rather than Flutter's full-width
/// underline: this is a control, not a page banner, and it should read as one
/// group of related views instead of three separate screens.
class _RosterTabs extends StatelessWidget {
  const _RosterTabs();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: AlignmentDirectional.centerStart,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: AppRadius.mediumR,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColors.accentPrimary.withValues(alpha: 0.25),
            borderRadius: AppRadius.smallR,
          ),
          labelColor: AppColors.textPrimary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle:
              const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          tabs: const [
            Tab(text: 'الفريق'),
            Tab(text: 'الحضور'),
            Tab(text: 'المسحوبات'),
          ],
        ),
      ),
    );
  }
}

// ── Tab 1: the team ──────────────────────────────────────────────────

class _TeamTab extends ConsumerStatefulWidget {
  const _TeamTab();

  @override
  ConsumerState<_TeamTab> createState() => _TeamTabState();
}

class _TeamTabState extends ConsumerState<_TeamTab> {
  bool _showInactive = false;

  @override
  Widget build(BuildContext context) {
    final employeesAsync = ref.watch(allEmployeesProvider);
    final openAsync = ref.watch(openAttendanceProvider);
    final canManage = ref.watch(permissionServiceProvider).canManageUsers;
    final onFloor = {
      for (final a in openAsync.value ?? const <EmployeeAttendanceRow>[])
        a.employeeId,
    };

    return employeesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('خطأ: $e',
              style: const TextStyle(color: AppColors.danger))),
      data: (all) {
        // Owners (شركاء) are not staff — see the screen doc. Filtered here so
        // every count and list below is about employees alone.
        final employees = all.where((e) => !e.isPartner).toList()
          ..sort((a, b) {
            if (a.active != b.active) return a.active ? -1 : 1;
            return a.name.compareTo(b.name);
          });
        final inactiveCount = employees.where((e) => !e.active).length;
        final shown =
            _showInactive ? employees : employees.where((e) => e.active).toList();

        if (employees.isEmpty) {
          return const Center(
            child: Text('لا يوجد موظفين مسجلين',
                style: TextStyle(color: AppColors.textTertiary)),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('${shown.length} موظف',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
                const Spacer(),
                if (inactiveCount > 0)
                  _ToggleChip(
                    label: _showInactive
                        ? 'إخفاء المعطّلين ($inactiveCount)'
                        : 'إظهار المعطّلين ($inactiveCount)',
                    onTap: () =>
                        setState(() => _showInactive = !_showInactive),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: ListView.separated(
                itemCount: shown.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _EmployeeRow(
                  employee: shown[i],
                  onFloor: onFloor.contains(shown[i].id),
                  canManage: canManage,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _EmployeeRow extends ConsumerWidget {
  const _EmployeeRow({
    required this.employee,
    required this.onFloor,
    required this.canManage,
  });

  final EmployeeRow employee;
  final bool onFloor;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = UserRole.values.firstWhere(
      (r) => r.name == employee.role,
      orElse: () => UserRole.cashier,
    );
    final disabled = !employee.active;

    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: GlassCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (disabled
                        ? AppColors.textTertiary
                        : AppColors.accentPrimary)
                    .withValues(alpha: 0.15),
                borderRadius: AppRadius.mediumR,
              ),
              child: Icon(Icons.badge_rounded,
                  color: disabled
                      ? AppColors.textTertiary
                      : AppColors.accentSecondary,
                  size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(employee.name,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.cardTitle),
                      ),
                      if (disabled) ...[
                        const SizedBox(width: 6),
                        const _Badge(
                            label: 'معطّل',
                            color: AppColors.statusMaintenance),
                      ],
                      if (onFloor) ...[
                        const SizedBox(width: 6),
                        const _Badge(
                            label: 'على الشيفت',
                            color: AppColors.statusAvailable),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(employee.phone,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            ),
            _Badge(
              label: role.labelAr,
              color: AppColors.accentSecondary,
              filled: true,
            ),
            if (canManage) ...[
              const SizedBox(width: AppSpacing.sm),
              _RowMenu(employee: employee),
            ],
          ],
        ),
      ),
    );
  }
}

/// The per-row action menu. Every action here is a repository call that is
/// itself permission-gated and audit-logged, so hiding the menu for a
/// non-admin is a courtesy, not the guard.
class _RowMenu extends ConsumerWidget {
  const _RowMenu({required this.employee});

  final EmployeeRow employee;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      tooltip: 'خيارات',
      color: AppColors.bgElevated,
      icon: const Icon(Icons.more_vert_rounded,
          color: AppColors.textSecondary, size: 20),
      onSelected: (value) => _handle(context, ref, value),
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('تعديل البيانات')),
        const PopupMenuItem(
            value: 'resetPin', child: Text('إعادة تعيين الرقم السري')),
        if (employee.active)
          const PopupMenuItem(value: 'deactivate', child: Text('تعطيل')),
        if (!employee.active)
          const PopupMenuItem(
              value: 'reactivate', child: Text('إعادة تفعيل')),
      ],
    );
  }

  Future<void> _handle(
      BuildContext context, WidgetRef ref, String action) async {
    final repo = ref.read(employeeRepositoryProvider);
    switch (action) {
      case 'edit':
        await showEditEmployeeDialog(context, employee);
      case 'resetPin':
        final pin = await askNewPin(context, employee);
        if (pin == null) return;
        await repo.resetPin(employee, pin);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('تم تغيير الرقم السري لـ${employee.name}')),
          );
        }
      case 'deactivate':
        final ok = await _confirm(context,
            'تعطيل ${employee.name}؟',
            'الموظف مش هيقدر يسجّل دخول بعد كده، وكل سجله التاريخي هيفضل محفوظ.');
        if (ok != true) return;
        await repo.deactivate(employee.id);
      case 'reactivate':
        await repo.reactivate(employee.id);
    }
  }
}

// ── Tab 2: attendance ────────────────────────────────────────────────

class _AttendanceTab extends ConsumerWidget {
  const _AttendanceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allEmployeesProvider);
    final openAsync = ref.watch(openAttendanceProvider);
    final historyAsync = ref.watch(employeeAttendanceProvider);
    final canManage = ref.watch(permissionServiceProvider).canManageUsers;

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('خطأ: $e',
              style: const TextStyle(color: AppColors.danger))),
      data: (all) {
        final employees = all.where((e) => !e.isPartner).toList();
        final byId = {for (final e in employees) e.id: e};
        final open = (openAsync.value ?? const <EmployeeAttendanceRow>[])
            .where((a) => byId.containsKey(a.employeeId))
            .toList();
        final openIds = {for (final a in open) a.employeeId};
        final history = (historyAsync.value ?? const <EmployeeAttendanceRow>[])
            .where((a) => byId.containsKey(a.employeeId))
            .toList();

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Right column: who is on the floor, with a clock in/out button.
            SizedBox(
              width: 280,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.groups_rounded,
                            size: 16, color: AppColors.accentSecondary),
                        const SizedBox(width: 6),
                        Text('على الشيفت دلوقتي (${open.length})',
                            style: AppTypography.cardTitle),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: employees.isEmpty
                          ? const Center(
                              child: Text('مفيش موظفين',
                                  style: TextStyle(
                                      color: AppColors.textTertiary)))
                          : ListView(
                              children: [
                                for (final e in employees)
                                  _AttendancePersonRow(
                                    employee: e,
                                    open: openIds.contains(e.id),
                                    canManage: canManage,
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            // Left column: the punch register.
            Expanded(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('سجل الحضور والانصراف',
                        style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: history.isEmpty
                          ? const Center(
                              child: Text('مفيش تسجيلات حضور بعد',
                                  style: TextStyle(
                                      color: AppColors.textTertiary)))
                          : ListView.separated(
                              itemCount: history.length,
                              separatorBuilder: (_, __) => const Divider(
                                  color: AppColors.glassBorder,
                                  height: AppSpacing.md),
                              itemBuilder: (_, i) {
                                final a = history[i];
                                final e = byId[a.employeeId];
                                return _AttendanceHistoryRow(
                                    row: a, name: e?.name ?? '—');
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _AttendancePersonRow extends ConsumerWidget {
  const _AttendancePersonRow({
    required this.employee,
    required this.open,
    required this.canManage,
  });

  final EmployeeRow employee;
  final bool open;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(employeeRepositoryProvider);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(open ? Icons.login_rounded : Icons.logout_rounded,
              size: 16,
              color: open ? AppColors.statusAvailable : AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(employee.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: 13,
                    color: open
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
          ),
          if (canManage)
            TextButton(
              onPressed: () async {
                if (open) {
                  await repo.clockOut(employee.id);
                } else {
                  await repo.clockIn(employee.id);
                }
              },
              style: TextButton.styleFrom(
                foregroundColor: open
                    ? AppColors.textSecondary
                    : AppColors.statusAvailable,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                minimumSize: const Size(0, 30),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(open ? 'انصراف' : 'حضور',
                  style: const TextStyle(fontSize: 12)),
            ),
        ],
      ),
    );
  }
}

class _AttendanceHistoryRow extends StatelessWidget {
  const _AttendanceHistoryRow({required this.row, required this.name});

  final EmployeeAttendanceRow row;
  final String name;

  @override
  Widget build(BuildContext context) {
    final open = row.checkOut == null;
    final duration = row.checkOut?.difference(row.checkIn);
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: AppTypography.body),
              const SizedBox(height: 2),
              Text(
                '${stampOf(row.checkIn)}'
                '${row.checkOut != null ? '  ←  ${clockOf(row.checkOut!)}' : ''}',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        if (open)
          const _Badge(
              label: 'مفتوح', color: AppColors.statusAvailable, filled: true)
        else if (duration != null)
          Text(_durationLabel(duration),
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }

  String _durationLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    if (h == 0) return '$m دقيقة';
    return '$h س $m د';
  }
}

// ── Tab 3: withdrawals / repayments ──────────────────────────────────

class _WithdrawalsTab extends ConsumerWidget {
  const _WithdrawalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allAsync = ref.watch(allEmployeesProvider);
    final txAsync = ref.watch(employeeTransactionsProvider);
    final canManage = ref.watch(permissionServiceProvider).canManageUsers;

    return allAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child: Text('خطأ: $e',
              style: const TextStyle(color: AppColors.danger))),
      data: (all) {
        final employees = all.where((e) => !e.isPartner).toList();
        final byId = {for (final e in employees) e.id: e};
        // Only staff movements belong here — a partner's ledge is on الشراكة.
        final tx = (txAsync.value ?? const <EmployeeTransactionRow>[])
            .where((t) => byId.containsKey(t.employeeId))
            .toList();

        final balance = <int, double>{};
        for (final t in tx) {
          final cur = balance[t.employeeId] ?? 0;
          balance[t.employeeId] =
              cur + (t.kind == 'withdraw' ? t.amount : -t.amount);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 300,
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.account_balance_wallet_rounded,
                            size: 16, color: AppColors.accentSecondary),
                        const SizedBox(width: 6),
                        const Text('أرصدة الموظفين',
                            style: AppTypography.cardTitle),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: employees.isEmpty
                          ? const Center(
                              child: Text('مفيش موظفين',
                                  style: TextStyle(
                                      color: AppColors.textTertiary)))
                          : ListView(
                              children: [
                                for (final e in employees)
                                  _BalanceRow(
                                    employee: e,
                                    balance: balance[e.id] ?? 0,
                                    canManage: canManage,
                                  ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: GlassCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('حركات المسحوبات والسداد',
                        style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: tx.isEmpty
                          ? const Center(
                              child: Text('مفيش حركات مسحوبات بعد',
                                  style: TextStyle(
                                      color: AppColors.textTertiary)))
                          : ListView.separated(
                              itemCount: tx.length,
                              separatorBuilder: (_, __) => const Divider(
                                  color: AppColors.glassBorder,
                                  height: AppSpacing.md),
                              itemBuilder: (_, i) {
                                final t = tx[i];
                                final e = byId[t.employeeId];
                                return _TransactionRow(
                                  row: t,
                                  name: e?.name ?? '—',
                                  canDelete:
                                      ref
                                          .watch(permissionServiceProvider)
                                          .canEditSettings,
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BalanceRow extends ConsumerWidget {
  const _BalanceRow({
    required this.employee,
    required this.balance,
    required this.canManage,
  });

  final EmployeeRow employee;
  final double balance;
  final bool canManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            child: Text(employee.name,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 13)),
          ),
          Text(
            _egp(balance),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: balance > 0.005
                  ? AppColors.danger
                  : AppColors.textSecondary,
            ),
          ),
          if (canManage)
            IconButton(
              tooltip: 'تسجيل مسحوبات/سداد',
              onPressed: () =>
                  showStaffTransactionDialog(context, ref, employee),
              icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
              color: AppColors.accentSecondary,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({
    required this.row,
    required this.name,
    required this.canDelete,
  });

  final EmployeeTransactionRow row;
  final String name;
  final bool canDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWithdraw = row.kind == 'withdraw';
    return Row(
      children: [
        Icon(isWithdraw ? Icons.call_made_rounded : Icons.call_received_rounded,
            size: 15,
            color: isWithdraw ? AppColors.danger : AppColors.statusAvailable),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$name — ${isWithdraw ? 'مسحوبات' : 'سداد'}',
                  style: AppTypography.body),
              const SizedBox(height: 2),
              Text(
                stampOf(row.createdAt) +
                    (row.note != null && row.note!.isNotEmpty
                        ? '  ·  ${row.note}'
                        : ''),
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        Text(_egp(row.amount),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
        if (canDelete)
          IconButton(
            tooltip: 'حذف الحركة',
            onPressed: () async {
              final ok = await _confirm(
                  context,
                  'حذف الحركة؟',
                  '${isWithdraw ? 'مسحوبات' : 'سداد'} بمبلغ ${_egp(row.amount)} لـ$name هيتشال خالص.');
              if (ok != true) return;
              await ref
                  .read(employeeRepositoryProvider)
                  .deleteTransaction(row.id);
            },
            icon: const Icon(Icons.delete_outline_rounded, size: 18),
            color: AppColors.textTertiary,
            visualDensity: VisualDensity.compact,
          ),
      ],
    );
  }
}

// ── Dialogs ──────────────────────────────────────────────────────────

/// Add-employee dialog (name/phone/role/PIN). Returns the new id so callers
/// that need to select it can.
Future<int?> showAddEmployeeDialog(BuildContext context) {
  return showDialog<int>(
    context: context,
    builder: (_) => const _AddEmployeeDialog(),
  );
}

/// Edit an existing employee: name, phone, and job role.
Future<void> showEditEmployeeDialog(
    BuildContext context, EmployeeRow employee) {
  return showDialog<void>(
    context: context,
    builder: (_) => _EditEmployeeDialog(employee: employee),
  );
}

/// Asks for a new PIN for an employee. Returns the entered PIN, or null if
/// cancelled. The write is the caller's to make (it needs a WidgetRef).
///
/// Confirm-based on purpose: the raw PIN is never stored, so there is nothing
/// to show back and no way to undo a typo — the only safe options are "type it
/// again" and "cancel".
Future<String?> askNewPin(BuildContext context, EmployeeRow employee) async {
  final controller = TextEditingController();
  final pin = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: Text('رمز سري جديد — ${employee.name}'),
      content: TextField(
        controller: controller,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 10,
        decoration:
            const InputDecoration(labelText: 'الرقم السري (4 أرقام على الأقل)'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () {
            final value = controller.text.trim();
            if (value.length < 4) return;
            Navigator.of(ctx).pop(value);
          },
          child: const Text('حفظ'),
        ),
      ],
    ),
  );
  controller.dispose();
  return pin;
}

/// Withdraw/repay against a *staff* member's balance (not a partner's share).
Future<void> showStaffTransactionDialog(
    BuildContext context, WidgetRef ref, EmployeeRow employee) async {
  final result = await showDialog<_TxResult>(
    context: context,
    builder: (_) => _StaffTransactionDialog(employeeName: employee.name),
  );
  if (result == null) return;
  await ref.read(employeeRepositoryProvider).addTransaction(
        employeeId: employee.id,
        kind: result.kind,
        amount: result.amount,
        note: result.note,
      );
}

Future<bool?> _confirm(BuildContext context, String title, String body) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: Text(title),
      content: Text(body, style: const TextStyle(fontSize: 13)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: TextButton.styleFrom(foregroundColor: AppColors.danger),
          child: const Text('تأكيد'),
        ),
      ],
    ),
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
      setState(() =>
          _error = 'الاسم ورقم الموبايل مطلوبين والرقم السري 4 أرقام على الأقل');
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
    return _DialogShell(
      title: 'موظف جديد',
      subtitle: 'الموظف بيسجل دخوله بالرقم السري، وصلاحياته من شاشة الصلاحيات',
      children: [
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
          decoration:
              const InputDecoration(labelText: 'الرقم السري (4 أرقام على الأقل)'),
        ),
        const SizedBox(height: AppSpacing.sm),
        _RoleDropdown(value: _role, onChanged: (v) => setState(() => _role = v)),
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
    );
  }
}

class _EditEmployeeDialog extends ConsumerStatefulWidget {
  const _EditEmployeeDialog({required this.employee});

  final EmployeeRow employee;

  @override
  ConsumerState<_EditEmployeeDialog> createState() =>
      _EditEmployeeDialogState();
}

class _EditEmployeeDialogState extends ConsumerState<_EditEmployeeDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.employee.name);
  late final TextEditingController _phone =
      TextEditingController(text: widget.employee.phone);
  late String _role = widget.employee.role;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final phone = _phone.text.trim();
    if (name.isEmpty || phone.isEmpty) {
      setState(() => _error = 'الاسم ورقم الموبايل مطلوبين');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(employeeRepositoryProvider);
    try {
      if (name != widget.employee.name) {
        await repo.rename(widget.employee.id, name);
      }
      if (phone != widget.employee.phone) {
        await repo.setPhone(widget.employee.id, phone);
      }
      if (_role != widget.employee.role) {
        await repo.setRole(widget.employee.id, _role);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: 'تعديل — ${widget.employee.name}',
      children: [
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
        const SizedBox(height: AppSpacing.sm),
        _RoleDropdown(value: _role, onChanged: (v) => setState(() => _role = v)),
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
                label: _saving ? 'جارٍ الحفظ...' : 'حفظ',
                icon: Icons.check_rounded,
                expand: true,
                onPressed: _saving ? null : _save,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TxResult {
  _TxResult(this.kind, this.amount, this.note);
  final String kind;
  final double amount;
  final String? note;
}

class _StaffTransactionDialog extends StatefulWidget {
  const _StaffTransactionDialog({required this.employeeName});

  final String employeeName;

  @override
  State<_StaffTransactionDialog> createState() =>
      _StaffTransactionDialogState();
}

class _StaffTransactionDialogState extends State<_StaffTransactionDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
  String _kind = 'withdraw';
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  void _submit() {
    final value = double.tryParse(_amount.text.trim());
    if (value == null || value <= 0) {
      setState(() => _error = 'اكتب مبلغ صحيح أكبر من صفر');
      return;
    }
    Navigator.of(context).pop(_TxResult(
      _kind,
      value,
      _note.text.trim().isEmpty ? null : _note.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: Text('حركة مالية — ${widget.employeeName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _KindChip(
                  label: 'مسحوبات',
                  selected: _kind == 'withdraw',
                  color: AppColors.danger,
                  onTap: () => setState(() => _kind = 'withdraw'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _KindChip(
                  label: 'سداد',
                  selected: _kind == 'repayment',
                  color: AppColors.statusAvailable,
                  onTap: () => setState(() => _kind = 'repayment'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _amount,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'المبلغ',
              prefixText: 'EGP ',
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _note,
            decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(_error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        TextButton(
          onPressed: _submit,
          child: const Text('تسجيل'),
        ),
      ],
    );
  }
}

// ── Shared bits ──────────────────────────────────────────────────────

/// The standard modal used by the add/edit dialogs, so both read the same.
class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.title,
    this.subtitle,
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;

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
            Text(title, style: AppTypography.sectionTitle),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: AppTypography.secondary),
            ],
            const SizedBox(height: AppSpacing.lg),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  const _RoleDropdown({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
              value: value,
              isExpanded: true,
              dropdownColor: AppColors.bgElevated,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              items: [
                for (final role in UserRole.values)
                  DropdownMenuItem(
                    value: role.name,
                    child: Text(role.labelAr),
                  ),
              ],
              onChanged: (v) => onChanged(v ?? 'cashier'),
            ),
          ),
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    this.filled = false,
  });

  final String label;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: filled ? 0.18 : 0.25),
        borderRadius: AppRadius.smallR,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: filled ? color : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  const _ToggleChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: AppRadius.smallR,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 11, color: AppColors.accentSecondary)),
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : AppColors.glassFill,
          borderRadius: AppRadius.smallR,
          border: Border.all(
              color: selected ? color : AppColors.glassBorder),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            color: selected ? color : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// EGP, two decimals like every other money figure in the app.
String _egp(double v) => v < -0.005
    ? '− EGP ${v.abs().toStringAsFixed(2)}'
    : 'EGP ${v.toStringAsFixed(2)}';
