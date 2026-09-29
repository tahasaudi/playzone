// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_feature_dao.dart';

// ignore_for_file: type=lint
mixin _$EmployeeFeatureDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $EmployeeFeatureOverridesTable get employeeFeatureOverrides =>
      attachedDatabase.employeeFeatureOverrides;
  EmployeeFeatureDaoManager get managers => EmployeeFeatureDaoManager(this);
}

class EmployeeFeatureDaoManager {
  final _$EmployeeFeatureDaoMixin _db;
  EmployeeFeatureDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$EmployeeFeatureOverridesTableTableManager get employeeFeatureOverrides =>
      $$EmployeeFeatureOverridesTableTableManager(
          _db.attachedDatabase, _db.employeeFeatureOverrides);
}
