import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/stock_count_repository.dart';

String _two(int n) => n.toString().padLeft(2, '0');

String _fmt(DateTime d) => '${_two(d.day)}/${_two(d.month)} ${_two(d.hour)}:${_two(d.minute)}';

/// Periodic inventory ("جرد دوري"). Start a count: every product's
/// system quantity is snapshotted, you enter what's actually there per
/// product, and one "اعتماد" writes the counted values back into stock.
class StockCountScreen extends ConsumerStatefulWidget {
  const StockCountScreen({super.key});

  @override
  ConsumerState<StockCountScreen> createState() => _StockCountScreenState();
}

class _StockCountScreenState extends ConsumerState<StockCountScreen> {
  int? _openCountId;
  bool _applying = false;

  Future<void> _newCount() async {
    final employee = ref.read(currentEmployeeProvider);
    final id = await ref
        .read(stockCountRepositoryProvider)
        .createCount(employeeId: employee?.id);
    setState(() => _openCountId = id);
  }

  Future<void> _apply() async {
    setState(() => _applying = true);
    final applied = await ref
        .read(stockCountRepositoryProvider)
        .applyCount(_openCountId!);
    setState(() {
      _applying = false;
      _openCountId = null;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'تم اعتماد الجرد — اتعدّل $applied منتج وباقي الكميات زي ما هي'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final countsAsync = ref.watch(recentStockCountsProvider);
    final permissions = ref.watch(permissionServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الجرد الدوري', style: AppTypography.sectionTitle),
                  SizedBox(height: 2),
                  Text('عدّ الكمية الفعلية وقارنها بالسجل',
                      style: AppTypography.secondary),
                ],
              ),
            ),
            if (permissions.canStockCount && _openCountId == null)
              SizedBox(
                width: 160,
                child: PrimaryButton(
                  label: 'بدء جرد جديد',
                  icon: Icons.bar_chart_rounded,
                  expand: true,
                  onPressed: _newCount,
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_openCountId != null)
          _CountEditor(
            countId: _openCountId!,
            canApply: permissions.canAdjustStock,
            applying: _applying,
            onApply: _apply,
            onClose: () => setState(() => _openCountId = null),
          )
        else
          Expanded(
            child: countsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('خطأ: $e',
                      style: const TextStyle(color: AppColors.danger))),
              data: (counts) {
                if (counts.isEmpty) {
                  return const Center(
                    child: Text('لا يوجد جرد مسجل بعد',
                        style: TextStyle(color: AppColors.textTertiary)),
                  );
                }
                return ListView.separated(
                  itemCount: counts.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) {
                    final c = counts[i];
                    return GlassCard(
                      child: Row(
                        children: [
                          Icon(
                            c.applied
                                ? Icons.check_circle_rounded
                                : Icons.pending_rounded,
                            size: 20,
                            color: c.applied
                                ? AppColors.statusAvailable
                                : AppColors.statusPaused,
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'جرد ${_fmt(c.createdAt)}'
                                  '${c.note?.isNotEmpty == true ? ' — ${c.note}' : ''}',
                                  style: AppTypography.cardTitle,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  c.applied
                                      ? 'تم اعتماده ${c.appliedAt == null ? '' : _fmt(c.appliedAt!)}'
                                      : 'قيد العد',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: c.applied
                                          ? AppColors.statusAvailable
                                          : AppColors.statusPaused),
                                ),
                              ],
                            ),
                          ),
                          if (!c.applied && permissions.canStockCount)
                            SizedBox(
                              width: 150,
                              child: SecondaryButton(
                                label: 'متابعة العد',
                                icon: Icons.edit_rounded,
                                onPressed: () =>
                                    setState(() => _openCountId = c.id),
                              ),
                            ),
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

/// Interactive counting grid for one count session, updated row by row.
/// Every row is INDEPENDENT: it starts uncounted, and only the rows the
/// cashier actually filled in are written back to stock on اعتماد.
class _CountEditor extends ConsumerStatefulWidget {
  const _CountEditor({
    required this.countId,
    required this.canApply,
    required this.applying,
    required this.onApply,
    required this.onClose,
  });

  final int countId;
  final bool canApply;
  final bool applying;
  final VoidCallback onApply;
  final VoidCallback onClose;

  @override
  ConsumerState<_CountEditor> createState() => _CountEditorState();
}

class _CountEditorState extends ConsumerState<_CountEditor> {
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemsAsync = ref.watch(stockCountItemsProvider(widget.countId));

    return Expanded(
      child: itemsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
            child: Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
        data: (items) {
          // Only the rows the cashier typed a number into count as a real
          // difference; the rest still show their stored quantity.
          final counted = items.where((i) => i.counted).toList();
          final totalDiff = counted.fold<int>(0, (sum, i) => sum + i.difference);
          final hasDiff = counted.any((i) => i.difference != 0);

          final needle = _search.text.trim();
          final visible = needle.isEmpty
              ? items
              : items
                  .where((i) => i.productName.toLowerCase().contains(needle.toLowerCase()))
                  .toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'اتعدّل ${counted.length} من ${items.length} منتج'
                      '${hasDiff ? ' — فرق الجرد ${totalDiff > 0 ? '+' : ''}$totalDiff قطعة' : ''}',
                      style: AppTypography.cardTitle,
                    ),
                  ),
                  SizedBox(
                    width: 220,
                    height: 38,
                    child: TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      style:
                          const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                      decoration: InputDecoration(
                        hintText: 'دوّر على صنف واحد…',
                        hintStyle: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12),
                        prefixIcon: const Icon(Icons.search_rounded,
                            size: 16, color: AppColors.textSecondary),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.glassFill,
                        contentPadding: EdgeInsets.zero,
                        border: OutlineInputBorder(
                          borderRadius: AppRadius.smallR,
                          borderSide:
                              const BorderSide(color: AppColors.glassBorder),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: AppRadius.smallR,
                          borderSide:
                              const BorderSide(color: AppColors.glassBorder),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: AppRadius.smallR,
                          borderSide: const BorderSide(
                              color: AppColors.glassBorderPurple),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  SecondaryButton(
                    label: 'خروج',
                    icon: Icons.close_rounded,
                    onPressed: widget.onClose,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'اكتب الكمية في الصنف اللي بتعدّه هو — الاعتماد يعدّل هذا الصنف بس.',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.md),
              Expanded(
                child: visible.isEmpty
                    ? const Center(
                        child: Text('مفيش صنف بالاسم ده',
                            style: TextStyle(color: AppColors.textTertiary)),
                      )
                    : ListView.separated(
                        itemCount: visible.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.sm),
                        itemBuilder: (_, i) =>
                            _CountRow(key: ValueKey(visible[i].id), item: visible[i]),
                      ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: widget.applying
                          ? 'جارٍ الاعتماد...'
                          : 'اعتماد الجرد (تحديث المخزون)',
                      icon: Icons.check_rounded,
                      expand: true,
                      onPressed: widget.canApply && !widget.applying && hasDiff
                          ? widget.onApply
                          : null,
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// One countable product. A stateful widget so its text field and focus
/// node are created once (the old inline version leaked both on every
/// rebuild and could drop what the cashier typed).
class _CountRow extends ConsumerStatefulWidget {
  const _CountRow({super.key, required this.item});
  final StockCountItemRow item;

  @override
  ConsumerState<_CountRow> createState() => _CountRowState();
}

class _CountRowState extends ConsumerState<_CountRow> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.item.countedQty.toString());
  late final FocusNode _focus = FocusNode();
  bool _saved = false;

  @override
  void initState() {
    super.initState();
    // Commit when the cashier leaves the field (or presses enter) — and
    // only then, so a half-typed number is never written.
    _focus.addListener(_commitIfBlurred);
  }

  void _commitIfBlurred() {
    if (_focus.hasFocus) return;
    _commit();
  }

  void _commit() {
    final value = int.tryParse(_controller.text.trim());
    if (value == null || value < 0) return;
    if (value == widget.item.countedQty && _saved) return;
    _saved = true;
    ref
        .read(stockCountRepositoryProvider)
        .setCounted(widget.item.stockCountId, widget.item.productId, value);
  }

  @override
  void dispose() {
    _focus.removeListener(_commitIfBlurred);
    _focus.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = !item.counted
        ? AppColors.textTertiary
        : item.difference == 0
            ? AppColors.statusAvailable
            : item.difference < 0
                ? AppColors.danger
                : AppColors.accentSecondary;

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.productName, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text('المسجل: ${item.systemQty} قطعة',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
          ),
          SizedBox(
            width: 110,
            child: TextField(
              controller: _controller,
              focusNode: _focus,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _commit(),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                isDense: true,
                labelText: 'الكمية الفعلية',
                labelStyle:
                    const TextStyle(fontSize: 11, color: AppColors.textTertiary),
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            width: 86,
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: AppRadius.smallR,
            ),
            child: Text(
              !item.counted
                  ? 'لسه'
                  : item.difference == 0
                      ? 'مطابق'
                      : '${item.difference > 0 ? '+' : ''}${item.difference}',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// Items of one count session, keyed by countId.
final stockCountItemsProvider =
    StreamProvider.autoDispose.family<List<StockCountItemRow>, int>(
        (ref, countId) {
  return ref.watch(stockCountRepositoryProvider).watchItems(countId);
});