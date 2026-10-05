import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../data/repositories/loyalty_repository.dart';
import 'device_card.dart';

/// What the checkout modal hands back to the caller: the manual discount,
/// how many loyalty points were spent, and the cash/card tender split.
/// The caller passes these straight into SessionRepository.checkout.
class CheckoutResult {
  const CheckoutResult({
    this.discount = 0,
    this.redeemedPoints = 0,
    this.paidCash = 0,
    this.paidCard = 0,
  });
  final double discount;
  final int redeemedPoints;
  final double paidCash;
  final double paidCard;
}

/// Shows the checkout modal for completing a session.
///
/// [timeCost] and [ordersTotal] are the two halves of the bill, and the bill is
/// what this screen is about: the card said time plus orders, and a checkout
/// that quoted less than the card was asking the cashier to remember which of
/// the two numbers was the real one. [ordersTotal] has already been paid for at
/// the counter when it was ordered, so it is shown as part of the bill and not
/// charged again here — see the "already settled" line.
Future<void> showCheckoutModal(
  BuildContext context,
  DeviceUiModel device, {
  double timeCost = 0,
  double ordersTotal = 0,
  int? customerId,
  int customerPoints = 0,
  double discountRate = 0,
  Future<void> Function(CheckoutResult result)? onConfirm,
}) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'checkout',
    barrierColor: Colors.black54,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, anim1, anim2) => const SizedBox(),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return ScaleTransition(
        scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
        child: FadeTransition(
          opacity: anim,
          child: _CheckoutModalContent(
            device: device,
            timeCost: timeCost,
            ordersTotal: ordersTotal,
            customerId: customerId,
            customerPoints: customerPoints,
            discountRate: discountRate,
            onConfirm: onConfirm,
          ),
        ),
      );
    },
  );
}

class _CheckoutModalContent extends ConsumerStatefulWidget {
  const _CheckoutModalContent({
    required this.device,
    required this.timeCost,
    required this.ordersTotal,
    required this.customerId,
    required this.customerPoints,
    required this.discountRate,
    this.onConfirm,
  });

  final DeviceUiModel device;
  final double timeCost;
  final double ordersTotal;
  final int? customerId;
  final int customerPoints;
  final double discountRate;
  final Future<void> Function(CheckoutResult result)? onConfirm;

  @override
  ConsumerState<_CheckoutModalContent> createState() =>
      _CheckoutModalContentState();
}

enum _PayMethod { cash, card, mixed }

class _CheckoutModalContentState extends ConsumerState<_CheckoutModalContent> {
  final _discount = TextEditingController();
  final _cash = TextEditingController();
  final _card = TextEditingController();
  _PayMethod _payMethod = _PayMethod.cash;
  bool _redeem = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    // A configured happy-hour offer pre-fills the discount as its EGP
    // value (the field is EGP; offers are stored as a percentage).
    if (widget.discountRate > 0) {
      final offerEgp = widget.timeCost * widget.discountRate / 100;
      _discount.text = offerEgp.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _discount.dispose();
    _cash.dispose();
    _card.dispose();
    super.dispose();
  }

  double get _manualDiscount => double.tryParse(_discount.text.trim()) ?? 0;

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(loyaltySettingsProvider).value;
    final pointValue =
        settings?.pointValueEGP ?? LoyaltyRepository.defaultPointValueEGP;
    final minimum = settings?.minimumRedeemPoints ??
        LoyaltyRepository.defaultMinimumRedeemPoints;

    // One bill: the gaming time plus what the machine ordered, paid once, here.
    // The same two numbers the card adds up, so no two screens can quote
    // different bills for the same sitting.
    final bill = widget.timeCost + widget.ordersTotal;
    final afterDiscount =
        (bill - _manualDiscount).clamp(0, double.infinity).toDouble();

    // Redemption: only with a customer, enough points, and something left
    // to cover. Points spent are capped by both the balance and the bill.
    final canRedeem = widget.customerId != null &&
        widget.customerPoints >= minimum &&
        afterDiscount > 0 &&
        pointValue > 0;
    final maxRedeemablePoints = pointValue > 0
        ? (afterDiscount / pointValue).floor().clamp(0, widget.customerPoints)
        : 0;
    final redeemedPoints = _redeem ? maxRedeemablePoints : 0;
    final redeemValue = redeemedPoints * pointValue;
    final total =
        (afterDiscount - redeemValue).clamp(0, double.infinity).toDouble();

    final paidCash = switch (_payMethod) {
      _PayMethod.cash => total,
      _PayMethod.card => 0.0,
      _PayMethod.mixed => double.tryParse(_cash.text.trim()) ?? 0,
    };
    final paidCard = switch (_payMethod) {
      _PayMethod.cash => 0.0,
      _PayMethod.card => total,
      _PayMethod.mixed => double.tryParse(_card.text.trim()) ?? 0,
    };

    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: AppRadius.largeR,
            border: Border.all(color: AppColors.glassBorderPurple),
            boxShadow: AppShadows.glow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('إقفال الجلسة', style: AppTypography.sectionTitle),
              const SizedBox(height: 2),
              Text('${widget.device.type.labelAr} — ${widget.device.name}',
                  style: AppTypography.secondary),
              const SizedBox(height: AppSpacing.lg),
              _row('مدة اللعب', widget.device.elapsed ?? '00:00:00'),
              _row('اللعب', 'EGP ${widget.timeCost.toStringAsFixed(2)}'),
              _row('الكافيه', 'EGP ${widget.ordersTotal.toStringAsFixed(2)}'),
              _discountRow(),
              if (redeemedPoints > 0)
                _row('نقاط الولاء', '− EGP ${redeemValue.toStringAsFixed(2)}'),
              const Divider(
                  color: AppColors.glassBorder, height: AppSpacing.xl),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('الإجمالي',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text('EGP ${total.toStringAsFixed(2)}',
                      style: AppTypography.numberLarge),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              if (widget.customerId != null)
                _loyaltyRow(canRedeem, widget.customerPoints, minimum),
              const SizedBox(height: AppSpacing.md),
              const Text('طريقة الدفع', style: AppTypography.body),
              const SizedBox(height: AppSpacing.sm),
              _paymentSelector(),
              if (_payMethod == _PayMethod.mixed) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(child: _amountField(_cash, 'كاش')),
                    const SizedBox(width: 8),
                    Expanded(child: _amountField(_card, 'كارت')),
                  ],
                ),
                if (paidCash + paidCard + 0.001 < total)
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Text('المبلغ المدفوع أقل من الإجمالي',
                        style:
                            TextStyle(color: AppColors.danger, fontSize: 12)),
                  ),
              ],
              if (_error != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(_error!,
                    style:
                        const TextStyle(color: AppColors.danger, fontSize: 13)),
              ],
              const SizedBox(height: AppSpacing.lg),
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
                      label: 'إتمام التحصيل',
                      icon: Icons.check_circle_rounded,
                      expand: true,
                      onPressed: () => _confirm(
                          total,
                          _manualDiscount + redeemValue,
                          redeemedPoints,
                          paidCash,
                          paidCard),
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

  Future<void> _confirm(double total, double discount, int redeemedPoints,
      double paidCash, double paidCard) async {
    if (paidCash + paidCard + 0.001 < total) {
      setState(() => _error = 'المبلغ المدفوع أقل من الإجمالي المطلوب');
      return;
    }
    try {
      if (widget.onConfirm != null) {
        await widget.onConfirm!(CheckoutResult(
          discount: discount,
          redeemedPoints: redeemedPoints,
          paidCash: paidCash,
          paidCard: paidCard,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  Widget _discountRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('الخصم (EGP)',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
          SizedBox(
            width: 120,
            child: TextField(
              controller: _discount,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.end,
              onChanged: (_) => setState(() {}),
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: _fieldDecoration('0'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loyaltyRow(bool canRedeem, int points, int minimum) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.smallR,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.stars_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text('رصيد الولاء: $points نقطة',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
          if (canRedeem)
            Switch(
              value: _redeem,
              activeThumbColor: AppColors.accentPrimary,
              onChanged: (v) => setState(() => _redeem = v),
            )
          else
            Text('أقل من $minimum',
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _paymentSelector() {
    Widget option(_PayMethod method, String label, IconData icon) {
      final selected = _payMethod == method;
      return Expanded(
        child: GestureDetector(
          onTap: () => setState(() => _payMethod = method),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.accentPrimary.withOpacity(0.2)
                  : AppColors.glassFill,
              borderRadius: AppRadius.smallR,
              border: Border.all(
                  color: selected
                      ? AppColors.glassBorderPurple
                      : AppColors.glassBorder),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon,
                    size: 16,
                    color: selected
                        ? AppColors.accentSecondary
                        : AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(label,
                    style: TextStyle(
                        fontSize: 13,
                        color: selected
                            ? AppColors.textPrimary
                            : AppColors.textSecondary)),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        option(_PayMethod.cash, 'كاش', Icons.payments_rounded),
        const SizedBox(width: 8),
        option(_PayMethod.card, 'كارت', Icons.credit_card_rounded),
        const SizedBox(width: 8),
        option(_PayMethod.mixed, 'مختلط', Icons.call_split_rounded),
      ],
    );
  }

  Widget _amountField(TextEditingController controller, String hint) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      onChanged: (_) => setState(() {}),
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: _fieldDecoration(hint),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
      isDense: true,
      filled: true,
      fillColor: AppColors.glassFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
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
    );
  }

  Widget _row(String label, String value, {Color? tone, bool strong = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: tone ?? AppColors.textSecondary, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  color: tone ?? AppColors.textPrimary,
                  fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
                  fontSize: strong ? 15 : 14)),
        ],
      ),
    );
  }
}
