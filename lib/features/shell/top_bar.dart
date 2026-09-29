import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../core/auth/role_provider.dart';
import '../../data/repositories/employee_repository.dart';
import '../../data/repositories/notification_repository.dart';
import 'sidebar.dart';
import 'notification_popover.dart';
import 'shift_close_dialog.dart';

class AppTopBar extends ConsumerWidget {
  const AppTopBar({
    super.key,
    required this.title,
    required this.subtitle,
    this.isOffline = true,
    this.onMenuTap,
    this.onNavigate,
  });

  final String title;
  final String subtitle;
  final bool isOffline;
  final VoidCallback? onMenuTap;
  final void Function(String route)? onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(effectiveRoleProvider);
    final employee = ref.watch(currentEmployeeProvider);

    return SizedBox(
      height: AppSpacing.topBarHeight,
      child: Row(
        children: [
          // Menu button — opens the navigation drawer.
          _TopIconButton(
            icon: Icons.menu_rounded,
            tooltip: 'القائمة',
            onTap: onMenuTap,
          ),
          const SizedBox(width: AppSpacing.sm),

          // Quick jumps: the two screens the staff live in. One click
          // instead of opening the drawer (or remembering F1 / F2).
          _TopIconButton(
            icon: Icons.dashboard_rounded,
            tooltip: 'الشاشة الرئيسية (F1)',
            onTap: () => onNavigate?.call('dashboard'),
          ),
          const SizedBox(width: AppSpacing.sm),
          _TopIconButton(
            icon: Icons.point_of_sale_rounded,
            tooltip: 'الكاشير (F2)',
            onTap: () => onNavigate?.call('pos'),
          ),
          const SizedBox(width: AppSpacing.sm),
          // The wall screen that gets pushed/cast to the LG TV.
          _TopIconButton(
            icon: Icons.tv_rounded,
            tooltip: 'شاشة التلفزيون',
            onTap: () => onNavigate?.call('tv'),
          ),
          const SizedBox(width: AppSpacing.md),

          // Settings shortcut — goes straight to the pricing/system page.
          if (routeAllowed('settings', role)) ...[
            _TopIconButton(
              icon: Icons.settings_rounded,
              tooltip: 'الإعدادات (F3)',
              onTap: () => onNavigate?.call('settings'),
            ),
            const SizedBox(width: AppSpacing.md),
          ],

          // Left: page title + subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.textSecondary)),
              ],
            ),
          ),

          // Offline / connection indicator
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            margin: const EdgeInsets.only(left: AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: AppRadius.smallR,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color:
                        isOffline ? AppColors.textTertiary : AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isOffline ? 'وضع أوفلاين' : 'متصل',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),

          const SizedBox(width: AppSpacing.md),

          // Close-shift icon — spec: an icon on the home screen to close
          // the shift. Only shown to whoever has that permission.
          _CloseShiftIcon(),

          const SizedBox(width: AppSpacing.sm),

          // Employee switcher — temporary stand-in for real PIN login.
          // Selecting an employee here drives BOTH the role AND every
          // per-employee permission override, plus attributes new
          // sessions/invoices to that employee for revenue reporting.
          const _EmployeeSwitcher(),

          const SizedBox(width: AppSpacing.md),

          _NotificationBell(onNavigate: onNavigate),

          const SizedBox(width: AppSpacing.sm),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              borderRadius: AppRadius.mediumR,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 15,
                  backgroundColor: AppColors.accentPrimary,
                  child: Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(employee?.name ?? 'بدون تسجيل',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary)),
                    Text(role.labelAr,
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TopIconButton extends StatelessWidget {
  const _TopIconButton({
    required this.icon,
    this.tooltip,
    this.onTap,
  });

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip ?? '',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.glassFill,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.glassBorder),
            ),
            child: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _EmployeeSwitcher extends ConsumerWidget {
  const _EmployeeSwitcher();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(activeEmployeesProvider);
    final current = ref.watch(currentEmployeeProvider);

    return employeesAsync.when(
      loading: () => const SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, __) => const SizedBox.shrink(),
      data: (employees) {
        if (employees.isEmpty) return const SizedBox.shrink();
        final value =
            current != null && employees.any((e) => e.id == current.id)
                ? current
                : employees.first;

        // Auto-select the first employee on first load so
        // effectiveRoleProvider has something real to derive from.
        if (current == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(currentEmployeeProvider.notifier).setEmployee(value);
          });
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: AppRadius.smallR,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: value.id,
              dropdownColor: AppColors.bgElevated,
              icon: const Icon(Icons.expand_more_rounded,
                  size: 16, color: AppColors.textSecondary),
              style:
                  const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              items: employees
                  .map(
                      (e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                  .toList(),
              onChanged: (id) {
                final selected = employees.firstWhere((e) => e.id == id);
                ref
                    .read(currentEmployeeProvider.notifier)
                    .setEmployee(selected);
              },
            ),
          ),
        );
      },
    );
  }
}

class _CloseShiftIcon extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GestureDetector(
      onTap: () => showShiftCloseDialog(context, ref),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.glassFill,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.glassBorder),
        ),
        child: const Icon(Icons.lock_clock_rounded,
            size: 18, color: AppColors.warning),
      ),
    );
  }
}

class _NotificationBell extends ConsumerStatefulWidget {
  const _NotificationBell({this.onNavigate});
  final void Function(String route)? onNavigate;

  @override
  ConsumerState<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<_NotificationBell> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final count = ref.watch(notificationsProvider).length;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: () => showNotificationsPopover(
          context,
          widget.onNavigate ?? (_) {},
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color:
                    _hovering ? AppColors.glassFillStrong : AppColors.glassFill,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.glassBorder),
              ),
              child: Icon(
                count > 0
                    ? Icons.notifications_rounded
                    : Icons.notifications_none_rounded,
                size: 19,
                color: count > 0
                    ? AppColors.accentSecondary
                    : AppColors.textSecondary,
              ),
            ),
            if (count > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.danger,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.bgElevated, width: 1.5),
                  ),
                  child: Text(
                    count > 9 ? '9+' : '$count',
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.white,
                        fontWeight: FontWeight.w700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
