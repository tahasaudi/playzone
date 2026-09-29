import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/auth/role_provider.dart';
import '../../core/auth/current_employee_provider.dart';
import 'sidebar.dart';

/// The slide-in navigation drawer (opened from the top-bar menu button).
/// Renders the same sections as the old fixed sidebar — logo, groups and
/// per-route permission locks — but lives in a slide-out panel instead.
class AppNavDrawer extends ConsumerWidget {
  const AppNavDrawer({
    super.key,
    required this.activeRoute,
    required this.onSelect,
  });

  final String activeRoute;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(effectiveRoleProvider);

    return Drawer(
      backgroundColor: Colors.transparent,
      width: 280,
      shape: const RoundedRectangleBorder(),
      child: Container(
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: AppSpacing.lg),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: AppRadius.largeR,
          border: Border.all(color: AppColors.glassBorder),
          boxShadow: AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Brand
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryButtonGradient,
                    borderRadius: AppRadius.mediumR,
                  ),
                  child: const Icon(Icons.sports_esports_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PLAYZONE',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: 1.2)),
                    Text('Gaming Café',
                        style: TextStyle(
                            fontSize: 11, color: AppColors.textTertiary)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const _Label('الرئيسية'),
                  _section(context, mainNavItems, role),
                  const _Label('الأعمال'),
                  _section(context, businessNavItems, role),
                  const _Label('التحليلات'),
                  _section(context, analyticsNavItems, role),
                  const _Label('النظام'),
                  _section(context, systemNavItems, role),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _section(BuildContext context, List<NavItem> items, UserRole role) {
    return Column(
      children: [
        for (final item in items)
          _DrawerItem(
            item: item,
            active: item.route == activeRoute,
            locked: !routeAllowed(item.route, role),
            onTap: () {
              Navigator.of(context).pop();
              onSelect(item.route);
            },
          ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: AppSpacing.xs),
      child: Text(text,
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary)),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  const _DrawerItem({
    required this.item,
    required this.active,
    required this.locked,
    required this.onTap,
  });

  final NavItem item;
  final bool active;
  final bool locked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fg = locked
        ? AppColors.textTertiary
        : active
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: InkWell(
        borderRadius: AppRadius.mediumR,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: active ? AppColors.accentPrimary.withOpacity(0.18) : null,
            borderRadius: AppRadius.mediumR,
            border:
                active ? Border.all(color: AppColors.glassBorderPurple) : null,
          ),
          child: Row(
            children: [
              Icon(item.icon,
                  size: 19, color: active ? AppColors.accentSecondary : fg),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(item.labelAr,
                    style: TextStyle(
                        fontSize: 13,
                        color: fg,
                        fontWeight:
                            active ? FontWeight.w600 : FontWeight.w400)),
              ),
              if (locked)
                const Icon(Icons.lock_rounded,
                    size: 14, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
