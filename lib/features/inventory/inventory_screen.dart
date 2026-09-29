import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/permissions/permission_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/product_dao.dart';
import '../../data/repositories/product_repository.dart';
import '../dashboard/hero_and_kpi.dart';
import '../products/product_manager.dart';

/// Inventory screen — spec section 25/18/19, now backed by the real
/// products table. Reads/writes the same ProductRepository used by POS
/// and Settings, so editing here is reflected everywhere immediately.
class InventoryScreen extends ConsumerWidget {
  const InventoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsWithCategoryProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final canEdit = ref.watch(permissionServiceProvider).canChangePrice;

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
      data: (allProducts) {
        final inventoryValue = allProducts.fold<double>(
            0, (sum, p) => sum + p.product.costPrice * p.product.stockQuantity);
        final lowStockCount = allProducts.where((p) => p.isLowStock).length;
        final totalProducts = allProducts.length;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _kpiRow(inventoryValue, lowStockCount, totalProducts),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('كل المنتجات', style: AppTypography.sectionTitle),
                        SizedBox(height: 2),
                        Text('أضف المنتجات والتصنيفات اللي بتبيعها',
                            style: AppTypography.secondary),
                      ],
                    ),
                  ),
                  if (canEdit) ...[
                    SecondaryButton(
                      label: 'تصنيف جديد',
                      icon: Icons.create_new_folder_outlined,
                      onPressed: () => showCategoryDialog(context, ref),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    PrimaryButton(
                      label: 'منتج جديد',
                      icon: Icons.add_rounded,
                      onPressed: () => showProductDialog(context, ref),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              if (canEdit)
                categoriesAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (categories) => _categoryStrip(
                    context,
                    ref,
                    categories,
                    allProducts,
                  ),
                ),
              if (canEdit) const SizedBox(height: AppSpacing.md),
              if (allProducts.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: Center(
                    child: Text(
                      canEdit
                          ? 'لا توجد منتجات بعد — اضغط "منتج جديد" للبداية'
                          : 'لا توجد منتجات بعد',
                      style: const TextStyle(color: AppColors.textTertiary),
                    ),
                  ),
                )
              else
                GlassCard(
                  child: Column(
                    children: [
                      _headerRow(canEdit),
                      const Divider(color: AppColors.glassBorder, height: AppSpacing.lg),
                      for (final p in allProducts) ...[
                        _productRow(context, ref, p, canEdit),
                        if (p != allProducts.last)
                          const Divider(color: AppColors.glassBorder, height: AppSpacing.md),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// One chip per category with its live product count, plus rename/delete.
  Widget _categoryStrip(
    BuildContext context,
    WidgetRef ref,
    List<CategoryRow> categories,
    List<ProductWithCategory> allProducts,
  ) {
    final counts = <int, int>{};
    for (final p in allProducts) {
      counts.update(p.category.id, (v) => v + 1, ifAbsent: () => 1);
    }

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.sm,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          for (final category in categories)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accentPrimary.withOpacity(0.12),
                borderRadius: AppRadius.smallR,
                border: Border.all(color: AppColors.glassBorderPurple),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.label_rounded,
                      size: 14, color: AppColors.accentSecondary),
                  const SizedBox(width: 6),
                  Text(category.name, style: AppTypography.body),
                  const SizedBox(width: 6),
                  Text('${counts[category.id] ?? 0}',
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.textTertiary)),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => showCategoryDialog(context, ref,
                        existing: category),
                    child: const Icon(Icons.edit_rounded,
                        size: 14, color: AppColors.textSecondary),
                  ),
                  InkWell(
                    onTap: () =>
                        confirmDeleteCategory(context, ref, category),
                    child: const Icon(Icons.delete_outline_rounded,
                        size: 14, color: AppColors.danger),
                  ),
                ],
              ),
            ),
          if (categories.isEmpty)
            const Text('لا توجد تصنيفات — أضف تصنيف عشان تبدأ',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _kpiRow(double inventoryValue, int lowStock, int totalProducts) {
    return LayoutBuilder(builder: (context, constraints) {
      final columns = constraints.maxWidth > 900 ? 4 : 2;
      return GridView.count(
        crossAxisCount: columns,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: AppSpacing.md,
        crossAxisSpacing: AppSpacing.md,
        childAspectRatio: 1.8,
        children: [
          StatCard(
            icon: Icons.inventory_2_rounded,
            label: 'قيمة المخزون',
            value: 'EGP ${inventoryValue.toStringAsFixed(0)}',
            iconColor: AppColors.accentSecondary,
          ),
          StatCard(
            icon: Icons.warning_amber_rounded,
            label: 'مخزون منخفض',
            value: '$lowStock',
            iconColor: AppColors.warning,
          ),
          StatCard(
            icon: Icons.category_rounded,
            label: 'إجمالي المنتجات',
            value: '$totalProducts',
            iconColor: AppColors.accentPrimary,
          ),
          const StatCard(
            icon: Icons.trending_up_rounded,
            label: 'مبيعات اليوم',
            value: 'EGP 2,750',
            iconColor: AppColors.statusAvailable,
          ),
        ],
      );
    });
  }

  Widget _headerRow(bool canEdit) {
    const style = TextStyle(
        fontSize: 12, color: AppColors.textTertiary, fontWeight: FontWeight.w600);
    return Row(
      children: [
        const Expanded(flex: 3, child: Text('المنتج', style: style)),
        const Expanded(flex: 2, child: Text('الفئة', style: style)),
        const Expanded(flex: 2, child: Text('المخزون', style: style)),
        const Expanded(flex: 2, child: Text('التكلفة', style: style)),
        const Expanded(flex: 2, child: Text('سعر البيع', style: style)),
        const Expanded(flex: 2, child: Text('الربح', style: style)),
        const Expanded(flex: 2, child: Text('الحالة', style: style)),
        if (canEdit)
          const Expanded(
              flex: 1,
              child: Text('إجراءات',
                  style: style, textAlign: TextAlign.center)),
      ],
    );
  }

  Widget _productRow(BuildContext context, WidgetRef ref,
      ProductWithCategory p, bool canEdit) {
    final product = p.product;
    return Row(
      children: [
        Expanded(flex: 3, child: Text(product.name, style: AppTypography.cardTitle)),
        Expanded(
            flex: 2,
            child: Text(p.category.name,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text('${product.stockQuantity}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text('EGP ${product.costPrice.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text('EGP ${product.sellingPrice.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13))),
        Expanded(
            flex: 2,
            child: Text('EGP ${p.profit.toStringAsFixed(0)}',
                style: TextStyle(
                    color: p.profit >= 0 ? AppColors.statusAvailable : AppColors.danger,
                    fontWeight: FontWeight.w600,
                    fontSize: 13))),
        Expanded(flex: 2, child: _stockStatus(p)),
        if (canEdit)
          Expanded(
            flex: 1,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  tooltip: 'تعديل',
                  icon: const Icon(Icons.edit_rounded,
                      size: 18, color: AppColors.textSecondary),
                  onPressed: () => showProductDialog(context, ref,
                      existing: product),
                ),
                IconButton(
                  tooltip: 'حذف',
                  icon: const Icon(Icons.delete_outline_rounded,
                      size: 18, color: AppColors.danger),
                  onPressed: () => confirmDeleteProduct(context, ref, product),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _stockStatus(ProductWithCategory p) {
    if (p.isOutOfStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.danger.withOpacity(0.15),
          borderRadius: AppRadius.smallR,
        ),
        child: const Text('نفذ',
            style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600)),
      );
    }
    if (p.isLowStock) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.15),
          borderRadius: AppRadius.smallR,
        ),
        child: const Text('منخفض',
            style: TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.statusAvailable.withOpacity(0.15),
        borderRadius: AppRadius.smallR,
      ),
      child: const Text('متوفر',
          style: TextStyle(fontSize: 11, color: AppColors.statusAvailable, fontWeight: FontWeight.w600)),
    );
  }
}
