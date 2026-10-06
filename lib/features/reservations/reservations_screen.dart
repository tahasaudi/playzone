import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/daos/reservation_dao.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../data/repositories/reservation_repository.dart';
import '../../data/repositories/customer_repository.dart';
import '../../data/repositories/device_repository.dart';

/// Reservations screen — spec §15. The booking board: open reservations
/// with their lifecycle actions (confirm → arrive → start session, plus
/// cancel / no-show), and a recent history list underneath.
class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final openAsync = ref.watch(upcomingReservationsProvider);
    final recentAsync = ref.watch(recentReservationsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('حجوزات الأجهزة', style: AppTypography.sectionTitle),
                    SizedBox(height: 2),
                    Text('أكّد الحجز، استقبل العميل، وابدأ الجلسة',
                        style: AppTypography.secondary),
                  ],
                ),
              ),
              SizedBox(
                width: 180,
                child: PrimaryButton(
                  label: 'حجز جديد',
                  icon: Icons.add_rounded,
                  expand: true,
                  onPressed: () => showNewReservationDialog(context, ref),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('الحجوزات المفتوحة', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          openAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('خطأ: $e',
                style: const TextStyle(color: AppColors.danger)),
            data: (reservations) {
              if (reservations.isEmpty) {
                return const GlassCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: Text('لا توجد حجوزات مفتوحة حاليًا',
                          style: TextStyle(color: AppColors.textTertiary)),
                    ),
                  ),
                );
              }
              return GlassCard(
                child: Column(
                  children: [
                    for (final r in reservations) ...[
                      _ReservationRow(entry: r),
                      if (r != reservations.last)
                        const Divider(
                            color: AppColors.glassBorder,
                            height: AppSpacing.lg),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('آخر الحجوزات', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.sm),
          recentAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (reservations) => GlassCard(
              child: reservations.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                      child: Center(
                        child: Text('مفيش حجوزات مسجلة بعد',
                            style: TextStyle(color: AppColors.textTertiary)),
                      ),
                    )
                  : Column(
                      children: [
                        for (final r in reservations) ...[
                          _HistoryRow(entry: r),
                          if (r != reservations.last)
                            const Divider(
                                color: AppColors.glassBorder,
                                height: AppSpacing.md),
                        ],
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservationRow extends ConsumerWidget {
  const _ReservationRow({required this.entry});
  final ReservationWithDetails entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(reservationRepositoryProvider);
    final r = entry.reservation;
    final status = r.status;

    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColors.accentPrimary.withOpacity(0.15),
            borderRadius: AppRadius.mediumR,
          ),
          child: const Icon(Icons.event_note_rounded,
              color: AppColors.accentSecondary, size: 22),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.customer.name, style: AppTypography.cardTitle),
              const SizedBox(height: 2),
              Text(
                '${entry.device.name} · ${_fmtRange(r.startTime, r.endTime)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReservationStatusChip(status: status),
              const SizedBox(height: 4),
              Text(_startsInLabel(r.startTime),
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
        ),
        _actions(context, repo, status),
      ],
    );
  }

  Widget _actions(
      BuildContext context, ReservationRepository repo, String status) {
    final buttons = <Widget>[];

    if (status == 'Pending') {
      buttons.add(SecondaryButton(
          label: 'تأكيد',
          icon: Icons.check_rounded,
          onPressed: () => repo.confirm(entry.reservation.id)));
    }
    if (status == 'Confirmed') {
      buttons.add(SecondaryButton(
          label: 'وصل',
          icon: Icons.directions_walk_rounded,
          onPressed: () => repo.markArrived(entry.reservation.id)));
    }
    if (status == 'Arrived') {
      buttons.add(PrimaryButton(
          label: 'بدء الجلسة',
          icon: Icons.play_arrow_rounded,
          onPressed: () async {
            await repo.startSession(entry);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم بدء الجلسة من الحجز')));
            }
          }));
    }
    if (status == 'Pending' || status == 'Confirmed') {
      buttons.add(IconButton(
        tooltip: 'إلغاء',
        icon:
            const Icon(Icons.close_rounded, size: 18, color: AppColors.danger),
        onPressed: () => repo.cancel(entry.reservation.id),
      ));
      buttons.add(IconButton(
        tooltip: 'لم يحضر',
        icon: const Icon(Icons.person_off_rounded,
            size: 18, color: AppColors.textTertiary),
        onPressed: () => repo.markNoShow(entry.reservation.id),
      ));
    }

    return Row(mainAxisSize: MainAxisSize.min, children: buttons);
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final ReservationWithDetails entry;

  @override
  Widget build(BuildContext context) {
    final r = entry.reservation;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(entry.customer.name,
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(entry.device.name,
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 3,
            child: Text(_fmtRange(r.startTime, r.endTime),
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12)),
          ),
          _ReservationStatusChip(status: r.status),
        ],
      ),
    );
  }
}

class _ReservationStatusChip extends StatelessWidget {
  const _ReservationStatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'Pending' => ('قيد التأكيد', AppColors.warning),
      'Confirmed' => ('مؤكد', AppColors.accentSecondary),
      'Arrived' => ('وصل', AppColors.statusActive),
      'Completed' => ('تم', AppColors.statusAvailable),
      'Cancelled' => ('ملغي', AppColors.danger),
      'NoShow' => ('لم يحضر', AppColors.textTertiary),
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

/// Opens the new-reservation form. Kept as a function so both the board
/// header and (potentially) a dashboard quick-action can reuse it.
Future<void> showNewReservationDialog(BuildContext context, WidgetRef ref) {
  return showDialog(
    context: context,
    builder: (_) => const _NewReservationDialog(),
  );
}

class _NewReservationDialog extends ConsumerStatefulWidget {
  const _NewReservationDialog();

  @override
  ConsumerState<_NewReservationDialog> createState() =>
      _NewReservationDialogState();
}

class _NewReservationDialogState extends ConsumerState<_NewReservationDialog> {
  int? _customerId;
  int? _deviceId;
  DateTime _start = DateTime.now().add(const Duration(hours: 1));
  int _durationMinutes = 60;
  String? _error;
  bool _saving = false;

  Future<void> _pickStart() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: 60)),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_start),
    );
    if (time == null) return;
    setState(() {
      _start =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (_customerId == null || _deviceId == null) {
      setState(() => _error = 'اختر العميل والجهاز الأول');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final employee = ref.read(currentEmployeeProvider);
      await ref.read(reservationRepositoryProvider).create(
            customerId: _customerId!,
            deviceId: _deviceId!,
            startTime: _start,
            endTime: _start.add(Duration(minutes: _durationMinutes)),
            employeeId: employee?.id,
          );
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('تم إنشاء الحجز')));
      }
    } on ReservationOverlapException catch (e) {
      setState(() => _error = '$e');
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allActiveCustomersProvider);
    final devicesAsync = ref.watch(devicesWithTypeProvider);

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 460,
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
            const Text('حجز جديد', style: AppTypography.sectionTitle),
            const SizedBox(height: AppSpacing.lg),
            const Text('العميل', style: AppTypography.body),
            const SizedBox(height: 6),
            customersAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) =>
                  Text('$e', style: const TextStyle(color: AppColors.danger)),
              data: (customers) => _dropdown<int>(
                value: _customerId,
                hint: 'اختر العميل',
                items: customers
                    .map((c) => DropdownMenuItem(
                        value: c.id, child: Text('${c.name} — ${c.phone}')))
                    .toList(),
                onChanged: (v) => setState(() => _customerId = v),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('الجهاز', style: AppTypography.body),
            const SizedBox(height: 6),
            devicesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) =>
                  Text('$e', style: const TextStyle(color: AppColors.danger)),
              data: (devices) => _dropdown<int>(
                value: _deviceId,
                hint: 'اختر الجهاز',
                items: devices
                    .map((d) => DropdownMenuItem(
                        value: d.device.id,
                        child: Text('${d.type.name} — ${d.device.name}')))
                    .toList(),
                onChanged: (v) => setState(() => _deviceId = v),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                const Text('وقت البداية', style: AppTypography.body),
                const Spacer(),
                SecondaryButton(
                  label: _fmtDateTime(_start),
                  icon: Icons.schedule_rounded,
                  onPressed: _pickStart,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Text('المدة', style: AppTypography.body),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: [
                for (final m in [30, 60, 90, 120, 180])
                  GestureDetector(
                    onTap: () => setState(() => _durationMinutes = m),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: _durationMinutes == m
                            ? AppColors.accentPrimary.withOpacity(0.2)
                            : AppColors.glassFill,
                        borderRadius: AppRadius.smallR,
                        border: Border.all(
                            color: _durationMinutes == m
                                ? AppColors.glassBorderPurple
                                : AppColors.glassBorder),
                      ),
                      child: Text('$m دقيقة',
                          style: TextStyle(
                              fontSize: 12,
                              color: _durationMinutes == m
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary)),
                    ),
                  ),
              ],
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
                    label: _saving ? 'جارٍ الحجز...' : 'تأكيد الحجز',
                    icon: Icons.event_available_rounded,
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

String _fmtRange(DateTime start, DateTime end) =>
    '${_fmtTime(start)} – ${_fmtTime(end)}';

String _fmtTime(DateTime d) => clockOf(d);

String _fmtDateTime(DateTime d) => '${shortDayOf(d)} ${clockOf(d)}';

String _startsInLabel(DateTime start) {
  final diff = start.difference(DateTime.now());
  if (diff.isNegative) return 'بدأ بالفعل';
  if (diff.inMinutes < 60) return 'بعد ${diff.inMinutes} دقيقة';
  if (diff.inHours < 24) return 'بعد ${diff.inHours} ساعة';
  return 'بعد ${diff.inDays} يوم';
}
