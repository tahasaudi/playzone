import 'package:flutter/material.dart';

import '../../core/database/daos/session_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

/// The wall-display cards, shared by the on-screen TV mode and the
/// background broadcaster, so what the cashier previews is exactly what
/// the LG TV shows.
class TvCardGrid extends StatelessWidget {
  const TvCardGrid({super.key, required this.entries});

  final List<SessionBoardEntry> entries;

  @override
  Widget build(BuildContext context) {
    final columns = entries.length == 1
        ? 1
        : entries.length <= 4
            ? 2
            : 3;
    return GridView.count(
      crossAxisCount: columns,
      mainAxisSpacing: AppSpacing.lg,
      crossAxisSpacing: AppSpacing.lg,
      childAspectRatio: 1.5,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      children: entries.map((e) => TvSessionCard(entry: e)).toList(),
    );
  }
}

class TvSessionCard extends StatelessWidget {
  const TvSessionCard({super.key, required this.entry});

  final SessionBoardEntry entry;

  @override
  Widget build(BuildContext context) {
    final s = entry.session;
    final paused = s.status == 'paused';
    final timeUp = s.status == 'timeup';
    final remaining = entry.remainingMinutes;
    final cost = s.finalCost ?? entry.liveCost;
    final accent = timeUp
        ? AppColors.warning
        : paused
            ? AppColors.statusPaused
            : AppColors.accentSecondary;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.heroR,
        border: Border.all(color: accent.withOpacity(0.5), width: 2),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text('${entry.type.name} — ${entry.device.name}',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              const Spacer(),
              Text(
                timeUp
                    ? 'انتهى الوقت'
                    : paused
                        ? 'متوقف'
                        : remaining != null
                            ? 'فاضل ${_mmss(remaining)}'
                            : 'وقت مفتوح',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.w700, color: accent),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(_hhmmss(entry.elapsedActiveMinutes),
                  style: TextStyle(
                      fontSize: 92,
                      height: 1,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: timeUp
                          ? AppColors.warning
                          : AppColors.textPrimary)),
            ),
          ),
          Row(
            children: [
              Expanded(child: _kv('العميل', entry.customer?.name ?? 'زائر')),
              Expanded(child: _kv('السعر', 'EGP ${cost.toStringAsFixed(2)}')),
              Expanded(child: _kv('الوضع', s.mode == 'multi' ? 'مالتي' : 'فردي')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _kv(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textTertiary)),
        const SizedBox(height: 2),
        Text(value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary)),
      ],
    );
  }

  String _hhmmss(double minutes) {
    final total = (minutes * 60).round();
    return '${_2(total ~/ 3600)}:${_2((total % 3600) ~/ 60)}:${_2(total % 60)}';
  }

  String _mmss(double minutes) {
    final total = (minutes * 60).round();
    return '${_2((total % 3600) ~/ 60)}:${_2(total % 60)}';
  }

  String _2(int v) => v.toString().padLeft(2, '0');
}
