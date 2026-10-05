import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/database/daos/invoice_dao.dart';
import '../../core/database/daos/product_dao.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/product_repository.dart';

class _OrderLine {
  _OrderLine({required this.product, required this.quantity});
  final ProductWithCategory product;
  int quantity;
  double get total => product.product.sellingPrice * quantity;
}

/// Café-order dialog for a LIVE session: pick products, the charged
/// invoice is linked to the session (sessionId) so the session panel's
/// "الطلبات" row and the checkout total both pick it up. Payments can be
/// cash or card.
Future<void> showSessionOrderModal(
  BuildContext context, {
  required int sessionId,
  int? customerId,
  int? employeeId,
  String deviceTitle = '',
}) {
  return showDialog(
    context: context,
    builder: (_) => SessionOrderModalContent(
      sessionId: sessionId,
      customerId: customerId,
      employeeId: employeeId,
      deviceTitle: deviceTitle,
    ),
  );
}

class SessionOrderModalContent extends ConsumerStatefulWidget {
  const SessionOrderModalContent({
    super.key,
    required this.sessionId,
    this.customerId,
    this.employeeId,
    this.deviceTitle = '',
  });

  final int sessionId;
  final int? customerId;
  final int? employeeId;
  final String deviceTitle;

  @override
  ConsumerState<SessionOrderModalContent> createState() =>
      _SessionOrderModalContentState();
}

class _SessionOrderModalContentState
    extends ConsumerState<SessionOrderModalContent> {
  final Map<int, _OrderLine> _lines = {};
  bool _card = false;
  String? _error;
  bool _saving = false;

  double get _total => _lines.values.fold<double>(0, (sum, l) => sum + l.total);

  void _add(ProductWithCategory product) {
    final existing = _lines[product.product.id];
    if (existing != null) {
      existing.quantity++;
    } else {
      _lines[product.product.id] = _OrderLine(product: product, quantity: 1);
    }
    setState(() {});
  }

  Future<void> _confirm() async {
    if (_lines.isEmpty) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      // Written with no payment against it. The order is rung up now and
      // settled once, with the rest of the bill, at checkout — a customer who
      // ordered three waters is not charged for them twice because the
      // cashier took the money at the counter and then again at the table.
      await ref.read(invoiceRepositoryProvider).createInvoice(
            sessionId: widget.sessionId,
            customerId: widget.customerId,
            employeeId: widget.employeeId,
            lines: [
              for (final line in _lines.values)
                InvoiceLineInput(
                  productId: line.product.product.id,
                  description: line.product.product.name,
                  quantity: line.quantity,
                  unitPrice: line.product.product.sellingPrice,
                ),
            ],
            settled: false,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تمت إضافة الطلب للجلسة')));
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsWithCategoryProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 720,
        height: 560,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
          boxShadow: AppShadows.glow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('طلب من الكافيه للجلسة',
                style: AppTypography.sectionTitle),
            if (widget.deviceTitle.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(widget.deviceTitle, style: AppTypography.secondary),
            ],
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                    child: Text('خطأ: $e',
                        style: const TextStyle(color: AppColors.danger))),
                data: (products) {
                  final available = products
                      .where((p) =>
                          p.product.active && p.product.stockQuantity > 0)
                      .toList();
                  if (available.isEmpty) {
                    return const Center(
                      child: Text('لا توجد منتجات متاحة للطلب',
                          style: TextStyle(color: AppColors.textTertiary)),
                    );
                  }
                  return LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth > 600 ? 4 : 3;
                    return GridView.count(
                      crossAxisCount: columns,
                      mainAxisSpacing: AppSpacing.sm,
                      crossAxisSpacing: AppSpacing.sm,
                      childAspectRatio: 2.1,
                      children: available.map((p) {
                        final qty = _lines[p.product.id]?.quantity ?? 0;
                        return GestureDetector(
                          onTap: () => _add(p),
                          child: GlassCard(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(p.product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.cardTitle),
                                const SizedBox(height: 2),
                                Text(
                                    'EGP ${p.product.sellingPrice.toStringAsFixed(0)}'
                                    '${qty > 0 ? ' × $qty' : ''}',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: qty > 0
                                            ? AppColors.accentSecondary
                                            : AppColors.textSecondary)),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  });
                },
              ),
            ),
            if (_lines.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                height: 120,
                child: ListView(
                  children: [
                    for (final line in _lines.values)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            Expanded(
                                child: Text(line.product.product.name,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textPrimary))),
                            Text(
                                '${line.quantity} × EGP '
                                '${line.product.product.sellingPrice.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const Divider(color: AppColors.glassBorder),
              Row(
                children: [
                  const Text('الإجمالي',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary)),
                  const Spacer(),
                  Text('EGP ${_total.toStringAsFixed(2)}',
                      style: AppTypography.numberLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  SecondaryButton(
                    label: _card ? 'تحويل لكاش' : 'تحويل لكارت',
                    icon: _card
                        ? Icons.payments_rounded
                        : Icons.credit_card_rounded,
                    onPressed: () => setState(() => _card = !_card),
                  ),
                  const Spacer(),
                  SecondaryButton(
                    label: 'إلغاء',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    label: _saving ? '...' : 'تحصيل الطلب',
                    icon: Icons.check_circle_rounded,
                    onPressed: _saving ? null : _confirm,
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
