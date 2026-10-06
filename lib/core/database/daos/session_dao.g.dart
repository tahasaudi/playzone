// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_dao.dart';

// ignore_for_file: type=lint
mixin _$SessionDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeviceTypesTable get deviceTypes => attachedDatabase.deviceTypes;
  $DevicesTable get devices => attachedDatabase.devices;
  $CustomersTable get customers => attachedDatabase.customers;
  $EmployeesTable get employees => attachedDatabase.employees;
  $PackagesTable get packages => attachedDatabase.packages;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $SessionEventsTable get sessionEvents => attachedDatabase.sessionEvents;
  SessionDaoManager get managers => SessionDaoManager(this);
}

class SessionDaoManager {
  final _$SessionDaoMixin _db;
  SessionDaoManager(this._db);
  $$DeviceTypesTableTableManager get deviceTypes =>
      $$DeviceTypesTableTableManager(_db.attachedDatabase, _db.deviceTypes);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$PackagesTableTableManager get packages =>
      $$PackagesTableTableManager(_db.attachedDatabase, _db.packages);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$SessionEventsTableTableManager get sessionEvents =>
      $$SessionEventsTableTableManager(_db.attachedDatabase, _db.sessionEvents);
}
