import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/session_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_card.dart';
import '../../data/repositories/invoice_repository.dart';
import '../../data/repositories/session_repository.dart';

/// Sessions — the shop's memory of what already happened.
///
/// Deliberately empty on arrival: the cashier picks a period, presses بحث,
/// and only then do the sessions come back. A history that opens with every
/// row ever recorded is one nobody can read, and nobody walks up to this
/// page asking for "all of it" — they ask for last night, or Tuesday, or
/// whatever the argument at the counter is about.
///
/// Tapping a row opens that session's own sheet: what it cost, what was
/// ordered and at what hour, and the timeline of everything that happened
/// to it while it ran.
class SessionsScreen extends ConsumerStatefulWidget {
  const SessionsScreen({super.key});

  @override
  ConsumerState<SessionsScreen> createState() => _SessionsScreenState();
}

class _SessionsScreenState extends ConsumerState<SessionsScreen> {
  // Search is a deliberate act — `_searched` stays false until the button is
  // pressed, so the page never renders a history the cashier did not ask for.
  final TextEditingController _search = TextEditingController();
  String _query = '';
  bool _searched = false;

  // A date RANGE plus an optional time window, so a shift owner can count
  // exactly how many sessions ran in a period ("حصر" — e.g. every session
  // between 8 ص and 11 م on a given night).
  bool _todayOnly = false;
  DateTime? _fromDay;
  DateTime? _toDay;
  TimeOfDay? _fromTime;
  TimeOfDay? _toTime;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

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
    final s = entry.session;
    final at = s.endTime ?? s.startTime;
    if (_todayOnly && !_sameDay(at, DateTime.now())) return false;
    if (at.isBefore(_rangeStart) || at.isAfter(_rangeEnd)) return false;

    // The clock window applies whenever it was asked for, with or without a
    // date beside it — "جلسات من 8 ص لـ 11 م" is a complete request on its
    // own, and skipping it because no date was picked used to silently drop
    // the whole reason the chip was there.
    final fromM =
        _fromTime == null ? null : _fromTime!.hour * 60 + _fromTime!.minute;
    final toM = _toTime == null ? null : _toTime!.hour * 60 + _toTime!.minute;
    if (fromM != null || toM != null) {
      final minutes = at.hour * 60 + at.minute;
      if (fromM != null && minutes < fromM) return false;
      if (toM != null && minutes > toM) return false;
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      final haystack = '${entry.type.name} ${entry.device.name} '
              '${entry.customer?.name ?? ''} ${s.status}'
          .toLowerCase();
      if (!haystack.contains(q)) return false;
    }
    return true;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool get _hasFilters =>
      _query.trim().isNotEmpty ||
      _todayOnly ||
      _fromDay != null ||
      _toDay != null ||
      _fromTime != null ||
      _toTime != null;

  void _runSearch() {
    FocusScope.of(context).unfocus();
    // The list is bound to the current query, so the only thing missing is
    // permission to show it: this is the button that turns the page on.
    if (!_searched) setState(() => _searched = true);
  }

  void _resetFilters() => setState(() {
        _search.clear();
        _query = '';
        _searched = false;
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
    if (picked != null) {
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
        _searched = true;
      });
    }
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
    if (picked != null) {
      setState(() {
        _fromDay = picked.start;
        _toDay = picked.end;
        _todayOnly = false;
        _searched = true;
      });
    }
  }

  Future<void> _pickTime({required bool from}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: (from ? _fromTime : _toTime) ??
          (from
              ? const TimeOfDay(hour: 8, minute: 0)
              : const TimeOfDay(hour: 23, minute: 0)),
    );
    if (picked != null) {
      setState(() {
        if (from) {
          _fromTime = picked;
        } else {
          _toTime = picked;
        }
        _searched = true;
      });
    }
  }

  String get _rangeLabel {
    if (_todayOnly) return 'النهارده';
    if (_fromDay == null && _toDay == null) return 'كل الأيام';
    String fmt(DateTime d) => '${d.day}/${d.month}/${d.year}';
    if (_fromDay != null && _toDay != null) {
      return _sameDay(_fromDay!, _toDay!)
          ? fmt(_fromDay!)
          : '${fmt(_fromDay!)} ← ${fmt(_toDay!)}';
    }
    return fmt(_fromDay ?? _toDay!);
  }

  void _openDetail(SessionBoardEntry entry) {
    // Half the window at most: the sheet is an answer, not another page —
    // the list it came from must stay visible behind it so the cashier can
    // keep reading rows while checking one of them.
    final maxHeight = MediaQuery.of(context).size.height * 0.5;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: _SessionDetailSheet(entry: entry, maxHeight: maxHeight),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final completedAsync = ref.watch(completedSessionsProvider);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('الجلسات', style: AppTypography.sectionTitle),
          const SizedBox(height: 2),
          const Text('اختار الفترة واضغط بحث عشان تشوف الجلسات اللي حصلت',
              style: AppTypography.secondary),
          const SizedBox(height: AppSpacing.lg),
          _SessionFilterBar(
            rangeLabel: _rangeLabel,
            controller: _search,
            todayOnly: _todayOnly,
            fromTime: _fromTime,
            toTime: _toTime,
            hasFilters: _hasFilters,
            onQueryChanged: (v) => setState(() => _query = v),
            onSearch: _runSearch,
            onToggleToday: () => setState(() {
              _todayOnly = !_todayOnly;
              if (_todayOnly) {
                _fromDay = null;
                _toDay = null;
              }
              _searched = true;
            }),
            onPickRange: _pickRange,
            onPickFromDay: () => _pickDay(from: true),
            onPickToDay: () => _pickDay(from: false),
            onPickFrom: () => _pickTime(from: true),
            onPickTo: () => _pickTime(from: false),
            onReset: _resetFilters,
          ),
          const SizedBox(height: AppSpacing.lg),
          if (!_searched)
            const GlassCard(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(
                  child: Text('اضغط بحث عشان تطلّع الجلسات',
                      style: TextStyle(color: AppColors.textTertiary)),
                ),
              ),
            )
          else
            completedAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Text('خطأ: $e',
                  style: const TextStyle(color: AppColors.danger)),
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

                final revenue = filtered.fold<double>(
                    0,
                    (sum, s) =>
                        sum +
                        (s.session.finalCost ?? s.session.accumulatedCost));
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
                    Text('النتائج (${filtered.length})',
                        style: AppTypography.cardTitle),
                    const SizedBox(height: AppSpacing.sm),
                    GlassCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          for (final s in filtered) ...[
                            _HistoryRow(
                              entry: s,
                              onTap: () => _openDetail(s),
                            ),
                            if (s != filtered.last)
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
                      fontSize: 18, fontWeight: FontWeight.w700, color: color)),
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
                    style:
                        TextStyle(fontSize: 11, color: AppColors.textTertiary)),
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

/// The search field, the بحث button and every filter — one row, because they
/// are one gesture: say what you want, press the button, read the answer.
class _SessionFilterBar extends StatelessWidget {
  const _SessionFilterBar({
    required this.controller,
    required this.rangeLabel,
    required this.todayOnly,
    required this.fromTime,
    required this.toTime,
    required this.hasFilters,
    required this.onQueryChanged,
    required this.onSearch,
    required this.onToggleToday,
    required this.onPickRange,
    required this.onPickFromDay,
    required this.onPickToDay,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onReset,
  });

  final TextEditingController controller;
  final String rangeLabel;
  final bool todayOnly;
  final TimeOfDay? fromTime;
  final TimeOfDay? toTime;
  final bool hasFilters;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onSearch;
  final VoidCallback onToggleToday;
  final VoidCallback onPickRange;
  final VoidCallback onPickFromDay;
  final VoidCallback onPickToDay;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;
  final VoidCallback onReset;

  String _timeLabel(TimeOfDay? t) =>
      t == null ? '—' : clockOfDay(t.hour, t.minute);

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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
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
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: controller,
            onChanged: onQueryChanged,
            onSubmitted: (_) => onSearch(),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            cursorColor: AppColors.accentPrimary,
            decoration: InputDecoration(
              isDense: true,
              hintText: 'اسم الجهاز أو الزبون',
              hintStyle: AppTypography.secondary,
              prefixIcon: const Icon(Icons.search_rounded,
                  size: 18, color: AppColors.textTertiary),
              suffixIcon: controller.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.backspace_rounded,
                          size: 16, color: AppColors.textTertiary),
                      onPressed: controller.clear,
                    ),
              filled: true,
              fillColor: AppColors.glassFill,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              border: OutlineInputBorder(
                borderRadius: AppRadius.smallR,
                borderSide: const BorderSide(color: AppColors.glassBorder),
              ),
            ),
          ),
        ),
        PrimaryButton(
            label: 'بحث', icon: Icons.search_rounded, onPressed: onSearch),
        chip(
          icon: Icons.today_rounded,
          label: 'النهارده',
          active: todayOnly,
          onTap: onToggleToday,
        ),
        chip(
          icon: Icons.date_range_rounded,
          label: 'الفترة: $rangeLabel',
          active: !todayOnly && rangeLabel != 'كل الأيام',
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
  const _HistoryRow({required this.entry, required this.onTap});
  final SessionBoardEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final s = entry.session;
    final cost = s.finalCost ?? s.accumulatedCost;
    return InkWell(
      onTap: onTap,
      borderRadius: AppRadius.smallR,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
              flex: 3,
              child: Text(_fmtRange(s.startTime, s.endTime),
                  style: const TextStyle(
                      color: AppColors.textTertiary, fontSize: 12)),
            ),
            SizedBox(
              width: 90,
              child: Text('EGP ${cost.toStringAsFixed(1)}',
                  textAlign: TextAlign.end, style: AppTypography.cardTitle),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_left_rounded,
                size: 18, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }
}

/// One session, opened up: the money, the drinks, and the timeline.
///
/// Everything here is read live rather than captured on open — the sheet is
/// used over sessions that may still be running, and a sheet that lies by
/// being one second stale is worse than no sheet.
class _SessionDetailSheet extends ConsumerWidget {
  const _SessionDetailSheet({required this.entry, required this.maxHeight});

  final SessionBoardEntry entry;
  final double maxHeight;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = entry.session;
    final events =
        ref.watch(sessionEventsProvider(s.id)).valueOrNull ?? const [];
    final allLines =
        ref.watch(sessionOrderLinesProvider(s.id)).valueOrNull ?? const [];
    // The gaming-time line is the bill talking about itself; the café lines
    // are what the customer actually ordered, and those are the ones with an
    // hour attached to them.
    final orderLines = allLines.where((l) => l.productId != null).toList();
    final ordersTotal = orderLines.fold<double>(0, (sum, l) => sum + l.total);

    final split = s.singleCost + s.multiCost;
    final hasSplit = split > 0.001;
    final total = s.finalCost ?? s.accumulatedCost;

    double timeCost;
    if (s.fixedPrice != null) {
      timeCost = s.fixedPrice!;
    } else if (hasSplit) {
      timeCost = split;
    } else if (s.finalCost != null) {
      timeCost =
          (s.finalCost! - ordersTotal).clamp(0, double.infinity).toDouble();
    } else {
      timeCost = s.accumulatedCost;
    }

    Widget moneyRow(String label, String value,
        {Color? color, bool strong = false, double top = 0}) {
      return Padding(
        padding: EdgeInsets.only(top: top),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: strong ? 13 : 12,
                      fontWeight: strong ? FontWeight.w700 : FontWeight.w400,
                      color: strong
                          ? AppColors.textPrimary
                          : AppColors.textSecondary)),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: strong ? 15 : 13,
                    fontWeight: FontWeight.w700,
                    color: color ?? AppColors.textPrimary)),
          ],
        ),
      );
    }

    Widget sectionTitle(String title) => Padding(
          padding:
              const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
          child: Text(title, style: AppTypography.cardTitle),
        );

    Widget _meta(String label, String value) => Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary)),
            ],
          ),
        );

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 28,
                offset: const Offset(0, -8)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header — fixed, so the session's identity never scrolls away
            // from the numbers that belong to it.
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${entry.type.name} — ${entry.device.name}',
                            style: AppTypography.cardTitle),
                        const SizedBox(height: 2),
                        Text(
                          '${entry.customer?.name ?? 'زائر'} · '
                          '${_fmtRange(s.startTime, s.endTime)}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded,
                        size: 20, color: AppColors.textTertiary),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    sectionTitle('الجلسة'),
                    Row(
                      children: [
                        _meta(
                            'المدة', _fmtDuration(entry.elapsedActiveMinutes)),
                        _meta('الوضع', s.mode == 'multi' ? 'مالتي' : 'فردي'),
                        _meta('الحالة', _statusOf(s.status)),
                      ],
                    ),
                    sectionTitle('الفلوس'),
                    moneyRow('وقت اللعب', 'EGP ${timeCost.toStringAsFixed(2)}'),
                    if (hasSplit) ...[
                      moneyRow('فردي لوحده',
                          'EGP ${s.singleCost.toStringAsFixed(2)}',
                          color: AppColors.accentSecondary),
                      moneyRow('مالتي لوحده',
                          'EGP ${s.multiCost.toStringAsFixed(2)}',
                          color: AppColors.accentSecondary),
                      moneyRow(
                          'إجمالي الوقت', 'EGP ${split.toStringAsFixed(2)}',
                          top: 2),
                    ],
                    if (ordersTotal > 0)
                      moneyRow(
                          'الطلبات', 'EGP ${ordersTotal.toStringAsFixed(2)}'),
                    moneyRow('الإجمالي', 'EGP ${total.toStringAsFixed(2)}',
                        color: AppColors.statusAvailable, strong: true, top: 6),
                    if (!hasSplit && s.fixedPrice == null && total > 0)
                      const Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          'الجلسات القديمة مش مقسمة لفردي ومالتي — التقسيم بيتسجل من بعد التحديث',
                          style: TextStyle(
                              fontSize: 11, color: AppColors.textTertiary),
                        ),
                      ),
                    sectionTitle('الطلبات'),
                    if (orderLines.isEmpty)
                      const Text('مفيش طلبات في الجلسة دي',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textTertiary))
                    else
                      for (final line in orderLines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${line.description} ×${line.quantity}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                              Text(
                                clockOf(line.createdAt ?? s.startTime),
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textTertiary),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              SizedBox(
                                width: 86,
                                child: Text(
                                  'EGP ${line.total.toStringAsFixed(2)}',
                                  textAlign: TextAlign.end,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.textPrimary),
                                ),
                              ),
                            ],
                          ),
                        ),
                    sectionTitle('اللي حصل'),
                    if (events.isEmpty)
                      const Text(
                        'الجلسات القديمة متسجلة بوقتها بس — الأحداث بتتسجل من بعد التحديث',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary),
                      )
                    else
                      for (final e in events)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: _eventColor(e.type),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Text(_eventLabel(e),
                                    style: const TextStyle(
                                        fontSize: 13,
                                        color: AppColors.textSecondary)),
                              ),
                              Text(clockOf(e.at),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textTertiary)),
                            ],
                          ),
                        ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusOf(String status) => switch (status) {
        'active' => 'شغّال',
        'paused' => 'متوقف',
        'timeup' => 'خلص الوقت',
        'completed' => 'محسوبة',
        _ => status,
      };

  String _eventLabel(SessionEventRow e) => switch (e.type) {
        'start' => 'بداية الجلسة',
        'pause' => 'إيقاف مؤقت',
        'resume' => 'استئناف',
        'mode' => 'تحويل لـ ${e.note == 'multi' ? 'مالتي' : 'فردي'}',
        'screen_on' => 'الشاشة اتفتحت',
        'screen_off' => 'الشاشة اتقفلت',
        'extend' => 'تمديد ${e.note ?? ''} دقيقة',
        'timeup' => 'خلص الوقت',
        'checkout' => 'تحصيل ودفع',
        _ => e.type,
      };

  Color _eventColor(String type) => switch (type) {
        'pause' => AppColors.statusPaused,
        'resume' => AppColors.statusAvailable,
        'screen_on' => AppColors.accentSecondary,
        'screen_off' => AppColors.textTertiary,
        'mode' => AppColors.infoBlue,
        'checkout' => AppColors.statusAvailable,
        'timeup' => AppColors.danger,
        _ => AppColors.textSecondary,
      };
}

String _fmtDuration(double minutes) {
  final totalSeconds = (minutes * 60).round();
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  return '${h.toString().padLeft(2, '0')}'
      ':${m.toString().padLeft(2, '0')}'
      ':${s.toString().padLeft(2, '0')}';
}

/// `6/10 9:05 ص – 10:30 م` — the day, because a list read without one is a
/// guess, and the clock in the café's own words rather than 21:05.
String _fmtRange(DateTime start, DateTime? end) {
  if (end == null) return '${shortDayOf(start)} ${clockOf(start)} – —';
  if (start.year != end.year ||
      start.month != end.month ||
      start.day != end.day) {
    return '${shortDayOf(start)} ${clockOf(start)} – '
        '${shortDayOf(end)} ${clockOf(end)}';
  }
  return '${shortDayOf(start)} ${clockOf(start)} – ${clockOf(end)}';
}
