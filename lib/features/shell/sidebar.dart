import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/theme/app_theme.dart';
import '../../core/auth/role_provider.dart';

class NavItem {
  const NavItem(this.icon, this.labelAr, this.route);
  final IconData icon;
  final String labelAr;
  final String route;
}

const List<NavItem> mainNavItems = [
  NavItem(Icons.grid_view_rounded, 'الرئيسية', 'dashboard'),
  NavItem(Icons.sports_esports_rounded, 'الجلسات', 'sessions'),
  NavItem(Icons.point_of_sale_rounded, 'الكاشير', 'pos'),
  NavItem(Icons.devices_rounded, 'الأجهزة', 'devices'),
];

const List<NavItem> businessNavItems = [
  NavItem(Icons.people_alt_rounded, 'العملاء', 'customers'),
  NavItem(Icons.event_note_rounded, 'الحجوزات', 'reservations'),
  NavItem(Icons.local_offer_rounded, 'الباقات والعروض', 'packages'),
  NavItem(Icons.local_cafe_rounded, 'المنتجات', 'products'),
  NavItem(Icons.inventory_2_rounded, 'المخزون', 'inventory'),
  NavItem(Icons.fact_check_rounded, 'الجرد الدوري', 'stock_counts'),
  NavItem(Icons.assignment_return_rounded, 'المرتجعات', 'refunds'),
  NavItem(Icons.badge_rounded, 'الموظفين', 'employees'),
  NavItem(Icons.schedule_rounded, 'الشيفتات', 'shifts'),
];

const List<NavItem> analyticsNavItems = [
  NavItem(Icons.bar_chart_rounded, 'التقارير', 'reports'),
  NavItem(Icons.groups_rounded, 'أداء الموظفين', 'employee_performance'),
  NavItem(Icons.query_stats_rounded, 'الإحصائيات', 'statistics'),
  NavItem(Icons.account_balance_wallet_rounded, 'الحسابات', 'accounting'),
  NavItem(Icons.receipt_long_rounded, 'المصروفات', 'expenses'),
  NavItem(Icons.lock_rounded, 'الشاشة المحمية', 'protected'),
];

const List<NavItem> systemNavItems = [
  NavItem(Icons.settings_rounded, 'الإعدادات', 'settings'),
  NavItem(Icons.tv_rounded, 'شاشات الكافيه', 'screens'),
  NavItem(Icons.edit_note_rounded, 'إدارة الأسماء', 'names_manager'),
  NavItem(Icons.admin_panel_settings_rounded, 'صلاحيات الموظفين',
      'employee_permissions'),
  NavItem(Icons.history_rounded, 'سجل العمليات', 'audit'),
  NavItem(Icons.backup_rounded, 'النسخ الاحتياطي', 'backup'),
];

/// Routes that require a permission beyond the baseline. A cashier will
/// see these greyed out with a lock icon instead of hidden entirely —
/// staff should see what exists, just not be able to open it.
bool routeAllowed(String route, UserRole role) {
  switch (route) {
    case 'settings':
      return role.canEditPrices;
    // The wall screens are shop equipment: a cashier has to be able to see
    // which one is broken and turn it off, even if only a manager re-binds a
    // screen to a machine. Gating the whole page would hide the one thing it
    // exists to show.
    case 'screens':
      return true;
    case 'reports':
    case 'statistics':
    case 'audit':
    case 'employee_performance':
      return role.canViewReports;
    case 'employees':
    case 'employee_permissions':
      return role.canManageUsers;
    case 'accounting':
    case 'expenses':
    case 'refunds':
      // Ledger, expenses and refunds share the reports audience.
      return role.canViewReports;
    case 'stock_counts':
      // Periodic stock count touches real inventory — admin-only (mirrors
      // PermissionService.canStockCount).
      return role == UserRole.admin;
    case 'names_manager':
      // Renaming catalog entities is an admin concern.
      return role.canEditPrices;
    case 'backup':
      return role == UserRole.admin;
    default:
      return true;
  }
}

class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    super.key,
    required this.activeRoute,
    required this.onSelect,
  });

  final String activeRoute;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(currentRoleProvider);
    return Container(
      width: AppSpacing.sidebarWidth,
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.md, AppSpacing.md, 0, AppSpacing.md),
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: AppRadius.largeR,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Logo(),
          const SizedBox(height: AppSpacing.xl),
          Expanded(
            child: ListView(
              children: [
                const _SectionLabel('الرئيسية'),
                ...mainNavItems.map((i) => _buildItem(i, role)),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel('الأعمال'),
                ...businessNavItems.map((i) => _buildItem(i, role)),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel('التحليلات'),
                ...analyticsNavItems.map((i) => _buildItem(i, role)),
                const SizedBox(height: AppSpacing.lg),
                const _SectionLabel('النظام'),
                ...systemNavItems.map((i) => _buildItem(i, role)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItem(NavItem item, UserRole role) {
    final allowed = routeAllowed(item.route, role);
    return _SidebarItem(
      item: item,
      active: activeRoute == item.route,
      locked: !allowed,
      onTap: allowed ? () => onSelect(item.route) : null,
    );
  }
}

class _Logo extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryButtonGradient,
            borderRadius: AppRadius.mediumR,
          ),
          child: const Icon(Icons.sports_esports_rounded,
              color: Colors.white, size: 22),
        ),
        const SizedBox(width: AppSpacing.sm),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('PLAYZONE',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  letterSpacing: 1,
                )),
            Text('Gaming Café',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 11)),
          ],
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.md, 0, 6),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textTertiary,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  const _SidebarItem({
    required this.item,
    required this.active,
    required this.onTap,
    this.locked = false,
  });

  final NavItem item;
  final bool active;
  final bool locked;
  final VoidCallback? onTap;

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final locked = widget.locked;
    final bg = active
        ? AppColors.accentPrimary.withOpacity(0.18)
        : _hovering && !locked
            ? AppColors.glassFillStrong
            : Colors.transparent;
    final fg = locked
        ? AppColors.textTertiary
        : active
            ? AppColors.textPrimary
            : AppColors.textSecondary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: locked ? SystemMouseCursors.forbidden : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppTheme.hoverDuration,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: AppRadius.mediumR,
            border:
                active ? Border.all(color: AppColors.glassBorderPurple) : null,
          ),
          child: Row(
            children: [
              Icon(
                widget.item.icon,
                size: 19,
                color: locked
                    ? AppColors.textTertiary
                    : active
                        ? AppColors.accentSecondary
                        : AppColors.textSecondary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  widget.item.labelAr,
                  style: TextStyle(
                    color: fg,
                    fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ),
              if (locked)
                const Icon(Icons.lock_rounded,
                    size: 13, color: AppColors.textTertiary),
            ],
          ),
        ),
      ),
    );
  }
}
