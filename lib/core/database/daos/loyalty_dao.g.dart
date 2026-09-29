// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loyalty_dao.dart';

// ignore_for_file: type=lint
mixin _$LoyaltyDaoMixin on DatabaseAccessor<AppDatabase> {
  $LoyaltySettingsTable get loyaltySettings => attachedDatabase.loyaltySettings;
  $CustomersTable get customers => attachedDatabase.customers;
  LoyaltyDaoManager get managers => LoyaltyDaoManager(this);
}

class LoyaltyDaoManager {
  final _$LoyaltyDaoMixin _db;
  LoyaltyDaoManager(this._db);
  $$LoyaltySettingsTableTableManager get loyaltySettings =>
      $$LoyaltySettingsTableTableManager(
          _db.attachedDatabase, _db.loyaltySettings);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
}
