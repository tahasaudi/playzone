import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/auth/current_employee_provider.dart';
import '../../core/permissions/app_feature.dart';

class EmployeeFeatureRepository {
  EmployeeFeatureRepository(this._db);
  final AppDatabase _db;

  Stream<List<EmployeeFeatureOverrideRow>> watchForEmployee(int employeeId) =>
      _db.employeeFeatureDao.watchForEmployee(employeeId);

  Future<void> setOverride(int employeeId, AppFeature feature, bool visible) =>
      _db.employeeFeatureDao.setOverride(employeeId, feature.key, visible);

  Future<void> resetToDefault(int employeeId, AppFeature feature) =>
      _db.employeeFeatureDao.clearOverride(employeeId, feature.key);
}

final employeeFeatureRepositoryProvider = Provider<EmployeeFeatureRepository>((ref) {
  return EmployeeFeatureRepository(ref.watch(appDatabaseProvider));
});

/// Overrides for whichever employee is currently signed in (empty
/// stream/list if no employee is selected yet).
final currentEmployeeOverridesProvider =
    StreamProvider<List<EmployeeFeatureOverrideRow>>((ref) {
  final employee = ref.watch(currentEmployeeProvider);
  if (employee == null) return const Stream.empty();
  return ref.watch(employeeFeatureRepositoryProvider).watchForEmployee(employee.id);
});

/// The final, computed set of features visible to whoever is currently
/// signed in: role defaults with per-employee overrides applied on top.
/// Every screen/action visibility check in the app should read THIS
/// provider, never AppFeature.defaultsForRole directly, so an admin's
/// per-employee customization always wins.
final visibleFeaturesProvider = Provider<Set<AppFeature>>((ref) {
  final role = ref.watch(effectiveRoleProvider);
  final defaults = AppFeature.defaultsForRole(role);
  final overridesAsync = ref.watch(currentEmployeeOverridesProvider);

  final overrides = overridesAsync.value ?? const [];
  final result = Set<AppFeature>.from(defaults);

  for (final override in overrides) {
    final feature = AppFeature.fromKey(override.featureKey);
    if (feature == null) continue;
    if (override.visible) {
      result.add(feature);
    } else {
      result.remove(feature);
    }
  }

  return result;
});
