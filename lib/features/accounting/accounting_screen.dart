import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/account_repository.dart';
import '../../core/utils/time_format.dart';

String _fmt(DateTime d) => stampOf(d);

String _sourceLabel(String source) => switch (source) {
      'invoice' => 'فاتورة بيع',
      'expense' => 'مصروف',
      'refund' => 'مرتجع',
      'manual' => 'يدوي',
      _ => source,
    };

/// Accounting ("شاشة الحسابات"). Every transaction in the app is
/// auto-posted into a category (مبيعات الألعاب، مبيعات الكافيه،
/// المصروفات، المرتجعات) — this screen shows the categories with their
/// running balances and every movement. Category names are editable by an
/// admin (canEditSettings).
class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> {
  int? _selectedAccountId;

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final entriesAsync = ref.watch(accountEntriesProvider);
    final permissions = ref.watch(permissionServiceProvider);
    final repo = ref.read(accountRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الحسابات', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('كل حركة مالية بتتسجل تلقائيًا في تصنيفها',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: accountsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (accounts) {
              if (accounts.isEmpty) {
                return const Center(
                  child: Text('لا يوجد بنود حسابية',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return entriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('خطأ: $e',
                        style: const TextStyle(color: AppColors.danger))),
                data: (entries) {
                  final totalIn = entries
                      .where((e) => e.direction == 'in')
                      .fold<double>(0, (s, e) => s + e.amount);
                  final totalOut = entries
                      .where((e) => e.direction == 'out')
                      .fold<double>(0, (s, e) => s + e.amount);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GlassCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                  'إجمالي الداخل: EGP ${totalIn.toStringAsFixed(2)}',
                                  style: AppTypography.cardTitle),
                            ),
                            Expanded(
                              child: Text(
                                  'إجمالي الخارج: EGP ${totalOut.toStringAsFixed(2)}',
                                  style: AppTypography.cardTitle),
                            ),
                            Expanded(
                              child: Text(
                                  'الصافي: EGP ${(totalIn - totalOut).toStringAsFixed(2)}',
                                  style: TextStyle(
                                      color: totalIn - totalOut >= 0
                                          ? AppColors.statusAvailable
                                          : AppColors.danger,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      // Category balance cards.
                      LayoutBuilder(builder: (context, constraints) {
                        final columns = constraints.maxWidth > 1200
                            ? 4
                            : constraints.maxWidth > 700
                                ? 2
                                : 1;
                        return GridView.count(
                          crossAxisCount: columns,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: AppSpacing.sm,
                          crossAxisSpacing: AppSpacing.sm,
                          childAspectRatio: 2.6,
                          children: [
                            for (final account in accounts)
                              GestureDetector(
                                onTap: () => setState(() => _selectedAccountId =
                                    _selectedAccountId == account.id
                                        ? null
                                        : account.id),
                                child: _AccountBalanceCard(
                                  account: account,
                                  balance: repo.balanceOf(account, entries),
                                  selected: _selectedAccountId == account.id,
                                  canRename: permissions.canEditSettings,
                                ),
                              ),
                          ],
                        );
                      }),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        _selectedAccountId == null
                            ? 'كل الحركات'
                            : 'حركات ${accounts.where((a) => a.id == _selectedAccountId).map((a) => a.name).firstOrNull ?? ''}',
                        style: AppTypography.cardTitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Expanded(
                        child: ListView.separated(
                          itemCount: entries.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: AppSpacing.sm),
                          itemBuilder: (_, i) {
                            final entry = entries[i];
                            if (_selectedAccountId != null &&
                                entry.accountId != _selectedAccountId) {
                              return const SizedBox.shrink();
                            }
                            final accountName = accounts
                                .where((a) => a.id == entry.accountId)
                                .map((a) => a.name)
                                .firstOrNull;
                            final isIn = entry.direction == 'in';
                            return GlassCard(
                              child: Row(
                                children: [
                                  Icon(
                                    isIn
                                        ? Icons.arrow_downward_rounded
                                        : Icons.arrow_upward_rounded,
                                    size: 18,
                                    color: isIn
                                        ? AppColors.statusAvailable
                                        : AppColors.danger,
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${accountName ?? 'بند'} — ${_sourceLabel(entry.source)}',
                                          style: AppTypography.cardTitle,
                                        ),
                                        // "اتباع من اي؟" — the note carries
                                        // the category and the exact items
                                        // behind this entry.
                                        if (entry.note?.isNotEmpty == true) ...[
                                          const SizedBox(height: 3),
                                          Container(
                                            width: double.infinity,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: AppColors.accentPrimary
                                                  .withOpacity(0.10),
                                              borderRadius: AppRadius.smallR,
                                            ),
                                            child: Text(
                                              entry.note!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textPrimary,
                                              ),
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 3),
                                        Text(
                                          _fmt(entry.createdAt),
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textTertiary),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isIn ? '+' : '-'} EGP ${entry.amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        color: isIn
                                            ? AppColors.statusAvailable
                                            : AppColors.danger),
                                  ),
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
            },
          ),
        ),
      ],
    );
  }
}

class _AccountBalanceCard extends ConsumerWidget {
  const _AccountBalanceCard({
    required this.account,
    required this.balance,
    required this.selected,
    required this.canRename,
  });

  final AccountRow account;
  final double balance;
  final bool selected;
  final bool canRename;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: account.name);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 360,
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
              const Text('تغيير اسم البند', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم البند'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    label: 'إلغاء',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    label: 'حفظ',
                    icon: Icons.check_rounded,
                    onPressed: () =>
                        Navigator.of(context).pop(controller.text.trim()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || result.isEmpty || result == account.name) return;
    await ref.read(accountRepositoryProvider).rename(account.id, result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final positive = balance >= 0;
    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(account.name, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                  account.kind == 'revenue' ? 'إيراد' : 'مصروف',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
                const SizedBox(height: 4),
                Text(
                  'EGP ${balance.toStringAsFixed(2)}',
                  style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: positive
                          ? AppColors.statusAvailable
                          : AppColors.danger),
                ),
              ],
            ),
          ),
          if (canRename)
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  size: 18, color: AppColors.textSecondary),
              onPressed: () => _rename(context, ref),
            ),
          if (selected)
            const Icon(Icons.filter_alt_rounded,
                size: 16, color: AppColors.accentSecondary),
        ],
      ),
    );
  }
}
