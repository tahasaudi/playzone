// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation_dao.dart';

// ignore_for_file: type=lint
mixin _$ReservationDaoMixin on DatabaseAccessor<AppDatabase> {
  $CustomersTable get customers => attachedDatabase.customers;
  $DeviceTypesTable get deviceTypes => attachedDatabase.deviceTypes;
  $DevicesTable get devices => attachedDatabase.devices;
  $EmployeesTable get employees => attachedDatabase.employees;
  $ReservationsTable get reservations => attachedDatabase.reservations;
  ReservationDaoManager get managers => ReservationDaoManager(this);
}

class ReservationDaoManager {
  final _$ReservationDaoMixin _db;
  ReservationDaoManager(this._db);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$DeviceTypesTableTableManager get deviceTypes =>
      $$DeviceTypesTableTableManager(_db.attachedDatabase, _db.deviceTypes);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$ReservationsTableTableManager get reservations =>
      $$ReservationsTableTableManager(_db.attachedDatabase, _db.reservations);
}
