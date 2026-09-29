// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'employee_dao.dart';

// ignore_for_file: type=lint
mixin _$EmployeeDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $EmployeeTransactionsTable get employeeTransactions =>
      attachedDatabase.employeeTransactions;
  $EmployeeAttendanceTable get employeeAttendance =>
      attachedDatabase.employeeAttendance;
  EmployeeDaoManager get managers => EmployeeDaoManager(this);
}

class EmployeeDaoManager {
  final _$EmployeeDaoMixin _db;
  EmployeeDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$EmployeeTransactionsTableTableManager get employeeTransactions =>
      $$EmployeeTransactionsTableTableManager(
          _db.attachedDatabase, _db.employeeTransactions);
  $$EmployeeAttendanceTableTableManager get employeeAttendance =>
      $$EmployeeAttendanceTableTableManager(
          _db.attachedDatabase, _db.employeeAttendance);
}
