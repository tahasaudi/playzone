import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/repositories/offer_repository.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/account_repository.dart';

/// "إدارة الأسماء" — rename anything with a name in the app from one
/// place: products, categories, devices, device types, packages, offers,
/// employees and accounting categories. Each row calls the entity's own
/// repository, so the same permission + audit rules still apply.
class NamesManagerScreen extends ConsumerWidget {
  const NamesManagerScreen({super.key});

  Future<void> _promptRename(
    BuildContext context,
    WidgetRef ref,
    String label,
    String current,
    Future<void> Function(String) onRename,
  ) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: AppRadius.largeR,
            border: Border.all(color: AppColors.glassBorderPurple),
            boxShadow: AppShadows.cardHover,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: controller,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'الاسم الجديد'),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    label: 'إلغاء',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    label: 'حفظ',
                    icon: Icons.check_rounded,
                    onPressed: () =>
                        Navigator.of(context).pop(controller.text.trim()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || result.isEmpty || result == current) return;
    try {
      await onRename(result);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحفظ')));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  /// Confirms with the cashier, calls [onDelete], and surfaces the result —
  /// including the friendly Arabic guards ("مينفعش تحذف...") straight from
  /// the repository. Deleting a name is destructive, so it always asks.
  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required Future<void> Function() onDelete,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 360,
          padding: const EdgeInsets.all(AppSpacing.xl),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: AppRadius.largeR,
            border: Border.all(color: AppColors.glassBorderPurple),
            boxShadow: AppShadows.cardHover,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('حذف $label', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.lg),
              Text('هيتم حذف "$label". متابعة؟', style: AppTypography.body),
              const SizedBox(height: AppSpacing.lg),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SecondaryButton(
                    label: 'إلغاء',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 8),
                  PrimaryButton(
                    label: 'حذف',
                    icon: Icons.delete_rounded,
                    onPressed: () => Navigator.of(context).pop(true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (ok != true) return;
    try {
      await onDelete();
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم الحذف')));
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
    final permissions = ref.watch(permissionServiceProvider);

    final productsAsync = ref.watch(productsWithCategoryProvider);
    final categoriesAsync = ref.watch(allCategoriesProvider);
    final devicesAsync = ref.watch(devicesWithTypeProvider);
    final typesAsync = ref.watch(deviceTypesProvider);
    final packagesAsync = ref.watch(allPackagesProvider);
    final offersAsync = ref.watch(allOffersProvider);
    final employeesAsync = ref.watch(activeEmployeesProvider);
    final accountsAsync = ref.watch(accountsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('إدارة الأسماء', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('غيّر أي اسم في البرنامج من مكان واحد',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: ListView(
            children: [
              if (permissions.canChangePrice)
                _Section(
                  title: 'المنتجات',
                  icon: Icons.inventory_2_rounded,
                  child: _RowList(
                    async: productsAsync,
                    nameOf: (p) => p.product.name,
                    onRename: (p, name) => ref
                        .read(productRepositoryProvider)
                        .renameProduct(p.product.id, name),
                    prompt: (p) => 'تغيير اسم المنتج "${p.product.name}"',
                  ),
                ),
              if (permissions.canChangePrice)
                _Section(
                  title: 'التصنيفات',
                  icon: Icons.category_rounded,
                  child: categoriesAsync.when(
                    loading: () => _empty('...'),
                    error: (e, _) => _empty('$e'),
                    data: (cats) {
                      if (cats.isEmpty) return _empty('لا توجد تصنيفات');
                      return Column(
                        children: [
                          for (final c in cats)
                            _renameRow(
                              context,
                              ref,
                              label: 'تغيير اسم التصنيف "${c.name}"',
                              current: c.name,
                              onRename: (name) async {
                                await ref
                                    .read(productRepositoryProvider)
                                    .renameCategory(c.id, name);
                              },
                              onDelete: () => _confirmDelete(
                                context,
                                ref,
                                label: 'تصنيف "${c.name}"',
                                onDelete: () async {
                                  await ref
                                      .read(productRepositoryProvider)
                                      .deleteCategory(c);
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              if (permissions.canEditSettings || permissions.canChangePrice)
                _Section(
                  title: 'الأجهزة',
                  icon: Icons.devices_rounded,
                  child: _RowList(
                    async: devicesAsync,
                    nameOf: (d) => d.device.name,
                    onRename: (d, name) => ref
                        .read(deviceRepositoryProvider)
                        .renameDevice(d.device.id, name),
                    prompt: (d) => 'تغيير اسم الجهاز "${d.device.name}"',
                  ),
                ),
              if (permissions.canChangePrice)
                _Section(
                  title: 'أنواع الأجهزة',
                  icon: Icons.device_unknown_rounded,
                  child: typesAsync.when(
                    loading: () => _empty('...'),
                    error: (e, _) => _empty('$e'),
                    data: (types) {
                      if (types.isEmpty) return _empty('لا توجد أنواع');
                      return Column(
                        children: [
                          for (final t in types)
                            _renameRow(
                              context,
                              ref,
                              label: 'تغيير اسم النوع "${t.name}"',
                              current: t.name,
                              onRename: (name) async {
                                await ref
                                    .read(deviceRepositoryProvider)
                                    .renameType(t.id, name);
                              },
                              onDelete: () => _confirmDelete(
                                context,
                                ref,
                                label: 'نوع الجهاز "${t.name}"',
                                onDelete: () async {
                                  await ref
                                      .read(deviceRepositoryProvider)
                                      .deleteType(t);
                                  ref.invalidate(deviceTypesProvider);
                                },
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              if (permissions.canChangePrice)
                _Section(
                  title: 'الباقات',
                  icon: Icons.card_giftcard_rounded,
                  child: _RowList(
                    async: packagesAsync,
                    nameOf: (p) => p.package.name,
                    onRename: (p, name) => ref
                        .read(packageRepositoryProvider)
                        .renamePackage(p.package.id, name),
                    prompt: (p) => 'تغيير اسم الباقة "${p.package.name}"',
                  ),
                ),
              if (permissions.canChangePrice)
                _Section(
                  title: 'العروض',
                  icon: Icons.local_offer_rounded,
                  child: _RowList(
                    async: offersAsync,
                    nameOf: (o) => o.name,
                    onRename: (o, name) => ref
                        .read(offerRepositoryProvider)
                        .renameOffer(o.id, name),
                    prompt: (o) => 'تغيير اسم العرض "${o.name}"',
                  ),
                ),
              if (permissions.canManageUsers)
                _Section(
                  title: 'الموظفين',
                  icon: Icons.badge_rounded,
                  child: _RowList(
                    async: employeesAsync,
                    nameOf: (e) => e.name,
                    onRename: (e, name) =>
                        ref.read(employeeRepositoryProvider).rename(e.id, name),
                    prompt: (e) => 'تغيير اسم الموظف "${e.name}"',
                  ),
                ),
              if (permissions.canEditSettings)
                _Section(
                  title: 'بنود الحسابات',
                  icon: Icons.account_balance_wallet_rounded,
                  child: _RowList(
                    async: accountsAsync,
                    nameOf: (a) => a.name,
                    onRename: (a, name) =>
                        ref.read(accountRepositoryProvider).rename(a.id, name),
                    prompt: (a) => 'تغيير اسم البند "${a.name}"',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _empty(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary))),
      );

  Widget _renameRow(
    BuildContext context,
    WidgetRef ref, {
    required String label,
    required String current,
    required Future<void> Function(String) onRename,
    Future<void> Function()? onDelete,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(current, style: AppTypography.body),
        ),
        IconButton(
          icon: const Icon(Icons.edit_rounded,
              size: 18, color: AppColors.accentSecondary),
          onPressed: () =>
              _promptRename(context, ref, label, current, onRename),
        ),
        if (onDelete != null)
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.danger),
            tooltip: 'حذف',
            onPressed: () => onDelete(),
          ),
      ],
    );
  }
}

/// Generic rename list over a Riverpod async stream of named rows.
class _RowList<T> extends StatelessWidget {
  const _RowList({
    required this.async,
    required this.nameOf,
    required this.onRename,
    required this.prompt,
  });

  final AsyncValue<List<T>> async;
  final String Function(T) nameOf;
  final Future<void> Function(T, String) onRename;
  final String Function(T) prompt;

  @override
  Widget build(BuildContext context) {
    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Center(
            child: Text('$e',
                style: const TextStyle(color: AppColors.danger, fontSize: 12))),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(
                child: Text('لا توجد عناصر',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textTertiary))),
          );
        }
        return Column(
          children: [
            for (final row in rows)
              Row(
                children: [
                  Expanded(child: Text(nameOf(row), style: AppTypography.body)),
                  IconButton(
                    icon: const Icon(Icons.edit_rounded,
                        size: 18, color: AppColors.accentSecondary),
                    onPressed: () async {
                      final controller =
                          TextEditingController(text: nameOf(row));
                      final result = await showDialog<String>(
                        context: context,
                        builder: (_) => Dialog(
                          backgroundColor: Colors.transparent,
                          child: Container(
                            width: 360,
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppColors.bgElevated,
                              borderRadius: AppRadius.largeR,
                              border: Border.all(
                                  color: AppColors.glassBorderPurple),
                              boxShadow: AppShadows.cardHover,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(prompt(row),
                                    style: AppTypography.sectionTitle),
                                const SizedBox(height: AppSpacing.lg),
                                TextField(
                                  controller: controller,
                                  autofocus: true,
                                  decoration: const InputDecoration(
                                      labelText: 'الاسم الجديد'),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SecondaryButton(
                                      label: 'إلغاء',
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                    const SizedBox(width: 8),
                                    PrimaryButton(
                                      label: 'حفظ',
                                      icon: Icons.check_rounded,
                                      onPressed: () => Navigator.of(context)
                                          .pop(controller.text.trim()),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                      if (result == null ||
                          result.isEmpty ||
                          result == nameOf(row)) {
                        return;
                      }
                      try {
                        await onRename(row, result);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم الحفظ')));
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(SnackBar(content: Text('$e')));
                        }
                      }
                    },
                  ),
                ],
              ),
          ],
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(
      {required this.title, required this.icon, required this.child});

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.accentSecondary),
            const SizedBox(width: AppSpacing.sm),
            Text(title, style: AppTypography.cardTitle),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        GlassCard(child: child),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }
}
