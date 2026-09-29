import '../auth/role_provider.dart';

/// Every screen, section, and sensitive action in the app that an admin
/// can individually show or hide per employee. This is the "شامل لكل
/// حاجة" list — if it's a nav item or a sensitive action anywhere in
/// PlayZone, it has an entry here.
///
/// Adding a new screen/action later just means adding one more value +
/// wiring one `isVisible(AppFeature.x)` check at the point it's used —
/// the override storage and the Employee Permissions screen need no
/// changes.
enum AppFeature {
  // Navigation / screens
  dashboard('dashboard', 'الرئيسية'),
  pos('pos', 'الكاشير'),
  devicesScreen('devices_screen', 'شاشة الأجهزة'),
  sessionsScreen('sessions_screen', 'الشاشة الجلسات'),
  customersScreen('customers_screen', 'العملاء'),
  productsScreen('products_screen', 'المنتجات'),
  inventoryScreen('inventory_screen', 'المخزون'),
  employeesScreen('employees_screen', 'الموظفين'),
  shiftsScreen('shifts_screen', 'الشيفتات'),
  reportsScreen('reports_screen', 'التقارير'),
  auditScreen('audit_screen', 'سجل العمليات'),
  settingsScreen('settings_screen', 'الإعدادات'),
  backupScreen('backup_screen', 'النسخ الاحتياطي'),
  employeePermissionsScreen('employee_permissions_screen', 'صلاحيات الموظفين'),
  reservationsScreen('reservations_screen', 'الحجوزات'),
  packagesOffersScreen('packages_offers_screen', 'الباقات والعروض'),
  employeePerformanceScreen(
      'employee_performance_screen', 'أداء الموظفين'),
  accountingScreen('accounting_screen', 'شاشة الحسابات'),
  expensesScreen('expenses_screen', 'المصروفات'),
  expenseLogScreen('expense_log_screen', 'سجل عمليات المصروفات'),
  refundsScreen('refunds_screen', 'المرتجعات'),
  stockCountScreen('stock_count_screen', 'الجرد الدوري'),
  namesManagerScreen('names_manager_screen', 'إدارة الأسماء'),
  protectedScreen('protected_screen', 'الشاشة المحمية'),

  // Sensitive actions
  changePrice('change_price', 'تغيير الأسعار'),
  applyDiscount('apply_discount', 'عمل خصم'),
  refund('refund', 'استرداد'),
  cancelInvoice('cancel_invoice', 'إلغاء فاتورة'),
  adjustStock('adjust_stock', 'تعديل المخزون'),
  manageEmployees('manage_employees', 'إدارة الموظفين'),
  closeShift('close_shift', 'إقفال الشيفت'),
  backupRestore('backup_restore', 'نسخ احتياطي/استرجاع'),
  viewProductCost('view_product_cost', 'رؤية تكلفة المنتج'),

  // Dashboard locked metrics — each is its own permission. Their numbers
  // live on the dedicated PIN-protected screen (الشاشة المحمية), never
  // on the dashboard itself.
  viewPerformance('view_performance', 'أداء اليوم'),
  viewDailyRevenue('view_daily_revenue', 'الإيراد اليومي'),
  viewDailyExpenses('view_daily_expenses', 'مصروفات اليوم'),
  viewDailyProfit('view_daily_profit', 'الربح اليومي'),
  viewGamingRevenue('view_gaming_revenue', 'إيراد الألعاب'),
  viewSessionCount('view_session_count', 'الجلسات الشغّالة'),
  viewExpectedRevenue(
      'view_expected_revenue', 'الإيراد المتوقع'),
  viewEmployeeRevenueBreakdown(
      'view_employee_revenue_breakdown', 'مشاهدة إيراد كل موظف على حدة');

  const AppFeature(this.key, this.labelAr);
  final String key;
  final String labelAr;

  static AppFeature? fromKey(String key) =>
      AppFeature.values.where((f) => f.key == key).firstOrNull;

  /// Role-based defaults — the starting point before any per-employee
  /// override is applied. Mirrors the existing UserRoleX booleans in
  /// role_provider.dart so nothing changes for an employee until an
  /// admin explicitly customizes them.
  static Set<AppFeature> defaultsForRole(UserRole role) {
    final always = <AppFeature>{
      AppFeature.dashboard,
      AppFeature.pos,
      AppFeature.devicesScreen,
      AppFeature.customersScreen,
      AppFeature.productsScreen,
      AppFeature.inventoryScreen,
      AppFeature.applyDiscount,
      AppFeature.reservationsScreen,
      AppFeature.packagesOffersScreen,
    };

    switch (role) {
      case UserRole.admin:
        return AppFeature.values.toSet(); // everything
      case UserRole.shiftSupervisor:
        return {
          ...always,
          AppFeature.sessionsScreen,
          AppFeature.shiftsScreen,
          AppFeature.reportsScreen,
          AppFeature.auditScreen,
          AppFeature.accountingScreen,
          AppFeature.expensesScreen,
          AppFeature.expenseLogScreen,
          AppFeature.employeePerformanceScreen,
          AppFeature.protectedScreen,
          AppFeature.closeShift,
          AppFeature.viewPerformance,
          AppFeature.viewDailyRevenue,
          AppFeature.viewDailyExpenses,
          AppFeature.viewDailyProfit,
          AppFeature.viewGamingRevenue,
          AppFeature.viewSessionCount,
          AppFeature.viewExpectedRevenue,
        };
      case UserRole.cashier:
        return always;
    }
  }
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
