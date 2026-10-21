import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/accounting/profit.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/database/app_database.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/refund_repository.dart';
import '../dashboard/hero_and_kpi.dart';

const _filters = ['اليوم', 'أمس', 'الأسبوع', 'الشهر', 'مخصص'];

/// The three streams below are deliberately *not* the shared
/// `invoicesInRangeProvider` family, because that one follows the app-wide
/// [reportPeriodProvider] (today / week / month). This screen offers "أمس"
/// and "مخصص" on top of those, so it must drive its own window — otherwise the
/// chips would say one thing and the numbers show another.
final _invoicesForRangeProvider =
    StreamProvider.family<List<InvoiceRow>, ({DateTime from, DateTime to})>(
        (ref, range) => ref
            .watch(invoiceRepositoryProvider)
            .watchBetween(from: range.from, to: range.to));

final _itemsForRangeProvider =
    StreamProvider.family<List<InvoiceItemRow>, ({DateTime from, DateTime to})>(
        (ref, range) => ref
            .watch(invoiceRepositoryProvider)
            .watchItemsBetween(from: range.from, to: range.to));

final _refundsForRangeProvider =
    StreamProvider.family<List<RefundRow>, ({DateTime from, DateTime to})>(
        (ref, range) => ref
            .watch(refundRepositoryProvider)
            .watchBetween(from: range.from, to: range.to));

/// Reports screen — spec section 27.
///
/// Every number on this page is computed from the café's own recorded
/// invoices, invoice lines, expenses and refunds. It used to also carry a
/// handful of hard-coded charts (a weekly trend, a fake "الأكثر مبيعًا"
/// ranking, busiest hours, device utilisation) that were placeholders from
/// before any invoice history existed. Those were removed: a plausible but
/// invented bar chart is worse than no chart, because staff act on it —
/// buying stock for a product ranking that was never real ("مياه ٢١٠ قطعة"
/// for a drink the shop does not even stock).
///
/// What replaced them is honest aggregation of the actual rows: the real
/// best-sellers, the games-vs-café split and a tender breakdown, all for the
/// window on screen. The split reuses [Accounting.revenueBreakdown], so
/// ألعاب + كافيه − خصومات reconciles to الإيراد to the piastre — the screen
/// never shows three figures that cannot be made to add up.
///
/// When a window genuinely holds no data the card says so rather than drawing
/// an empty or invented shape.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _activeFilter = _filters.first;
  bool _exporting = false;

  /// The custom window, only meaningful when [_activeFilter] is 'مخصص'.
  DateTimeRange? _customRange;

  /// The window the screen is showing, computed once and held.
  ///
  /// This matters more than it looks. The range is the key of the three
  /// range-scoped providers, so a range object that changes identity on every
  /// `build` makes Riverpod treat each rebuild as a *new* stream: the query
  /// re-runs and the loading spinner never settles. Building it inline from
  /// `DateTime.now()` did exactly that — `now` advances between rebuilds, so
  /// the key never matched the one before it.
  ///
  /// Holding it here means the key is stable until the staff actually change
  /// the filter. `_refreshRange` is the only thing that moves it on.
  ({DateTime from, DateTime to})? _range;

  @override
  void initState() {
    super.initState();
    _range = _computeRange(_activeFilter);
  }

  /// The end of the current window. A live window ("اليوم", "الأسبوع") has to
  /// include what happened a moment ago, so on refresh it moves to *now*,
  /// while the start stays put — the day does not shift forward mid-shift.
  ({DateTime from, DateTime to}) _computeRange(String filter) {
    final now = DateTime.now();
    return switch (filter) {
      'اليوم' => (from: DateTime(now.year, now.month, now.day), to: now),
      'أمس' => (
          from: DateTime(now.year, now.month, now.day - 1),
          to: DateTime(now.year, now.month, now.day)
        ),
      'الأسبوع' => (from: now.subtract(const Duration(days: 7)), to: now),
      'الشهر' => (from: DateTime(now.year, now.month, 1), to: now),
      // 'مخصص' uses the range the user actually picked. The end is exclusive,
      // so add a day to include everything that happened on the last day.
      _ => _customRange == null
          ? (from: now.subtract(const Duration(days: 30)), to: now)
          : (
              from: _customRange!.start,
              to: _customRange!.end.add(const Duration(days: 1))
            ),
    };
  }

  /// Switches the window. The key is rebuilt here and nowhere else, so picking
  /// a filter re-queries once instead of on every rebuild.
  void _selectFilter(String filter) {
    setState(() {
      _activeFilter = filter;
      _range = _computeRange(filter);
    });
  }

  ({DateTime from, DateTime to}) get _currentRange =>
      _range ?? _computeRange(_activeFilter);

  /// Opens the date picker for 'مخصص'. Cancelling leaves the previous choice.
  Future<void> _pickCustomRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 3),
      lastDate: now,
      initialDateRange: _customRange ??
          DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now),
      helpText: 'اختار الفترة',
      saveText: 'اختيار',
    );
    if (picked == null) return;
    setState(() {
      _customRange = picked;
      _activeFilter = 'مخصص';
      // The picked dates are the new window; rebuild the key from them.
      _range = _computeRange('مخصص');
    });
  }

  /// What the filter chip shows — for 'مخصص' the picked dates are shown so the
  /// chip never hides which window is on screen.
  String _filterLabel() {
    if (_activeFilter != 'مخصص' || _customRange == null) return _activeFilter;
    return '${dayOf(_customRange!.start)} — ${dayOf(_customRange!.end)}';
  }

  /// Exports the currently-selected window as a UTF-8 CSV (opens in
  /// Excel) covering فواتير/بنود/مصروفات.
  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final range = _currentRange;
      final label = _filterLabel();
      final invoices = await ref
          .read(invoiceRepositoryProvider)
          .watchBetween(from: range.from, to: range.to)
          .first;
      final items = await ref
          .read(invoiceRepositoryProvider)
          .watchItemsBetween(from: range.from, to: range.to)
          .first;
      final refunds = await ref
          .read(refundRepositoryProvider)
          .watchBetween(from: range.from, to: range.to)
          .first;
      final costByProduct = {
        for (final p in await ref.read(productRepositoryProvider).allProducts())
          p.id: p.costPrice,
      };
      final employees =
          ref.read(activeEmployeesProvider).valueOrNull ?? const [];
      String empName(int? id) => id == null
          ? ''
          : employees.where((e) => e.id == id).map((e) => e.name).firstOrNull ??
              '';

      final allExpenses = ref.read(allExpensesProvider).valueOrNull ?? const [];
      final expenses = allExpenses
          .where((e) =>
              !e.createdAt.isBefore(range.from) &&
              e.createdAt.isBefore(range.to))
          .toList();

      String csvCell(String s) {
        final clean = s.replaceAll('"', '""');
        return clean.contains(',') ||
                clean.contains('"') ||
                clean.contains('\n')
            ? '"$clean"'
            : clean;
      }

      String fmt(DateTime d) => stampOf(d);

      final sb = StringBuffer();
      // BOM so Excel detects UTF-8 and Arabic renders correctly.
      sb.write('\uFEFF');
      sb.writeln(
          'تقرير اللعبة $label (${fmt(range.from)} - ${fmt(range.to)})');
      sb.writeln('');

      final settled = Accounting.settledOnly(invoices);
      final revenue = Accounting.revenue(invoices);
      final expenseTotal = Accounting.expenses(expenses);
      final refundsTotal = Accounting.refunds(refunds);
      final cogs = Accounting.costOfGoods(items, costByProduct);
      final profit = Accounting.netProfit(
        revenue: revenue,
        costOfGoods: cogs,
        expenses: expenseTotal,
        refunds: refundsTotal,
      );
      final count = settled.length;
      final split =
          Accounting.revenueBreakdown(invoices: invoices, items: items);
      final gameCount = split.gaming;
      final cafeCount = split.cafe;

      sb.writeln('ملخص,القيمة');
      sb.writeln('عدد الفواتير المسدَّدة,$count');
      sb.writeln('إجمالي الإيرادات (المسدَّد),${revenue.toStringAsFixed(2)}');
      sb.writeln('إيراد الألعاب (مسدَّد),${gameCount.toStringAsFixed(2)}');
      sb.writeln('إيراد الكافيه (مسدَّد),${cafeCount.toStringAsFixed(2)}');
      sb.writeln('الخصومات,${split.discounts.toStringAsFixed(2)}');
      sb.writeln('تكلفة البضاعة,${cogs.toStringAsFixed(2)}');
      sb.writeln('إجمالي المصروفات,${expenseTotal.toStringAsFixed(2)}');
      sb.writeln('المرتجعات,${refundsTotal.toStringAsFixed(2)}');
      sb.writeln('صافي الربح,${profit.toStringAsFixed(2)}');
      sb.writeln('');

      sb.writeln('فواتير');
      sb.writeln('رقم الفاتورة,التاريخ,النوع,الحالة,الإجمالي,الخصم,نقدي,كارت,الموظف');
      for (final i in invoices) {
        final type = i.sessionId != null ? 'ألعاب' : 'كافيه';
        final state = Accounting.isSettled(i) ? 'مسدَّد' : 'أجل/غير مسدَّد';
        sb.writeln(
            '${i.id},${fmt(i.createdAt)},$type,$state,${i.total.toStringAsFixed(2)},${i.discount.toStringAsFixed(2)},${i.paidCash.toStringAsFixed(2)},${i.paidCard.toStringAsFixed(2)},${csvCell(empName(i.employeeId))}');
      }
      sb.writeln('');

      if (refunds.isNotEmpty) {
        sb.writeln('مرتجعات');
        sb.writeln('رقم المرتجع,رقم الفاتورة,التاريخ,المبلغ,السبب,الموظف');
        for (final r in refunds) {
          sb.writeln(
              '${r.id},${r.invoiceId},${fmt(r.createdAt)},${r.amount.toStringAsFixed(2)},${csvCell(r.reason ?? '')},${csvCell(empName(r.employeeId))}');
        }
        sb.writeln('');
      }

      if (items.isNotEmpty) {
        sb.writeln('بنود الفواتير');
        sb.writeln('رقم الفاتورة,الوصف,الكمية,سعر الوحدة,الإجمالي');
        for (final it in items) {
          sb.writeln(
              '${it.invoiceId},${csvCell(it.description)},${it.quantity},${it.unitPrice.toStringAsFixed(2)},${it.total.toStringAsFixed(2)}');
        }
        sb.writeln('');
      }

      sb.writeln('مصروفات');
      sb.writeln('التاريخ,التصنيف,الوصف,المبلغ');
      for (final e in expenses) {
        sb.writeln(
            '${fmt(e.createdAt)},${csvCell(e.category)},${csvCell(e.description ?? '')},${e.amount.toStringAsFixed(2)}');
      }

      final dir =
          Directory('${Platform.environment['USERPROFILE'] ?? '.'}\\Documents');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final stamp = DateTime.now()
          .toIso8601String()
          .replaceAll(':', '')
          .replaceAll('.', '')
          .replaceAll('-', '');
      final path = '${dir.path}\\playzone_report_$stamp.csv';
      File(path).writeAsStringSync(sb.toString());

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم حفظ التقرير: $path'),
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

  @override
  Widget build(BuildContext context) {
    final range = _currentRange;
    final invoicesAsync = ref.watch(_invoicesForRangeProvider(range));
    final itemsAsync = ref.watch(_itemsForRangeProvider(range));
    final refundsAsync = ref.watch(_refundsForRangeProvider(range));
    final expensesAsync = ref.watch(allExpensesProvider);
    final costAsync = ref.watch(costByProductProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterRow(),
          const SizedBox(height: AppSpacing.lg),
          invoicesAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('خطأ: $e',
                style: const TextStyle(color: AppColors.danger)),
            data: (invoices) {
              final expenses = (expensesAsync.value ?? const <ExpenseRow>[])
                  .where((e) =>
                      !e.createdAt.isBefore(range.from) &&
                      e.createdAt.isBefore(range.to))
                  .toList();
              final items = itemsAsync.value ?? const <InvoiceItemRow>[];
              final refunds = refundsAsync.value ?? const <RefundRow>[];
              final costByProduct = costAsync.value ?? const <int, double>{};

              return _PeriodReport(
                range: range,
                invoices: invoices,
                items: items,
                expenses: expenses,
                refunds: refunds,
                costByProduct: costByProduct,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _filterRow() {
    return Row(
      children: [
        ..._filters.map((f) {
          final active = f == _activeFilter;
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: GestureDetector(
              // 'مخصص' asks for the dates; every other chip is a fixed window.
              onTap: () => f == 'مخصص'
                  ? _pickCustomRange()
                  : _selectFilter(f),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.accentPrimary.withValues(alpha: 0.2)
                      : AppColors.glassFill,
                  borderRadius: AppRadius.mediumR,
                  border: Border.all(
                      color: active
                          ? AppColors.glassBorderPurple
                          : AppColors.glassBorder),
                ),
                child: Text(f,
                    style: TextStyle(
                        fontSize: 13,
                        color: active
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400)),
              ),
            ),
          );
        }),
        const Spacer(),
        // Live windows ("اليوم", "الأسبوع") end at the moment they were opened,
        // so a bill rung up afterwards would sit outside them. This pulls the
        // end up to now without changing which window is selected.
        if (_activeFilter == 'اليوم' || _activeFilter == 'الأسبوع')
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              tooltip: 'تحديث',
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => setState(() {
                _range = _computeRange(_activeFilter);
              }),
            ),
          ),
        const SizedBox(width: 8),
        SizedBox(
          width: 200,
          child: SecondaryButton(
            label: _exporting ? 'جارٍ التصدير...' : 'تصدير Excel (CSV)',
            icon: Icons.file_download_rounded,
            onPressed: _exporting ? null : _exportCsv,
          ),
        ),
      ],
    );
  }
}

/// The whole report body for one window, computed once from the real rows.
class _PeriodReport extends StatelessWidget {
  const _PeriodReport({
    required this.range,
    required this.invoices,
    required this.items,
    required this.expenses,
    required this.refunds,
    required this.costByProduct,
  });

  final ({DateTime from, DateTime to}) range;
  final List<InvoiceRow> invoices;
  final List<InvoiceItemRow> items;
  final List<ExpenseRow> expenses;
  final List<RefundRow> refunds;
  final Map<int, double> costByProduct;

  @override
  Widget build(BuildContext context) {
    final settled = Accounting.settledOnly(invoices);
    final revenue = Accounting.revenue(invoices);
    final cash = Accounting.cash(invoices);
    final card = Accounting.card(invoices);
    final expenseTotal = Accounting.expenses(expenses);
    final refundsTotal = Accounting.refunds(refunds);
    final cogs = Accounting.costOfGoods(items, costByProduct);
    final profit = Accounting.netProfit(
      revenue: revenue,
      costOfGoods: cogs,
      expenses: expenseTotal,
      refunds: refundsTotal,
    );
    // Use the app's canonical split rather than "does the invoice have a
    // session": gaming/café is decided per *line*, and this helper also makes
    // gaming + café − discounts reconcile to revenue exactly.
    final split =
        Accounting.revenueBreakdown(invoices: invoices, items: items);
    final gameRevenue = split.gaming;
    final cafeRevenue = split.cafe;
    final discounts = split.discounts;
    final avgTicket = settled.isEmpty ? 0.0 : revenue / settled.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'الفترة: ${stampOf(range.from)} — ${stampOf(range.to)}',
          style: AppTypography.secondary,
        ),
        const SizedBox(height: AppSpacing.md),
        _kpiGrid(revenue, profit, expenseTotal, avgTicket, settled.length),
        const SizedBox(height: AppSpacing.lg),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _splitCard(gameRevenue, cafeRevenue)),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _moneyCard(
                title: 'طرق الدفع',
                rows: [
                  ('نقدي', cash, AppColors.statusAvailable),
                  ('كارت', card, AppColors.accentSecondary),
                  ('خصومات', discounts, AppColors.warning),
                  ('مرتجعات', refundsTotal, AppColors.danger),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _bestSellersCard(items),
        const SizedBox(height: AppSpacing.md),
        _expensesCard(expenses),
      ],
    );
  }

  Widget _kpiGrid(double revenue, double profit, double expenseTotal,
      double avgTicket, int settledCount) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 1200
          ? 5
          : constraints.maxWidth > 700
              ? 3
              : 2;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.5,
        children: [
          StatCard(
              icon: Icons.payments_rounded,
              label: 'الإيرادات (مسدَّد)',
              value: 'EGP ${revenue.toStringAsFixed(0)}',
              iconColor: AppColors.accentSecondary),
          StatCard(
              icon: Icons.savings_rounded,
              label: 'الربح (بعد التكلفة والمصروفات)',
              value: 'EGP ${profit.toStringAsFixed(0)}',
              iconColor: AppColors.statusAvailable),
          StatCard(
              icon: Icons.receipt_long_rounded,
              label: 'فواتير مسدَّدة',
              value: '$settledCount',
              iconColor: AppColors.statusActive),
          StatCard(
              icon: Icons.trending_up_rounded,
              label: 'متوسط الفاتورة',
              value: 'EGP ${avgTicket.toStringAsFixed(0)}',
              iconColor: AppColors.accentPrimary),
          StatCard(
              icon: Icons.money_off_rounded,
              label: 'المصروفات',
              value: 'EGP ${expenseTotal.toStringAsFixed(0)}',
              iconColor: AppColors.danger),
        ],
      );
    });
  }

  Widget _splitCard(double gameRevenue, double cafeRevenue) {
    final total = gameRevenue + cafeRevenue;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('ألعاب مقابل كافيه', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.md),
          if (total == 0)
            const Text('لا توجد إيرادات في الفترة دي',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13))
          else ...[
            _splitRow('ألعاب', gameRevenue, total, AppColors.accentPrimary),
            const SizedBox(height: AppSpacing.sm),
            _splitRow('كافيه', cafeRevenue, total, AppColors.warning),
          ],
        ],
      ),
    );
  }

  Widget _splitRow(String label, double value, double total, Color color) {
    final ratio = total == 0 ? 0.0 : value / total;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
                child: Text(label,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 13))),
            Text('EGP ${value.toStringAsFixed(0)}  (${(ratio * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: AppRadius.smallR,
          child: SizedBox(
            height: 8,
            child: Stack(
              children: [
                Container(color: AppColors.glassFill),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(color: color),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _moneyCard(
      {required String title,
      required List<(String, double, Color)> rows}) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.md),
          for (final (label, value, color) in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(label,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 13))),
                  Text('EGP ${value.toStringAsFixed(0)}',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontSize: 13)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  /// Quantities are doubles in the database (a line can be 1.5 kg of coffee),
  /// but most are whole numbers — print those without a trailing ".0".
  static String _qtyLabel(double qty) =>
      qty == qty.roundToDouble() ? qty.toStringAsFixed(0) : qty.toString();

  /// The real best-sellers: aggregate the café's own invoice lines by product
  /// description, so the ranking reflects what was actually sold.
  ///
  /// Play-time lines (`وقت اللعب`, no product behind them) are skipped on
  /// purpose: this card answers "إيه اللي أجيب منه تاني؟", and a device's own
  /// hour count is not stock anyone can order. Leaving them in pushed بيبسي
  /// and اندومي off the list entirely — the shop's real products.
  Widget _bestSellersCard(List<InvoiceItemRow> items) {
    final byName = <String, ({double qty, double revenue})>{};
    for (final it in items) {
      if (it.productId == null) continue;
      final key = it.description.trim();
      if (key.isEmpty) continue;
      final prev = byName[key] ?? (qty: 0.0, revenue: 0.0);
      byName[key] =
          (qty: prev.qty + it.quantity, revenue: prev.revenue + it.total);
    }
    final ranked = byName.entries.toList()
      ..sort((a, b) => b.value.qty.compareTo(a.value.qty));
    final top = ranked.take(8).toList();

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الأكثر مبيعًا (من فواتيرك)', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.md),
          if (top.isEmpty)
            const Text('لا توجد مبيعات في الفترة دي',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13))
          else
            for (var i = 0; i < top.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Text('${i + 1}',
                        style: const TextStyle(
                            color: AppColors.textTertiary, fontSize: 12)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                        child: Text(top[i].key,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13))),
                    Text('${_qtyLabel(top[i].value.qty)} قطعة',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(width: AppSpacing.md),
                    SizedBox(
                      width: 90,
                      child: Text('EGP ${top[i].value.revenue.toStringAsFixed(0)}',
                          textAlign: TextAlign.left,
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _expensesCard(List<ExpenseRow> expenses) {
    final byCategory = <String, double>{};
    for (final e in expenses) {
      byCategory[e.category] = (byCategory[e.category] ?? 0) + e.amount;
    }
    final ranked = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('المصروفات حسب التصنيف', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.md),
          if (ranked.isEmpty)
            const Text('لا توجد مصروفات في الفترة دي',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 13))
          else
            for (final e in ranked)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                        child: Text(e.key,
                            style: const TextStyle(
                                color: AppColors.textPrimary, fontSize: 13))),
                    Text('EGP ${e.value.toStringAsFixed(0)}',
                        style: const TextStyle(
                            color: AppColors.textSecondary, fontSize: 12)),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

/// Device utilisation is deliberately absent: the café's play sessions carry
/// a device id but no start/end pair recorded per device in a way this screen
/// can turn into an honest occupancy ratio. The old bars were invented; they
/// were removed rather than faked differently. If the sessions table ever
/// records a device per interval, this is where the chart goes back.
