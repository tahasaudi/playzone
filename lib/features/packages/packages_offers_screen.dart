import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/permissions/permission_service.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/package_dao.dart';
import '../../data/repositories/package_repository.dart';
import '../../data/repositories/offer_repository.dart';
import '../../data/repositories/device_repository.dart';

/// Packages & Offers — spec (packages & offers phase). Packages are
/// fixed-price bundles ("3 ساعات PS5 بـ 75ج"); offers are happy-hour
/// percentage/fixed discounts. Both are pricing config, so the add/edit
/// controls only appear for roles that can change prices, and the
/// repository enforces the same rule server-side.
class PackagesOffersScreen extends ConsumerStatefulWidget {
  const PackagesOffersScreen({super.key});

  @override
  ConsumerState<PackagesOffersScreen> createState() =>
      _PackagesOffersScreenState();
}

class _PackagesOffersScreenState extends ConsumerState<PackagesOffersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = ref.watch(permissionServiceProvider).canChangePrice;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('الباقات والعروض', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('باقات بسعر ثابت وعروض ساعة — تظهر في شاشة الكاشير',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.md),
        Container(
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: AppRadius.mediumR,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: TabBar(
            controller: _tabController,
            indicator: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.25),
              borderRadius: AppRadius.mediumR,
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textTertiary,
            tabs: const [
              Tab(text: 'الباقات'),
              Tab(text: 'العروض'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _PackagesTab(canEdit: canEdit),
              _OffersTab(canEdit: canEdit),
            ],
          ),
        ),
      ],
    );
  }
}

class _PackagesTab extends ConsumerWidget {
  const _PackagesTab({required this.canEdit});
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final packagesAsync = ref.watch(allPackagesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (canEdit)
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: 'باقة جديدة',
              icon: Icons.add_rounded,
              onPressed: () => _showPackageDialog(context, ref),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: packagesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (packages) {
              if (packages.isEmpty) {
                return const Center(
                  child: Text('لا توجد باقات بعد',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return ListView.separated(
                itemCount: packages.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) =>
                    _PackageCard(entry: packages[i], canEdit: canEdit),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _PackageCard extends ConsumerWidget {
  const _PackageCard({required this.entry, required this.canEdit});
  final PackageWithType entry;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = entry.package;
    final repo = ref.read(packageRepositoryProvider);

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.15),
              borderRadius: AppRadius.mediumR,
            ),
            child: const Icon(Icons.card_giftcard_rounded,
                color: AppColors.accentSecondary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.name, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text('${entry.type.name} · ${p.durationMinutes} دقيقة',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text('EGP ${p.fixedPrice.toStringAsFixed(0)}',
              style: AppTypography.cardTitle),
          const SizedBox(width: AppSpacing.md),
          _ActiveBadge(active: p.active),
          if (canEdit) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'تعديل',
              icon: const Icon(Icons.edit_rounded,
                  size: 18, color: AppColors.textSecondary),
              onPressed: () =>
                  _showPackageDialog(context, ref, existing: entry),
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.danger),
              onPressed: () => repo.deletePackage(p.id),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showPackageDialog(BuildContext context, WidgetRef ref,
    {PackageWithType? existing}) {
  return showDialog(
    context: context,
    builder: (_) => _PackageDialog(existing: existing),
  );
}

class _PackageDialog extends ConsumerStatefulWidget {
  const _PackageDialog({this.existing});
  final PackageWithType? existing;

  @override
  ConsumerState<_PackageDialog> createState() => _PackageDialogState();
}

class _PackageDialogState extends ConsumerState<_PackageDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.package.name ?? '');
  late final TextEditingController _price = TextEditingController(
      text: widget.existing?.package.fixedPrice.toStringAsFixed(0) ?? '');
  late final TextEditingController _duration = TextEditingController(
      text: widget.existing?.package.durationMinutes.toString() ?? '60');
  int? _typeId;
  bool _active = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _typeId = widget.existing?.package.deviceTypeId;
    _active = widget.existing?.package.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _duration.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final price = double.tryParse(_price.text.trim());
    final duration = int.tryParse(_duration.text.trim());
    if (_name.text.trim().isEmpty ||
        _typeId == null ||
        price == null ||
        duration == null) {
      setState(() => _error = 'اكمل كل الحقول بقيم صحيحة');
      return;
    }
    final repo = ref.read(packageRepositoryProvider);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await repo.addPackage(
          name: _name.text.trim(),
          deviceTypeId: _typeId!,
          fixedPrice: price,
          durationMinutes: duration,
        );
      } else {
        await repo.updatePackage(existing.package.copyWith(
          name: _name.text.trim(),
          deviceTypeId: _typeId,
          fixedPrice: price,
          durationMinutes: duration,
          active: _active,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(deviceTypesProvider);
    return _DialogShell(
      title: widget.existing == null ? 'باقة جديدة' : 'تعديل الباقة',
      error: _error,
      onSave: _save,
      children: [
        _textField(_name, 'اسم الباقة'),
        const SizedBox(height: AppSpacing.md),
        typesAsync.when(
          loading: () => const LinearProgressIndicator(),
          error: (e, _) =>
              Text('$e', style: const TextStyle(color: AppColors.danger)),
          data: (types) => _dropdown<int>(
            value: _typeId,
            hint: 'نوع الجهاز',
            items: types
                .map((t) => DropdownMenuItem(value: t.id, child: Text(t.name)))
                .toList(),
            onChanged: (v) => setState(() => _typeId = v),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: _textField(_price, 'السعر (EGP)')),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: _textField(_duration, 'المدة (دقيقة)')),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _activeSwitch(_active, (v) => setState(() => _active = v)),
      ],
    );
  }
}

class _OffersTab extends ConsumerWidget {
  const _OffersTab({required this.canEdit});
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offersAsync = ref.watch(allOffersProvider);
    final activeNow = ref.watch(currentActiveOfferProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (activeNow != null)
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('العرض النشط دلوقتي: ${activeNow.name}',
                      style: AppTypography.cardTitle),
                ),
              ],
            ),
          ),
        if (canEdit)
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: PrimaryButton(
                label: 'عرض جديد',
                icon: Icons.add_rounded,
                onPressed: () => _showOfferDialog(context, ref),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: offersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (offers) {
              if (offers.isEmpty) {
                return const Center(
                  child: Text('لا توجد عروض بعد',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return ListView.separated(
                itemCount: offers.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) =>
                    _OfferCard(offer: offers[i], canEdit: canEdit),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _OfferCard extends ConsumerWidget {
  const _OfferCard({required this.offer, required this.canEdit});
  final OfferRow offer;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(offerRepositoryProvider);
    final value = offer.discountType == 'percentage'
        ? '${offer.discountValue.toStringAsFixed(0)}%'
        : 'EGP ${offer.discountValue.toStringAsFixed(0)}';

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.warning.withOpacity(0.15),
              borderRadius: AppRadius.mediumR,
            ),
            child: const Icon(Icons.percent_rounded,
                color: AppColors.warning, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(offer.name, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text('من ${_hour(offer.startHour)} إلى ${_hour(offer.endHour)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary)),
              ],
            ),
          ),
          Text(value, style: AppTypography.cardTitle),
          const SizedBox(width: AppSpacing.md),
          _ActiveBadge(active: offer.active),
          if (canEdit) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              tooltip: 'تعديل',
              icon: const Icon(Icons.edit_rounded,
                  size: 18, color: AppColors.textSecondary),
              onPressed: () => _showOfferDialog(context, ref, existing: offer),
            ),
            IconButton(
              tooltip: 'حذف',
              icon: const Icon(Icons.delete_outline_rounded,
                  size: 18, color: AppColors.danger),
              onPressed: () => repo.deleteOffer(offer.id),
            ),
          ],
        ],
      ),
    );
  }
}

Future<void> _showOfferDialog(BuildContext context, WidgetRef ref,
    {OfferRow? existing}) {
  return showDialog(
    context: context,
    builder: (_) => _OfferDialog(existing: existing),
  );
}

class _OfferDialog extends ConsumerStatefulWidget {
  const _OfferDialog({this.existing});
  final OfferRow? existing;

  @override
  ConsumerState<_OfferDialog> createState() => _OfferDialogState();
}

class _OfferDialogState extends ConsumerState<_OfferDialog> {
  late final TextEditingController _name =
      TextEditingController(text: widget.existing?.name ?? '');
  late final TextEditingController _value = TextEditingController(
      text: widget.existing?.discountValue.toStringAsFixed(0) ?? '');
  late String _type = widget.existing?.discountType ?? 'percentage';
  late int _startHour = widget.existing?.startHour ?? 14;
  late int _endHour = widget.existing?.endHour ?? 18;
  late bool _active = widget.existing?.active ?? true;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final value = double.tryParse(_value.text.trim());
    if (_name.text.trim().isEmpty || value == null) {
      setState(() => _error = 'اكتب اسم العرض وقيمة الخصم');
      return;
    }
    final repo = ref.read(offerRepositoryProvider);
    try {
      final existing = widget.existing;
      if (existing == null) {
        await repo.addOffer(
          name: _name.text.trim(),
          discountType: _type,
          discountValue: value,
          startHour: _startHour,
          endHour: _endHour,
        );
      } else {
        await repo.updateOffer(existing.copyWith(
          name: _name.text.trim(),
          discountType: _type,
          discountValue: value,
          startHour: _startHour,
          endHour: _endHour,
          active: _active,
        ));
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return _DialogShell(
      title: widget.existing == null ? 'عرض جديد' : 'تعديل العرض',
      error: _error,
      onSave: _save,
      children: [
        _textField(_name, 'اسم العرض'),
        const SizedBox(height: AppSpacing.md),
        _dropdown<String>(
          value: _type,
          hint: 'نوع الخصم',
          items: const [
            DropdownMenuItem(value: 'percentage', child: Text('نسبة %')),
            DropdownMenuItem(value: 'fixed', child: Text('مبلغ ثابت')),
          ],
          onChanged: (v) => setState(() => _type = v ?? 'percentage'),
        ),
        const SizedBox(height: AppSpacing.md),
        _textField(_value, _type == 'percentage' ? 'الخصم %' : 'الخصم EGP'),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
                child: _hourDropdown(
                    'من', _startHour, (v) => setState(() => _startHour = v))),
            const SizedBox(width: AppSpacing.md),
            Expanded(
                child: _hourDropdown(
                    'إلى', _endHour, (v) => setState(() => _endHour = v))),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _activeSwitch(_active, (v) => setState(() => _active = v)),
      ],
    );
  }
}

Widget _hourDropdown(String label, int value, ValueChanged<int> onChanged) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: AppTypography.secondary),
      const SizedBox(height: 4),
      _dropdown<int>(
        value: value,
        hint: label,
        items: [
          for (var h = 0; h < 24; h++)
            DropdownMenuItem(value: h, child: Text(_hour(h))),
        ],
        onChanged: (v) => onChanged(v ?? 0),
      ),
    ],
  );
}

class _DialogShell extends StatelessWidget {
  const _DialogShell({
    required this.title,
    required this.children,
    required this.onSave,
    this.error,
  });
  final String title;
  final List<Widget> children;
  final VoidCallback onSave;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 440,
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
            Text(title, style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            ...children,
            if (error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(error!,
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
                    label: 'حفظ',
                    icon: Icons.check_rounded,
                    expand: true,
                    onPressed: onSave,
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

class _ActiveBadge extends StatelessWidget {
  const _ActiveBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.success : AppColors.textTertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.smallR,
      ),
      child: Text(active ? 'نشط' : 'موقوف',
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

Widget _activeSwitch(bool value, ValueChanged<bool> onChanged) {
  return Row(
    children: [
      Switch(
        value: value,
        activeThumbColor: AppColors.accentPrimary,
        onChanged: onChanged,
      ),
      const SizedBox(width: AppSpacing.sm),
      Text(value ? 'نشط' : 'موقوف', style: AppTypography.body),
    ],
  );
}

Widget _textField(TextEditingController controller, String hint) {
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
            style:
                const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
        dropdownColor: AppColors.bgElevated,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

String _hour(int hour) => hourOf(hour);
