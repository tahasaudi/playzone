import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

enum DeviceStatus { available, active, paused, maintenance, timeup }

extension DeviceStatusX on DeviceStatus {
  Color get color {
    switch (this) {
      case DeviceStatus.available:
        return AppColors.statusAvailable;
      case DeviceStatus.active:
        return AppColors.statusActive;
      case DeviceStatus.paused:
        return AppColors.statusPaused;
      case DeviceStatus.maintenance:
        return AppColors.statusMaintenance;
      case DeviceStatus.timeup:
        return AppColors.warning;
    }
  }

  IconData get icon {
    switch (this) {
      case DeviceStatus.available:
        return Icons.check_circle_rounded;
      case DeviceStatus.active:
        return Icons.play_circle_rounded;
      case DeviceStatus.paused:
        return Icons.pause_circle_rounded;
      case DeviceStatus.maintenance:
        return Icons.build_circle_rounded;
      case DeviceStatus.timeup:
        return Icons.timer_off_rounded;
    }
  }

  String labelAr() {
    switch (this) {
      case DeviceStatus.available:
        return 'متاح';
      case DeviceStatus.active:
        return 'شغّال';
      case DeviceStatus.paused:
        return 'موقّف';
      case DeviceStatus.maintenance:
        return 'صيانة';
      case DeviceStatus.timeup:
        return 'خلص الوقت';
    }
  }
}

/// Status is ALWAYS communicated with color + icon + text together —
/// never color alone (spec section 39, accessibility).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.compact = false});

  final DeviceStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.sm : AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: status.color.withOpacity(0.14),
        borderRadius: AppRadius.smallR,
        border: Border.all(color: status.color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(status.icon, size: 14, color: status.color),
          const SizedBox(width: 6),
          Text(
            status.labelAr(),
            style: TextStyle(
              color: status.color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
