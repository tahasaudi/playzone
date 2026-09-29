import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/database/daos/session_dao.dart';
import '../../data/repositories/session_repository.dart';

/// Sessions — the operational view of play time: every running/paused
/// session with a live timer and quick pause/resume/mode controls, plus
/// a searchable/filterable history of completed sessions. Checkout still
/// happens on the Dashboard card so the payment flow has one home.
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  // History filters: a date RANGE plus an optional time window, so a
  // shift owner can count exactly how many sessions ran in a period
  // ("حصر" — e.g. every session between 20:00 and 23:00 on a given night).
  bool _todayOnly = false;
  DateTime? _fromDay;
  DateTime? _toDay;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  DateTime get _rangeStart {
    if (_todayOnly) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day);
    }
    final day = _fromDay ?? _toDay;
    if (day == null) return DateTime(2020);
    return DateTime(day.year, day.month, day.day);
  }

  DateTime get _rangeEnd {
    if (_todayOnly) {
      final now = DateTime.now();
      return DateTime(now.year, now.month, now.day, 23, 59, 59);
    }
    final day = _toDay ?? _fromDay;
    if (day == null) return DateTime.now().add(const Duration(days: 3650));
    return DateTime(day.year, day.month, day.day, 23, 59, 59);
  }

  bool _matches(SessionBoardEntry entry) {
    final at = entry.session.endTime ?? entry.session.startTime;
    if (_todayOnly && !_sameDay(at, DateTime.now())) return false;
    if (at.isBefore(_rangeStart) || at.isAfter(_rangeEnd)) return false;
    // The time window only narrows the LAST day of the range, which is
    // what "sessions between 20:00 and 23:00" means in practice.
    if (_fromDay == null && _toDay == null && !_todayOnly) return true;
    final minutes = at.hour * 60 + at.minute;
    if (_fromTime != null &&
        minutes < _fromTime!.hour * 60 + _fromTime!.minute) {
      return false;
    }
    if (_toTime != null && minutes > _toTime!.hour * 60 + _toTime!.minute) {
      return false;
    }
    return true;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _hasFilters =>
      _todayOnly ||
      _fromDay != null ||
      _toDay != null ||
      _fromTime != null ||
      _toTime != null;

  void _resetFilters() => setState(() {
        _todayOnly = false;
        _fromDay = null;
        _toDay = null;
        _fromTime = null;
        _toTime = null;
      });

  Future<void> _pickDay({required bool from}) async {
    final current = from ? _fromDay : _toDay;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null)
      setState(() {
        if (from) {
          _fromDay = picked;
          // Keep the range ordered when only one side was picked before.
          if (_toDay != null && _toDay!.isBefore(picked)) _toDay = picked;
        } else {
          _toDay = picked;
          if (_fromDay != null && _fromDay!.isAfter(picked)) _fromDay = picked;
        }
        _todayOnly = false;
      });
  }

  /// Picks both ends in one dialog — the common case is a single shift.
  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _fromDay != null && _toDay != null
          ? DateTimeRange(start: _fromDay!, end: _toDay!)
          : null,
    );
    if (picked != null)
      setState(() {
        _fromDay = picked.start;
        _toDay = picked.end;
        _todayOnly = false;
      });
  }

  Future<void> _pickTime({required bool from}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (from ? _fromTime : _toTime) ??
          (_hasFilters
              ? const TimeOfDay(hour: 12, minute: 0)
              : const TimeOfDay(hour: 9, minute: 0)),
    );
    if (picked != null)
      setState(() {
        if (from) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
      });
  }

  String get _rangeLabel {
    if (_todayOnly) return 'النهارده';
    if (_fromDay == null && _toDay == null) return 'كل الأيام';
    String fmt(DateTime d) =>
        '${d.day}/${d.month}/${d.year}';
    if (_fromDay != null && _toDay != null) {
      return _sameDay(_fromDay!, _toDay!)
          ? fmt(_fromDay!)
          : '${fmt(_fromDay!)} ← ${fmt(_toDay!)}';
    }
    return fmt(_fromDay ?? _toDay!);
  }

  @override
  Widget build(BuildContext context) {
    // Rebuilds once a second so the live timers/costs tick.
    ref.watch(oneSecondTickerProvider);
    final activeAsync = ref.watch(activeSessionsProvider);
    final completedAsync = ref.watch(completedSessionsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الجلسات', style: AppTypography.sectionTitle),
          const SizedBox(height: 2),
          const Text('الجلسات الجارية والمحسوبة لحظة بلحظة',
              style: AppTypography.secondary),
          const SizedBox(height: AppSpacing.lg),
          activeAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('خطأ: $e',
                style: const TextStyle(color: AppColors.danger)),
            data: (sessions) {
              if (sessions.isEmpty) {
                return const GlassCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: Text('لا توجد جلسات جارية حاليًا',
                          style: TextStyle(color: AppColors.textTertiary)),
                    ),
                  ),
                );
              }
              return Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  for (final s in sessions) _ActiveSessionCard(entry: s),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text('سجل الجلسات', style: AppTypography.cardTitle),
          const SizedBox(height: AppSpacing.xs),
          const Text('اختار الفترة عشان تعرف كام جلسة اتعملت فيها',
              style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          const SizedBox(height: AppSpacing.sm),
          _SessionFilterBar(
            rangeLabel: _rangeLabel,
            todayOnly: _todayOnly,
            fromTime: _fromTime,
            toTime: _toTime,
            hasFilters: _hasFilters,
            onToggleToday: () => setState(() {
              _todayOnly = !_todayOnly;
              if (_todayOnly) {
                _fromDay = null;
                _toDay = null;
              }
            }),
            onPickRange: _pickRange,
            onPickFromDay: () => _pickDay(from: true),
            onPickToDay: () => _pickDay(from: false),
            onPickFrom: () => _pickTime(from: true),
            onPickTo: () => _pickTime(from: false),
            onReset: _resetFilters,
          ),
          const SizedBox(height: AppSpacing.sm),
          completedAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (sessions) {
              final filtered = sessions.where(_matches).toList()
                ..sort((a, b) {
                  final aEnd = a.session.endTime ?? a.session.startTime;
                  final bEnd = b.session.endTime ?? b.session.startTime;
                  return bEnd.compareTo(aEnd);
                });
              if (filtered.isEmpty) {
                return const GlassCard(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                    child: Center(
                      child: Text('مفيش جلسات في الفترة دي',
                          style: TextStyle(color: AppColors.textTertiary)),
                    ),
                  ),
                );
              }

              // The newest session gets its own card at the very top, so
              // "what just happened?" is one glance — the rest of the
              // period sits under it.
              final latest = filtered.first;
              final rest = filtered.skip(1).toList();
              final revenue = filtered.fold<double>(
                  0, (sum, s) => sum + (s.session.finalCost ?? s.session.accumulatedCost));
              final minutes = filtered.fold<double>(
                  0, (sum, s) => sum + s.elapsedActiveMinutes);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CountSummary(
                    count: filtered.length,
                    revenue: revenue,
                    hours: minutes / 60,
                    rangeLabel: _rangeLabel,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Text('آخر جلسة', style: AppTypography.cardTitle),
                  const SizedBox(height: AppSpacing.xs),
                  _LatestSessionCard(entry: latest),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    rest.isEmpty ? 'مفيش جلسات قبل كده' : 'الجلسات السابقة (${rest.length})',
                    style: AppTypography.cardTitle,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  GlassCard(
                    child: rest.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                            child: Center(
                              child: Text('دي كانت أول جلسة في الفترة دي',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary)),
                            ),
                          )
                        : Column(
                            children: [
                              for (final s in rest) ...[
                                _HistoryRow(entry: s),
                                if (s != rest.last)
                                  const Divider(
                                      color: AppColors.glassBorder,
                                      height: AppSpacing.md),
                              ],
                            ],
                          ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// "الحصر" header — how many sessions ran in the picked period, for how
/// long, and what they billed.
class _CountSummary extends StatelessWidget {
  const _CountSummary({
    required this.count,
    required this.revenue,
    required this.hours,
    required this.rangeLabel,
  });

  final int count;
  final double revenue;
  final double hours;
  final String rangeLabel;

  @override
  Widget build(BuildContext context) {
    Widget cell(String label, String value, Color color) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
              const SizedBox(height: 2),
              Text(value,
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: color)),
            ],
          ),
        );

    return GlassCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      borderColor: AppColors.glassBorderPurple,
      child: Row(
        children: [
          cell('عدد الجلسات', '$count', AppColors.accentSecondary),
          cell('ساعات اللعب', hours.toStringAsFixed(1), AppColors.textPrimary),
          cell('الإيراد', 'EGP ${revenue.toStringAsFixed(0)}',
              AppColors.statusAvailable),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text('الفترة',
                    style: TextStyle(
                        fontSize: 11, color: AppColors.textTertiary)),
                const SizedBox(height: 2),
                Text(rangeLabel,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The single most recent session, pulled out of the list and shown on its
/// own at the top.
class _LatestSessionCard extends StatelessWidget {
  const _LatestSessionCard({required this.entry});
  final SessionBoardEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = entry.session;
    final cost = s.finalCost ?? s.accumulatedCost;
    final ended = s.endTime;

    return GlassCard(
      borderColor: AppColors.accentPrimary.withOpacity(0.4),
      child: Row(
        children: [
          const Icon(Icons.history_rounded,
              size: 22, color: AppColors.accentSecondary),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${entry.type.name} — ${entry.device.name}',
                    style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '${entry.customer?.name ?? 'زائر'} · '
                  '${ended == null ? 'لسه مفتوحة' : _fmtRange(entry.session.startTime, ended)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('EGP ${cost.toStringAsFixed(2)}', style: AppTypography.cardTitle),
              const SizedBox(height: 2),
              Text(_fmtDuration(entry.elapsedActiveMinutes),
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveSessionCard extends ConsumerWidget {
  const _ActiveSessionCard({required this.entry});
  final SessionBoardEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(sessionRepositoryProvider);
    final s = entry.session;
    final paused = s.status == 'paused';

    return SizedBox(
      width: 300,
      child: GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('${entry.type.name} — ${entry.device.name}',
                      style: AppTypography.cardTitle),
                ),
                _StatusChip(paused: paused),
              ],
            ),
            const SizedBox(height: 4),
            Text(entry.customer?.name ?? 'زائر',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textTertiary)),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _Metric(
                    label: 'الوقت',
                    value: _fmtDuration(entry.elapsedActiveMinutes),
                  ),
                ),
                Expanded(
                  child: _Metric(
                    label: 'التكلفة',
                    value: 'EGP ${entry.liveCost.toStringAsFixed(1)}',
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                if (paused)
                  SecondaryButton(
                    label: 'استئناف',
                    icon: Icons.play_arrow_rounded,
                    onPressed: () => repo.resume(entry),
                  )
                else
                  SecondaryButton(
                    label: 'إيقاف مؤقت',
                    icon: Icons.pause_rounded,
                    onPressed: () => repo.pause(entry),
                  ),
                const SizedBox(width: AppSpacing.sm),
                if (!paused)
                  SecondaryButton(
                    label: s.mode == 'multi' ? 'فردي' : 'مالتي',
                    icon: Icons.swap_horiz_rounded,
                    onPressed: () => repo.switchMode(
                        entry, s.mode == 'multi' ? 'single' : 'multi'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionFilterBar extends StatelessWidget {
  const _SessionFilterBar({
    required this.rangeLabel,
    required this.todayOnly,
    required this.fromTime,
    required this.toTime,
    required this.hasFilters,
    required this.onToggleToday,
    required this.onPickRange,
    required this.onPickFromDay,
    required this.onPickToDay,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onReset,
  });

  final String rangeLabel;
  final bool todayOnly;
  final TimeOfDay? fromTime;
  final TimeOfDay? toTime;
  final bool hasFilters;
  final VoidCallback onToggleToday;
  final VoidCallback onPickRange;
  final VoidCallback onPickFromDay;
  final VoidCallback onPickToDay;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onReset;

  String _timeLabel(TimeOfDay? t) => t == null
      ? '—'
      : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    Widget chip({
      required IconData icon,
      required String label,
      required VoidCallback onTap,
      bool active = false,
    }) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? AppColors.glassFillStrong : AppColors.glassFill,
            borderRadius: AppRadius.smallR,
            border: Border.all(
                color: active
                    ? AppColors.glassBorderPurple
                    : AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 15,
                  color: active
                      ? AppColors.accentSecondary
                      : AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: active
                          ? AppColors.textPrimary
                          : AppColors.textSecondary)),
            ],
          ),
        ),
      );
    }

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        chip(
          icon: Icons.today_rounded,
          label: 'النهارده',
          active: todayOnly,
          onTap: onToggleToday,
        ),
        chip(
          icon: Icons.date_range_rounded,
          label: 'الفترة: $rangeLabel',
          active: !todayOnly && hasFilters,
          onTap: onPickRange,
        ),
        chip(
          icon: Icons.event_rounded,
          label: 'من يوم',
          active: false,
          onTap: onPickFromDay,
        ),
        chip(
          icon: Icons.event_available_rounded,
          label: 'إلى يوم',
          active: false,
          onTap: onPickToDay,
        ),
        chip(
          icon: Icons.watch_later_outlined,
          label: 'من ${_timeLabel(fromTime)}',
          active: fromTime != null,
          onTap: onPickFrom,
        ),
        chip(
          icon: Icons.schedule_rounded,
          label: 'إلى ${_timeLabel(toTime)}',
          active: toTime != null,
          onTap: onPickTo,
        ),
        if (hasFilters)
          chip(
            icon: Icons.close_rounded,
            label: 'إلغاء البحث',
            active: true,
            onTap: onReset,
          ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});
  final SessionBoardEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = entry.session;
    final cost = s.finalCost ?? s.accumulatedCost;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text('${entry.type.name} — ${entry.device.name}',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontSize: 13)),
          ),
          Expanded(
            flex: 2,
            child: Text(entry.customer?.name ?? 'زائر',
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
          Expanded(
            flex: 2,
            child: Text(_fmtRange(s.startTime, s.endTime),
                style: const TextStyle(
                    color: AppColors.textTertiary, fontSize: 12)),
          ),
          SizedBox(
            width: 90,
            child: Text('EGP ${cost.toStringAsFixed(1)}',
                textAlign: TextAlign.end, style: AppTypography.cardTitle),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style:
                const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value,
            style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.paused});
  final bool paused;

  @override
  Widget build(BuildContext context) {
    final color = paused ? AppColors.statusPaused : AppColors.statusActive;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: AppRadius.smallR,
      ),
      child: Text(paused ? 'متوقف' : 'شغّال',
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

String _fmtTime(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

String _fmtRange(DateTime start, DateTime? end) =>
    '${_fmtTime(start)} – ${end == null ? '—' : _fmtTime(end)}';
