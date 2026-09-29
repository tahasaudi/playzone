import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../data/repositories/customer_repository.dart';

/// Customers screen — spec §9. Search box + list, add via a glass
/// dialog. This is the first screen wired end-to-end through the new
/// SQLite → Drift → Repository → Riverpod → UI stack (Phase 1's proof
/// that the architecture works, per the agreed build order).
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
    return Row(
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
                          try {
                            await ref.read(customerRepositoryProvider).addCustomer(
                                  name: name,
                                  phone: phone,
                                  email: emailController.text.trim().isEmpty
                                      ? null
                                      : emailController.text.trim(),
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
}
