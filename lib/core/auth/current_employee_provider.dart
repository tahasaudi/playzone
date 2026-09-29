import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import 'role_provider.dart';

/// The employee currently "signed in" at this terminal. There's still no
/// PIN entry screen — this is set via a dropdown of real employees in
/// the TopBar — but unlike the old bare role switcher, it's tied to an
/// actual Employees row. That's what makes per-employee permission
/// overrides and "revenue by employee" possible: both need to know
/// WHICH employee, not just which role.
class CurrentEmployeeNotifier extends StateNotifier<EmployeeRow?> {
  CurrentEmployeeNotifier() : super(null);
  void setEmployee(EmployeeRow employee) => state = employee;
}

final currentEmployeeProvider =
    StateNotifierProvider<CurrentEmployeeNotifier, EmployeeRow?>(
  (ref) => CurrentEmployeeNotifier(),
);

/// Derives the effective [UserRole] from whichever employee is
/// currently selected, falling back to [currentRoleProvider]'s manual
/// switcher only if no employee has been picked yet (e.g. right after
/// app launch, before the TopBar dropdown has loaded anyone).
final effectiveRoleProvider = Provider<UserRole>((ref) {
  final employee = ref.watch(currentEmployeeProvider);
  if (employee == null) return ref.watch(currentRoleProvider);

  switch (employee.role) {
    case 'admin':
      return UserRole.admin;
    case 'shiftSupervisor':
      return UserRole.shiftSupervisor;
    default:
      return UserRole.cashier;
  }
});
