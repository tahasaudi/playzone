import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/daos/product_dao.dart';
import '../../data/repositories/product_repository.dart';

/// Products — a read-only café catalog grouped by category (prices and
/// live stock). Price editing lives on the Settings → Café tab.
class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsWithCategoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('المنتجات', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('كتالوج الكافيه بالأسعار والمخزون',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: productsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (products) {
              if (products.isEmpty) {
                return const Center(
                  child: Text('لا توجد منتجات بعد',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              final byCategory = <String, List<ProductWithCategory>>{};
              for (final p in products) {
                byCategory.putIfAbsent(p.category.name, () => []).add(p);
              }
              return ListView(
                children: [
                  for (final entry in byCategory.entries) ...[
                    Text(entry.key, style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.sm),
                    GlassCard(
                      child: Column(
                        children: [
                          for (final p in entry.value) ...[
                            _ProductRow(entry: p),
                            if (p != entry.value.last)
                              const Divider(
                                  color: AppColors.glassBorder,
                                  height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.entry});
  final ProductWithCategory entry;

  @override
  Widget build(BuildContext context) {
    final p = entry.product;
    final out = entry.isOutOfStock;
    return Row(
      children: [
        const Icon(Icons.local_cafe_rounded,
            size: 18, color: AppColors.accentSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(p.name, style: AppTypography.cardTitle),
        ),
        Text('متوفر: ${p.stockQuantity}',
            style: TextStyle(
                fontSize: 12,
                color: out ? AppColors.danger : AppColors.textTertiary)),
        const SizedBox(width: AppSpacing.md),
        Text('EGP ${p.sellingPrice.toStringAsFixed(0)}',
            style: AppTypography.cardTitle),
      ],
    );
  }
}