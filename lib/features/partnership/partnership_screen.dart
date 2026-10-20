import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/accounting/profit.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/repositories/employee_repository.dart';
import '../reports/report_period_selector.dart';

/// شاشة الشراكة — "طه" صاحب المحل و"نادر" شريك (50% افتراضيًا أو حسب النسب).
///
/// القسمة بتتم على **صافي الربح** مش الإيراد، وبنفس تعريف كل شاشات البرنامج
/// ([Accounting]): الإيراد (المسدَّد) − تكلفة البضاعة − المصروفات − المرتجعات.
/// ولكل شريك: نصيبه = الربح × النسبة، والصافي المستحق = نصيبه − مسحوباته + سداده.
///
/// الشاشة جدول واحد كل سطر فيه بيقفل مع اللي فوقه بالظبط:
///   الإيراد = ألعاب + كافيه − الخصومات، ثم يطرح التكاليف ⇒ صافي الربح.
/// وكل سطر جنبه «تفصيل» بيفتح الحركات اللي اتحسب منها الرقم نفسه.
class PartnershipScreen extends ConsumerWidget {
  const PartnershipScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(partnershipSnapshotProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text('الشراكة', style: AppTypography.sectionTitle),
                  SizedBox(height: 2),
                  Text('حسابات الشركاء على أساس صافي الربح — كل سطر يفتح تفصيلو',
                      style: AppTypography.secondary),
                ],
              ),
            ),
            ReportPeriodSelector(provider: partnershipPeriodProvider),
            const SizedBox(width: AppSpacing.md),
            TextButton.icon(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => const _AddPartnerDialog(),
              ),
              icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
              label: const Text('إضافة شريك'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accentSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: snapshotAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('خطأ: $e',
                  style: const TextStyle(color: AppColors.danger)),
            ),
            data: (snap) => SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FinancialBreakdown(snap: snap),
                  const SizedBox(height: AppSpacing.lg),
                  _PartnersSection(snap: snap),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Money / labels ───────────────────────────────────────────────────

/// EGP, two decimals like every other money figure in the app — a shared
/// precision is what lets a column of numbers visibly add up (نصيب شريك من
/// ربح فردي بيطلع بكسور، و«0 جنيه» كان هيخفيها).
String _egp(double v) => v < -0.005
    ? '− EGP ${v.abs().toStringAsFixed(2)}'
    : 'EGP ${v.toStringAsFixed(2)}';

String _methodLabel(String method) => switch (method) {
      'cash' => 'كاش',
      'card' => 'كارت',
      'mixed' => 'مختلط',
      'credit' => 'آجل',
      'unpaid' => 'غير مسدَّد',
      _ => method,
    };

// ── Dashboard table ──────────────────────────────────────────────────

class _FinancialBreakdown extends StatelessWidget {
  const _FinancialBreakdown({required this.snap});
  final PartnersSnapshot snap;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.insights_rounded,
                  size: 18, color: AppColors.accentSecondary),
              SizedBox(width: AppSpacing.sm),
              Text('ملخص الفترة', style: AppTypography.cardTitle),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _section('الإيراد'),
          _BreakdownRow(
            label: 'الإيراد (المسدَّد)',
            value: snap.revenue,
            bold: true,
            onDetail: () => _openRevenueDetail(context, snap),
          ),
          _BreakdownRow(
            label: 'ألعاب (وقت اللعب)',
            value: snap.gamingRevenue,
            indent: 20,
            onDetail: () => _openGamingDetail(context, snap),
          ),
          _BreakdownRow(
            label: 'كافيه',
            value: snap.cafeRevenue,
            indent: 20,
            onDetail: () => _openCafeDetail(context, snap),
          ),
          if (snap.discounts > 0.005)
            _BreakdownRow(
              label: 'الخصومات',
              value: -snap.discounts,
              indent: 20,
              valueColor: AppColors.warning,
              onDetail: () => _openDiscountDetail(context, snap),
            ),
          _divider(),
          _section('التكاليف'),
          _BreakdownRow(
            label: 'تكلفة البضاعة (المشتريات)',
            value: snap.costOfGoods,
            onDetail: () => _openCogsDetail(context, snap),
          ),
          _BreakdownRow(
            label: 'المصروفات',
            value: snap.expenses,
            onDetail: () => _openExpensesDetail(context, snap),
          ),
          _BreakdownRow(
            label: 'المرتجعات',
            value: snap.refunds,
            onDetail: () => _openRefundsDetail(context, snap),
          ),
          _divider(),
          _BreakdownRow(
            label: 'صافي الربح',
            value: snap.profit,
            bold: true,
            valueColor: snap.profit >= 0
                ? AppColors.statusAvailable
                : AppColors.danger,
          ),
          _divider(),
          _section('مسحوبات الشركاء'),
          _BreakdownRow(
            label: 'إجمالي المسحوبات',
            value: snap.totalWithdrawals,
            onDetail: () =>
                _openTransactionsDetail(context, snap, kind: 'withdraw'),
          ),
          _BreakdownRow(
            label: 'إجمالي السداد',
            value: snap.totalRepayments,
            onDetail: () =>
                _openTransactionsDetail(context, snap, kind: 'repayment'),
          ),
          _divider(),
          _BreakdownRow(
            label: 'إجمالي نصيب الشركاء',
            value: snap.totalShares,
            valueColor: AppColors.accentSecondary,
          ),
          if (snap.totalSharePercent < 99.999)
            _BreakdownRow(
              label: 'المتبقّي للمحل',
              value: snap.keptByShop,
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'صافي الربح = الإيراد (المسدَّد) − تكلفة البضاعة − المصروفات − المرتجعات.',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
          if (snap.totalSharePercent > 100) ...[
            const SizedBox(height: AppSpacing.md),
            Row(
              children: const [
                Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 18),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'مجموع نِسب الشركاء أكتر من 100% — ده معناه إن القسمة بتدفع أكتر من اللي المحل كسبه. راجع النسب من "إضافة شريك".',
                    style: TextStyle(color: AppColors.danger, fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
        child: Text(title,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textTertiary)),
      );

  Widget _divider() => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Divider(height: 1, color: AppColors.glassBorder),
      );
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.value,
    this.indent = 0,
    this.bold = false,
    this.valueColor,
    this.onDetail,
  });

  final String label;
  final double value;
  final double indent;
  final bool bold;
  final Color? valueColor;
  final VoidCallback? onDetail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsetsDirectional.only(
          start: indent, top: 6, bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: bold ? 14 : 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(
            _egp(value),
            style: TextStyle(
              fontSize: bold ? 15 : 13,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w600,
              color: valueColor ?? AppColors.textPrimary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          SizedBox(
            width: 64,
            child: onDetail == null
                ? null
                : Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: _detailButton(onDetail!),
                  ),
          ),
        ],
      ),
    );
  }
}

Widget _detailButton(VoidCallback onTap) => TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 28),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: AppColors.accentSecondary,
        textStyle: const TextStyle(fontSize: 12),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smallR,
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
      child: const Text('تفصيل'),
    );

Widget _chip(String label, String value, {Color? color}) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.glassFillStrong,
        borderRadius: AppRadius.smallR,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Text('$label: $value',
          style: TextStyle(
              fontSize: 12,
              color: color ?? AppColors.textSecondary,
              fontWeight: FontWeight.w600)),
    );

// ── Partners ─────────────────────────────────────────────────────────

class _PartnersSection extends StatelessWidget {
  const _PartnersSection({required this.snap});
  final PartnersSnapshot snap;

  @override
  Widget build(BuildContext context) {
    if (snap.partners.isEmpty) {
      return GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('الشركاء', style: AppTypography.cardTitle),
            SizedBox(height: AppSpacing.sm),
            Text(
              'مافيش شركاء مسجّلين. اضغط "إضافة شريك" واكتب اسم الشريك (زي طه ونادر) ونسبته من صافي الربح.',
              style: TextStyle(color: AppColors.textTertiary, fontSize: 13),
            ),
          ],
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الشركاء ونصيب كل واحد', style: AppTypography.cardTitle),
        const SizedBox(height: AppSpacing.sm),
        if (snap.totalSharePercent < 99.999) ...[
          Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  size: 16, color: AppColors.textTertiary),
              SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'النسب المسجّلة بتغطّي أقل من 100% من الربح — الباقي بيتحسب للمحل. لو فيه شريك تاني (زي صاحب المحل) مش مسجّل، ضيفه من "إضافة شريك".',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        ...snap.partners.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _PartnerCard(entry: e, snap: snap),
            )),
      ],
    );
  }
}

class _PartnerCard extends ConsumerWidget {
  const _PartnerCard({required this.entry, required this.snap});
  final PartnerLedgerEntry entry;
  final PartnersSnapshot snap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final net = entry.net;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.handshake_rounded,
                  size: 20, color: AppColors.accentSecondary),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(entry.partner.name, style: AppTypography.cardTitle),
              ),
              Text('${entry.sharePercent.toStringAsFixed(0)}%',
                  style: const TextStyle(color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.sm,
            children: [
              _chip('نصيبه من الربح', _egp(entry.share)),
              _chip('مسحوبات', _egp(entry.withdrawals)),
              _chip('سداد', _egp(entry.repayments)),
              _chip('الصافي المستحق', _egp(net),
                  color: net >= 0
                      ? AppColors.statusAvailable
                      : AppColors.danger),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _action(context, ref, 'withdraw', 'تسجيل مسحوبات',
                  Icons.call_made_rounded),
              const SizedBox(width: AppSpacing.sm),
              _action(context, ref, 'repayment', 'تسجيل سداد',
                  Icons.call_received_rounded),
              const SizedBox(width: AppSpacing.sm),
              _action(
                context,
                ref,
                'withdraw',
                'تفصيل المسحوبات',
                Icons.receipt_long_rounded,
                detail: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(BuildContext context, WidgetRef ref, String kind, String label,
      IconData icon,
      {bool detail = false}) {
    return TextButton.icon(
      onPressed: () {
        if (detail) {
          _openTransactionsDetail(context, snap,
              kind: kind, partnerId: entry.partner.id);
        } else {
          _openTransaction(context, ref, kind);
        }
      },
      icon: Icon(icon, size: 16),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      style: TextButton.styleFrom(
        foregroundColor: AppColors.accentSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.smallR,
          side: const BorderSide(color: AppColors.glassBorder),
        ),
      ),
    );
  }

  Future<void> _openTransaction(
      BuildContext context, WidgetRef ref, String kind) async {
    final result = await showDialog<_TxResult>(
      context: context,
      builder: (_) =>
          _TransactionDialog(partnerName: entry.partner.name, kind: kind),
    );
    if (result == null) return;
    await ref.read(employeeRepositoryProvider).addTransaction(
          employeeId: entry.partner.id,
          kind: kind,
          amount: result.amount,
          note: result.note,
        );
    ref.invalidate(partnershipSnapshotProvider);
  }
}

// ── Detail dialogs ───────────────────────────────────────────────────

/// A shared shell for every "تفصيل" dialog: a title, a row of summary chips,
/// then the movements. Built once so every breakdown reads the same way.
class _DetailDialog extends StatelessWidget {
  const _DetailDialog({
    required this.title,
    this.subtitle,
    this.summary = const [],
    required this.children,
  });

  final String title;
  final String? subtitle;
  final List<Widget> summary;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
          ],
        ],
      ),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary.isNotEmpty) ...[
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: summary,
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 400),
              child: children.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text('مافيش حركات في الفترة دي',
                            style:
                                TextStyle(color: AppColors.textTertiary)),
                      ),
                    )
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: children,
                      ),
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إغلاق'),
        ),
      ],
    );
  }
}

Widget _detailLine(String primary, String value, {String? secondary}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(primary,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textPrimary)),
              if (secondary != null)
                Text(secondary,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontFeatures: [FontFeature.tabularFigures()])),
      ],
    ),
  );
}

Map<int, List<InvoiceItemRow>> _itemsByInvoice(List<InvoiceItemRow> items) {
  final map = <int, List<InvoiceItemRow>>{};
  for (final item in items) {
    map.putIfAbsent(item.invoiceId, () => <InvoiceItemRow>[]).add(item);
  }
  return map;
}

Future<void> _openRevenueDetail(
    BuildContext context, PartnersSnapshot snap) async {
  final rows = [...snap.invoices]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final byInvoice = _itemsByInvoice(snap.items);
  await showDialog<void>(
    context: context,
    builder: (_) => _DetailDialog(
      title: 'تفصيل الإيراد (المسدَّد)',
      subtitle: '${rows.length} فاتورة مسدَّدة',
      summary: [
        _chip('ألعاب', _egp(snap.gamingRevenue)),
        _chip('كافيه', _egp(snap.cafeRevenue)),
        if (snap.discounts > 0.005)
          _chip('خصومات', _egp(-snap.discounts), color: AppColors.warning),
        _chip('الإجمالي', _egp(snap.revenue),
            color: AppColors.statusAvailable),
      ],
      children: [
        for (final inv in rows) _invoiceDetailLine(inv, byInvoice[inv.id]),
      ],
    ),
  );
}

Widget _invoiceDetailLine(InvoiceRow inv, List<InvoiceItemRow>? lines) {
  final split = Accounting.revenueBreakdown(
    invoices: [inv],
    items: lines ?? const [],
  );
  final parts = <String>[
    'ألعاب ${_egp(split.gaming)}',
    'كافيه ${_egp(split.cafe)}',
    if (split.discounts > 0.005) 'خصم ${_egp(split.discounts)}',
  ];
  return _detailLine(
    '#${inv.id} · ${_methodLabel(inv.paymentMethod)}',
    _egp(inv.total),
    secondary: '${stampOf(inv.createdAt)} — ${parts.join(' · ')}',
  );
}

Future<void> _openGamingDetail(
    BuildContext context, PartnersSnapshot snap) async {
  final lines = snap.items.where((l) => l.productId == null).toList()
    ..sort((a, b) => b.id.compareTo(a.id));
  final total = lines.fold<double>(0, (s, l) => s + l.total);
  final at = {for (final i in snap.invoices) i.id: i.createdAt};
  await showDialog<void>(
    context: context,
    builder: (_) => _DetailDialog(
      title: 'تفصيل الألعاب (وقت اللعب)',
      subtitle: 'بنود «وقت اللعب» على الفواتير المسدَّدة',
      summary: [
        _chip('عدد البنود', '${lines.length}'),
        _chip('الإجمالي', _egp(total)),
      ],
      children: [
        for (final l in lines)
          _detailLine(
            '#${l.invoiceId} · ${l.description} ×${l.quantity}',
            _egp(l.total),
            secondary: at[l.invoiceId] == null
                ? null
                : stampOf(at[l.invoiceId]!),
          ),
      ],
    ),
  );
}

Future<void> _openCafeDetail(
    BuildContext context, PartnersSnapshot snap) async {
  final lines = snap.items.where((l) => l.productId != null).toList()
    ..sort((a, b) => b.id.compareTo(a.id));
  final total = lines.fold<double>(0, (s, l) => s + l.total);
  final at = {for (final i in snap.invoices) i.id: i.createdAt};
  await showDialog<void>(
    context: context,
    builder: (_) => _DetailDialog(
      title: 'تفصيل الكافيه',
      subtitle: 'بنود المنتجات على الفواتير المسدَّدة',
      summary: [
        _chip('عدد البنود', '${lines.length}'),
        _chip('الإجمالي', _egp(total)),
      ],
      children: [
        for (final l in lines)
          _detailLine(
            '#${l.invoiceId} · ${l.description} ×${l.quantity}',
            _egp(l.total),
            secondary: at[l.invoiceId] == null
                ? null
                : stampOf(at[l.invoiceId]!),
          ),
      ],
    ),
  );
}

Future<void> _openDiscountDetail(
    BuildContext context, PartnersSnapshot snap) async {
  final rows = snap.invoices.where((i) => i.discount > 0.005).toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  await showDialog<void>(
    context: context,
    builder: (_) => _DetailDialog(
      title: 'تفصيل الخصومات',
      subtitle: '${rows.length} فاتورة فيها خصم',
      summary: [_chip('الإجمالي', _egp(snap.discounts))],
      children: [
        for (final inv in rows)
          _detailLine(
            '#${inv.id} · ${_methodLabel(inv.paymentMethod)}',
            _egp(-inv.discount),
            secondary:
                '${stampOf(inv.createdAt)} — قبل الخصم ${_egp(inv.subtotal)}',
          ),
      ],
    ),
  );
}

Future<void> _openCogsDetail(
    BuildContext context, PartnersSnapshot snap) async {
  final qty = <int, int>{};
  for (final l in snap.items) {
    final pid = l.productId;
    if (pid == null) continue;
    qty[pid] = (qty[pid] ?? 0) + l.quantity;
  }
  final entries = qty.entries
      .map((e) => (
            name: snap.productsById[e.key]?.name ?? 'منتج محذوف',
            qty: e.value,
            unit: snap.costByProduct[e.key] ?? 0,
            total: (snap.costByProduct[e.key] ?? 0) * e.value,
          ))
      .toList()
    ..sort((a, b) => b.total.compareTo(a.total));
  await showDialog<void>(
    context: context,
    builder: (_) => _DetailDialog(
      title: 'تفصيل تكلفة البضاعة (المشتريات)',
      subtitle: 'الكميات المباعة × سعر التكلفة الحالي',
      summary: [
        _chip('عدد الأصناف', '${entries.length}'),
        _chip('الإجمالي', _egp(snap.costOfGoods),
            color: AppColors.statusAvailable),
      ],
      children: [
        for (final e in entries)
          _detailLine(
            '${e.name} ×${e.qty}',
            _egp(e.total),
            secondary: 'تكلفة الوحدة ${_egp(e.unit)}',
          ),
      ],
    ),
  );
}

Future<void> _openExpensesDetail(
    BuildContext context, PartnersSnapshot snap) async {
  final rows = [...snap.expenseRows]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  await showDialog<void>(
    context: context,
    builder: (_) => _DetailDialog(
      title: 'تفصيل المصروفات',
      subtitle: '${rows.length} مصروف في الفترة',
      summary: [_chip('الإجمالي', _egp(snap.expenses))],
      children: [
        for (final e in rows)
          _detailLine(
            e.description == null || e.description!.isEmpty
                ? e.category
                : '${e.category} — ${e.description}',
            _egp(e.amount),
            secondary: stampOf(e.createdAt),
          ),
      ],
    ),
  );
}

Future<void> _openRefundsDetail(
    BuildContext context, PartnersSnapshot snap) async {
  final rows = [...snap.refundRows]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  await showDialog<void>(
    context: context,
    builder: (_) => _DetailDialog(
      title: 'تفصيل المرتجعات',
      subtitle: '${rows.length} مرتجع في الفترة',
      summary: [_chip('الإجمالي', _egp(snap.refunds))],
      children: [
        for (final r in rows)
          _detailLine(
            'فاتورة #${r.invoiceId}'
            '${r.reason == null || r.reason!.isEmpty ? '' : ' — ${r.reason}'}',
            _egp(r.amount),
            secondary: stampOf(r.createdAt),
          ),
      ],
    ),
  );
}

Future<void> _openTransactionsDetail(
  BuildContext context,
  PartnersSnapshot snap, {
  required String kind,
  int? partnerId,
}) async {
  final isWithdraw = kind == 'withdraw';
  final nameOf = {for (final p in snap.partners) p.partner.id: p.partner.name};
  final partnerIds = nameOf.keys.toSet();
  final rows = snap.transactions
      .where((t) =>
          t.kind == kind &&
          partnerIds.contains(t.employeeId) &&
          (partnerId == null || t.employeeId == partnerId))
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  final total = rows.fold<double>(0, (s, t) => s + t.amount);
  await showDialog<void>(
    context: context,
    builder: (_) => _DetailDialog(
      title: 'تفصيل ${isWithdraw ? 'المسحوبات' : 'السداد'}'
          '${partnerId == null ? '' : ' — ${nameOf[partnerId] ?? ''}'}',
      subtitle: '${rows.length} حركة',
      summary: [
        _chip('الإجمالي', _egp(total),
            color:
                isWithdraw ? AppColors.warning : AppColors.statusAvailable),
      ],
      children: [
        for (final t in rows)
          _detailLine(
            nameOf[t.employeeId] ?? 'موظف',
            _egp(t.amount),
            secondary: '${stampOf(t.createdAt)}'
                '${t.note == null || t.note!.isEmpty ? '' : ' · ${t.note}'}',
          ),
      ],
    ),
  );
}

// ── Withdrawal / repayment entry ─────────────────────────────────────

class _TxResult {
  _TxResult(this.amount, this.note);
  final double amount;
  final String? note;
}

/// Small dialog for a withdrawal or a repayment against a partner's share.
class _TransactionDialog extends StatefulWidget {
  const _TransactionDialog({required this.partnerName, required this.kind});
  final String partnerName;
  final String kind;

  @override
  State<_TransactionDialog> createState() => _TransactionDialogState();
}

class _TransactionDialogState extends State<_TransactionDialog> {
  final _amount = TextEditingController();
  final _note = TextEditingController();
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
    Navigator.of(context).pop(
      _TxResult(value, _note.text.trim().isEmpty ? null : _note.text.trim()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isWithdraw = widget.kind == 'withdraw';
    return AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title:
          Text('${isWithdraw ? 'مسحوبات' : 'سداد'} — ${widget.partnerName}'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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
            const SizedBox(height: AppSpacing.sm),
            Text(_error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('إلغاء'),
        ),
        FilledButton(onPressed: _submit, child: const Text('حفظ')),
      ],
    );
  }
}

/// The one place partnerships are administered.
///
/// A partner (شريك) is not an employee, so this dialog works **only** on
/// records already marked as partners — it never lists the staff. That is the
/// point of it: the old "إدارة الشركاء" dialog showed every employee and made
/// you pick which ones were partners, which is exactly how طه ونادر ended up
/// as rows in a staff list they do not belong to.
///
/// It does all three things the shop needs in one place:
///  * add a new partner — name and share, phone optional;
///  * change an existing partner's name or share;
///  * remove a partner (unmark, so their history is kept but they stop
///    counting in the split).
class _AddPartnerDialog extends ConsumerStatefulWidget {
  const _AddPartnerDialog();

  @override
  ConsumerState<_AddPartnerDialog> createState() => _AddPartnerDialogState();
}

class _AddPartnerDialogState extends ConsumerState<_AddPartnerDialog> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _share = TextEditingController(text: '50');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _share.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final share = double.tryParse(_share.text.trim());
    if (name.isEmpty) {
      setState(() => _error = 'اكتب اسم الشريك');
      return;
    }
    if (share == null || share <= 0 || share > 100) {
      setState(() => _error = 'النسبة لازم تكون رقم من 1 لـ100');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(employeeRepositoryProvider).addPartner(
            name: name,
            share: share,
            phone: _phone.text.trim(),
          );
      if (!mounted) return;
      ref.invalidate(partnershipSnapshotProvider);
      _name.clear();
      _phone.clear();
      _share.text = '50';
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only partners — never employees. The list everyone is weighed against
    // must be exactly the people who will be paid, or the ≤100% check is
    // meaningless.
    final partners = (ref.watch(partnersProvider).value ?? const <EmployeeRow>[])
        .where((p) => p.active)
        .toList();
    final total =
        partners.fold<double>(0, (s, p) => s + EmployeeRepository.normalizedShare(p.partnerShare));

    return AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: const Text('إضافة شريك'),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'الشريك مش موظف — مش بيسجّل دخول ومش بيظهر في شاشة الموظفين. حدّد اسمه ونسبته من صافي الربح.',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
              ),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: _name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم الشريك'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _share,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'نسبته من صافي الربح',
                        suffixText: '%',
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: TextField(
                      controller: _phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'رقم الموبايل (اختياري)',
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(_error!,
                    style: const TextStyle(
                        color: AppColors.danger, fontSize: 13)),
              ],
              if (partners.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.lg),
                Row(
                  children: [
                    const Text('الشركاء الحاليين',
                        style: AppTypography.cardTitle),
                    const Spacer(),
                    Text('${total.toStringAsFixed(0)}% من 100%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: total > 100
                              ? AppColors.danger
                              : AppColors.textSecondary,
                        )),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                for (final p in partners)
                  _PartnerEditRow(partner: p),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('تم'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('إضافة'),
        ),
      ],
    );
  }
}

/// One existing partner inside the add dialog: edit the name or share inline,
/// or remove the partner outright.
class _PartnerEditRow extends ConsumerStatefulWidget {
  const _PartnerEditRow({required this.partner});

  final EmployeeRow partner;

  @override
  ConsumerState<_PartnerEditRow> createState() => _PartnerEditRowState();
}

class _PartnerEditRowState extends ConsumerState<_PartnerEditRow> {
  late final TextEditingController _name =
      TextEditingController(text: widget.partner.name);
  late final TextEditingController _share = TextEditingController(
      text: EmployeeRepository.normalizedShare(widget.partner.partnerShare)
          .toStringAsFixed(0));

  @override
  void dispose() {
    _name.dispose();
    _share.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final repo = ref.read(employeeRepositoryProvider);
    final name = _name.text.trim();
    final share = double.tryParse(_share.text.trim());
    try {
      await repo.updatePartner(
        widget.partner.id,
        name: name == widget.partner.name ? null : name,
        share: share,
      );
      if (!mounted) return;
      ref.invalidate(partnershipSnapshotProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('تعذّر الحفظ: $e')));
    }
  }

  Future<void> _remove() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text('إلغاء شراكة ${widget.partner.name}؟'),
        content: const Text(
          'هيتشال من قسمة الربح، وكل مسحوباته وسجله التاريخي هيفضلوا محفوظين. تقدر ترجّعه تاني في أي وقت.',
          style: TextStyle(fontSize: 13),
        ),
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
    if (ok != true) return;
    await ref
        .read(employeeRepositoryProvider)
        .setPartner(widget.partner.id, isPartner: false);
    if (!mounted) return;
    ref.invalidate(partnershipSnapshotProvider);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: TextField(
              controller: _name,
              decoration: const InputDecoration(
                  isDense: true, labelText: 'الاسم'),
              onSubmitted: (_) => _save(),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 90,
            child: TextField(
              controller: _share,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                  isDense: true, suffixText: '%'),
              onSubmitted: (_) => _save(),
            ),
          ),
          IconButton(
            tooltip: 'حفظ التعديل',
            onPressed: _save,
            icon: const Icon(Icons.check_rounded, size: 18),
            color: AppColors.accentSecondary,
            visualDensity: VisualDensity.compact,
          ),
          IconButton(
            tooltip: 'إلغاء الشراكة',
            onPressed: _remove,
            icon: const Icon(Icons.person_remove_rounded, size: 18),
            color: AppColors.textTertiary,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

