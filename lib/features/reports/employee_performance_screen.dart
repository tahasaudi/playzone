import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/product_dao.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/expense_repository.dart';
import '../../data/repositories/product_repository.dart';
import 'report_period_selector.dart';

/// Employee performance — the manager's per-employee P&L. Rolls the
/// invoices in the selected window up per employee, subtracts the real
/// cost of the products sold (COGS from Products.costPrice) and any
/// store purchases/expenses that employee recorded, so "صافي الربح"
/// shows how much that employee actually brought in for the store.
class EmployeePerformanceScreen extends ConsumerWidget {
  const EmployeePerformanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoicesAsync = ref.watch(invoicesInRangeProvider);
    final itemsAsync = ref.watch(invoiceItemsInRangeProvider);
    final expensesAsync = ref.watch(allExpensesProvider);
    final productsAsync = ref.watch(productsWithCategoryProvider);
    final employeesAsync = ref.watch(activeEmployeesProvider);
    final range = currentReportRange(ref.watch(reportPeriodProvider));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('أداء الموظفين', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('الإيرادات وصافي الربح لكل موظف في الفترة المختارة',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.md),
        const ReportPeriodSelector(),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: invoicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (invoices) => employeesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                  child: Text('خطأ: $e',
                      style: const TextStyle(color: AppColors.danger))),
              data: (employees) {
                final items = itemsAsync.value ?? const <InvoiceItemRow>[];
                final expenses = expensesAsync.value ?? const <ExpenseRow>[];
                final productCost = <int, double>{
                  for (final p
                      in productsAsync.value ?? const <ProductWithCategory>[])
                    p.product.id: p.product.costPrice,
                };
                final stats = _aggregate(
                  employees,
                  invoices,
                  items,
                  expenses.where((e) =>
                      !e.createdAt.isBefore(range.from) &&
                      e.createdAt.isBefore(range.to)),
                  productCost,
                );
                if (stats.isEmpty) {
                  return const Center(
                    child: Text('مفيش بيانات في الفترة دي',
                        style: TextStyle(color: AppColors.textTertiary)),
                  );
                }
                final maxRevenue = stats.first.revenue;
                return ListView.separated(
                  itemCount: stats.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (_, i) =>
                      _EmployeeRow(stat: stats[i], maxRevenue: maxRevenue),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  List<_EmployeeStat> _aggregate(
    List<EmployeeRow> employees,
    List<InvoiceRow> invoices,
    List<InvoiceItemRow> items,
    Iterable<ExpenseRow> expenses,
    Map<int, double> productCost,
  ) {
    final byEmployee = <int?, _EmployeeStat>{};
    for (final e in employees) {
      byEmployee[e.id] = _EmployeeStat(employee: e);
    }
    final invoiceOwner = <int, int?>{};
    for (final inv in invoices) {
      invoiceOwner[inv.id] = inv.employeeId;
      final stat = byEmployee[inv.employeeId] ?? _EmployeeStat(employee: null);
      stat.invoiceCount++;
      stat.revenue += inv.total;
      stat.cash += inv.paidCash;
      stat.card += inv.paidCard;
      byEmployee[inv.employeeId] = stat;
    }
    // Product cost of whatever was sold — the employee who made the
    // invoice bears the COGS of its product lines.
    for (final item in items) {
      if (item.productId == null) continue;
      final owner = invoiceOwner[item.invoiceId];
      final stat = byEmployee[owner] ?? _EmployeeStat(employee: null);
      stat.cogs += (productCost[item.productId] ?? 0) * item.quantity;
      byEmployee[owner] = stat;
    }
    // Store purchases/expenses recorded by an employee reduce their net.
    for (final e in expenses) {
      final stat = byEmployee[e.employeeId] ?? _EmployeeStat(employee: null);
      stat.expenses += e.amount;
      byEmployee[e.employeeId] = stat;
    }
    final list = byEmployee.values.where((s) => s.invoiceCount > 0).toList()
      ..sort((a, b) => b.revenue.compareTo(a.revenue));
    return list;
  }
}

class _EmployeeStat {
  _EmployeeStat({required this.employee});
  final EmployeeRow? employee;
  int invoiceCount = 0;
  double revenue = 0;
  double cash = 0;
  double card = 0;
  double cogs = 0;
  double expenses = 0;

  String get name => employee?.name ?? 'غير محدد';
  double get average => invoiceCount == 0 ? 0 : revenue / invoiceCount;
  double get profit => revenue - cogs - expenses;
}

class _EmployeeRow extends StatelessWidget {
  const _EmployeeRow({required this.stat, required this.maxRevenue});
  final _EmployeeStat stat;
  final double maxRevenue;

  @override
  Widget build(BuildContext context) {
    final ratio = maxRevenue <= 0 ? 0.0 : stat.revenue / maxRevenue;
    final profit = stat.profit;
    final profitColor = profit >= 0 ? AppColors.success : AppColors.danger;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.badge_rounded,
                  size: 20, color: AppColors.accentSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(stat.name, style: AppTypography.cardTitle),
              ),
              Text('إيراد EGP ${stat.revenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(width: AppSpacing.lg),
              Text('ربح EGP ${profit.toStringAsFixed(0)}',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: profitColor)),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          ClipRRect(
            borderRadius: AppRadius.smallR,
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 6,
              backgroundColor: AppColors.glassFill,
              valueColor: const AlwaysStoppedAnimation(AppColors.accentPrimary),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _metric(
                  Icons.receipt_long_rounded, '${stat.invoiceCount} فاتورة'),
              const SizedBox(width: AppSpacing.lg),
              _metric(Icons.shopping_basket_rounded,
                  'تكلفة البضاعة EGP ${stat.cogs.toStringAsFixed(0)}'),
              const SizedBox(width: AppSpacing.lg),
              _metric(Icons.storefront_rounded,
                  'مشتريات المحل EGP ${stat.expenses.toStringAsFixed(0)}'),
              const SizedBox(width: AppSpacing.lg),
              _metric(Icons.payments_rounded,
                  'كاش EGP ${stat.cash.toStringAsFixed(0)}'),
              const SizedBox(width: AppSpacing.lg),
              _metric(Icons.credit_card_rounded,
                  'كارت EGP ${stat.card.toStringAsFixed(0)}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metric(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textTertiary),
        const SizedBox(width: 4),
        Text(text,
            style:
                const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
