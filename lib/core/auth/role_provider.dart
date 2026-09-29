import 'package:flutter_riverpod/flutter_riverpod.dart';

enum UserRole { admin, shiftSupervisor, cashier }

extension UserRoleX on UserRole {
  String get labelAr {
    switch (this) {
      case UserRole.admin:
        return 'أدمن';
      case UserRole.shiftSupervisor:
        return 'مشرف شيفت';
      case UserRole.cashier:
        return 'كاشير';
    }
  }

  /// Can edit device/product prices (Settings → Pricing).
  bool get canEditPrices => this == UserRole.admin;

  /// Can view Reports / Analytics / Audit Log screens.
  bool get canViewReports =>
      this == UserRole.admin || this == UserRole.shiftSupervisor;

  /// Can manage user accounts and their roles.
  bool get canManageUsers => this == UserRole.admin;

  /// Can open sessions, sell in POS, apply a discount at checkout.
  /// All three roles can do this — it's the baseline operational permission.
  bool get canManageSessions => true;
  bool get canApplyDiscount => true;

  /// Can see product cost prices (POS/product admin + reports).
  bool get canViewCost => this == UserRole.admin;
}

/// Holds the currently logged-in user's role. There's no login screen yet,
/// so this is switchable from the top bar for testing — it'll be set by
/// the real PIN login once that screen is built.
class RoleNotifier extends StateNotifier<UserRole> {
  RoleNotifier() : super(UserRole.admin);
  void setRole(UserRole role) => state = role;
}

final currentRoleProvider = StateNotifierProvider<RoleNotifier, UserRole>(
  (ref) => RoleNotifier(),
);
