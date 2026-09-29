import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../data/repositories/product_repository.dart';

/// Add / edit product dialog. Pass [existing] to switch it into edit mode.
Future<void> showProductDialog(BuildContext context, WidgetRef ref,
    {ProductRow? existing}) {
  return showDialog(
    context: context,
    builder: (_) => _ProductDialog(existing: existing),
  );
}

/// Add / rename category dialog. Pass [existing] to rename instead of add.
Future<void> showCategoryDialog(BuildContext context, WidgetRef ref,
    {CategoryRow? existing}) {
  return showDialog(
    context: context,
    builder: (_) => _CategoryDialog(existing: existing),
  );
}

/// Soft-deletes a product after a confirmation. Returns true if it went
/// through — a refused permission or a failure surfaces a SnackBar.
Future<void> confirmDeleteProduct(
    BuildContext context, WidgetRef ref, ProductRow product) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: const Text('حذف المنتج'),
      content: Text(
          'هيتم حذف "${product.name}" من قائمة المنتجات والكاشير مع الحفاظ على فواتيره السابقة. متابعة؟'),
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
  try {
    await ref.read(productRepositoryProvider).deleteProduct(product);
  } catch (e) {
    if (context.mounted) _showError(context, '$e');
  }
}

/// Deletes an empty category. The "still has products" case is rejected by
/// the repository, so the message here is just the guard's own wording.
Future<void> confirmDeleteCategory(
    BuildContext context, WidgetRef ref, CategoryRow category) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (_) => AlertDialog(
      backgroundColor: AppColors.bgElevated,
      title: const Text('حذف التصنيف'),
      content: Text('هيتم حذف تصنيف "${category.name}". متابعة؟'),
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
  try {
    await ref.read(productRepositoryProvider).deleteCategory(category);
  } catch (e) {
    if (context.mounted) _showError(context, '$e');
  }
}

void _showError(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
      .showSnackBar(SnackBar(content: Text(message)));
}

// ---------------------------------------------------------------- product

class _ProductDialog extends ConsumerStatefulWidget {
  const _ProductDialog({this.existing});
  final ProductRow? existing;

  @override
  ConsumerState<_ProductDialog> createState() => _ProductDialogState();
}

class _ProductDialogState extends ConsumerState<_ProductDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _cost = TextEditingController(
      text: widget.existing == null
          ? ''
          : _trimNumber(widget.existing!.costPrice));
  late final TextEditingController _selling = TextEditingController(
      text: widget.existing == null
          ? ''
          : _trimNumber(widget.existing!.sellingPrice));
  late final TextEditingController _stock = TextEditingController(
      text: widget.existing?.stockQuantity.toString() ?? '0');
  late final TextEditingController _minStock = TextEditingController(
      text: widget.existing?.minimumStock.toString() ?? '5');
  late final TextEditingController _unit =
      TextEditingController(text: widget.existing?.unit ?? 'قطعة');
  late int? _categoryId = widget.existing?.categoryId;
  late bool _active = widget.existing?.active ?? true;
  String? _error;
  bool _saving = false;

  static String _trimNumber(double value) =>
      value == value.roundToDouble() ? value.toStringAsFixed(0) : '$value';

  @override
  void dispose() {
    _name.dispose();
    _cost.dispose();
    _selling.dispose();
    _stock.dispose();
    _minStock.dispose();
    _unit.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final cost = double.tryParse(_cost.text.trim());
    final selling = double.tryParse(_selling.text.trim());
    final stock = int.tryParse(_stock.text.trim());
    final minStock = int.tryParse(_minStock.text.trim());

    if (name.isEmpty) {
      setState(() => _error = 'اسم المنتج مطلوب');
      return;
    }
    if (_categoryId == null) {
      setState(() => _error = 'اختر التصنيف، أو أضف تصنيف جديد من تحت');
      return;
    }
    if (cost == null || selling == null) {
      setState(() => _error = 'اكتب سعر التكلفة وسعر البيع بأرقام صحيحة');
      return;
    }
    if (cost < 0 || selling < 0) {
      setState(() => _error = 'الأسعار مش ممكن تكون بالسالب');
      return;
    }
    if (stock == null || minStock == null || stock < 0 || minStock < 0) {
      setState(() => _error = 'الكميات لازم تكون أرقام صحيحة 0 أو أكتر');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final repo = ref.read(productRepositoryProvider);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await repo.addProduct(
          name: name,
          categoryId: _categoryId!,
          costPrice: cost,
          sellingPrice: selling,
          stockQuantity: stock,
          minimumStock: minStock,
          unit: _unit.text,
        );
      } else {
        await repo.updateProduct(existing.copyWith(
          name: name,
          categoryId: _categoryId,
          costPrice: cost,
          sellingPrice: selling,
          stockQuantity: stock,
          minimumStock: minStock,
          unit: _unit.text.trim().isEmpty ? 'قطعة' : _unit.text.trim(),
          active: _active,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final cost = double.tryParse(_cost.text.trim());
    final selling = double.tryParse(_selling.text.trim());

    return _ManagerDialogShell(
      title: widget.existing == null ? 'منتج جديد' : 'تعديل المنتج',
      error: _error,
      saving: _saving,
      onSave: _save,
      children: [
        _field(_name, 'اسم المنتج'),
        const SizedBox(height: AppSpacing.md),
        categoriesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              Text('$e', style: const TextStyle(color: AppColors.danger)),
          data: (categories) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _dropdown<int>(
                value: _categoryId,
                hint: 'التصنيف',
                items: categories
                    .map((c) =>
                        DropdownMenuItem(value: c.id, child: Text(c.name)))
                    .toList(),
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('تصنيف مش موجود؟',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textTertiary)),
                  TextButton(
                    onPressed: () => showCategoryDialog(context, ref),
                    child: const Text('＋ أضف تصنيف'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _field(_cost, 'سعر التكلفة (EGP)')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _field(_selling, 'سعر البيع (EGP)')),
          ],
        ),
        if (cost != null && selling != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              'الربح للقطعة: EGP ${(selling - cost).toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 12,
                color: selling >= cost
                    ? AppColors.statusAvailable
                    : AppColors.danger,
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _field(_stock, 'الكمية في المخزون')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _field(_minStock, 'حد التنبيه')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _field(_unit, 'الوحدة')),
          ],
        ),
        if (widget.existing != null) ...[
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Switch(
                value: _active,
                activeThumbColor: AppColors.accentPrimary,
                onChanged: (v) => setState(() => _active = v),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(_active ? 'نشط' : 'موقوف', style: AppTypography.body),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  'المنتج الموقوف بيختفي من الكاشير والمخزون',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// -------------------------------------------------------------- category

class _CategoryDialog extends ConsumerStatefulWidget {
  const _CategoryDialog({this.existing});
  final CategoryRow? existing;

  @override
  ConsumerState<_CategoryDialog> createState() => _CategoryDialogState();
}

class _CategoryDialogState extends ConsumerState<_CategoryDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
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
      setState(() => _error = 'اسم التصنيف مطلوب');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final repo = ref.read(productRepositoryProvider);
    try {
      if (widget.existing == null) {
        await repo.addCategory(name);
      } else {
        await repo.renameCategory(widget.existing!.id, name);
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _ManagerDialogShell(
      title: widget.existing == null ? 'تصنيف جديد' : 'تعديل التصنيف',
      error: _error,
      saving: _saving,
      onSave: _save,
      children: [
        _field(_name, 'اسم التصنيف (مثلاً: مشروبات، سناكس)'),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'التصنيف بيظهر في الكاشير بمجرد ما تضيفله منتج واحد.',
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------- shell

class _ManagerDialogShell extends StatelessWidget {
  const _ManagerDialogShell({
    required this.title,
    required this.children,
    required this.onSave,
    this.error,
    this.saving = false,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final String? error;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 520,
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
              Text(title, style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.lg),
              ...children,
              if (error != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(error!,
                    style: const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'إلغاء',
                      onPressed: saving ? null : () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: PrimaryButton(
                      label: saving ? 'جاري الحفظ…' : 'حفظ',
                      icon: Icons.check_rounded,
                      expand: true,
                      onPressed: saving ? null : onSave,
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

Widget _field(TextEditingController controller, String hint) {
  return TextField(
    controller: controller,
    style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
      isDense: true,
      filled: true,
      fillColor: AppColors.glassFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.smallR,
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.smallR,
        borderSide: const BorderSide(color: AppColors.glassBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.smallR,
        borderSide: const BorderSide(color: AppColors.glassBorderPurple),
      ),
    ),
  );
}

Widget _dropdown<T>({
  required T? value,
  required String hint,
  required List<DropdownMenuItem<T>> items,
  required ValueChanged<T?> onChanged,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.glassFill,
      borderRadius: AppRadius.smallR,
      border: Border.all(color: AppColors.glassBorder),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        hint: Text(hint,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        dropdownColor: AppColors.bgElevated,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}
