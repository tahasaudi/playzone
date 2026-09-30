import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../core/utils/esc_handler_provider.dart';
import '../dashboard/dashboard_screen.dart';
import '../pos/pos_screen.dart';
import '../settings/pricing_settings_screen.dart';
import '../inventory/inventory_screen.dart';
import '../reports/reports_screen.dart';
import '../customers/customers_screen.dart';
import '../employees/employee_permissions_screen.dart';
import '../reservations/reservations_screen.dart';
import '../packages/packages_offers_screen.dart';
import '../reports/employee_performance_screen.dart';
import '../invoices/invoices_screen.dart';
import '../products/products_screen.dart';
import '../employees/employees_screen.dart';
import '../sessions/sessions_screen.dart';
import '../devices/devices_screen.dart';
import '../shifts/shifts_screen.dart';
import '../reports/statistics_screen.dart';
import '../audit/audit_log_screen.dart';
import '../settings/backup_screen.dart';
import '../settings/names_manager_screen.dart';
import '../accounting/accounting_screen.dart';
import '../expenses/expenses_screen.dart';
import '../refunds/refunds_screen.dart';
import '../inventory/stock_count_screen.dart';
import '../reports/protected_screen.dart';
import '../search/global_search_dialog.dart';
import '../tv/tv_broadcaster.dart';
import '../tv/tv_mode_screen.dart';
import '../tv/tv_screens_page.dart';
import '../../core/database/daos/device_dao.dart';
import '../../core/database/daos/session_dao.dart';
import '../../core/tv/tv_display_service.dart';
import '../../core/tv/tv_screen_report.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/session_repository.dart';
import 'sidebar.dart';
import 'top_bar.dart';
import 'app_nav_drawer.dart';

/// The main desktop shell: ambient background + floating sidebar +
/// top bar + main content area. Every screen renders inside [content].
///
/// Also owns the app's global keyboard shortcuts:
/// - ESC closes whatever's open — a real dialog/modal route, OR an
///   in-page overlay panel that registered itself via
///   [escCloseHandlerProvider] (e.g. the Session Details Panel).
/// - F1/F2/F3 jump straight to the most-used screens.
class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  String _activeRoute = 'dashboard';
  final FocusNode _shortcutsFocusNode = FocusNode();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _shortcutsFocusNode.dispose();
    super.dispose();
  }

  void _openDrawer() => _scaffoldKey.currentState?.openDrawer();

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    // Ctrl+K / Cmd+K — global search from anywhere.
    if (event.logicalKey == LogicalKeyboardKey.keyK &&
        (HardwareKeyboard.instance.isControlPressed ||
            HardwareKeyboard.instance.isMetaPressed)) {
      showGlobalSearchDialog(context, (route) {
        if (mounted) setState(() => _activeRoute = route);
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape) {
      // 1) An in-page overlay (like the session panel) registered a
      //    closer — give it first refusal.
      final overlayCloser = ref.read(escCloseHandlerProvider);
      if (overlayCloser != null) {
        overlayCloser();
        ref.read(escCloseHandlerProvider.notifier).state = null;
        return KeyEventResult.handled;
      }
      // 2) Otherwise, close a real dialog/modal route if one is open.
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.f1) {
      setState(() => _activeRoute = 'dashboard');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f2) {
      setState(() => _activeRoute = 'pos');
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.f3) {
      final role = ref.read(effectiveRoleProvider);
      if (routeAllowed('settings', role))
        setState(() => _activeRoute = 'settings');
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    // If the role changes (e.g. via the employee switcher) while the
    // user is on a screen they no longer have permission for, bounce
    // them back to the dashboard instead of leaving them on a page they
    // can't use.
    final role = ref.watch(effectiveRoleProvider);

    // TV wiring: each wall screen follows one machine. Starting a session
    // hands that screen back to HDMI (the console); collecting it paints
    // the screen black. Both are single commands, so nothing polls in the
    // background — we only discover the renderers while the app is idle so
    // the first session of the day does not pay for a port scan.
    final tvConfig = ref.watch(tvConfigProvider);
    // An unbound screen prints as UNBOUND, never "all". It used to print
    // "all", which reads as "follows every machine" when it in fact means
    // "follows nothing" — and that misreading is what left a wall screen
    // sitting black through every session while looking configured.
    TvDisplayService.configSummary = () => tvConfig.enabled
        ? 'on | ${tvConfig.ip}->${tvConfig.deviceId ?? "UNBOUND"}'
            '${tvConfig.hasSecond ? " | ${tvConfig.secondIp}->${tvConfig.secondDeviceId ?? "UNBOUND"}" : ""}'
        : 'off';

    // Tell the TV layer who each screen is, by name, and whether the machine
    // behind it is busy. That is what lets a sleeping panel be reported as the
    // normal thing it is, while a sleeping panel with a live session is
    // reported as the fault it is. The screens page does the same through its
    // own provider; setting it here as well keeps `/status` truthful even with
    // that page closed.
    final tvDevices = ref.watch(devicesWithTypeProvider).valueOrNull ??
        const <DeviceWithType>[];
    final tvBusy = {
      for (final s in ref.watch(activeSessionsProvider).valueOrNull ??
          const <SessionBoardEntry>[])
        s.device.id,
    };
    TvDisplayService.featureEnabled = tvConfig.enabled;
    TvDisplayService.screenIdentities = [
      for (final slot in tvConfig.identities)
        TvScreenIdentity(
          ip: slot.ip,
          name: slot.name,
          deviceId: slot.deviceId,
          deviceName: slot.deviceId == null
              ? null
              : tvDevices
                  .where((d) => d.device.id == slot.deviceId)
                  .map((d) => '${d.type.name} — ${d.device.name}')
                  .firstOrNull,
          sessionRunning: slot.deviceId != null && tvBusy.contains(slot.deviceId),
        ),
    ];

    if (tvConfig.enabled && tvConfig.addresses.isNotEmpty) {
      final tv = TvDisplayService.instance;
      if (!tv.isRunning) tv.startServer();
      if (tvConfig.showCards) {
        tv.startPushing(tvIp: tvConfig.ip);
      } else {
        for (final ip in tvConfig.addresses) {
          if (!tv.hasControlUrlFor(ip)) tv.warmUp(tvIp: ip);
        }
      }
      // Ask each screen once after startup, so the screens page can answer with a
      // fact instead of "we don't know yet". Two small requests, off the
      // critical path — and without them every screen reads as unproven for
      // the whole shift, which is the one answer a status panel must never
      // make someone settle for. Asked twice because a panel that is on but
      // still finishing its boot has no renderer to answer yet, and reporting
      // it as unproven would be wrong in the other direction.
      for (final wait in const [
        Duration(seconds: 3),
        Duration(seconds: 20),
      ]) {
        unawaited(Future<void>.delayed(wait, () {
          if (!mounted) return;
          TvDisplayService.instance.probeAll(tvConfig.addresses.toList());
        }));
      }
    }
    if (!routeAllowed(_activeRoute, role) && _activeRoute != 'dashboard') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _activeRoute = 'dashboard');
      });
    }

    return Focus(
      autofocus: true,
      focusNode: _shortcutsFocusNode,
      onKeyEvent: _handleKey,
      child: Scaffold(
        key: _scaffoldKey,
        drawer: AppNavDrawer(
          activeRoute: _activeRoute,
          onSelect: (route) => setState(() => _activeRoute = route),
        ),
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.appBackground),
          child: Stack(
            children: [
              // Aurora nebula — magenta core top-left, cosmic blue depth
              // bottom-right. Atmosphere, not distraction.
              const Positioned(
                top: -220,
                left: -180,
                child: _GlowBlob(
                  size: 720,
                  opacity: 0.30,
                  variant: _GlowVariant.auroraTop,
                ),
              ),
              const Positioned(
                bottom: -260,
                right: -200,
                child: _GlowBlob(
                  size: 780,
                  opacity: 0.22,
                  variant: _GlowVariant.nebulaBottom,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppTopBar(
                      title: _titleFor(_activeRoute),
                      subtitle: _subtitleFor(_activeRoute),
                      onMenuTap: _openDrawer,
                      onNavigate: (route) =>
                          setState(() => _activeRoute = route),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Expanded(child: _buildContent()),
                  ],
                ),
              ),
              // Live preview + background push to the LG TV, whatever
              // screen the cashier is on.
              const TvBroadcaster(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    switch (_activeRoute) {
      case 'dashboard':
        return const DashboardScreen();
      case 'pos':
        return const PosScreen();
      case 'settings':
        return PricingSettingsScreen(
          onNavigate: (route) => setState(() => _activeRoute = route),
        );
      case 'tv':
        return const TvModeScreen();
      case 'screens':
        return const TvScreensPage();
      case 'tv_full':
        return TvModeScreen(
          fullscreen: true,
          onExit: () => setState(() => _activeRoute = 'tv'),
        );
      case 'inventory':
        return const InventoryScreen();
      case 'reports':
        return const ReportsScreen();
      case 'customers':
        return const CustomersScreen();
      case 'employee_permissions':
        return const EmployeePermissionsScreen();
      case 'reservations':
        return const ReservationsScreen();
      case 'packages':
        return const PackagesOffersScreen();
      case 'employee_performance':
        return const EmployeePerformanceScreen();
      case 'invoices':
        return const InvoicesScreen();
      case 'products':
        return const ProductsScreen();
      case 'employees':
        return const EmployeesScreen();
      case 'sessions':
        return const SessionsScreen();
      case 'devices':
        return const DevicesScreen();
      case 'shifts':
        return const ShiftsScreen();
      case 'statistics':
        return const StatisticsScreen();
      case 'audit':
        return const AuditLogScreen();
      case 'accounting':
        return const AccountingScreen();
      case 'expenses':
        return const ExpensesScreen();
      case 'refunds':
        return const RefundsScreen();
      case 'stock_counts':
        return const StockCountScreen();
      case 'names_manager':
        return const NamesManagerScreen();
      case 'protected':
        return const ProtectedScreen();
      case 'backup':
        return const BackupScreen();
      default:
        return Center(
          child: Text(
            'شاشة "$_activeRoute" — قيد الإنشاء في المرحلة الجاية',
            style: const TextStyle(color: AppColors.textSecondary),
          ),
        );
    }
  }

  String _titleFor(String route) {
    switch (route) {
      case 'pos':
        return 'الكاشير';
      case 'settings':
        return 'الإعدادات';
      case 'inventory':
        return 'المخزون';
      case 'reports':
        return 'التقارير';
      case 'customers':
        return 'العملاء';
      case 'employee_permissions':
        return 'صلاحيات الموظفين';
      case 'reservations':
        return 'الحجوزات';
      case 'packages':
        return 'الباقات والعروض';
      case 'employee_performance':
        return 'أداء الموظفين';
      case 'invoices':
        return 'الفواتير';
      case 'products':
        return 'المنتجات';
      case 'employees':
        return 'الموظفين';
      case 'sessions':
        return 'الجلسات';
      case 'devices':
        return 'الأجهزة';
      case 'shifts':
        return 'الشيفتات';
      case 'statistics':
        return 'الإحصائيات';
      case 'audit':
        return 'سجل العمليات';
      case 'accounting':
        return 'الحسابات';
      case 'expenses':
        return 'المصروفات';
      case 'refunds':
        return 'المرتجعات';
      case 'stock_counts':
        return 'الجرد الدوري';
      case 'names_manager':
        return 'إدارة الأسماء';
      case 'protected':
        return 'الشاشة المحمية';
      case 'backup':
        return 'النسخ الاحتياطي';
      case 'screens':
        return 'شاشات الكافيه';
      default:
        return 'الرئيسية';
    }
  }

  String _subtitleFor(String route) {
    switch (route) {
      case 'pos':
        return 'بيع سريع من المنتجات والمشروبات — F2';
      case 'settings':
        return 'إدارة أسعار الأجهزة والنظام — F3';
      case 'inventory':
        return 'متابعة المخزون والأرباح';
      case 'reports':
        return 'أداء الكافيه بالأرقام';
      case 'customers':
        return 'إدارة بيانات العملاء والولاء';
      case 'employee_permissions':
        return 'تحكّم كامل فيما يظهر لكل موظف';
      case 'reservations':
        return 'حجز الأجهزة ومتابعة الوصول';
      case 'packages':
        return 'باقات بسعر ثابت وعروض ساعة';
      case 'employee_performance':
        return 'الإيرادات والفواتير لكل موظف';
      case 'invoices':
        return 'سجل عمليات البيع';
      case 'products':
        return 'كتالوج الكافيه';
      case 'employees':
        return 'فريق العمل';
      case 'sessions':
        return 'الجلسات الجارية والمحسوبة لحظة بلحظة';
      case 'devices':
        return 'حالة كل جهاز والأسعار الفعلية';
      case 'shifts':
        return 'سجل إقفال الخزنة';
      case 'statistics':
        return 'ملخص الإيرادات والمصروفات والأرباح';
      case 'audit':
        return 'كل عملية حساسة مسجّلة';
      case 'accounting':
        return 'أرصدة الحسابات وحركة القيد المزدوج';
      case 'expenses':
        return 'تسجيل المصروفات ومتابعة سجل العمليات';
      case 'refunds':
        return 'استرجاع دفعات العملاء ومرتجع البضاعة';
      case 'stock_counts':
        return 'حصيلة جرد الأصناف وضبط المخزون';
      case 'names_manager':
        return 'تعديل الأسماء في كل الكتالوج من مكان واحد';
      case 'protected':
        return 'الإيرادات والأرباح والإيراد المتوقع — برقم سري';
      case 'backup':
        return 'نسخ آمنة من قاعدة البيانات';
      case 'screens':
        return 'كل شاشة باسمها وحالتها لحظيًا';
      default:
        return 'مساء الخير 👋 — F1';
    }
  }
}

enum _GlowVariant { auroraTop, nebulaBottom }

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({
    required this.size,
    required this.opacity,
    required this.variant,
  });
  final double size;
  final double opacity;
  final _GlowVariant variant;

  @override
  Widget build(BuildContext context) {
    final gradient = switch (variant) {
      _GlowVariant.auroraTop => AppColors.auroraGlow(opacity: opacity),
      _GlowVariant.nebulaBottom => AppColors.nebulaGlow(opacity: opacity),
    };
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
        ),
      ),
    );
  }
}
