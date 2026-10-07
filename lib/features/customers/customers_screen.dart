import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/product_dao.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../core/utils/time_format.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/product_repository.dart';

/// Customers screen — spec §9. Search box + list, add via a glass
/// dialog. This is the first screen wired end-to-end through the new
/// SQLite → Drift → Repository → Riverpod → UI stack (Phase 1's proof
/// that the architecture works, per the agreed build order).
///
/// Above that, it is where the owner manages الأجل (الدفع على الحساب)
/// and الأسعار الخاصة: tapping a customer opens their card with the
/// collected balance, the receipts journal, and the price overrides.
class CustomersScreen extends ConsumerWidget {
  const CustomersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customersAsync = ref.watch(customersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _searchField(ref)),
            const SizedBox(width: AppSpacing.md),
            PrimaryButton(
              label: 'عميل جديد',
              icon: Icons.person_add_rounded,
              onPressed: () => _showAddCustomerDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: customersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                Center(child: Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
            data: (customers) {
              if (customers.isEmpty) {
                return const Center(
                  child: Text('لا يوجد عملاء حتى الآن',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return SingleChildScrollView(
                child: GlassCard(
                  child: Column(
                    children: [
                      for (final c in customers) ...[
                        _customerRow(context, ref, c),
                        if (c != customers.last)
                          const Divider(color: AppColors.glassBorder, height: AppSpacing.lg),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _searchField(WidgetRef ref) {
    return TextField(
      onChanged: (v) => ref.read(customerSearchQueryProvider.notifier).state = v,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: 'دور بالاسم أو رقم التليفون...',
        hintStyle: const TextStyle(color: AppColors.textTertiary),
        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.glassFill,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mediumR,
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumR,
          borderSide: const BorderSide(color: AppColors.glassBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mediumR,
          borderSide: const BorderSide(color: AppColors.glassBorderPurple),
        ),
      ),
    );
  }

  Widget _customerRow(BuildContext context, WidgetRef ref, CustomerRow c) {
    final hasCredit = c.creditEnabled;
    return InkWell(
      onTap: () => showDialog<void>(
        context: context,
        builder: (_) => _CustomerDetailDialog(customerId: c.id, initial: c),
      ),
      borderRadius: AppRadius.mediumR,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: c.isVip
                  ? AppColors.accentPrimary.withOpacity(0.3)
                  : AppColors.glassFill,
              child: Text(c.name.isNotEmpty ? c.name[0] : '?',
                  style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(c.name, style: AppTypography.cardTitle),
                      if (c.isVip) ...[
                        const SizedBox(width: 6),
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.warning),
                      ],
                      if (hasCredit) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.book_rounded, size: 13, color: AppColors.accentPrimary),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(c.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ],
              ),
            ),
            _statChip('${c.totalVisits}', 'زيارة'),
            const SizedBox(width: AppSpacing.sm),
            _statChip('EGP ${c.totalSpent.toStringAsFixed(0)}', 'إجمالي'),
            const SizedBox(width: AppSpacing.sm),
            _statChip('${c.loyaltyPoints}', 'نقطة'),
            if (hasCredit) ...[
              const SizedBox(width: AppSpacing.sm),
              _creditChip(c),
            ],
            const SizedBox(width: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.glassFill,
                borderRadius: AppRadius.smallR,
              ),
              child: Text(c.customerLevel,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () async {
                await ref.read(customerRepositoryProvider).deactivate(c.id);
              },
              child: const Icon(Icons.person_remove_rounded, size: 18, color: AppColors.textTertiary),
            ),
          ],
        ),
      ),
    );
  }

  /// المتبقي على العميل من الأجل — أحمر ما دام فيه فلوس، أخضر لما يكون
  /// سدّد كل حاجة.
  Widget _creditChip(CustomerRow c) {
    final owing = c.creditBalance > 0.01;
    final color = owing ? AppColors.danger : AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: AppRadius.smallR,
      ),
      child: Text(
        owing ? 'عليه ${c.creditBalance.toStringAsFixed(0)} ج' : 'أجل كامل',
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _statChip(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
      ],
    );
  }

  void _showAddCustomerDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final emailController = TextEditingController();
    final limitController = TextEditingController();
    bool creditEnabled = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            width: 400,
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
                const Text('عميل جديد', style: AppTypography.sectionTitle),
                const SizedBox(height: AppSpacing.lg),
                _dialogField(nameController, 'الاسم *'),
                const SizedBox(height: AppSpacing.sm),
                _dialogField(phoneController, 'رقم التليفون *', keyboardType: TextInputType.phone),
                const SizedBox(height: AppSpacing.sm),
                _dialogField(emailController, 'الإيميل (اختياري)', keyboardType: TextInputType.emailAddress),
                const SizedBox(height: AppSpacing.sm),
                _creditToggle(
                  title: 'الدفع بالآجل (على الحساب)',
                  enabled: creditEnabled,
                  onChanged: (v) => setState(() => creditEnabled = v),
                ),
                if (creditEnabled) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _dialogField(limitController, 'سقف الأجل بالجنيه (صفر = بدون حد)',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                ],
                if (errorText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(errorText!, style: const TextStyle(color: AppColors.danger, fontSize: 12)),
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
                      child: PrimaryButton(
                        label: 'إضافة',
                        onPressed: () async {
                          final name = nameController.text.trim();
                          final phone = phoneController.text.trim();
                          if (name.isEmpty || phone.isEmpty) {
                            setState(() => errorText = 'الاسم ورقم التليفون مطلوبين');
                            return;
                          }
                          final limit = double.tryParse(limitController.text.trim().replaceAll(',', '')) ?? 0;
                          try {
                            await ref.read(customerRepositoryProvider).addCustomer(
                                  name: name,
                                  phone: phone,
                                  email: emailController.text.trim().isEmpty
                                      ? null
                                      : emailController.text.trim(),
                                  creditEnabled: creditEnabled,
                                  creditLimit: creditEnabled ? (limit < 0 ? 0 : limit) : 0,
                                );
                            if (context.mounted) Navigator.of(context).pop();
                          } catch (e) {
                            setState(() => errorText = 'رقم التليفون ده مسجّل بالفعل');
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController controller, String label,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.glassFill,
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

  Widget _creditToggle({
    required String title,
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: enabled ? AppColors.accentPrimary.withOpacity(0.10) : AppColors.glassFill,
        borderRadius: AppRadius.smallR,
        border: Border.all(
            color: enabled ? AppColors.glassBorderPurple : AppColors.glassBorder),
      ),
      child: Row(
        children: [
          const Icon(Icons.account_balance_wallet_rounded, size: 16,
              color: AppColors.accentPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(title,
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ),
          Switch(
            value: enabled,
            onChanged: onChanged,
            activeColor: AppColors.accentPrimary,
            activeTrackColor: AppColors.accentPrimary.withOpacity(0.4),
          ),
        ],
      ),
    );
  }
}

/// بطاقة العميل — كل حاجة عن العميل في مكان واحد: بياناته، المتبقي على
/// حسابه (الأجل) مع التحصيل والسداد، والأسعار الخاصة.
class _CustomerDetailDialog extends ConsumerStatefulWidget {
  const _CustomerDetailDialog({required this.customerId, required this.initial});
  final int customerId;
  final CustomerRow initial;

  @override
  ConsumerState<_CustomerDetailDialog> createState() =>
      _CustomerDetailDialogState();
}

class _CustomerDetailDialogState extends ConsumerState<_CustomerDetailDialog> {
  @override
  Widget build(BuildContext context) {
    // Live copy of the customer (the row refreshes after تحصيل / تعديل) —
    // falls back to the snapshot that opened the card.
    final live = ref.watch(allActiveCustomersProvider).value;
    final customer = live?.where((c) => c.id == widget.customerId).firstOrNull ??
        widget.initial;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
        constraints: const BoxConstraints(maxHeight: 620),
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
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: customer.isVip
                      ? AppColors.accentPrimary.withOpacity(0.3)
                      : AppColors.glassFill,
                  child: Text(customer.name.isNotEmpty ? customer.name[0] : '?',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(customer.name,
                                style: AppTypography.sectionTitle),
                          ),
                          if (customer.isVip) ...[
                            const SizedBox(width: 6),
                            const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
                          ],
                        ],
                      ),
                      Text('${customer.phone} · ${customer.customerLevel}',
                          style: const TextStyle(
                              color: AppColors.textSecondary, fontSize: 12)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 18, color: AppColors.textTertiary),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                _miniStat('${customer.totalVisits}', 'زيارة'),
                const SizedBox(width: AppSpacing.md),
                _miniStat('EGP ${customer.totalSpent.toStringAsFixed(0)}', 'إجمالي'),
                const SizedBox(width: AppSpacing.md),
                _miniStat('${customer.loyaltyPoints}', 'نقطة'),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // ── الأجل ─────────────────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: customer.creditEnabled
                    ? AppColors.accentPrimary.withOpacity(0.06)
                    : AppColors.glassFill,
                borderRadius: AppRadius.mediumR,
                border: Border.all(
                    color: customer.creditEnabled
                        ? AppColors.glassBorderPurple
                        : AppColors.glassBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.account_balance_wallet_rounded,
                          size: 16, color: AppColors.accentPrimary),
                      const SizedBox(width: 6),
                      Text(
                        customer.creditEnabled ? 'الأجل مفعّل' : 'الأجل مقفول',
                        style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary),
                      ),
                      const Spacer(),
                      Text(
                        'السقف: ${customer.creditLimit <= 0 ? "بدون حد" : "${customer.creditLimit.toStringAsFixed(0)} ج"}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      Text(
                        'المتبقي على العميل',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'EGP ${customer.creditBalance.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: customer.creditBalance > 0.01
                                ? AppColors.danger
                                : AppColors.success),
                      ),
                    ],
                  ),
                  if (customer.creditEnabled) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      children: [
                        Expanded(
                          child: SecondaryButton(
                            label: 'تحصيل دفعة',
                            icon: Icons.savings_rounded,
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) =>
                                  _CollectPaymentDialog(customer: customer),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SecondaryButton(
                            label: 'سجل السداد',
                            icon: Icons.receipt_long_rounded,
                            onPressed: () => showDialog<void>(
                              context: context,
                              builder: (_) =>
                                  _PaymentsHistoryDialog(customerId: customer.id),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: SecondaryButton(
                    label: 'الأسعار الخاصة',
                    icon: Icons.price_change_rounded,
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _SpecialPricesDialog(customerId: customer.id),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryButton(
                    label: 'تعديل',
                    icon: Icons.edit_rounded,
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) => _EditCustomerDialog(customer: customer),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value,
            style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w700)),
        Text(label,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 10)),
      ],
    );
  }
}

/// تعديل بيانات العميل + تشغيل/قفل الأجل وتغيير السقف في أي وقت — حتى لو
/// العميل واصل للسقف، المالك يرفعه من هنا.
class _EditCustomerDialog extends ConsumerStatefulWidget {
  const _EditCustomerDialog({required this.customer});
  final CustomerRow customer;

  @override
  ConsumerState<_EditCustomerDialog> createState() => _EditCustomerDialogState();
}

class _EditCustomerDialogState extends ConsumerState<_EditCustomerDialog> {
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _limit;
  late bool _creditEnabled;
  String? _error;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _name = TextEditingController(text: c.name);
    _phone = TextEditingController(text: c.phone);
    _email = TextEditingController(text: c.email ?? '');
    _limit = TextEditingController(
        text: c.creditLimit > 0 ? c.creditLimit.toStringAsFixed(0) : '');
    _creditEnabled = c.creditEnabled;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    _limit.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 400,
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
            const Text('تعديل العميل', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            TextField(
                controller: _name,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _dec('الاسم *')),
            const SizedBox(height: AppSpacing.sm),
            TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _dec('رقم التليفون *')),
            const SizedBox(height: AppSpacing.sm),
            TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _dec('الإيميل (اختياري)')),
            const SizedBox(height: AppSpacing.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _creditEnabled
                    ? AppColors.accentPrimary.withOpacity(0.10)
                    : AppColors.glassFill,
                borderRadius: AppRadius.smallR,
                border: Border.all(
                    color: _creditEnabled
                        ? AppColors.glassBorderPurple
                        : AppColors.glassBorder),
              ),
              child: Row(
                children: [
                  const Icon(Icons.account_balance_wallet_rounded, size: 16,
                      color: AppColors.accentPrimary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('الدفع بالآجل (على الحساب)',
                        style: TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                  ),
                  Switch(
                    value: _creditEnabled,
                    onChanged: (v) => setState(() => _creditEnabled = v),
                    activeColor: AppColors.accentPrimary,
                    activeTrackColor: AppColors.accentPrimary.withOpacity(0.4),
                  ),
                ],
              ),
            ),
            if (_creditEnabled) ...[
              const SizedBox(height: AppSpacing.sm),
              TextField(
                  controller: _limit,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: _dec('سقف الأجل بالجنيه (صفر = بدون حد)')),
            ],
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12)),
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
                  child: PrimaryButton(
                    label: 'حفظ',
                    onPressed: () async {
                      final name = _name.text.trim();
                      final phone = _phone.text.trim();
                      if (name.isEmpty || phone.isEmpty) {
                        setState(() => _error = 'الاسم ورقم التليفون مطلوبين');
                        return;
                      }
                      final limit = double.tryParse(
                              _limit.text.trim().replaceAll(',', '')) ??
                          0;
                      final updated = widget.customer.copyWith(
                        name: name,
                        phone: phone,
                        email: Value(_email.text.trim().isEmpty
                            ? null
                            : _email.text.trim()),
                        creditEnabled: _creditEnabled,
                        creditLimit: _creditEnabled ? (limit < 0 ? 0 : limit) : 0,
                      );
                      try {
                        await ref.read(customerRepositoryProvider)
                            .updateCustomer(updated);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم حفظ التعديل')));
                        }
                      } catch (e) {
                        setState(() => _error = 'رقم التليفون ده مسجّل بالفعل');
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.glassFill,
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

/// تحصيل دفعة من العميل على حسابه — بتنقص من المتبقي فورًا.
class _CollectPaymentDialog extends ConsumerStatefulWidget {
  const _CollectPaymentDialog({required this.customer});
  final CustomerRow customer;

  @override
  ConsumerState<_CollectPaymentDialog> createState() =>
      _CollectPaymentDialogState();
}

class _CollectPaymentDialogState extends ConsumerState<_CollectPaymentDialog> {
  late final TextEditingController _amount;
  String _method = 'cash';
  String? _error;

  @override
  void initState() {
    super.initState();
    _amount = TextEditingController(
        text: widget.customer.creditBalance > 0
            ? widget.customer.creditBalance.toStringAsFixed(0)
            : '');
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
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
            const Text('تحصيل دفعة', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text('المتبقي على ${widget.customer.name}: EGP ${widget.customer.creditBalance.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'المبلغ المحصّل (ج.م)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixText: 'EGP ',
                prefixStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.glassFill,
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
            Row(
              children: [
                _methodChip('كاش', 'cash'),
                const SizedBox(width: 6),
                _methodChip('كارت', 'card'),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12)),
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
                  child: PrimaryButton(
                    label: 'تحصيل',
                    icon: Icons.savings_rounded,
                    onPressed: () async {
                      final amount =
                          double.tryParse(_amount.text.trim().replaceAll(',', ''));
                      if (amount == null || amount <= 0) {
                        setState(() => _error = 'اكتب مبلغ أكبر من صفر');
                        return;
                      }
                      await ref.read(customerRepositoryProvider)
                          .collectCreditPayment(
                            customerId: widget.customer.id,
                            amount: amount,
                            method: _method,
                            employeeId:
                                ref.read(currentEmployeeProvider)?.id,
                          );
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('تم تسجيل التحصيل')));
                      }
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodChip(String label, String value) {
    final active = _method == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _method = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active
                ? AppColors.accentPrimary.withOpacity(0.15)
                : AppColors.glassFill,
            borderRadius: AppRadius.smallR,
            border: Border.all(
                color: active ? AppColors.glassBorderPurple : AppColors.glassBorder),
          ),
          child: Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: active ? AppColors.textPrimary : AppColors.textSecondary,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400)),
        ),
      ),
    );
  }
}

/// سجل السداد — كل دفعة اتاخدت من العميل على حسابه.
class _PaymentsHistoryDialog extends ConsumerWidget {
  const _PaymentsHistoryDialog({required this.customerId});
  final int customerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paymentsAsync = ref.watch(creditPaymentsProvider(customerId));

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        constraints: const BoxConstraints(maxHeight: 520),
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
            const Text('سجل السداد', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: paymentsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e',
                    style: const TextStyle(color: AppColors.danger)),
                data: (payments) {
                  if (payments.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('لسه مفيش سداد',
                          style: TextStyle(color: AppColors.textTertiary)),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: payments.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.glassBorder, height: 1),
                    itemBuilder: (_, i) {
                      final p = payments[i];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Icon(
                                p.method == 'card'
                                    ? Icons.credit_card_rounded
                                    : Icons.payments_rounded,
                                size: 16,
                                color: p.method == 'card'
                                    ? AppColors.accentSecondary
                                    : AppColors.success),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                  '${stampOf(p.createdAt)} · ${p.method == 'card' ? "كارت" : "كاش"}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary)),
                            ),
                            Text('EGP ${p.amount.toStringAsFixed(0)}',
                                style: const TextStyle(
                                    color: AppColors.textPrimary,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 13)),
                          ],
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

/// الأسعار الخاصة: لكل منتج سعر خاص ليه للعميل ده. الضغطة على المنتج
/// بتفتح نافذة تحديد السعر (أو حذفه لو محدد قبل كده).
class _SpecialPricesDialog extends ConsumerStatefulWidget {
  const _SpecialPricesDialog({required this.customerId});
  final int customerId;

  @override
  ConsumerState<_SpecialPricesDialog> createState() =>
      _SpecialPricesDialogState();
}

class _SpecialPricesDialogState extends ConsumerState<_SpecialPricesDialog> {
  String _query = '';
  final TextEditingController _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productsWithCategoryProvider);
    final specialsAsync = ref.watch(specialPricesForCustomerProvider(widget.customerId));

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        constraints: const BoxConstraints(maxHeight: 600),
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
            const Text('الأسعار الخاصة', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            const Text(
                'دوس على أي منتج عشان تحدد له سعر خاص للعميل ده — بيظهر في الكاشير لما العميل يتحدد',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _search,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'دوّر على منتج…',
                hintStyle:
                    const TextStyle(color: AppColors.textTertiary, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded,
                    size: 18, color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.glassFill,
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 10),
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
                  borderSide:
                      const BorderSide(color: AppColors.glassBorderPurple),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Flexible(
              child: productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Text('$e',
                    style: const TextStyle(color: AppColors.danger)),
                data: (products) {
                  final specials = specialsAsync.value ?? const [];
                  final specialMap = {
                    for (final s in specials) s.productId: s.price,
                  };
                  final q = _query.trim().toLowerCase();
                  final filtered = q.isEmpty
                      ? products
                      : products
                          .where((p) =>
                              p.product.name.toLowerCase().contains(q) ||
                              p.category.name.toLowerCase().contains(q))
                          .toList();
                  if (filtered.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(AppSpacing.lg),
                      child: Text('مفيش نتائج',
                          style: TextStyle(color: AppColors.textTertiary)),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const Divider(color: AppColors.glassBorder, height: 1),
                    itemBuilder: (_, i) {
                      final p = filtered[i];
                      final special = specialMap[p.product.id];
                      return InkWell(
                        onTap: () => showDialog<void>(
                          context: context,
                          builder: (_) => _PriceInputDialog(
                            customerId: widget.customerId,
                            product: p,
                            currentSpecialPrice: special,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.local_cafe_rounded,
                                  size: 15, color: AppColors.accentSecondary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(p.product.name,
                                        style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textPrimary)),
                                    Text(
                                        '${p.category.name} · العادي ${p.product.sellingPrice.toStringAsFixed(0)} ج',
                                        style: const TextStyle(
                                            fontSize: 10,
                                            color: AppColors.textTertiary)),
                                  ],
                                ),
                              ),
                              if (special != null)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.accentPrimary
                                        .withOpacity(0.15),
                                    borderRadius: AppRadius.smallR,
                                  ),
                                  child: Text(
                                      '${special.toStringAsFixed(0)} ج',
                                      style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.accentPrimary)),
                                )
                              else
                                const Icon(Icons.add_circle_outline_rounded,
                                    size: 16, color: AppColors.textTertiary),
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

class _PriceInputDialog extends ConsumerStatefulWidget {
  const _PriceInputDialog({
    required this.customerId,
    required this.product,
    required this.currentSpecialPrice,
  });
  final int customerId;
  final ProductWithCategory product;
  final double? currentSpecialPrice;

  @override
  ConsumerState<_PriceInputDialog> createState() => _PriceInputDialogState();
}

class _PriceInputDialogState extends ConsumerState<_PriceInputDialog> {
  late final TextEditingController _price;
  String? _error;

  @override
  void initState() {
    super.initState();
    final current = widget.currentSpecialPrice;
    _price = TextEditingController(
        text: current == null ? '' : current.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _price.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 340,
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
            Text('سعر خاص — ${widget.product.product.name}',
                style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.sm),
            Text('السعر العادي: EGP ${widget.product.product.sellingPrice.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _price,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18),
              decoration: InputDecoration(
                labelText: 'السعر الخاص (ج.م)',
                labelStyle: const TextStyle(color: AppColors.textSecondary),
                prefixText: 'EGP ',
                prefixStyle: const TextStyle(color: AppColors.textSecondary),
                filled: true,
                fillColor: AppColors.glassFill,
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
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(_error!,
                  style: const TextStyle(color: AppColors.danger, fontSize: 12)),
            ],
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                if (widget.currentSpecialPrice != null) ...[
                  Expanded(
                    child: SecondaryButton(
                      label: 'حذف',
                      icon: Icons.delete_outline_rounded,
                      onPressed: () async {
                        await ref.read(customerRepositoryProvider)
                            .deleteSpecialPrice(
                              customerId: widget.customerId,
                              productId: widget.product.product.id,
                            );
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: SecondaryButton(
                    label: 'إلغاء',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: PrimaryButton(
                    label: 'حفظ',
                    onPressed: () async {
                      final price = double.tryParse(
                          _price.text.trim().replaceAll(',', ''));
                      if (price == null || price < 0) {
                        setState(() => _error = 'اكتب سعر صح');
                        return;
                      }
                      await ref.read(customerRepositoryProvider)
                          .setSpecialPrice(
                            customerId: widget.customerId,
                            productId: widget.product.product.id,
                            price: price,
                          );
                      if (context.mounted) Navigator.of(context).pop();
                    },
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