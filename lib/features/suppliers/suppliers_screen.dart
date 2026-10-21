import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/supplier_dao.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/supplier_repository.dart';
import '../../data/repositories/product_repository.dart';

String supplierActionLabel(String action) => switch (action) {
      'supplier_added' => 'إضافة مورد',
      'supplier_updated' => 'تعديل مورد',
      'supplier_deleted' => 'حذف مورد',
      'purchase_recorded' => 'تسجيل فاتورة شراء',
      'purchase_deleted' => 'حذف فاتورة شراء',
      _ => action,
    };

String _money(double v) => 'EGP ${v.toStringAsFixed(2)}';

/// Suppliers ("الموردين") — spec-wise the answer to "اشتريت من مين وبكام".
///
/// Three tabs, matching the expenses screen's shape: the purchase invoices
/// themselves, the supplier directory they are bought from, and the audit
/// trail of both. Recording a purchase raises stock and writes an expense in
/// one transaction, so the numbers here and in الحسابات can never disagree.
class SuppliersScreen extends ConsumerStatefulWidget {
  const SuppliersScreen({super.key});

  @override
  ConsumerState<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends ConsumerState<SuppliersScreen> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('الموردين وفواتير الشراء',
                    style: AppTypography.sectionTitle),
              ),
              SizedBox(
                width: 200,
                child: PrimaryButton(
                  label: 'فاتورة شراء',
                  icon: Icons.add_shopping_cart_rounded,
                  expand: true,
                  onPressed: () => showRecordPurchaseDialog(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            tabs: [
              Tab(text: 'فواتير الشراء'),
              Tab(text: 'الموردين'),
              Tab(text: 'سجل العمليات'),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Expanded(
            child: TabBarView(
              children: [
                _PurchasesTab(),
                _SuppliersTab(),
                _SupplierLogTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ purchases

class _PurchasesTab extends ConsumerWidget {
  const _PurchasesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final purchasesAsync = ref.watch(purchasesProvider);
    final permissions = ref.watch(permissionServiceProvider);
    final canDelete = permissions.canAdjustStock;

    return purchasesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child:
              Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
      data: (purchases) {
        if (purchases.isEmpty) {
          return const Center(
            child: Text('مفيش فواتير شراء مسجلة بعد',
                style: TextStyle(color: AppColors.textTertiary)),
          );
        }
        final total = purchases.fold<double>(0, (s, p) => s + p.total);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('إجمالي المشتريات: ${_money(total)}',
                style: AppTypography.cardTitle),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: ListView.separated(
                itemCount: purchases.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _PurchaseCard(
                  purchase: purchases[i],
                  canDelete: canDelete,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _PurchaseCard extends ConsumerWidget {
  const _PurchaseCard({required this.purchase, required this.canDelete});

  final PurchaseRow purchase;
  final bool canDelete;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('حذف فاتورة الشراء'),
        content: Text(
            'هيتم حذف فاتورة "${purchase.supplierName}" بقيمة ${_money(purchase.total)}، '
            'وهيترجّع المخزون زي ما كان، وهيتشال المصروف المرتبط بيها. متابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(supplierRepositoryProvider).deletePurchase(purchase);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حذف الفاتورة')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(purchaseItemsProvider(purchase.id));
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_rounded,
                  size: 20, color: AppColors.accentSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(purchase.supplierName,
                        style: AppTypography.cardTitle),
                    const SizedBox(height: 2),
                    Text(stampOf(purchase.purchaseDate),
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Text(_money(purchase.total),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary)),
              if (canDelete)
                IconButton(
                  icon: const Icon(Icons.delete_forever_rounded,
                      size: 18, color: AppColors.danger),
                  tooltip: 'حذف الفاتورة',
                  onPressed: () => _delete(context, ref),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          itemsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (e, _) => Text('خطأ في البنود: $e',
                style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            data: (items) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final item in items)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('• ${item.productName}',
                              style: const TextStyle(
                                  fontSize: 13, color: AppColors.textSecondary)),
                        ),
                        Text(
                          '${item.quantity} × ${item.unitCost.toStringAsFixed(0)} = ${item.lineTotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                if (purchase.note?.isNotEmpty == true) ...[
                  const SizedBox(height: 6),
                  Text(purchase.note!,
                      style: const TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textTertiary)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------ suppliers

class _SuppliersTab extends ConsumerWidget {
  const _SuppliersTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppliersAsync = ref.watch(suppliersProvider);
    final permissions = ref.watch(permissionServiceProvider);
    final canEdit = permissions.canChangePrice;

    return suppliersAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
          child:
              Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
      data: (suppliers) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${suppliers.length} مورد',
                      style: AppTypography.cardTitle),
                ),
                if (canEdit)
                  SizedBox(
                    width: 160,
                    child: PrimaryButton(
                      label: 'إضافة مورد',
                      icon: Icons.add_rounded,
                      expand: true,
                      onPressed: () => showAddSupplierDialog(context, ref),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: suppliers.isEmpty
                  ? const Center(
                      child: Text('مفيش موردين مسجلين — ابدأ بإضافة مورد',
                          style: TextStyle(color: AppColors.textTertiary)),
                    )
                  : ListView.separated(
                      itemCount: suppliers.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _SupplierCard(
                        supplier: suppliers[i],
                        canEdit: canEdit,
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _SupplierCard extends ConsumerWidget {
  const _SupplierCard({required this.supplier, required this.canEdit});

  final SupplierRow supplier;
  final bool canEdit;

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('حذف المورد'),
        content: Text(
            'هيتم إخفاء "${supplier.name}" من قايمة الموردين. فواتير الشراء القديمة هتفضل زي ما هي. متابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child:
                const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(supplierRepositoryProvider).deleteSupplier(supplier);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم حذف المورد')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.storefront_rounded,
              size: 20, color: AppColors.accentSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(supplier.code == null
                        ? supplier.name
                        : '(${supplier.code}) ${supplier.name}',
                    style: AppTypography.cardTitle),
                if (supplier.phone?.isNotEmpty == true ||
                    supplier.note?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (supplier.phone?.isNotEmpty == true) supplier.phone!,
                      if (supplier.note?.isNotEmpty == true) supplier.note!,
                    ].join(' — '),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          if (canEdit) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  size: 18, color: AppColors.textSecondary),
              tooltip: 'تعديل',
              onPressed: () => showAddSupplierDialog(context, ref,
                  existing: supplier),
            ),
            IconButton(
              icon: const Icon(Icons.delete_forever_rounded,
                  size: 18, color: AppColors.danger),
              tooltip: 'حذف',
              onPressed: () => _delete(context, ref),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------- dialogs

Future<void> showAddSupplierDialog(BuildContext context, WidgetRef ref,
    {SupplierRow? existing}) {
  return showDialog(
    context: context,
    builder: (_) => _SupplierDialog(existing: existing),
  );
}

class _SupplierDialog extends ConsumerStatefulWidget {
  const _SupplierDialog({this.existing});
  final SupplierRow? existing;

  @override
  ConsumerState<_SupplierDialog> createState() => _SupplierDialogState();
}

class _SupplierDialogState extends ConsumerState<_SupplierDialog> {
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _phone = TextEditingController(text: widget.existing?.phone ?? '');
  late final _note = TextEditingController(text: widget.existing?.note ?? '');
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(supplierRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.addSupplier(
            name: _name.text, phone: _phone.text, note: _note.text);
      } else {
        await repo.updateSupplier(widget.existing!,
            name: _name.text, phone: _phone.text, note: _note.text);
      }
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
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
            Text(widget.existing == null ? 'مورد جديد' : 'تعديل المورد',
                style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'اسم المورد'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'التليفون (اختياري)'),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _note,
              decoration: const InputDecoration(labelText: 'ملاحظة (اختياري)'),
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

// ----------------------------------------------------- record purchase dialog

Future<void> showRecordPurchaseDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (_) => const _RecordPurchaseDialog(),
  );
}

/// One editable line in the purchase form.
class _DraftLine {
  _DraftLine(this.productId, this.productName, this.quantity, this.unitCost);
  int productId;
  String productName;
  int quantity;
  double unitCost;

  double get total => quantity * unitCost;
}

class _RecordPurchaseDialog extends ConsumerStatefulWidget {
  const _RecordPurchaseDialog();

  @override
  ConsumerState<_RecordPurchaseDialog> createState() =>
      _RecordPurchaseDialogState();
}

class _RecordPurchaseDialogState
    extends ConsumerState<_RecordPurchaseDialog> {
  SupplierRow? _supplier;
  DateTime _date = DateTime.now();
  final _note = TextEditingController();
  final List<_DraftLine> _lines = [];
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  double get _total => _lines.fold<double>(0, (s, l) => s + l.total);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _addLine(_DraftLine draft) async {
    setState(() {
      _lines.add(draft);
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_supplier == null) {
      setState(() => _error = 'اختار المورد');
      return;
    }
    if (_lines.isEmpty) {
      setState(() => _error = 'ضيف بند واحد على الأقل');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final employee = ref.read(currentEmployeeProvider);
    try {
      await ref.read(supplierRepositoryProvider).recordPurchase(
            supplier: _supplier!,
            purchaseDate: _date,
            lines: [
              for (final l in _lines)
                PurchaseLine(
                  productId: l.productId,
                  productName: l.productName,
                  quantity: l.quantity,
                  unitCost: l.unitCost,
                ),
            ],
            note: _note.text,
            employeeId: employee?.id,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم تسجيل الفاتورة وزيادة المخزون')));
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final suppliersAsync = ref.watch(suppliersProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 640,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 620),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('فاتورة شراء جديدة',
                  style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: suppliersAsync.when(
                      loading: () => const LinearProgressIndicator(),
                      error: (e, _) => Text('خطأ: $e'),
                      data: (suppliers) => DropdownButtonFormField<int>(
                        initialValue: _supplier?.id,
                        isExpanded: true,
                        decoration:
                            const InputDecoration(labelText: 'المورد'),
                        items: [
                          for (final s in suppliers)
                            DropdownMenuItem(
                                value: s.id,
                                child: Text(s.code == null
                                    ? s.name
                                    : '(${s.code}) ${s.name}')),
                        ],
                        onChanged: (id) => setState(() => _supplier = suppliers
                            .where((s) => s.id == id)
                            .firstOrNull),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: const InputDecoration(labelText: 'التاريخ'),
                        child: Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded, size: 16),
                            const SizedBox(width: 8),
                            Text(dayOf(_date)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Text('بنود الفاتورة',
                  style: AppTypography.cardTitle),
              const SizedBox(height: AppSpacing.sm),
              _PurchaseEntryStrip(onAdd: _addLine),
              const SizedBox(height: AppSpacing.md),
              Flexible(
                child: _lines.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                        child: Center(
                          child: Text('لسه مفيش بنود — ابحث فوق واضغط إضافة',
                              style:
                                  TextStyle(color: AppColors.textTertiary)),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _lines.length,
                        itemBuilder: (_, i) {
                          final l = _lines[i];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                Expanded(
                                    child: Text(l.productName,
                                        style: const TextStyle(fontSize: 13))),
                                Text(
                                    '${l.quantity} × ${l.unitCost.toStringAsFixed(0)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary)),
                                const SizedBox(width: AppSpacing.md),
                                Text(_money(l.total),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                                IconButton(
                                  icon: const Icon(Icons.close_rounded,
                                      size: 16, color: AppColors.danger),
                                  onPressed: () =>
                                      setState(() => _lines.removeAt(i)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextField(
                controller: _note,
                decoration:
                    const InputDecoration(labelText: 'ملاحظة (اختياري)'),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  const Expanded(
                    child: Text('الإجمالي',
                        style: AppTypography.cardTitle),
                  ),
                  Text(_money(_total),
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accentSecondary)),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              const Text(
                'التسجيل هيزوّد المخزون ويحدّث سعر التكلفة ويسجّل مصروف المشتريات.',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
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
                      label: _saving ? 'جارٍ الحفظ...' : 'حفظ الفاتورة',
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
}

/// The always-open entry strip that sits inside the purchase form.
///
/// This replaces the old "إضافة بند" popup. The popup meant: tap a button,
/// a second dialog opens, hunt for the product, type two numbers, confirm,
/// and then do it all again for the next item — four clicks per line before
/// any typing. Here the cashier stays in one place: search, tap the product
/// (quantity and price fill themselves in), adjust if needed, press Enter or
/// "إضافة", and the strip clears itself ready for the next product.
///
/// Typing a barcode works too — a scanner just types fast and presses Enter,
/// which lands on [onSubmitted] of the search box.
class _PurchaseEntryStrip extends ConsumerStatefulWidget {
  const _PurchaseEntryStrip({required this.onAdd});

  /// Called with a finished line; the parent appends it to the invoice.
  final void Function(_DraftLine) onAdd;

  @override
  ConsumerState<_PurchaseEntryStrip> createState() =>
      _PurchaseEntryStripState();
}

class _PurchaseEntryStripState extends ConsumerState<_PurchaseEntryStrip> {
  ProductRow? _product;
  final _search = TextEditingController();
  final _qty = TextEditingController(text: '1');
  final _cost = TextEditingController();
  final _searchFocus = FocusNode();
  final _qtyFocus = FocusNode();
  final _costFocus = FocusNode();
  String? _error;
  bool _showResults = false;

  @override
  void dispose() {
    _search.dispose();
    _qty.dispose();
    _cost.dispose();
    _searchFocus.dispose();
    _qtyFocus.dispose();
    _costFocus.dispose();
    super.dispose();
  }

  void _choose(ProductRow p) {
    setState(() {
      _product = p;
      _error = null;
      _showResults = false;
      // Seed the price with what was last paid; the cashier overwrites it if
      // the supplier's price has moved. Quantity defaults to 1 unless the
      // cashier already typed one before picking.
      if (_cost.text.trim().isEmpty) {
        _cost.text = p.costPrice == 0 ? '' : p.costPrice.toStringAsFixed(0);
      }
      _search.text = p.name;
    });
    // Straight to quantity — the two numbers are the only thing left to type.
    _qtyFocus.requestFocus();
    _qty.selection =
        TextSelection(baseOffset: 0, extentOffset: _qty.text.length);
  }

  void _submit() {
    final qty = int.tryParse(_qty.text.trim());
    final cost = double.tryParse(_cost.text.trim());
    if (_product == null) {
      setState(() => _error = 'اختار الصنف من نتايج البحث');
      _searchFocus.requestFocus();
      return;
    }
    if (qty == null || qty <= 0) {
      setState(() => _error = 'الكمية لازم تكون رقم أكبر من صفر');
      _qtyFocus.requestFocus();
      return;
    }
    if (cost == null || cost < 0) {
      setState(() => _error = 'سعر الشراء لازم يكون رقم صحيح');
      _costFocus.requestFocus();
      return;
    }
    widget.onAdd(_DraftLine(_product!.id, _product!.name, qty, cost));
    // Reset for the next product, and put the cursor back where the cashier
    // is about to type again.
    setState(() {
      _product = null;
      _search.clear();
      _qty.text = '1';
      _cost.clear();
      _error = null;
      _showResults = false;
    });
    _searchFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final resultsAsync = ref.watch(productSearchProvider(_search.text));
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.bgBase.withValues(alpha: 0.4),
        borderRadius: AppRadius.mediumR,
        border: Border.all(
            color: _product == null
                ? AppColors.glassBorder
                : AppColors.accentSecondary.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _search,
            focusNode: _searchFocus,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'ابحث عن الصنف بالاسم أو الكود',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _product == null
                  ? null
                  : const Icon(Icons.check_circle_rounded,
                      color: AppColors.accentSecondary, size: 20),
              helperText: _product == null
                  ? 'اكتب جزء من الاسم أو الكود، وبعدين اختار الصنف من اللي تحت'
                  : 'تم اختيار ${_product!.name} — عدّل الكمية والسعر واضغط Enter',
            ),
            onChanged: (_) => setState(() {
              _product = null;
              _showResults = true;
            }),
            onTap: () => setState(() => _showResults = true),
            onSubmitted: (_) {
              // A barcode scanner ends with Enter: take the single match.
              final results = resultsAsync.value;
              if (results != null && results.length == 1) {
                _choose(results.first);
              }
            },
          ),
          if (_showResults && _product == null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 190),
              child: resultsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger)),
                data: (products) {
                  if (products.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.md),
                      child: Text('مفيش صنف بالاسم أو الكود ده',
                          style: TextStyle(color: AppColors.textTertiary)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: products.length,
                    itemBuilder: (_, i) {
                      final p = products[i];
                      return ListTile(
                        dense: true,
                        title: Text(p.name),
                        subtitle: Text(
                          [
                            if (p.sku?.isNotEmpty == true) 'كود: ${p.sku}',
                            'المخزون: ${p.stockQuantity}',
                            'آخر تكلفة: ${p.costPrice.toStringAsFixed(0)}',
                          ].join('  ·  '),
                          style: const TextStyle(fontSize: 11),
                        ),
                        onTap: () => _choose(p),
                      );
                    },
                  );
                },
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qty,
                  focusNode: _qtyFocus,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'الكمية'),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: TextField(
                  controller: _cost,
                  focusNode: _costFocus,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration:
                      const InputDecoration(labelText: 'سعر الشراء للوحدة'),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              PrimaryButton(
                label: 'إضافة',
                icon: Icons.add_rounded,
                onPressed: _submit,
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(_error!,
                style: const TextStyle(color: AppColors.danger, fontSize: 13)),
          ],
        ],
      ),
    );
  }
}

// ------------------------------------------------------------------- log tab

class _SupplierLogTab extends ConsumerWidget {
  const _SupplierLogTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logAsync = ref.watch(supplierLogProvider);
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
            final value = row.newValue ?? row.oldValue ?? '';
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
                        Text(supplierActionLabel(row.action),
                            style: AppTypography.cardTitle),
                        const SizedBox(height: 2),
                        Text(stampOf(row.createdAt),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  if (value.isNotEmpty) ...[
                    const SizedBox(width: AppSpacing.md),
                    Text(value,
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
