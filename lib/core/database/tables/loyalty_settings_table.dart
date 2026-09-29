import 'package:drift/drift.dart';

/// Single-row Loyalty program configuration (id is always 1).
/// - [pointsPerCurrency]: how many loyalty points a customer earns per
///   EGP paid (1 → 1 point per EGP).
/// - [minimumRedeemPoints]: the floor before points can be spent at
///   checkout (e.g. 100 points).
/// - [pointValueEGP]: how much one point is worth when redeemed (1 →
///   100 points = EGP 100 off).
///
/// The row is created/updated by the loyalty settings tab; the math is
/// shared through LoyaltyMath so the invoice writer can't drift from the
/// UI preview.
@DataClassName('LoyaltySettingsRow')
class LoyaltySettings extends Table {
  IntColumn get id => integer().autoIncrement()();
  RealColumn get pointsPerCurrency =>
      real().withDefault(const Constant(1))();
  IntColumn get minimumRedeemPoints =>
      integer().withDefault(const Constant(100))();
  RealColumn get pointValueEGP => real().withDefault(const Constant(1))();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();
}