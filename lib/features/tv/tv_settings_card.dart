import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/tv/tv_display_service.dart';
import '../../core/tv/tv_screen_report.dart';
import 'tv_mode_screen.dart';

/// A one-line verdict on every wall screen, with a way through to the page
/// that can fix them.
///
/// This used to be the whole TV setup crammed into a strip at the bottom of
/// the pricing screen: two address boxes, a device dropdown, four buttons
/// that all aimed at the *first* screen no matter what they were labelled,
/// and a status blob that mixed both panels into one line of counters. None
/// of it could answer "which screen is wrong?", and the buttons actively
/// misled — pressing "جرّب إطفاء" next to the 65" addressed the 55".
///
/// So the editing and the diagnosis moved to a page of their own, one panel
/// per screen, each with buttons that can only ever address that screen. What
/// stays here is the glance: is every screen fine, and if not, which one.
class TvHealthSummary extends ConsumerWidget {
  const TvHealthSummary({super.key, required this.onManage});

  final VoidCallback onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reports = ref.watch(tvScreenReportsProvider).valueOrNull ??
        TvDisplayService.instance.reports();
    final bad = reports.where((r) => r.severity == TvSeverity.bad).toList();
    final warn = reports.where((r) => r.severity == TvSeverity.warn).toList();
    final clean = bad.isEmpty && warn.isEmpty;
    final tone = !clean && bad.isNotEmpty
        ? AppColors.danger
        : !clean
            ? AppColors.warning
            : AppColors.statusAvailable;
    final named = [...bad, ...warn].map((r) => r.name).join('، ');

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.mediumR,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          Icon(
            clean ? Icons.verified_rounded : Icons.warning_amber_rounded,
            size: 17,
            color: tone,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              reports.isEmpty
                  ? 'لسه بنفحص الشاشات…'
                  : clean
                      ? 'كل الشاشات تمام (${reports.length})'
                      : 'فيها مشكلة: $named',
              style: TextStyle(fontSize: 12, color: tone),
            ),
          ),
          TextButton(
            onPressed: onManage,
            child: const Text('إدارة الشاشات',
                style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
