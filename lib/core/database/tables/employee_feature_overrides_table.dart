import 'package:drift/drift.dart';
import 'employees_table.dart';

/// A per-employee override of one app feature's visibility. Only
/// OVERRIDES are stored here — if no row exists for
/// (employeeId, featureKey), the feature falls back to that employee's
/// role default (see AppFeature.defaultsForRole). This keeps the table
/// small: an admin who never customizes anyone's permissions has zero
/// rows here, not one row per feature per employee.
@DataClassName('EmployeeFeatureOverrideRow')
class EmployeeFeatureOverrides extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get employeeId => integer().references(Employees, #id)();
  TextColumn get featureKey => text()(); // matches AppFeature.key
  BoolColumn get visible => boolean()();

  @override
  List<Set<Column>> get uniqueKeys => [
        {employeeId, featureKey},
      ];
}
