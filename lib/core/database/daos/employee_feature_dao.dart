import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/employee_feature_overrides_table.dart';

part 'employee_feature_dao.g.dart';

@DriftAccessor(tables: [EmployeeFeatureOverrides])
class EmployeeFeatureDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeeFeatureDaoMixin {
  EmployeeFeatureDao(super.db);

  Stream<List<EmployeeFeatureOverrideRow>> watchForEmployee(int employeeId) =>
      (select(employeeFeatureOverrides)
            ..where((o) => o.employeeId.equals(employeeId)))
          .watch();

  /// Sets an explicit show/hide override for one feature. Upserts by the
  /// (employeeId, featureKey) unique key defined on the table.
  Future<void> setOverride(int employeeId, String featureKey, bool visible) {
    return into(employeeFeatureOverrides).insertOnConflictUpdate(
      EmployeeFeatureOverridesCompanion.insert(
        employeeId: employeeId,
        featureKey: featureKey,
        visible: visible,
      ),
    );
  }

  /// Removes the override so the feature falls back to the employee's
  /// role default.
  Future<void> clearOverride(int employeeId, String featureKey) {
    return (delete(employeeFeatureOverrides)
          ..where((o) => o.employeeId.equals(employeeId) & o.featureKey.equals(featureKey)))
        .go();
  }
}
