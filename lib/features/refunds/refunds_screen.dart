import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/invoice_dao.dart';
import '../../core/database/daos/refund_dao.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/refund_repository.dart';
import '../../data/repositories/invoice_repository.dart';

String _fmt(DateTime d) {
  final now = DateTime.now();
  final sameDay =
      d.year == now.year && d.month == now.month && d.day == now.day;
  return sameDay ? 'اليوم ${clockOf(d)}' : stampOf(d);
}

/// Arabic label for the stored payment method code.
String _payLabel(String method) {
  switch (method) {
    case 'card':
      return 'كارت';
    case 'mixed':
      return 'مختلط';
    case 'credit':
      return 'آجل';
    default:
      return 'كاش';
  }
}

/// Full one-line description of an invoice for the search results.
String _invoiceSubtitle(InvoiceWithCustomer e) {
  final inv = e.invoice;
  final customer = e.customer;
  final buffer =
      StringBuffer('${_fmt(inv.createdAt)} · ${_payLabel(inv.paymentMethod)}');
  if (customer != null && customer.name.trim().isNotEmpty) {
    buffer.write(' · ${customer.name}');
  }
  if (customer != null && customer.phone.trim().isNotEmpty) {
    buffer.write(' · ${customer.phone}');
  }
  return buffer.toString();
}

/// Filters invoices by code, customer name/phone or amount.
List<InvoiceWithCustomer> _filterInvoices(
    List<InvoiceWithCustomer> all, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return all;
  return all.where((e) {
    final inv = e.invoice;
    final name = e.customer?.name.toLowerCase() ?? '';
    final phone = e.customer?.phone.toLowerCase() ?? '';
    return inv.id.toString().contains(q) ||
        name.contains(q) ||
        phone.contains(q) ||
        inv.total.toStringAsFixed(0).contains(q) ||
        inv.total.toStringAsFixed(2).contains(q);
  }).toList();
}

/// Refunds ("المرتجعات"). Built around finding a bill and refunding from it:
/// a search box + a live list of recent invoices (the newest is always one
/// tap away) on the left, and the refund report on the right. Tap any invoice
/// to see exactly what it contained and return just the items you want — even
/// a single product. Every refund posts the money back to the refunds account
/// and restocks the returned lines. Creating one requires the refund
/// permission and is audit-logged.
class RefundsScreen extends ConsumerStatefulWidget {
  const RefundsScreen({super.key});

  @override
  ConsumerState<RefundsScreen> createState() => _RefundsScreenState();
}

class _RefundsScreenState extends ConsumerState<RefundsScreen> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(searchableInvoicesProvider);
    final canRefund = ref.watch(permissionServiceProvider).canRefund;
    final refundedTotals = ref.watch(refundedTotalsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المرتجعات', style: AppTypography.sectionTitle),
                  SizedBox(height: 2),
                  Text(
                    'دوّر على الفاتورة ودوس عليها ترجّع بنودها — أو ارجّع آخر فاتورة بضغطة',
                    style: AppTypography.secondary,
                  ),
                ],
              ),
            ),
            if (canRefund)
              SizedBox(
                width: 170,
                child: PrimaryButton(
                  label: 'تسجيل مرتجع',
                  icon: Icons.assignment_return_rounded,
                  expand: true,
                  onPressed: () => showAddRefundDialog(context, ref),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(child: _invoicesPanel(invoicesAsync, canRefund, refundedTotals)),
      ],
    );
  }

  Widget _invoicesPanel(AsyncValue<List<InvoiceWithCustomer>> async,
      bool canRefund, Map<int, double> refundedTotals) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الفواتير', style: AppTypography.sectionTitle),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'ابحث برقم الفاتورة أو اسم/تليفون العميل أو المبلغ',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            if (canRefund)
              SecondaryButton(
                label: 'آخر فاتورة',
                icon: Icons.history_rounded,
                onPressed: () {
                  final all = async.valueOrNull;
                  if (all == null || all.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('لا توجد فواتير مسجلة')),
                    );
                    return;
                  }
                  final e = all.first;
                  showAddRefundDialog(context, ref,
                      invoice: e.invoice, customerName: e.customer?.name);
                },
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('خطأ: $e',
                  style: const TextStyle(color: AppColors.danger)),
            ),
            data: (all) {
              final list = _filterInvoices(all, _query);
              if (list.isEmpty) {
                return Center(
                  child: Text(
                    _query.trim().isEmpty ? 'لا توجد فواتير' : 'مفيش نتائج للبحث',
                    style: const TextStyle(color: AppColors.textTertiary),
                  ),
                );
              }
              final latestId = all.isEmpty ? null : all.first.invoice.id;
              return ListView.separated(
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) {
                  final e = list[i];
                  return _InvoiceCard(
                    entry: e,
                    isLatest: e.invoice.id == latestId,
                    refunded: refundedTotals[e.invoice.id] ?? 0,
                    onTap: canRefund
                        ? () => showAddRefundDialog(context, ref,
                            invoice: e.invoice,
                            customerName: e.customer?.name)
                        : null,
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

/// A single invoice row: code, time/payment/customer, and the value still on
/// the bill (its original total minus anything already refunded). Tapping it
/// opens the invoice's detail + return view.
class _InvoiceCard extends StatelessWidget {
  const _InvoiceCard({
    required this.entry,
    required this.isLatest,
    required this.refunded,
    this.onTap,
  });

  final InvoiceWithCustomer entry;
  final bool isLatest;

  /// How much has already been refunded off this invoice.
  final double refunded;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final inv = entry.invoice;
    final net = inv.total - refunded;
    final netValue = net < 0 ? 0.0 : net;
    return MouseRegion(
      cursor:
          onTap == null ? SystemMouseCursors.basic : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentPrimary.withOpacity(0.15),
                  borderRadius: AppRadius.smallR,
                ),
                child: const Icon(Icons.receipt_long_rounded,
                    size: 18, color: AppColors.accentSecondary),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('فاتورة #${inv.id}',
                            style: AppTypography.cardTitle),
                        if (isLatest) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.accentPrimary.withOpacity(0.18),
                              borderRadius: AppRadius.smallR,
                            ),
                            child: const Text('آخر فاتورة',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.accentSecondary)),
                          ),
                        ],
                        if (refunded > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withOpacity(0.18),
                              borderRadius: AppRadius.smallR,
                            ),
                            child: const Text('مرتجع',
                                style: TextStyle(
                                    fontSize: 10, color: AppColors.danger)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _invoiceSubtitle(entry),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (refunded > 0)
                    Text('EGP ${inv.total.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                          decoration: TextDecoration.lineThrough,
                        )),
                  Text('EGP ${netValue.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: refunded > 0
                              ? AppColors.accentSecondary
                              : AppColors.textPrimary)),
                ],
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.sm),
                const Icon(Icons.chevron_left_rounded,
                    size: 20, color: AppColors.textTertiary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Opens the refund dialog. Pass [invoice] to go straight to its detail +
/// return view (used by the invoice rows and the "آخر فاتورة" shortcut);
/// leave it null and the dialog shows a searchable picker first.
Future<void> showAddRefundDialog(BuildContext context, WidgetRef ref,
    {InvoiceRow? invoice, String? customerName}) {
  return showDialog(
    context: context,
    builder: (_) =>
        _AddRefundDialog(invoice: invoice, customerName: customerName),
  );
}

class _AddRefundDialog extends ConsumerStatefulWidget {
  const _AddRefundDialog({this.invoice, this.customerName});
  final InvoiceRow? invoice;
  final String? customerName;

  @override
  ConsumerState<_AddRefundDialog> createState() => _AddRefundDialogState();
}

class _AddRefundDialogState extends ConsumerState<_AddRefundDialog> {
  InvoiceRow? _invoice;
  String? _customerName;

  // Return selection: an item is included by default (all of its remaining
  // quantity); unticking adds it here, a stepper writes an override.
  final Set<int> _excluded = {};
  final Map<int, int> _qty = {};

  final _amount = TextEditingController();
  final _reason = TextEditingController();
  final _search = TextEditingController();
  String _query = '';
  bool _manualAmount = false;
  bool _restock = true;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _invoice = widget.invoice;
    _customerName = widget.customerName;
  }

  @override
  void dispose() {
    _amount.dispose();
    _reason.dispose();
    _search.dispose();
    super.dispose();
  }

  /// Builds the list of lines to return from [items]/[refunded].  /// Builds the list of lines to return from [items]/[refunded].
  List<RefundLineInput> _buildLines(
      List<InvoiceItemRow> items, Map<int, int> refunded) {
    final lines = <RefundLineInput>[];
    for (final item in items) {
      final remaining = item.quantity - (refunded[item.id] ?? 0);
      if (remaining <= 0) continue;
      if (_excluded.contains(item.id)) continue;
      final qty = (_qty[item.id] ?? remaining).clamp(1, remaining);
      lines.add(RefundLineInput(
        invoiceItemId: item.id,
        quantity: qty,
        unitPrice: item.unitPrice,
        productId: item.productId,
      ));
    }
    return lines;
  }

  Future<void> _save() async {
    final inv = _invoice;
    if (inv == null) return;
    final items =
        ref.read(invoiceItemsProvider(inv.id)).valueOrNull ?? const [];
    final refunded =
        ref.read(refundedQuantitiesProvider(inv.id)).valueOrNull ?? const {};
    final lines = _buildLines(items, refunded);
    final computed = lines.fold<double>(0, (s, l) => s + l.total);
    final amount =
        _manualAmount ? (double.tryParse(_amount.text.trim()) ?? -1) : computed;
    if (amount <= 0) {
      setState(() => _error = _manualAmount
          ? 'اكتب مبلغ صحيح'
          : 'اختار بند واحد على الأقل للاسترداد');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final employee = ref.read(currentEmployeeProvider);
    try {
      await ref.read(refundRepositoryProvider).createRefund(
            invoiceId: inv.id,
            amount: amount,
            lines: _manualAmount ? const [] : lines,
            reason: _reason.text.trim().isEmpty ? null : _reason.text.trim(),
            employeeId: employee?.id,
            restock: _restock,
          );
      ref.invalidate(refundedQuantitiesProvider(inv.id));
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم تسجيل المرتجع')));
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoicesAsync = ref.watch(searchableInvoicesProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 540,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_invoice == null ? 'تسجيل مرتجع' : 'تفاصيل الفاتورة',
                  style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.lg),
              if (_invoice == null)
                _invoicePicker(invoicesAsync)
              else
                _invoiceReturn(_invoice!),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'إلغاء',
                      onPressed:
                          _saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: PrimaryButton(
                      label: _saving ? 'جاري الحفظ...' : 'حفظ المرتجع',
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
      ),
    );
  }

  Widget _invoicePicker(AsyncValue<List<InvoiceWithCustomer>> async) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _search,
                onChanged: (v) => setState(() => _query = v),
                decoration: const InputDecoration(
                  hintText: 'ابحث بالرقم أو اسم/تليفون العميل',
                  prefixIcon: Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SecondaryButton(
              label: 'آخر فاتورة',
              icon: Icons.history_rounded,
              onPressed: () {
                final list = async.valueOrNull;
                if (list == null || list.isEmpty) return;
                setState(() {
                  _invoice = list.first.invoice;
                  _customerName = list.first.customer?.name;
                });
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          height: 240,
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: AppRadius.smallR,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: async.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child:
                  Text('$e', style: const TextStyle(color: AppColors.danger)),
            ),
            data: (all) {
              final list = _filterInvoices(all, _query);
              if (list.isEmpty) {
                return const Center(
                  child: Text('مفيش نتائج',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(AppSpacing.sm),
                itemCount: list.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.xs),
                itemBuilder: (_, i) {
                  final e = list[i];
                  return _PickerRow(
                    entry: e,
                    onTap: () => setState(() {
                      _invoice = e.invoice;
                      _customerName = e.customer?.name;
                    }),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _invoiceReturn(InvoiceRow inv) {
    final itemsAsync = ref.watch(invoiceItemsProvider(inv.id));
    final refunded =
        ref.watch(refundedQuantitiesProvider(inv.id)).valueOrNull ?? const {};
    final returnedAny = refunded.values.any((q) => q > 0);
    final alreadyRefunded = ref.watch(refundedTotalsProvider)[inv.id] ?? 0;
    final remaining = (inv.total - alreadyRefunded) < 0
        ? 0.0
        : inv.total - alreadyRefunded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoice summary.
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: AppRadius.smallR,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_long_rounded,
                      size: 18, color: AppColors.accentSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text('فاتورة #${inv.id}',
                        style: AppTypography.cardTitle),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (alreadyRefunded > 0)
                        Text('EGP ${inv.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textTertiary,
                              decoration: TextDecoration.lineThrough,
                            )),
                      Text('EGP ${remaining.toStringAsFixed(2)}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${_fmt(inv.createdAt)} · ${_payLabel(inv.paymentMethod)}'
                '${_customerName?.isNotEmpty == true ? ' · $_customerName' : ''}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              if (alreadyRefunded > 0) ...[
                const SizedBox(height: 4),
                Text(
                  'قيمة الفاتورة كانت EGP ${inv.total.toStringAsFixed(2)} · '
                  'اترجع منها EGP ${alreadyRefunded.toStringAsFixed(2)} · '
                  'المتبقي EGP ${remaining.toStringAsFixed(2)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.danger),
                ),
              ] else if (returnedAny) ...[
                const SizedBox(height: 4),
                const Text('فيه بنود اتّرجعت قبل كده من الفاتورة دي',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.statusAvailable)),
              ],
              const SizedBox(height: AppSpacing.sm),
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(
                  onPressed: () => setState(() {
                    _invoice = null;
                    _amount.clear();
                    _manualAmount = false;
                  }),
                  child: const Text('تغيير الفاتورة'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Text('بنود الفاتورة', style: AppTypography.cardTitle),
            const Spacer(),
            TextButton(
              onPressed: () => setState(() {
                _excluded.clear();
                _qty.clear();
              }),
              child: const Text('تحديد الكل'),
            ),
            TextButton(
              onPressed: () => setState(() => _excluded
                ..clear()
                ..addAll(
                    itemsAsync.valueOrNull?.map((e) => e.id) ?? const <int>[])),
              child: const Text('إلغاء الكل'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        itemsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text('خطأ: $e',
              style: const TextStyle(color: AppColors.danger)),
          data: (items) {
            if (items.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Text('الفاتورة دي ملهاش بنود',
                    style: TextStyle(color: AppColors.textTertiary)),
              );
            }
            final lines = _buildLines(items, refunded);
            final computed = lines.fold<double>(0, (s, l) => s + l.total);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxHeight: 260),
                  decoration: BoxDecoration(
                    color: AppColors.bgBase.withOpacity(0.35),
                    borderRadius: AppRadius.smallR,
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    itemCount: items.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.xs),
                    itemBuilder: (_, i) =>
                        _lineTile(items[i], refunded[items[i].id] ?? 0),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _amountRow(computed),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _reason,
                  decoration: const InputDecoration(
                    labelText: 'السبب (اختياري)',
                    isDense: true,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Expanded(
                      child: Text('إرجاع البنود المختارة للمخزون',
                          style: TextStyle(color: AppColors.textPrimary)),
                    ),
                    Switch(
                      value: _restock,
                      onChanged: (v) => setState(() => _restock = v),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(_error!,
                      style: const TextStyle(color: AppColors.danger)),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _amountRow(double computed) {
    if (_manualAmount) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _amount,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'المبلغ المسترد',
                suffixText: 'جنيه',
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          TextButton(
            onPressed: () => setState(() => _manualAmount = false),
            child: const Text('حساب تلقائي'),
          ),
        ],
      );
    }
    return Row(
      children: [
        const Text('المبلغ المسترد', style: TextStyle(color: AppColors.textSecondary)),
        const SizedBox(width: AppSpacing.sm),
        Text('EGP ${computed.toStringAsFixed(2)}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.accentSecondary)),
        const Spacer(),
        TextButton(
          onPressed: () => setState(() {
            _manualAmount = true;
            _amount.text = computed.toStringAsFixed(0);
          }),
          child: const Text('تعديل المبلغ'),
        ),
      ],
    );
  }

  Widget _lineTile(InvoiceItemRow item, int alreadyReturned) {
    final remaining = item.quantity - alreadyReturned;
    final fullyReturned = remaining <= 0;
    final selected = !fullyReturned && !_excluded.contains(item.id);
    final qty = selected ? (_qty[item.id] ?? remaining).clamp(1, remaining) : 0;
    final lineTotal = item.unitPrice * (selected ? qty : 0);

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.smallR,
        border: Border.all(
          color: selected
              ? AppColors.glassBorderPurple
              : AppColors.glassBorder,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            child: fullyReturned
                ? const Icon(Icons.check_circle_rounded,
                    size: 20, color: AppColors.statusAvailable)
                : Checkbox(
                    value: selected,
                    onChanged: (v) => setState(() {
                      if (v == true) {
                        _excluded.remove(item.id);
                      } else {
                        _excluded.add(item.id);
                      }
                    }),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.description,
                    style: AppTypography.body, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(
                  '${item.quantity} × EGP ${item.unitPrice.toStringAsFixed(2)}'
                  '${item.productId == null ? ' · وقت' : ''}'
                  '${fullyReturned ? ' · اترجّع بالكامل' : (alreadyReturned > 0 ? ' · اتّرجّع $alreadyReturned' : '')}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          if (selected) ...[
            _stepBtn(
              Icons.remove_rounded,
              qty > 1 ? () => setState(() => _qty[item.id] = qty - 1) : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text('$qty',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
            ),
            _stepBtn(
              Icons.add_rounded,
              qty < remaining
                  ? () => setState(() => _qty[item.id] = qty + 1)
                  : null,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Text('EGP ${lineTotal.toStringAsFixed(2)}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? AppColors.textPrimary
                    : AppColors.textTertiary,
              )),
        ],
      ),
    );
  }

  Widget _stepBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smallR,
      child: Container(
        width: 26,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: onTap == null
              ? Colors.transparent
              : AppColors.accentPrimary.withOpacity(0.15),
          borderRadius: AppRadius.smallR,
        ),
        child: Icon(icon,
            size: 16,
            color: onTap == null
                ? AppColors.textTertiary
                : AppColors.accentSecondary),
      ),
    );
  }
}

/// A tappable invoice row inside the dialog's picker.
class _PickerRow extends StatelessWidget {
  const _PickerRow({required this.entry, required this.onTap});

  final InvoiceWithCustomer entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smallR,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('فاتورة #${entry.invoice.id}',
                      style: AppTypography.cardTitle),
                  const SizedBox(height: 2),
                  Text(_invoiceSubtitle(entry),
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text('EGP ${entry.invoice.total.toStringAsFixed(2)}',
                style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
