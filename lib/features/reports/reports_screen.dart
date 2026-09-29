import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/mini_bar_chart.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../dashboard/hero_and_kpi.dart';

const _filters = ['اليوم', 'أمس', 'الأسبوع', 'الشهر', 'مخصص'];

/// Reports screen — spec section 27. Revenue/profit come from real
/// invoices+expenses; the charts below (weekly trend, top products,
/// busiest hours, device utilization) stay mock until enough invoice
/// history accumulates to aggregate meaningfully.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _activeFilter = _filters.first;
  bool _exporting = false;

  ({DateTime from, DateTime to}) _rangeFor(String filter) {
    final now = DateTime.now();
    return switch (filter) {
      'اليوم' => (from: DateTime(now.year, now.month, now.day), to: now),
      'أمس' => (
          from: DateTime(now.year, now.month, now.day - 1),
          to: DateTime(now.year, now.month, now.day)
        ),
      'الأسبوع' => (from: now.subtract(const Duration(days: 7)), to: now),
      'الشهر' => (from: DateTime(now.year, now.month, 1), to: now),
      _ => (from: now.subtract(const Duration(days: 30)), to: now),
    };
  }

  /// Exports the currently-selected window as a UTF-8 CSV (opens in
  /// Excel) covering فواتير/بنود/مصروفات.
  Future<void> _exportCsv() async {
    setState(() => _exporting = true);
    try {
      final range = _rangeFor(_activeFilter);
      final invoices = await ref
          .read(invoiceRepositoryProvider)
          .watchBetween(from: range.from, to: range.to)
          .first;
      final items = await ref
          .read(invoiceRepositoryProvider)
          .watchItemsBetween(from: range.from, to: range.to)
          .first;
      final employees = ref.read(activeEmployeesProvider).valueOrNull ?? const [];
      String empName(int? id) => id == null
          ? ''
          : employees.where((e) => e.id == id).map((e) => e.name).firstOrNull ?? '';

      final allExpenses = ref.read(allExpensesProvider).valueOrNull ?? const [];
      final expenses = allExpenses
          .where((e) =>
              !e.createdAt.isBefore(range.from) && e.createdAt.isBefore(range.to))
          .toList();

      String csvCell(String s) {
        final clean = s.replaceAll('"', '""');
        return clean.contains(',') || clean.contains('"') || clean.contains('\n')
            ? '"$clean"'
            : clean;
      }

      String two(int n) => n.toString().padLeft(2, '0');
      String fmt(DateTime d) =>
          '${two(d.day)}/${two(d.month)}/${d.year} ${two(d.hour)}:${two(d.minute)}';

      final sb = StringBuffer();
      // BOM so Excel detects UTF-8 and Arabic renders correctly.
      sb.write('\uFEFF');
      sb.writeln('تقرير اللعبة $_activeFilter (${fmt(range.from)} - ${fmt(range.to)})');
      sb.writeln('');

      final revenue = invoices.fold<double>(0, (s, i) => s + i.total);
      final expenseTotal = expenses.fold<double>(0, (s, e) => s + e.amount);
      final count = invoices.length;
      final gameCount =
          invoices.where((i) => i.sessionId != null).fold<double>(0, (s, i) => s + i.total);
      final cafeCount = invoices
          .where((i) => i.sessionId == null)
          .fold<double>(0, (s, i) => s + i.total);

      sb.writeln('ملخص,القيمة');
      sb.writeln('عدد الفواتير,$count');
      sb.writeln('إجمالي الإيرادات,${revenue.toStringAsFixed(2)}');
      sb.writeln('إيراد الألعاب,${gameCount.toStringAsFixed(2)}');
      sb.writeln('إيراد الكافيه,${cafeCount.toStringAsFixed(2)}');
      sb.writeln('إجمالي المصروفات,${expenseTotal.toStringAsFixed(2)}');
      sb.writeln('الربح (بعد المصروفات),${(revenue - expenseTotal).toStringAsFixed(2)}');
      sb.writeln('');

      sb.writeln('فواتير');
      sb.writeln(
          'رقم الفاتورة,التاريخ,النوع,الإجمالي,الخصم,نقدي,كارت,الموظف');
      for (final i in invoices) {
        final type = i.sessionId != null ? 'ألعاب' : 'كافيه';
        sb.writeln(
            '${i.id},${fmt(i.createdAt)},$type,${i.total.toStringAsFixed(2)},${i.discount.toStringAsFixed(2)},${i.paidCash.toStringAsFixed(2)},${i.paidCard.toStringAsFixed(2)},${csvCell(empName(i.employeeId))}');
      }
      sb.writeln('');

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

      final dir = Directory(
          '${Platform.environment['USERPROFILE'] ?? '.'}\\Documents');
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
          onPressed: () => Process.start(
              'explorer', ['/select,', path]).ignore(),
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
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _filterRow(),
          const SizedBox(height: AppSpacing.lg),
          _kpiRow(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _revenueOverTimeCard()),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _gamingVsCafeCard()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _topProductsCard()),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _busiestHoursCard()),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _deviceUtilizationCard(),
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
              onTap: () => setState(() => _activeFilter = f),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                decoration: BoxDecoration(
                  color: active
                      ? AppColors.accentPrimary.withOpacity(0.2)
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

  Widget _kpiRow() {
    final todayInvoices = ref.watch(todayInvoicesProvider).value ?? [];
    final todayExpenses = ref.watch(todayExpensesProvider).value ?? [];
    final revenue = todayInvoices.fold<double>(0, (sum, i) => sum + i.total);
    final expenseTotal = todayExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    // Profit is ALWAYS revenue minus expenses (spec: "الربح بيتحسب بعد
    // الطرح المصروفات من الايراد").
    final profit = revenue - expenseTotal;

    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 1200 ? 5 : constraints.maxWidth > 700 ? 3 : 2;
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
              label: 'الإيرادات (اليوم)',
              value: 'EGP ${revenue.toStringAsFixed(0)}',
              iconColor: AppColors.accentSecondary),
          StatCard(
              icon: Icons.savings_rounded,
              label: 'الربح (بعد المصروفات)',
              value: 'EGP ${profit.toStringAsFixed(0)}',
              iconColor: AppColors.statusAvailable),
          const StatCard(
              icon: Icons.sports_esports_rounded,
              label: 'ألعاب',
              value: 'EGP 5,700',
              iconColor: AppColors.statusActive),
          const StatCard(
              icon: Icons.local_cafe_rounded,
              label: 'كافيه',
              value: 'EGP 2,750',
              iconColor: AppColors.warning),
          StatCard(
              icon: Icons.money_off_rounded,
              label: 'المصروفات',
              value: 'EGP ${expenseTotal.toStringAsFixed(0)}',
              iconColor: AppColors.danger),
        ],
      );
    });
  }

  Widget _revenueOverTimeCard() {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الإيرادات على مدار الأسبوع', style: AppTypography.cardTitle),
          SizedBox(height: AppSpacing.md),
          MiniBarChart(
            valuePrefix: '',
            data: {
              'سبت': 1200,
              'حد': 1450,
              'اتنين': 900,
              'تلات': 1100,
              'أربع': 1600,
              'خميس': 1850,
              'جمعة': 2100,
            },
          ),
        ],
      ),
    );
  }

  Widget _gamingVsCafeCard() {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('ألعاب مقابل كافيه', style: AppTypography.cardTitle),
          SizedBox(height: AppSpacing.lg),
          ComparisonBar(
            labelA: 'ألعاب',
            valueA: 5700,
            colorA: AppColors.accentPrimary,
            labelB: 'كافيه',
            valueB: 2750,
            colorB: AppColors.warning,
          ),
        ],
      ),
    );
  }

  Widget _topProductsCard() {
    final products = [
      ('بيبسي', 142),
      ('قهوة تركي', 98),
      ('شيبسي', 76),
      ('ساندوتش', 54),
      ('مياه', 210),
    ]..sort((a, b) => b.$2.compareTo(a.$2));

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الأكثر مبيعًا', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.md),
          for (var i = 0; i < products.length; i++) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Text('${i + 1}',
                      style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                      child: Text(products[i].$1,
                          style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
                  Text('${products[i].$2} قطعة',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _busiestHoursCard() {
    return const GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('أكثر الساعات ازدحامًا', style: AppTypography.cardTitle),
          SizedBox(height: AppSpacing.md),
          MiniBarChart(
            barColor: AppColors.accentSecondary,
            data: {
              '2م': 3,
              '4م': 6,
              '6م': 9,
              '8م': 12,
              '10م': 15,
              '12ص': 8,
            },
          ),
        ],
      ),
    );
  }

  Widget _deviceUtilizationCard() {
    final devices = [
      ('PS5 #01', 0.85),
      ('PS5 #02', 0.62),
      ('PS5 #03', 0.91),
      ('PS4 #01', 0.40),
      ('بلياردو #01', 0.55),
    ];

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('نسبة استخدام الأجهزة', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.md),
          for (final (name, ratio) in devices)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  SizedBox(
                      width: 90,
                      child: Text(name,
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12))),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: AppRadius.smallR,
                      child: SizedBox(
                        height: 10,
                        child: Stack(
                          children: [
                            Container(color: AppColors.glassFill),
                            FractionallySizedBox(
                              widthFactor: ratio,
                              child: Container(color: AppColors.accentPrimary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Text('${(ratio * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
