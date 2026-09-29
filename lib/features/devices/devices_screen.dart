import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/app_database.dart';
import '../../core/database/daos/device_dao.dart';
import '../../core/database/daos/session_dao.dart';
import '../../core/permissions/permission_service.dart';
import '../../core/ir/ir_box_repository.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/session_repository.dart';
import '../../core/auth/current_employee_provider.dart';
import 'ir_box_link_dialog.dart';

/// Devices — the equipment roster. Shows each device with its type,
/// live status, and effective single/multi hourly rates, and lets an
/// authorized user add devices or park one in maintenance. Detailed
/// rate editing lives on Settings → Devices.
class DevicesScreen extends ConsumerWidget {
  const DevicesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(devicesWithTypeProvider);
    final canManage = ref.watch(permissionServiceProvider).canChangePrice;
    // Live sessions so a device row can start a session right here and
    // keep ticking its countdown/cost (same data as the Dashboard).
    ref.watch(oneSecondTickerProvider);
    final sessionsAsync = ref.watch(activeSessionsProvider);
    final sessionByDevice = {
      for (final s in sessionsAsync.value ?? const <SessionBoardEntry>[])
        s.device.id: s
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الأجهزة', style: AppTypography.sectionTitle),
                  SizedBox(height: 2),
                  Text('حالة كل جهاز والأسعار الفعلية',
                      style: AppTypography.secondary),
                ],
              ),
            ),
            if (canManage)
              SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'جهاز جديد',
                  icon: Icons.add_rounded,
                  expand: true,
                  onPressed: () => showAddDeviceDialog(context, ref),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Expanded(
          child: devicesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
                child: Text('خطأ: $e',
                    style: const TextStyle(color: AppColors.danger))),
            data: (devices) {
              if (devices.isEmpty) {
                return const Center(
                  child: Text('لا توجد أجهزة مسجلة',
                      style: TextStyle(color: AppColors.textTertiary)),
                );
              }
              return ListView.separated(
                itemCount: devices.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _DeviceRow(
                  entry: devices[i],
                  canManage: canManage,
                  session: sessionByDevice[devices[i].device.id],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _DeviceRow extends ConsumerWidget {
  const _DeviceRow({
    required this.entry,
    required this.canManage,
    this.session,
  });
  final DeviceWithType entry;
  final bool canManage;
  final SessionBoardEntry? session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(deviceRepositoryProvider);
    final device = entry.device;
    final status = device.status;
    final busy = status == 'active' || status == 'paused';
    final multiRate =
        device.customHourlyRateMulti ?? entry.type.defaultHourlyRateMulti;
    final irLink = ref.watch(irBoxLinksProvider)[device.id];
    final s = session;

    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.accentPrimary.withOpacity(0.15),
              borderRadius: AppRadius.mediumR,
            ),
            child: const Icon(Icons.devices_rounded,
                color: AppColors.accentSecondary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.type.name} — ${device.name}',
                    style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                  'فردي EGP ${entry.effectiveHourlyRate.toStringAsFixed(0)}/س · '
                  'مالتي EGP ${multiRate > 0 ? multiRate.toStringAsFixed(0) : entry.effectiveHourlyRate.toStringAsFixed(0)}/س'
                  '${irLink != null ? '  ·  ESP32: $irLink' : ''}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          if (s != null) ...[
            // Live countdown + cost while a session is running — ticks
            // every second via oneSecondTickerProvider.
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _LiveBadge(
                  label: 'الوقت',
                  value: _fmtDuration(s.elapsedActiveMinutes),
                  color: s.session.status == 'paused'
                      ? AppColors.statusPaused
                      : AppColors.statusActive,
                ),
                const SizedBox(height: 4),
                _LiveBadge(
                  label: 'التكلفة',
                  value: 'EGP ${s.liveCost.toStringAsFixed(1)}',
                  color: AppColors.accentSecondary,
                ),
              ],
            ),
            const SizedBox(width: AppSpacing.md),
          ] else if (!busy && status != 'maintenance') ...[
            PrimaryButton(
              label: 'بدء جلسة',
              icon: Icons.play_arrow_rounded,
              onPressed: () => _startSession(context, ref, device.id),
            ),
            const SizedBox(width: AppSpacing.md),
          ],
          _StatusChip(status: status),
          if (canManage) ...[
            const SizedBox(width: AppSpacing.md),
            SecondaryButton(
              label: status == 'maintenance' ? 'إتاحة' : 'صيانة',
              icon: status == 'maintenance'
                  ? Icons.check_circle_rounded
                  : Icons.build_rounded,
              onPressed: busy
                  ? null
                  : () => repo.updateStatus(
                        device.id,
                        status == 'maintenance' ? 'available' : 'maintenance',
                      ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _DeviceMenu(
                deviceId: device.id, deviceName: device.name, busy: busy),
          ],
        ],
      ),
    );
  }

  Future<void> _startSession(
      BuildContext context, WidgetRef ref, int deviceId) async {
    final employee = ref.read(currentEmployeeProvider);
    await ref
        .read(sessionRepositoryProvider)
        .start(deviceId: deviceId, employeeId: employee?.id);
    final links = ref.read(irBoxLinksProvider);
    final box = ref.read(irBoxRepositoryProvider).boxFor(deviceId, links);
    if (box != null) await box.send('power');
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(width: 6),
        Text(value,
            style: TextStyle(
                fontSize: 13, color: color, fontWeight: FontWeight.w600)),
      ],
    );
  }
}

/// Per-device rename/delete menu. Rename is price-config gated (it's a
/// settings screen action), delete (soft) is admin-settings gated and
/// refuses while a session is running on the device.
class _DeviceMenu extends ConsumerWidget {
  const _DeviceMenu({
    required this.deviceId,
    required this.deviceName,
    required this.busy,
  });

  final int deviceId;
  final String deviceName;
  final bool busy;

  Future<void> _rename(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController(text: deviceName);
    final result = await showDialog<String>(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 380,
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
              const Text('تغيير اسم الجهاز', style: AppTypography.sectionTitle),
              const SizedBox(height: AppSpacing.lg),
              TextField(
                controller: nameController,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'اسم الجهاز'),
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
                        Navigator.of(context).pop(nameController.text.trim()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (result == null || result.isEmpty) return;
    await ref.read(deviceRepositoryProvider).renameDevice(deviceId, result);
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    if (busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: const Text('حذف الجهاز'),
        content: const Text(
            'هيتم إخفاء الجهاز من القائمة مع الحفاظ على تاريخه. متابعة؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('حذف', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(deviceRepositoryProvider).deleteDevice(deviceId);
  }

  /// Re-classify a device (PS4 ↔ PS5 …) straight from the roster, so a
  /// mislabelled machine can be fixed without touching the database.
  Future<void> _changeType(BuildContext context, WidgetRef ref) async {
    final repo = ref.read(deviceRepositoryProvider);
    final types = await repo.allTypes();
    if (!context.mounted) return;
    if (types.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('مفيش أنواع أجهزة معرّفة')));
      return;
    }
    final chosen = await showDialog<DeviceTypeRow>(
      context: context,
      builder: (_) => _TypePickerDialog(types: types),
    );
    if (chosen == null) return;
    final ok = await repo.setDeviceType(deviceId, chosen.id, chosen.name);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok
          ? 'تم نقل الجهاز لـ ${chosen.name}'
          : 'مفيش نقل وقت ما يكون فيه جلسة شغالة على الجهاز'),
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final permissions = ref.watch(permissionServiceProvider);
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert_rounded,
          size: 20, color: AppColors.textSecondary),
      color: AppColors.bgElevated,
      onSelected: (v) {
        switch (v) {
          case 'rename':
            _rename(context, ref);
          case 'type':
            _changeType(context, ref);
          case 'delete':
            _remove(context, ref);
          case 'link':
            showIrBoxLinkDialog(context, ref,
                deviceId: deviceId, deviceName: deviceName);
        }
      },
      itemBuilder: (_) => [
        if (permissions.canChangePrice)
          const PopupMenuItem(
            value: 'rename',
            child: ListTile(
              leading:
                  Icon(Icons.edit_rounded, color: AppColors.accentSecondary),
              title: Text('تغيير الاسم'),
              dense: true,
            ),
          ),
        if (permissions.canChangePrice)
          const PopupMenuItem(
            value: 'type',
            child: ListTile(
              leading: Icon(Icons.swap_horiz_rounded,
                  color: AppColors.accentSecondary),
              title: Text('تغيير نوع الجهاز'),
              dense: true,
            ),
          ),
        if (permissions.canEditSettings)
          const PopupMenuItem(
            value: 'link',
            child: ListTile(
              leading:
                  Icon(Icons.link_rounded, color: AppColors.accentSecondary),
              title: Text('ربط بصندوق IR (ESP32)'),
              dense: true,
            ),
          ),
        if (permissions.canEditSettings && !busy)
          const PopupMenuItem(
            value: 'delete',
            child: ListTile(
              leading:
                  Icon(Icons.delete_forever_rounded, color: AppColors.danger),
              title: Text('حذف الجهاز'),
              dense: true,
            ),
          ),
      ],
    );
  }
}

/// Picks the device TYPE to move a machine into (PS4 / PS5 / any other
/// type configured in Settings).
class _TypePickerDialog extends StatelessWidget {
  const _TypePickerDialog({required this.types});
  final List<DeviceTypeRow> types;

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
            const Text('اختر نوع الجهاز', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            for (final t in types)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(t),
                  child: GlassCard(
                    hoverable: true,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        const Icon(Icons.sports_esports_rounded,
                            size: 20, color: AppColors.accentSecondary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                            child: Text(t.name, style: AppTypography.cardTitle)),
                        Text(
                          'فردي ${t.defaultHourlyRate.toStringAsFixed(0)} · '
                          'مالتي ${t.defaultHourlyRateMulti.toStringAsFixed(0)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'available' => ('متاح', AppColors.statusAvailable),
      'active' => ('شغّال', AppColors.statusActive),
      'paused' => ('متوقف', AppColors.statusPaused),
      'maintenance' => ('صيانة', AppColors.statusMaintenance),
      _ => (status, AppColors.textTertiary),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.smallR,
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w600)),
    );
  }
}

String _fmtDuration(double minutes) {
  final totalSeconds = (minutes * 60).round();
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  return '${h.toString().padLeft(2, '0')}:'
      '${m.toString().padLeft(2, '0')}:'
      '${s.toString().padLeft(2, '0')}';
}

Future<void> showAddDeviceDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (_) => const _AddDeviceDialog(),
  );
}

class _AddDeviceDialog extends ConsumerStatefulWidget {
  const _AddDeviceDialog();

  @override
  ConsumerState<_AddDeviceDialog> createState() => _AddDeviceDialogState();
}

class _AddDeviceDialogState extends ConsumerState<_AddDeviceDialog> {
  final _name = TextEditingController();
  int? _typeId;
  String? _error;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty || _typeId == null) {
      setState(() => _error = 'اكتب اسم الجهاز واختر النوع');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(deviceRepositoryProvider).addDevice(
            name: _name.text.trim(),
            deviceTypeId: _typeId!,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم إضافة الجهاز')));
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(deviceTypesProvider);
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
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
            const Text('جهاز جديد', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'اسم الجهاز'),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('النوع', style: AppTypography.body),
            const SizedBox(height: 6),
            typesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) =>
                  Text('$e', style: const TextStyle(color: AppColors.danger)),
              data: (types) => Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.glassFill,
                  borderRadius: AppRadius.smallR,
                  border: Border.all(color: AppColors.glassBorder),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: _typeId,
                    isExpanded: true,
                    hint: const Text('اختر النوع',
                        style: TextStyle(
                            color: AppColors.textTertiary, fontSize: 13)),
                    dropdownColor: AppColors.bgElevated,
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                    items: types
                        .map((t) =>
                            DropdownMenuItem(value: t.id, child: Text(t.name)))
                        .toList(),
                    onChanged: (v) => setState(() => _typeId = v),
                  ),
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: AppSpacing.md),
              Text(_error!,
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
                    label: _saving ? 'جارٍ الإضافة...' : 'إضافة',
                    icon: Icons.check_rounded,
                    expand: true,
                    onPressed: _saving ? null : _save,
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
