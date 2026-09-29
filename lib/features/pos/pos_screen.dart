import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/daos/product_dao.dart';
import '../../core/database/daos/invoice_dao.dart';
import '../../core/database/app_database.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/customer_repository.dart';

/// Cart line references a product by its DB id and looks up its live
/// price from productsWithCategoryProvider — so if the price changes in
/// Settings mid-shift, the cart reflects it immediately.
class CartLine {
  CartLine(this.productId, this.qty);
  final int productId;
  int qty;
}

// Icons aren't part of the product data — just a cosmetic lookup by name.
const Map<String, IconData> _productIcons = {
  'مياه': Icons.water_drop_rounded,
  'بيبسي': Icons.local_drink_rounded,
  'عصير': Icons.local_bar_rounded,
  'قهوة تركي': Icons.coffee_rounded,
  'كابتشينو': Icons.coffee_maker_rounded,
  'نسكافيه': Icons.coffee_rounded,
  'شيبسي': Icons.fastfood_rounded,
  'مكسرات': Icons.grain_rounded,
  'ساندوتش': Icons.lunch_dining_rounded,
  'بيتزا سلايس': Icons.local_pizza_rounded,
};

/// POS screen — optimized for cashier speed. Categories → product grid
/// → cart, all visible at once (spec section 18). Products now come live
/// from the SQLite database via productsWithCategoryProvider.
class PosScreen extends ConsumerStatefulWidget {
  const PosScreen({super.key});

  @override
  ConsumerState<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends ConsumerState<PosScreen> {
  String? _activeCategory;
  final List<CartLine> _cart = [];
  CustomerRow? _customer;
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickCustomer() async {
    final chosen = await showDialog<CustomerRow>(
      context: context,
      builder: (_) => const _CustomerPickerDialog(),
    );
    if (chosen != null) setState(() => _customer = chosen);
  }

  void _addToCart(ProductWithCategory p) {
    if (p.isOutOfStock) return;
    setState(() {
      final existing =
          _cart.where((l) => l.productId == p.product.id).firstOrNull;
      if (existing != null) {
        existing.qty++;
      } else {
        _cart.add(CartLine(p.product.id, 1));
      }
    });
  }

  void _changeQty(CartLine line, int delta) {
    setState(() {
      line.qty += delta;
      if (line.qty <= 0) _cart.remove(line);
    });
  }

  double _lineTotal(CartLine line, List<ProductWithCategory> all) {
    // The product may have been deleted from the catalogue mid-session
    // (soft delete) — price it at 0 rather than crashing the whole POS.
    final match = all.where((p) => p.product.id == line.productId);
    if (match.isEmpty) return 0;
    return match.first.product.sellingPrice * line.qty;
  }

  Future<void> _checkout(List<ProductWithCategory> allProducts) async {
    // Skip lines whose product was removed while it sat in the cart.
    final lines = <InvoiceLineInput>[];
    for (final line in _cart) {
      final match =
          allProducts.where((p) => p.product.id == line.productId).firstOrNull;
      if (match == null) continue;
      lines.add(InvoiceLineInput(
        description: match.product.name,
        quantity: line.qty,
        unitPrice: match.product.sellingPrice,
        productId: line.productId,
      ));
    }
    if (lines.isEmpty) {
      if (mounted) {
        setState(_cart.clear);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('مفيش منتجات صالحة في السلة')));
      }
      return;
    }

    await ref.read(invoiceRepositoryProvider).createInvoice(
          lines: lines,
          customerId: _customer?.id,
          employeeId: ref.read(currentEmployeeProvider)?.id,
        );

    if (mounted) {
      setState(() {
        _cart.clear();
        _customer = null;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('تم إتمام البيع بنجاح')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsWithCategoryProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) =>
          Center(child: Text('خطأ في تحميل المنتجات: $e', style: const TextStyle(color: AppColors.danger))),
      data: (allProducts) {
        final byCategory = <String, List<ProductWithCategory>>{};
        for (final p in allProducts) {
          byCategory.putIfAbsent(p.category.name, () => []).add(p);
        }
        // Search cuts across every category: the cashier types a name (or
        // part of one) and only matches survive, so nobody has to hunt
        // through tabs with a queue waiting.
        final query = _search.trim();
        if (query.isNotEmpty) {
          final needle = query.toLowerCase();
          for (final list in byCategory.values) {
            list.removeWhere((p) =>
                !p.product.name.toLowerCase().contains(needle) &&
                !p.category.name.toLowerCase().contains(needle));
          }
          byCategory.removeWhere((_, list) => list.isEmpty);
        }
        final categories = byCategory.keys.toList();
        if (categories.isEmpty) {
          return Center(
            child: Text(
              query.isEmpty
                  ? 'لا توجد منتجات بعد'
                  : 'مفيش منتج بالاسم ده',
              style: const TextStyle(color: AppColors.textTertiary),
            ),
          );
        }
        // If the active category lost its last product (deleted from the
        // catalogue) fall back to the first available one.
        if (_activeCategory == null || !byCategory.containsKey(_activeCategory)) {
          _activeCategory = categories.first;
        }
        final products = byCategory[_activeCategory] ?? [];
        final subtotal = _cart.fold<double>(0, (sum, l) => sum + _lineTotal(l, allProducts));

        return Column(
          children: [
            _searchBar(),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Categories
            SizedBox(
              width: 130,
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: SingleChildScrollView(
                  child: Column(
                    children: categories.map((c) {
                      final active = c == _activeCategory;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: GestureDetector(
                          onTap: () => setState(() => _activeCategory = c),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 9),
                            decoration: BoxDecoration(
                              color: active
                                  ? AppColors.accentPrimary.withOpacity(0.18)
                                  : Colors.transparent,
                              borderRadius: AppRadius.smallR,
                              border: active
                                  ? Border.all(color: AppColors.glassBorderPurple)
                                  : null,
                            ),
                            child: Text(c,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: active
                                        ? AppColors.textPrimary
                                        : AppColors.textSecondary,
                                    fontWeight:
                                        active ? FontWeight.w600 : FontWeight.w400)),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Product grid
            Expanded(
              flex: 3,
              child: GridView.count(
                crossAxisCount: 4,
                mainAxisSpacing: AppSpacing.sm,
                crossAxisSpacing: AppSpacing.sm,
                childAspectRatio: 1.15,
                children: products.map((p) => _productCard(p)).toList(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),

            // Cart — deliberately narrow: it only needs a name, a stepper
            // and a price, so the product grid keeps most of the screen.
            SizedBox(
              width: 230,
              child: GlassCard(
                padding: const EdgeInsets.all(AppSpacing.sm),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('الطلب', style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.xs),
                    Expanded(
                      child: _cart.isEmpty
                          ? const Center(
                              child: Text('السلة فاضية',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary)),
                            )
                          : SingleChildScrollView(
                              child: Column(
                                children: _cart
                                    .map((l) => _cartLineWidget(l, allProducts))
                                    .toList(),
                              ),
                            ),
                    ),
                    const Divider(color: AppColors.glassBorder, height: AppSpacing.md),
                    GestureDetector(
                      onTap: _pickCustomer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.glassFill,
                          borderRadius: AppRadius.smallR,
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.person_rounded,
                                size: 14, color: AppColors.accentSecondary),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _customer == null
                                    ? 'ربط بعميل'
                                    : '${_customer!.name} · ${_customer!.loyaltyPoints}',
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _customer == null
                                        ? AppColors.textTertiary
                                        : AppColors.textPrimary),
                              ),
                            ),
                            if (_customer != null)
                              GestureDetector(
                                onTap: () => setState(() => _customer = null),
                                child: const Icon(Icons.close_rounded,
                                    size: 12, color: AppColors.textTertiary),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    _totalRow('الإجمالي', subtotal, emphasize: true),
                    const SizedBox(height: AppSpacing.sm),
                    PrimaryButton(
                      label: 'الدفع',
                      icon: Icons.payment_rounded,
                      expand: true,
                      onPressed:
                          _cart.isEmpty ? null : () => _checkout(allProducts),
                    ),
                  ],
                ),
              ),
            ),
          ],
              ),
            ),
          ],
        );
      },
    );
  }

  /// Compact product search above the grid.
  Widget _searchBar() {
    return SizedBox(
      height: 42,
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _search = v),
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        decoration: InputDecoration(
          hintText: 'دوّر على منتج بالاسم…',
          hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 13),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 18, color: AppColors.textSecondary),
          suffixIcon: _search.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close_rounded, size: 16),
                  color: AppColors.textTertiary,
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _search = '');
                  },
                ),
          isDense: true,
          filled: true,
          fillColor: AppColors.glassFill,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
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
      ),
    );
  }

  Widget _productCard(ProductWithCategory p) {
    final outOfStock = p.isOutOfStock;
    final icon = _productIcons[p.product.name] ?? Icons.local_cafe_rounded;
    return Opacity(
      opacity: outOfStock ? 0.5 : 1,
      child: GlassCard(
        hoverable: !outOfStock,
        onTap: outOfStock ? null : () => _addToCart(p),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: AppColors.accentSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(p.product.name, style: AppTypography.cardTitle),
            const SizedBox(height: 4),
            Text('EGP ${p.product.sellingPrice.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            const SizedBox(height: 2),
            Text(
              outOfStock ? 'غير متاح' : 'متوفر: ${p.product.stockQuantity}',
              style: TextStyle(
                  fontSize: 11,
                  color: outOfStock ? AppColors.danger : AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartLineWidget(CartLine line, List<ProductWithCategory> all) {
    final match = all.where((p) => p.product.id == line.productId).firstOrNull;
    if (match == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          children: [
            const Expanded(
                child: Text('منتج محذوف',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textTertiary))),
            _qtyButton(Icons.close_rounded, () => _changeQty(line, -99)),
          ],
        ),
      );
    }
    // The cashier should always see WHICH category the item came from and
    // what a single unit costs — not just the name and the line total.
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(match.product.name,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 1),
                Text(
                  '${match.category.name} · EGP ${match.product.sellingPrice.toStringAsFixed(2)}',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 10, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          _qtyButton(Icons.remove, () => _changeQty(line, -1)),
          SizedBox(
            width: 20,
            child: Text('${line.qty}',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
          ),
          _qtyButton(Icons.add, () => _changeQty(line, 1)),
          SizedBox(
            width: 54,
            child: Text('EGP ${_lineTotal(line, all).toStringAsFixed(0)}',
                textAlign: TextAlign.end,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(color: AppColors.glassFill, borderRadius: AppRadius.smallR),
        child: Icon(icon, size: 14, color: AppColors.textSecondary),
      ),
    );
  }

  Widget _totalRow(String label, double value, {bool emphasize = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: emphasize ? 15 : 13,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
                color: emphasize ? AppColors.textPrimary : AppColors.textSecondary)),
        Text('EGP ${value.toStringAsFixed(0)}',
            style: TextStyle(
                fontSize: emphasize ? 20 : 14,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

/// Searchable customer picker for attaching a customer (loyalty) to a
/// POS sale. Returns the chosen [CustomerRow] via Navigator.pop.
class _CustomerPickerDialog extends ConsumerStatefulWidget {
  const _CustomerPickerDialog();

  @override
  ConsumerState<_CustomerPickerDialog> createState() =>
      _CustomerPickerDialogState();
}

class _CustomerPickerDialogState
    extends ConsumerState<_CustomerPickerDialog> {
  final TextEditingController _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allActiveCustomersProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 480),
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('اختر عميل', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _query,
              autofocus: true,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'ابحث بالاسم أو الموبايل',
                hintStyle: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.accentSecondary),
                filled: true,
                fillColor: AppColors.glassFill,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: customersAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e',
                    style: const TextStyle(color: AppColors.danger)),
                data: (customers) {
                  final q = _query.text.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? customers
                      : customers
                          .where((c) =>
                              c.name.toLowerCase().contains(q) ||
                              c.phone.toLowerCase().contains(q))
                          .toList();
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('مفيش نتائج',
                          style: TextStyle(color: AppColors.textTertiary)),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final c = filtered[i];
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(c),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          child: Row(
                            children: [
                              const Icon(Icons.person_rounded,
                                  size: 18, color: AppColors.accentSecondary),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(c.name,
                                    style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 13)),
                              ),
                              Text('${c.phone} · ${c.loyaltyPoints} نقطة',
                                  style: const TextStyle(
                                      color: AppColors.textTertiary,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
