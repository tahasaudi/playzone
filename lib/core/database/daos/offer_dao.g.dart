// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'offer_dao.dart';

// ignore_for_file: type=lint
mixin _$OfferDaoMixin on DatabaseAccessor<AppDatabase> {
  $OffersTable get offers => attachedDatabase.offers;
  OfferDaoManager get managers => OfferDaoManager(this);
}

class OfferDaoManager {
  final _$OfferDaoMixin _db;
  OfferDaoManager(this._db);
  $$OffersTableTableManager get offers =>
      $$OffersTableTableManager(_db.attachedDatabase, _db.offers);
}
