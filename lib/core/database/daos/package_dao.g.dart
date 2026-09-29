// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'package_dao.dart';

// ignore_for_file: type=lint
mixin _$PackageDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeviceTypesTable get deviceTypes => attachedDatabase.deviceTypes;
  $PackagesTable get packages => attachedDatabase.packages;
  PackageDaoManager get managers => PackageDaoManager(this);
}

class PackageDaoManager {
  final _$PackageDaoMixin _db;
  PackageDaoManager(this._db);
  $$DeviceTypesTableTableManager get deviceTypes =>
      $$DeviceTypesTableTableManager(_db.attachedDatabase, _db.deviceTypes);
  $$PackagesTableTableManager get packages =>
      $$PackagesTableTableManager(_db.attachedDatabase, _db.packages);
}
