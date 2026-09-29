import 'package:drift/drift.dart';

/// A happy-hour style offer: an active offer whose [startHour]..[endHour]
/// window contains the current hour applies to a checkout. The window is
/// kept deliberately simple (whole hours 0-23) since this is an offline,
/// single-device POS — no timezone/DST hair.
@DataClassName('OfferRow')
class Offers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get discountType => text()(); // 'percentage' | 'fixed'
  RealColumn get discountValue => real().withDefault(const Constant(0))();
  IntColumn get startHour => integer().withDefault(const Constant(0))();
  IntColumn get endHour => integer().withDefault(const Constant(23))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}