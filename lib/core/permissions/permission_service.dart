import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../auth/role_provider.dart';
import '../auth/current_employee_provider.dart';

/// Thrown when a repository/service method is called by a role that
/// isn't allowed to perform that action. The UI should normally prevent
/// this from ever happening (locked sidebar items, disabled buttons) —
/// this exception is the safety net for spec §22: "UI restrictions are
/// NOT enough. Business logic must also validate permissions."
class PermissionDeniedException implements Exception {
  PermissionDeniedException(this.action);
  final String action;

  @override
  String toString() => 'لا يمكن تنفيذ العملية بصلاحياتك الحالية: $action';
}

/// Centralized permission checks — spec §22 (PermissionService). Reads
/// the current role from [currentRoleProvider] and exposes both the raw
/// booleans (for UI — hide/disable) and a [require] helper (for
/// repositories/services — throw if not allowed).
///
/// The permission matrix itself still lives on [UserRoleX] in
/// role_provider.dart (single source of truth for the boolean rules);
/// this service is the enforcement point that both UI and business
/// logic go through.
class PermissionService {
  PermissionService(this._role);
  final UserRole _role;

  bool get canStartSession => true; // all 3 roles
  bool get canSellProducts => true; // all 3 roles
  bool get canApplyDiscount => _role.canApplyDiscount;
  bool get canViewReports => _role.canViewReports;
  bool get canChangePrice => _role.canEditPrices;
  bool get canManageEmployees => _role.canManageUsers;
  bool get canManageUsers => _role.canManageUsers;
  bool get canBackupRestore => _role == UserRole.admin;

  /// Admin-only, non-configurable (system settings / locked-PIN setup).
  bool get canEditSettings => _role == UserRole.admin;

  /// Seeing a product's cost price is a configurable, admin-side view.
  bool get canViewProductCost => _role.canViewCost;

  /// Ledger ("شاشة حسابات") visibility — same audience as the reports.
  bool get canViewAccounting => _role.canViewReports;

  /// Periodic stock count ("جرد دوري") — takes product inventory right
  /// now, so admin-only until a settings toggle makes it configurable.
  bool get canStockCount => _role == UserRole.admin;

  /// Refund/Cancel/StockAdjustment are "configurable" per spec §6 — for
  /// now admin-only, same as price changes, until a settings toggle for
  /// shift-supervisor-level exists.
  bool get canRefund => _role == UserRole.admin;
  bool get canCancelInvoice => _role == UserRole.admin;
  bool get canAdjustStock => _role == UserRole.admin;

  /// Throws [PermissionDeniedException] if [allowed] is false. Call this
  /// at the top of any repository method that performs a sensitive
  /// write, passing a human-readable Arabic description of the action.
  void require(bool allowed, String action) {
    if (!allowed) throw PermissionDeniedException(action);
  }
}

final permissionServiceProvider = Provider<PermissionService>((ref) {
  final role = ref.watch(effectiveRoleProvider);
  return PermissionService(role);
});
