import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/audit_log_repository.dart';

String expenseActionLabel(String action) => switch (action) {
      'expense_added' => 'إضافة مصروف',
      'expense_deleted' => 'حذف مصروف',
      'expense_category_changed' => 'تغيير تصنيف المصروف',
      _ => action,
    };

String _fmt(DateTime d) {
  final now = DateTime.now();
  final sameDay =
      d.year == now.year && d.month == now.month && d.day == now.day;
  String two(int n) => n.toString().padLeft(2, '0');
  final time = '${two(d.hour)}:${two(d.minute)}:${two(d.second)}';
  if (sameDay) return 'اليوم $time';
  return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
}

/// Expenses ("المصروفات"). Two tabs: the record itself (add / delete /
/// re-categorize) and its separate operations log (audit trail).
class ExpensesScreen extends StatelessWidget {
  const ExpensesScreen({super.key, this.initialTab = 0});

  final int initialTab;

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: initialTab,
      length: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('المصروفات', style: AppTypography.sectionTitle),
                    SizedBox(height: 2),
                    Text('كل مصروف بيتسجل في الحسابات تلقائيًا',
                        style: AppTypography.secondary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: AppRadius.mediumR,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: TabBar(
              indicator: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.25),
                borderRadius: AppRadius.mediumR,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: 'المصروفات'),
                Tab(text: 'سجل عمليات المصروفات'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          const Expanded(
            child: TabBarView(
              children: [
                _ExpensesTab(),
                _ExpenseLogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpensesTab extends ConsumerWidget {
  const _ExpensesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(allExpensesProvider);
    final permissions = ref.watch(permissionServiceProvider);
    final canEdit = permissions.canChangePrice;

    return expensesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child:
              Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
      data: (expenses) {
        final categories = expenses.map((e) => e.category).toSet().toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'الإجمالي: EGP ${expenses.fold<double>(0, (s, e) => s + e.amount).toStringAsFixed(0)}',
                    style: AppTypography.cardTitle,
                  ),
                ),
                if (canEdit)
                  SizedBox(
                    width: 160,
                    child: PrimaryButton(
                      label: 'إضافة مصروف',
                      icon: Icons.add_rounded,
                      expand: true,
                      onPressed: () => showAddExpenseDialog(context, ref),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: expenses.isEmpty
                  ? const Center(
                      child: Text('لا توجد مصروفات مسجلة',
                          style: TextStyle(color: AppColors.textTertiary)),
                    )
                  : ListView.separated(
                      itemCount: expenses.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final expense = expenses[i];
                        return GlassCard(
                          child: Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded,
                                  size: 20, color: AppColors.danger),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(expense.category,
                                        style: AppTypography.cardTitle),
                                    const SizedBox(height: 2),
                                    Text(
                                      expense.description?.isNotEmpty == true
                                          ? expense.description!
                                          : _fmt(expense.createdAt),
                                      style: const TextStyle(
                                          fontSize: 12,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Text('EGP ${expense.amount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary)),
                              if (canEdit) ...[
                                const SizedBox(width: AppSpacing.sm),
                                _ExpenseMenu(
                                    expense: expense, categories: categories),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

/// Rename-category / delete actions for one expense row.
class _ExpenseMenu extends ConsumerWidget {
  const _ExpenseMenu({required this.expense, required this.categories});

  final ExpenseRow expense;
  final List<String> categories;

  Future<void> _changeCategory(BuildContext context, WidgetRef ref) async {
    final selected = await showDialog<String>(
      context: context,
      builder: (dialogContext) => SimpleDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('تصنيف المصروف'),
        children: [
          for (final c in categories)
            SimpleDialogOption(
              onPressed: () => Navigator.of(dialogContext).pop(c),
              child: Text(c),
            ),
        ],
      ),
    );
    if (selected == null || selected == expense.category) return;
    await ref
        .read(expenseRepositoryProvider)
        .updateCategory(expense.id, selected);
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('حذف المصروف'),
        content: Text(
            'هيتم حذف مصروف "${expense.category}" قيمته EGP ${expense.amount.toStringAsFixed(2)} من السجل والحسابات. متابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(expenseRepositoryProvider).deleteExpense(expense.id);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          size: 20, color: AppColors.textSecondary),
      color: AppColors.bgElevated,
      onSelected: (v) {
        switch (v) {
          case 'category':
            _changeCategory(context, ref);
          case 'delete':
            _delete(context, ref);
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(
          value: 'category',
          child: ListTile(
            leading:
                Icon(Icons.category_rounded, color: AppColors.accentSecondary),
            title: Text('تغيير التصنيف'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: ListTile(
            leading:
                Icon(Icons.delete_forever_rounded, color: AppColors.danger),
            title: Text('حذف'),
            dense: true,
          ),
        ),
      ],
    );
  }
}

Future<void> showAddExpenseDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (_) => const _AddExpenseDialog(),
  );
}

class _AddExpenseDialog extends ConsumerStatefulWidget {
  const _AddExpenseDialog();

  @override
  ConsumerState<_AddExpenseDialog> createState() => _AddExpenseDialogState();
}

class _AddExpenseDialogState extends ConsumerState<_AddExpenseDialog> {
  final _category = TextEditingController();
  final _amount = TextEditingController();
  final _description = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _category.dispose();
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final category = _category.text.trim();
    final amount = double.tryParse(_amount.text.trim());
    if (category.isEmpty || amount == null || amount <= 0) {
      setState(() => _error = 'اكتب تصنيف ومبلغ صحيح');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final employee = ref.read(currentEmployeeProvider);
    try {
      await ref.read(expenseRepositoryProvider).addExpense(
            category: category,
            amount: amount,
            description: _description.text.trim().isEmpty
                ? null
                : _description.text.trim(),
            employeeId: employee?.id,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم تسجيل المصروف')));
      }
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
            const Text('مصروف جديد', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _category,
              autofocus: true,
              decoration:
                  const InputDecoration(labelText: 'التصنيف (كهربا، إيجار...)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'المبلغ (EGP)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'وصف (اختياري)'),
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
                    label: _saving ? 'جارٍ الحفظ...' : 'حفظ',
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

/// The expense operations log — a filtered audit trail of everything that
/// touched an expense (add / delete / re-categorize).
class _ExpenseLogTab extends ConsumerWidget {
  const _ExpenseLogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(expenseLogProvider);

    return logAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child:
              Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
      data: (rows) {
        if (rows.isEmpty) {
          return const Center(
            child: Text('لا توجد عمليات مسجلة بعد',
                style: TextStyle(color: AppColors.textTertiary)),
          );
        }
        return ListView.separated(
          itemCount: rows.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final row = rows[i];
            final amount = row.newValue ?? '';
            return GlassCard(
              child: Row(
                children: [
                  const Icon(Icons.history_rounded,
                      size: 20, color: AppColors.accentSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(expenseActionLabel(row.action),
                            style: AppTypography.cardTitle),
                        const SizedBox(height: 2),
                        Text(_fmt(row.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (amount.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.md),
                    Text(amount,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 13)),
                  ],
                  const SizedBox(width: AppSpacing.sm),
                  Text(row.performedByRole,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary)),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Audited operations where an expense was created or changed.
final expenseLogProvider = StreamProvider<List<AuditLogRow>>((ref) {
  return ref.watch(auditLogRepositoryProvider).watchFor(entityType: 'expense');
});
