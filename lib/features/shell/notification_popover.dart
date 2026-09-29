import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../data/repositories/notification_repository.dart';

/// Notification center popover — opened from the bell in the top bar.
/// The list is derived live (low stock, sessions paused too long,
/// reservations about to start); tapping one navigates to the screen
/// that owns the alert.
Future<void> showNotificationsPopover(
  BuildContext context,
  void Function(String route) onNavigate,
) {
  return showDialog(
    context: context,
    barrierColor: Colors.black26,
    builder: (_) => _NotificationsPopover(onNavigate: onNavigate),
  );
}

class _NotificationsPopover extends ConsumerWidget {
  const _NotificationsPopover({required this.onNavigate});
  final void Function(String route) onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);

    return Dialog(
      alignment: Alignment.topRight,
      insetPadding: const EdgeInsets.only(top: 84, right: 24),
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        constraints: const BoxConstraints(maxHeight: 460),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorderPurple),
          boxShadow: AppShadows.cardHover,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_rounded,
                      size: 20, color: AppColors.accentSecondary),
                  const SizedBox(width: AppSpacing.sm),
                  const Text('التنبيهات', style: AppTypography.cardTitle),
                  const Spacer(),
                  Text('${notifications.length}',
                      style: const TextStyle(
                          color: AppColors.textTertiary, fontSize: 13)),
                ],
              ),
            ),
            const Divider(color: AppColors.glassBorder, height: 1),
            Flexible(
              child: notifications.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(AppSpacing.xl),
                      child: Center(
                        child: Text('مفيش تنبيهات — كل حاجة تمام',
                            style: TextStyle(color: AppColors.textTertiary)),
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: notifications.length,
                      itemBuilder: (_, i) {
                        final n = notifications[i];
                        return InkWell(
                          onTap: n.route == null
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  onNavigate(n.route!);
                                },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md, vertical: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(n.icon, size: 20, color: n.severity.color),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(n.title,
                                          style: const TextStyle(
                                              color: AppColors.textPrimary,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600)),
                                      const SizedBox(height: 2),
                                      Text(n.body,
                                          style: const TextStyle(
                                              color: AppColors.textSecondary,
                                              fontSize: 12)),
                                    ],
                                  ),
                                ),
                                if (n.route != null)
                                  const Icon(
                                      Icons.arrow_forward_ios_rounded,
                                      size: 12,
                                      color: AppColors.textTertiary),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}