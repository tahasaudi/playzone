import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/device_dao.dart';
import '../../core/database/daos/product_dao.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/product_repository.dart';
import '../../data/repositories/loyalty_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../core/permissions/permission_service.dart';
import '../tv/tv_settings_card.dart';

/// Admin-facing pricing settings — now backed by the real SQLite database
/// via DeviceRepository/ProductRepository (Phase 1). Three sections:
/// 1. Default hourly rate per device TYPE
/// 2. Per-device overrides
/// 3. Café product prices
///
/// Every write here goes through a repository that also enforces
/// canChangePrice at the business-logic layer (spec §22) — this screen
/// only hides the controls; the repository is what actually protects it.
class PricingSettingsScreen extends ConsumerStatefulWidget {
  const PricingSettingsScreen({super.key, this.onNavigate});

  /// Lets the settings page jump straight to the two screens the staff
  /// use all day (dashboard / POS) without going back to the drawer.
  final void Function(String route)? onNavigate;

  @override
  ConsumerState<PricingSettingsScreen> createState() =>
      _PricingSettingsScreenState();
}

class _PricingSettingsScreenState extends ConsumerState<PricingSettingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('إدارة الأسعار', style: AppTypography.sectionTitle),
        const SizedBox(height: 2),
        const Text('الأسعار بتتحسب بالدقيقة تلقائيًا في كل الفواتير',
            style: AppTypography.secondary),
        const SizedBox(height: AppSpacing.sm),
        if (widget.onNavigate != null) ...[
          Row(
            children: [
              const Text('اختصارات:',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(width: AppSpacing.sm),
              _ShortcutChip(
                icon: Icons.dashboard_rounded,
                label: 'الشاشة الرئيسية',
                onTap: () => widget.onNavigate!('dashboard'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ShortcutChip(
                icon: Icons.point_of_sale_rounded,
                label: 'الكاشير',
                onTap: () => widget.onNavigate!('pos'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ShortcutChip(
                icon: Icons.receipt_long_rounded,
                label: 'الجلسات',
                onTap: () => widget.onNavigate!('sessions'),
              ),
              const SizedBox(width: AppSpacing.sm),
              _ShortcutChip(
                icon: Icons.inventory_2_rounded,
                label: 'المخزون',
                onTap: () => widget.onNavigate!('inventory'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
        const SizedBox(height: AppSpacing.xs),
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
            unselectedLabelColor: AppColors.textSecondary,
            dividerColor: Colors.transparent,
            tabs: const [
              Tab(text: 'أنواع الأجهزة'),
              Tab(text: 'أجهزة منفردة'),
              Tab(text: 'منتجات الكافيه'),
              Tab(text: 'الولاء'),
              Tab(text: 'الأزرار المحمية'),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: const [
              _TypeRatesTab(),
              _DeviceOverridesTab(),
              _ProductPricesTab(),
              _LoyaltyTab(),
              _LockedPinTab(),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            const Icon(Icons.tv_rounded,
                size: 16, color: AppColors.accentSecondary),
            const SizedBox(width: AppSpacing.sm),
            const Text('شاشة التلفزيون',
                style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary)),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: TvSettingsCard()),
          ],
        ),
      ],
    );
  }
}

/// One clickable shortcut in the settings header.
class _ShortcutChip extends StatelessWidget {
  const _ShortcutChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          borderRadius: AppRadius.smallR,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: AppColors.accentSecondary),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _TypeRatesTab extends ConsumerWidget {
  const _TypeRatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesWithTypeProvider);

    return devicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
      data: (devices) {
        // Distinct types from the loaded devices (types themselves are
        // fetched separately since a type might have zero devices yet).
        return FutureBuilder<List<DeviceTypeRow>>(
          future: ref.read(deviceRepositoryProvider).allTypes(),
          builder: (context, snapshot) {
            final types = snapshot.data ?? [];
            if (types.isEmpty) return const SizedBox.shrink();
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                    child: Column(
                      children: [
                        for (final type in types) ...[
                          _TypeRateRow(type: type),
                          if (type != types.last)
                            const Divider(color: AppColors.glassBorder, height: AppSpacing.lg),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _TypeRateRow extends ConsumerStatefulWidget {
  const _TypeRateRow({required this.type});
  final DeviceTypeRow type;

  @override
  ConsumerState<_TypeRateRow> createState() => _TypeRateRowState();
}

class _TypeRateRowState extends ConsumerState<_TypeRateRow> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.type.defaultHourlyRate.toStringAsFixed(0));
  late final TextEditingController _multiController =
      TextEditingController(text: widget.type.defaultHourlyRateMulti.toStringAsFixed(0));

  Future<void> _save() async {
    final value = double.tryParse(_controller.text.trim());
    final multi = double.tryParse(_multiController.text.trim());
    if (value == null || value < 0 || multi == null || multi < 0) return;
    try {
      await ref
          .read(deviceRepositoryProvider)
          .setTypeDefaultRate(widget.type.id, value);
      await ref
          .read(deviceRepositoryProvider)
          .setTypeDefaultRateMulti(widget.type.id, multi);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تم تحديث سعر ${widget.type.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.sports_esports_rounded, size: 20, color: AppColors.accentSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text(widget.type.name, style: AppTypography.cardTitle)),
        const Text('فردي', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(width: 4),
        _priceField(_controller),
        const SizedBox(width: AppSpacing.sm),
        const Text('مالتي', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(width: 4),
        _priceField(_multiController),
        const SizedBox(width: 6),
        _saveIcon(_save),
      ],
    );
  }
}

class _DeviceOverridesTab extends ConsumerWidget {
  const _DeviceOverridesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesWithTypeProvider);

    return devicesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
      data: (devices) {
        if (devices.isEmpty) {
          return const Center(
              child: Text('لا توجد أجهزة مضافة بعد', style: TextStyle(color: AppColors.textTertiary)));
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('سيب الخانة فاضية عشان الجهاز ياخد السعر الافتراضي لنوعه',
                  style: AppTypography.secondary),
              const SizedBox(height: AppSpacing.md),
              GlassCard(
                child: Column(
                  children: [
                    for (final d in devices) ...[
                      _DeviceOverrideRow(device: d),
                      if (d != devices.last)
                        const Divider(color: AppColors.glassBorder, height: AppSpacing.lg),
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
}

class _DeviceOverrideRow extends ConsumerStatefulWidget {
  const _DeviceOverrideRow({required this.device});
  final DeviceWithType device;

  @override
  ConsumerState<_DeviceOverrideRow> createState() => _DeviceOverrideRowState();
}

class _DeviceOverrideRowState extends ConsumerState<_DeviceOverrideRow> {
  late final TextEditingController _controller = TextEditingController(
      text: widget.device.device.customHourlyRate?.toStringAsFixed(0) ?? '');
  late final TextEditingController _multiController = TextEditingController(
      text: widget.device.device.customHourlyRateMulti?.toStringAsFixed(0) ??
          '');

  Future<void> _save() async {
    final text = _controller.text.trim();
    final multi = _multiController.text.trim();
    final value = text.isEmpty ? null : double.tryParse(text);
    final multiValue = multi.isEmpty ? null : double.tryParse(multi);
    try {
      await ref
          .read(deviceRepositoryProvider)
          .setDeviceRate(widget.device.device.id, value);
      await ref
          .read(deviceRepositoryProvider)
          .setDeviceRateMulti(widget.device.device.id, multiValue);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('تم تحديث سعر ${widget.device.type.name} #${widget.device.device.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.device;
    final defaultMulti = d.type.defaultHourlyRateMulti <= 0
        ? d.type.defaultHourlyRate
        : d.type.defaultHourlyRateMulti;
    return Row(
      children: [
        const Icon(Icons.sports_esports_rounded, size: 18, color: AppColors.accentSecondary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(child: Text('${d.type.name} — #${d.device.name}', style: AppTypography.cardTitle)),
        Text('فردي EGP ${d.type.defaultHourlyRate.toStringAsFixed(0)} · مالتي EGP ${defaultMulti.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(width: AppSpacing.sm),
        _priceField(_controller, hint: 'فردي'),
        const SizedBox(width: 6),
        _priceField(_multiController, hint: 'مالتي'),
        const SizedBox(width: 6),
        _saveIcon(_save),
      ],
    );
  }
}

class _ProductPricesTab extends ConsumerWidget {
  const _ProductPricesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsWithCategoryProvider);

    return productsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('خطأ: $e', style: const TextStyle(color: AppColors.danger))),
      data: (products) {
        final byCategory = <String, List<ProductWithCategory>>{};
        for (final p in products) {
          byCategory.putIfAbsent(p.category.name, () => []).add(p);
        }
        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: byCategory.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.key, style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.sm),
                    GlassCard(
                      child: Column(
                        children: [
                          for (final p in entry.value) ...[
                            _ProductRow(product: p),
                            if (p != entry.value.last)
                              const Divider(color: AppColors.glassBorder, height: AppSpacing.lg),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

class _ProductRow extends ConsumerStatefulWidget {
  const _ProductRow({required this.product});
  final ProductWithCategory product;

  @override
  ConsumerState<_ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends ConsumerState<_ProductRow> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.product.product.sellingPrice.toStringAsFixed(0));

  Future<void> _save() async {
    final value = double.tryParse(_controller.text.trim());
    if (value == null || value < 0) return;
    try {
      await ref.read(productRepositoryProvider).setSellingPrice(widget.product.product.id, value);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('تم تحديث سعر ${widget.product.product.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product.product;
    return Row(
      children: [
        Expanded(child: Text(product.name, style: AppTypography.cardTitle)),
        Text('متوفر: ${product.stockQuantity}',
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(width: AppSpacing.sm),
        _priceField(_controller),
        const SizedBox(width: 6),
        _saveIcon(_save),
      ],
    );
  }
}

Widget _saveIcon(VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.accentPrimary.withOpacity(0.2),
        borderRadius: AppRadius.smallR,
      ),
      child: const Icon(Icons.check_rounded, size: 16, color: AppColors.accentSecondary),
    ),
  );
}

Widget _priceField(TextEditingController controller, {String? hint}) {
  return SizedBox(
    width: 120,
    child: TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(
        prefixText: 'EGP ',
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textTertiary, fontSize: 12),
        prefixStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
        filled: true,
        fillColor: AppColors.glassFill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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

/// Loyalty program configuration — spec (loyalty phase). The three knobs
/// that drive earning + redemption; saving goes through the repository,
/// which enforces canChangePrice and writes an audit entry.
class _LoyaltyTab extends ConsumerStatefulWidget {
  const _LoyaltyTab();

  @override
  ConsumerState<_LoyaltyTab> createState() => _LoyaltyTabState();
}

class _LoyaltyTabState extends ConsumerState<_LoyaltyTab> {
  final _points = TextEditingController();
  final _minimum = TextEditingController();
  final _value = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Seed the fields once from the live settings row.
    Future.microtask(() async {
      final settings = await ref.read(loyaltyRepositoryProvider).getSettings();
      if (!mounted) return;
      _points.text =
          (settings?.pointsPerCurrency ?? LoyaltyRepository.defaultPointsPerCurrency)
              .toStringAsFixed(0);
      _minimum.text =
          (settings?.minimumRedeemPoints ?? LoyaltyRepository.defaultMinimumRedeemPoints)
              .toString();
      _value.text =
          (settings?.pointValueEGP ?? LoyaltyRepository.defaultPointValueEGP)
              .toStringAsFixed(0);
      setState(() => _loaded = true);
    });
  }

  @override
  void dispose() {
    _points.dispose();
    _minimum.dispose();
    _value.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final points = double.tryParse(_points.text.trim());
    final minimum = int.tryParse(_minimum.text.trim());
    final value = double.tryParse(_value.text.trim());
    if (points == null || minimum == null || value == null) return;
    try {
      await ref.read(loyaltyRepositoryProvider).updateSettings(
            pointsPerCurrency: points,
            minimumRedeemPoints: minimum,
            pointValueEGP: value,
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حفظ إعدادات الولاء')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassCard(
            child: Column(
              children: [
                _row(
                  'نقاط لكل جنيه',
                  'عدد نقاط الولاء اللي العميل يكسبها عن كل جنيه',
                  _points,
                  prefix: 'نقطة',
                ),
                const Divider(color: AppColors.glassBorder, height: AppSpacing.lg),
                _row(
                  'أقل عدد نقاط للاستبدال',
                  'الحد الأدنى قبل ما العميل يقدر يصرف النقاط',
                  _minimum,
                  prefix: 'نقطة',
                ),
                const Divider(color: AppColors.glassBorder, height: AppSpacing.lg),
                _row(
                  'قيمة النقطة',
                  'قيمة النقطة الواحدة عند الاستبدال',
                  _value,
                  prefix: 'EGP',
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Align(
            alignment: Alignment.centerLeft,
            child: PrimaryButton(
              label: 'حفظ إعدادات الولاء',
              icon: Icons.save_rounded,
              onPressed: _save,
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String title, String subtitle, TextEditingController controller,
      {required String prefix}) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.cardTitle),
              const SizedBox(height: 2),
              Text(subtitle, style: AppTypography.secondary),
            ],
          ),
        ),
        SizedBox(
          width: 140,
          child: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            decoration: InputDecoration(
              prefixText: '$prefix ',
              prefixStyle:
                  const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              filled: true,
              fillColor: AppColors.glassFill,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
        ),
      ],
    );
  }
}

/// Settings → الأزرار المحمية: manages the custom PIN that protects the
/// dashboard metric buttons. Defaults to 0000 from the DB seed; only an
/// admin (canEditSettings) may change it, and changes are audit-logged.
class _LockedPinTab extends ConsumerStatefulWidget {
  const _LockedPinTab();

  @override
  ConsumerState<_LockedPinTab> createState() => _LockedPinTabState();
}

class _LockedPinTabState extends ConsumerState<_LockedPinTab> {
  final _newPin = TextEditingController();
  final _confirmPin = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _newPin.dispose();
    _confirmPin.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final pin = _newPin.text.trim();
    if (pin.length < 4) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('الرقم السري 4 أرقام على الأقل')));
      return;
    }
    if (pin != _confirmPin.text.trim()) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('الرقمين غير متطابقين')));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(settingsRepositoryProvider).changeLockedPin(pin);
      _newPin.clear();
      _confirmPin.clear();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم تغيير الرقم السري')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('غير مسموح لك بتغيير الرقم السري')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final permissions = ref.watch(permissionServiceProvider);
    final editable = permissions.canEditSettings;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.lock_rounded, color: AppColors.accentSecondary),
                    SizedBox(width: AppSpacing.sm),
                    Text('الأزرار المحمية على الرئيسية', style: AppTypography.cardTitle),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'الأرقام الحساسة في الرئيسية (أداء اليوم، الإيراد، المصروفات، الربح، '
                  'الألعاب، الجلسات) مخفية خلف رقم سري مخصص. الموظف لازم يكون له '
                  'الصلاحية (من شاشة الصلاحيات) ويدخل الرقم السري ده عشان يشوف الرقم.',
                  style: AppTypography.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تغيير الرقم السري', style: AppTypography.cardTitle),
                const SizedBox(height: AppSpacing.sm),
                const Text('الرقم السري الافتراضي: 0000',
                    style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: _newPin,
                  enabled: editable,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'الرقم السري الجديد',
                    filled: true,
                    fillColor: AppColors.glassFill,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: _confirmPin,
                  enabled: editable,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 10,
                  decoration: const InputDecoration(
                    labelText: 'تأكيد الرقم السري',
                    filled: true,
                    fillColor: AppColors.glassFill,
                  ),
                  onSubmitted: (_) => editable ? _save() : null,
                ),
                const SizedBox(height: AppSpacing.lg),
                PrimaryButton(
                  label: _saving ? '...' : 'حفظ الرقم السري',
                  icon: Icons.save_rounded,
                  onPressed: editable && !_saving ? _save : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
