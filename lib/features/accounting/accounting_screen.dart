import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/account_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../core/utils/time_format.dart';
import '../reports/report_period_selector.dart';

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
/// running balances and their movements. Category names are editable by an
/// admin (canEditSettings).
///
/// The screen is windowed: it shows one period at a time (today by default)
/// and the totals at the top are computed from exactly the movements listed
/// underneath. Selecting a category narrows both together, so the headline
/// numbers and the table can never disagree — which they did when the totals
/// were summed over the entire history while the list was filtered.
class AccountingScreen extends ConsumerStatefulWidget {
  const AccountingScreen({super.key});

  @override
  ConsumerState<AccountingScreen> createState() => _AccountingScreenState();
}

class _AccountingScreenState extends ConsumerState<AccountingScreen> {
  int? _selectedAccountId;
  bool _exporting = false;

  /// Exports the current window's movements as a UTF-8 CSV that opens in Excel.
  ///
  /// Follows the same shape as the reports screen's export (BOM for Arabic, one
  /// section with a header row) so the two files feel like they came from the
  /// same program. The file lands in Documents with a timestamped name, and the
  /// snackbar offers to reveal it.
  ///
  /// The rows themselves no longer appear on the screen — the ledger shows its
  /// totals and its books, not a transaction list — so this export is how the
  /// individual movements are reached when the accountant asks for them.
  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final accounts = ref.read(accountsProvider).valueOrNull ?? const [];
      final period = ref.read(accountingPeriodProvider);
      final range = currentReportRange(period);
      final entries = await ref
          .read(accountRepositoryProvider)
          .watchEntriesBetween(from: range.from, to: range.to)
          .first;

      final nameOf = {for (final a in accounts) a.id: a.name};
      final selected =
          accounts.where((a) => a.id == _selectedAccountId).firstOrNull;
      // Export exactly what the owner is looking at: the same period and the
      // same category filter, so the file and the screen agree.
      final rows = _selectedAccountId == null
          ? entries
          : entries.where((e) => e.accountId == _selectedAccountId).toList();

      String csvCell(String s) {
        final clean = s.replaceAll('"', '""');
        return clean.contains(',') ||
                clean.contains('"') ||
                clean.contains('\n')
            ? '"$clean"'
            : clean;
      }

      final sb = StringBuffer();
      sb.write('\uFEFF');
      final scope = selected == null ? 'كل البنود' : selected.name;
      sb.writeln(
          'حركات الحسابات — $scope (${stampOf(range.from)} - ${stampOf(range.to)})');
      sb.writeln('');
      sb.writeln('التاريخ,البند,المصدر,النوع,المبلغ,ملاحظة');
      for (final e in rows) {
        final isIn = e.direction == 'in';
        sb.writeln([
          csvCell(stampOf(e.createdAt)),
          csvCell(nameOf[e.accountId] ?? 'بند'),
          csvCell(_sourceLabel(e.source)),
          isIn ? 'داخل' : 'خارج',
          (isIn ? '' : '-') + e.amount.toStringAsFixed(2),
          csvCell(e.note ?? ''),
        ].join(','));
      }

      final dir =
          Directory('${Platform.environment['USERPROFILE'] ?? '.'}\\Documents');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('.', '')
          .replaceAll('-', '');
      final path = '${dir.path}\\playzone_ledger_$stamp.csv';
      File(path).writeAsStringSync(sb.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم حفظ ${rows.length} حركة: $path'),
        action: SnackBarAction(
          label: 'فتح الملف',
          onPressed: () =>
              Process.start('explorer', ['/select,', path]).ignore(),
        ),
      ));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('فشل التصدير: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _addAccount() async {
    final created = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddAccountDialog(),
    );
    if (created == true) ref.invalidate(accountsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final accountsAsync = ref.watch(accountsProvider);
    final entriesAsync = ref.watch(accountingEntriesProvider);
    final prevEntriesAsync = ref.watch(previousAccountingEntriesProvider);
    final permissions = ref.watch(permissionServiceProvider);
    final repo = ref.read(accountRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الحسابات', style: AppTypography.sectionTitle),
                  SizedBox(height: 2),
                  Text('كل حركة مالية بتتسجل تلقائيًا في تصنيفها',
                      style: AppTypography.secondary),
                ],
              ),
            ),
            ReportPeriodSelector(provider: accountingPeriodProvider),
            const SizedBox(width: AppSpacing.md),
            TextButton.icon(
              onPressed: _exporting ? null : _exportCsv,
              icon: const Icon(Icons.download_rounded, size: 18),
              label: Text(_exporting ? 'جارٍ التصدير...' : 'تصدير Excel'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentSecondary,
              ),
            ),
            if (permissions.canEditSettings)
              TextButton.icon(
                onPressed: _addAccount,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('بند جديد'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.accentSecondary,
                ),
              ),
          ],
        ),
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
                data: (allEntries) {
                  // The category filter is applied once, here — every number on
                  // the screen (headline totals, card balances, the list) is
                  // derived from this same slice. The old code re-checked the
                  // filter inside the list builder and returned an empty box for
                  // skipped rows, which left blank gaps in the table instead of
                  // hiding them.
                  final entries = _selectedAccountId == null
                      ? allEntries
                      : allEntries
                          .where((e) => e.accountId == _selectedAccountId)
                          .toList();
                  final totals = repo.totalsOf(accounts, entries);
                  final selected = accounts
                      .where((a) => a.id == _selectedAccountId)
                      .firstOrNull;
                  // Only the categories that actually moved something in the
                  // window earn a card. An idle book is noise the owner has to
                  // scan past on every visit, and on a quiet day that is most of
                  // them.
                  final active = accounts
                      .where((a) => allEntries.any((e) => e.accountId == a.id))
                      .toList();
                  // The previous window is compared on the same category
                  // filter, so "الصافي" moves by the same thing on both sides.
                  final prevAll = prevEntriesAsync.valueOrNull ?? allEntries;
                  final prevEntries = _selectedAccountId == null
                      ? prevAll
                      : prevAll
                          .where((e) => e.accountId == _selectedAccountId)
                          .toList();
                  final prev = repo.totalsOf(accounts, prevEntries);
                  final hasPrevious = prevAll.isNotEmpty;

                  // The ledger is a summary now: headline figures over the whole
                  // window, then one card per book that moved. The per-movement
                  // list lives in the CSV export instead of on the screen, so
                  // the body scrolls rather than fighting for a slice of it.
                  return SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: _TotalTile(
                                  label: 'إجمالي الداخل',
                                  value: totals.totalIn,
                                  color: AppColors.statusAvailable,
                                  previous: hasPrevious ? prev.totalIn : null,
                                  upIsGood: true,
                                ),
                              ),
                              Expanded(
                                child: _TotalTile(
                                  label: 'إجمالي الخارج',
                                  value: totals.totalOut,
                                  color: AppColors.danger,
                                  previous: hasPrevious ? prev.totalOut : null,
                                  upIsGood: false,
                                ),
                              ),
                              Expanded(
                                child: _TotalTile(
                                  label: 'الصافي',
                                  value: totals.net,
                                  color: totals.net >= 0
                                      ? AppColors.statusAvailable
                                      : AppColors.danger,
                                  previous: hasPrevious ? prev.net : null,
                                  upIsGood: true,
                                  emphasized: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: [
                            const Text('البنود',
                                style: AppTypography.cardTitle),
                            const Spacer(),
                            if (selected != null)
                              TextButton.icon(
                                onPressed: () =>
                                    setState(() => _selectedAccountId = null),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('إلغاء الفلتر'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.accentSecondary,
                                ),
                              ),
                            Text(
                              selected == null
                                  ? 'الإجماليات فوق لكل البنود'
                                  : 'الإجماليات فوق لبند ${selected.name}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textTertiary),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        if (active.isEmpty)
                          const Padding(
                            padding:
                                EdgeInsets.symmetric(vertical: AppSpacing.lg),
                            child: Text(
                                'مفيش حركات في الفترة دي — جرّب تغيّر الفترة من فوق.',
                                style: TextStyle(
                                    color: AppColors.textTertiary,
                                    fontSize: 13)),
                          )
                        else
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
                                for (final account in active)
                                  GestureDetector(
                                    onTap: () => setState(() =>
                                        _selectedAccountId =
                                            _selectedAccountId == account.id
                                                ? null
                                                : account.id),
                                    child: _AccountBalanceCard(
                                      account: account,
                                      balance: repo.balanceOf(account, entries),
                                      selected:
                                          _selectedAccountId == account.id,
                                      canRename: permissions.canEditSettings,
                                    ),
                                  ),
                              ],
                            );
                          }),
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

/// One book (بند) with its net balance for the current window. Tapping the card
/// narrows the headline figures to that book, so "الصافي" answers "from where?".
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
              const Text('╪¬╪║┘è┘è╪▒ ╪º╪│┘à ╪º┘ä╪¿┘å╪»',
                  style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                autofocus: true,
                decoration:
                    const InputDecoration(labelText: '╪º╪│┘à ╪º┘ä╪¿┘å╪»'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    label: '╪Ñ┘ä╪║╪º╪í',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    label: '╪¡┘ü╪╕',
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
                  account.kind == 'revenue' ? '╪Ñ┘è╪▒╪º╪»' : '┘à╪╡╪▒┘ê┘ü',
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

/// A read-only look at the invoice that posted a sales movement.
///
/// Deliberately not an editor: a settled bill is the record of money already
/// taken, and changing it from the ledger would move numbers out from under
/// every report that already counted it. Corrections belong in the refunds

/// One headline figure (الداخل / الخارج / الصافي) with its caption, and — when
/// a previous window exists to compare against — how it moved since.
class _TotalTile extends StatelessWidget {
  const _TotalTile({
    required this.label,
    required this.value,
    required this.color,
    this.previous,
    this.upIsGood = true,
    this.emphasized = false,
  });

  final String label;
  final double value;
  final Color color;

  /// The same figure for the previous window, or null when there is nothing to
  /// compare against (a first day of trading).
  final double? previous;

  /// Whether a rise in this figure is good news. "الخارج" going up is not, so
  /// its arrow is coloured by the opposite of its own direction.
  final bool upIsGood;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final Change? change = _change();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(
          'EGP ${value.toStringAsFixed(2)}',
          style: TextStyle(
            color: color,
            fontWeight: emphasized ? FontWeight.w800 : FontWeight.w600,
            fontSize: emphasized ? 16 : 14,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        if (change != null) ...[
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(
                change.delta >= 0
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                size: 12,
                color:
                    change.good ? AppColors.statusAvailable : AppColors.danger,
              ),
              const SizedBox(width: 3),
              Text(
                '${change.percent.abs().toStringAsFixed(0)}% عن الفترة السابقة',
                style: TextStyle(
                  fontSize: 10,
                  color: change.good
                      ? AppColors.statusAvailable
                      : AppColors.danger,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// The comparison against [previous], or null when there is none to make.
  ///
  /// A previous window of zero has no percentage — "أعلى بنسبة لا نهائية" says
  /// nothing — so growth from nothing is reported as a plain rise instead of a
  /// ratio.
  Change? _change() {
    final was = previous;
    if (was == null || was == 0) return null;
    final delta = value - was;
    final improved = upIsGood ? delta >= 0 : delta <= 0;
    return Change(
      delta: delta,
      percent: delta / was.abs() * 100,
      good: improved,
    );
  }
}

/// How one figure moved between two windows.
class Change {
  const Change({
    required this.delta,
    required this.percent,
    required this.good,
  });

  final double delta;
  final double percent;

  /// Whether the movement is the direction the shop wants.
  final bool good;
}

/// Adds a category to the chart of accounts.
///
/// The seeded books cover what the app knows how to post automatically. A shop
/// still needs lines of its own ΓÇö ╪Ñ┘è╪¼╪º╪▒╪î ┘å┘é┘ä╪î ╪╡┘è╪º┘å╪⌐ ΓÇö and putting them under
/// "╪º┘ä┘à╪╡╪▒┘ê┘ü╪º╪¬" loses the breakdown the owner opened this screen to find.
class _AddAccountDialog extends ConsumerStatefulWidget {
  const _AddAccountDialog();

  @override
  ConsumerState<_AddAccountDialog> createState() => _AddAccountDialogState();
}

class _AddAccountDialogState extends ConsumerState<_AddAccountDialog> {
  final _name = TextEditingController();
  String _kind = 'expense';
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '╪º┘â╪¬╪¿ ╪º╪│┘à ╪º┘ä╪¿┘å╪»');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(accountRepositoryProvider)
          .createAccount(name: name, kind: _kind);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: const Text('╪¿┘å╪» ╪¡╪│╪º╪¿ ╪¼╪»┘è╪»'),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '╪º┘ä╪¿┘å╪» ╪¿┘è┘ü╪╢┘ä ┘ü╪º╪╢┘è ┘ä╪¡╪» ┘à╪º ╪¬╪│╪¼┘æ┘ä ╪╣┘ä┘è┘ç ╪¡╪▒┘â╪⌐. ╪¬┘é╪»╪▒ ╪¬╪║┘è┘æ╪▒ ╪º╪│┘à┘ç ┘ü┘è ╪ú┘è ┘ê┘é╪¬ ┘à┘å ╪º┘ä┘â╪º╪▒╪¬.',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: '╪º╪│┘à ╪º┘ä╪¿┘å╪»'),
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _kindChoice('expense', '┘à╪╡╪▒┘ê┘ü',
                      '┘ü┘ä┘ê╪│ ╪«╪º╪▒╪¼╪⌐ (╪Ñ┘è╪¼╪º╪▒╪î ┘å┘é┘ä╪î ╪╡┘è╪º┘å╪⌐)'),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _kindChoice('revenue', '╪Ñ┘è╪▒╪º╪»',
                      '┘ü┘ä┘ê╪│ ╪»╪º╪«┘ä╪⌐ (┘à╪¿┘è╪╣╪º╪¬ ╪Ñ╪╢╪º┘ü┘è╪⌐)'),
                ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!,
                  style:
                      const TextStyle(color: AppColors.danger, fontSize: 13)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('╪Ñ┘ä╪║╪º╪í'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('╪Ñ╪╢╪º┘ü╪⌐'),
        ),
      ],
    );
  }

  Widget _kindChoice(String value, String label, String hint) {
    final selected = _kind == value;
    return GestureDetector(
      onTap: () => setState(() => _kind = value),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary.withValues(alpha: 0.15)
              : AppColors.glassFill,
          borderRadius: AppRadius.smallR,
          border: Border.all(
            color:
                selected ? AppColors.glassBorderPurple : AppColors.glassBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                )),
            const SizedBox(height: 2),
            Text(hint,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
