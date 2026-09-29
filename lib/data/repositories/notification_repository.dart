import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import 'product_repository.dart';
import 'session_repository.dart';
import 'reservation_repository.dart';

enum NotificationSeverity { low, medium, high }

/// One item in the bell feed. [route] is where tapping it should take the
/// user (wired only if the AppShell route exists).
class AppNotification {
  AppNotification({
    required this.title,
    required this.body,
    this.severity = NotificationSeverity.medium,
    this.icon = Icons.notifications_none_rounded,
    this.route,
  });
  final String title;
  final String body;
  final NotificationSeverity severity;
  final IconData icon;
  final String? route;
}

extension NotificationSeverityX on NotificationSeverity {
  Color get color {
    switch (this) {
      case NotificationSeverity.low:
        return AppColors.textTertiary;
      case NotificationSeverity.medium:
        return AppColors.warning;
      case NotificationSeverity.high:
        return AppColors.danger;
    }
  }
}

/// The notification feed — derived purely from LIVE providers, no polling
/// and no extra tables: low stock, sessions paused too long, and
/// reservations about to start all appear the moment the underlying data
/// changes.
final notificationsProvider = Provider<List<AppNotification>>((ref) {
  final notifications = <AppNotification>[];

  // 1) Low-stock products (spec: alert on low stock).
  final lowStock = ref.watch(lowStockProductsProvider).value ?? const [];
  for (final p in lowStock) {
    notifications.add(AppNotification(
      severity:
          p.stockQuantity <= 0 ? NotificationSeverity.high : NotificationSeverity.medium,
      icon: Icons.inventory_2_rounded,
      title: p.stockQuantity <= 0 ? 'منتج نفد من المخزون' : 'مخزون منخفض',
      body: '«${p.name}» بقي ${p.stockQuantity} قطعة فقط',
      route: 'inventory',
    ));
  }

  // 2) Sessions paused longer than 15 minutes — likely forgotten.
  final sessions = ref.watch(activeSessionsProvider).value ?? const [];
  for (final s in sessions) {
    if (s.session.status != 'paused' || s.session.pausedAt == null) continue;
    final pausedMinutes =
        DateTime.now().difference(s.session.pausedAt!).inSeconds / 60.0;
    if (pausedMinutes >= 15) {
      notifications.add(AppNotification(
        severity: pausedMinutes >= 45
            ? NotificationSeverity.high
            : NotificationSeverity.medium,
        icon: Icons.pause_circle_rounded,
        title: 'جلسة متوقفة من فترة',
        body:
            '${s.type.name} — ${s.device.name} متوقف ${pausedMinutes.round()} دقيقة',
      ));
    }
  }

  // 3) Reservations starting within the next hour (or already arrived).
  final upcoming =
      ref.watch(upcomingReservationsProvider).value ?? const [];
  final now = DateTime.now();
  final inOneHour = now.add(const Duration(hours: 1));
  for (final r in upcoming) {
    if (r.reservation.status == 'Arrived') {
      notifications.add(AppNotification(
        severity: NotificationSeverity.high,
        icon: Icons.event_available_rounded,
        title: 'حجز وصل وينتظر',
        body: '${r.customer.name} وصل — ${r.device.name} جاهز لبدء الجلسة',
      ));
      continue;
    }
    final startsIn = r.reservation.startTime.difference(now);
    final startsInWindowMs = inOneHour.difference(now).inMilliseconds;
    if (!startsIn.isNegative && startsIn.inMilliseconds <= startsInWindowMs) {
      notifications.add(AppNotification(
        severity: startsIn.inMinutes <= 15
            ? NotificationSeverity.high
            : NotificationSeverity.medium,
        icon: Icons.event_rounded,
        title: 'حجز قرب يبدأ',
        body:
            '${r.customer.name} على ${r.device.name} بعد ${startsIn.inMinutes.clamp(1, 60).toInt()} دقيقة',
        route: 'reservations',
      ));
    }
  }

return notifications;
});