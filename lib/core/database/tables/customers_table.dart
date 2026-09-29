import 'package:drift/drift.dart';

/// Customer record — spec §9. totalVisits/totalSpent/loyaltyPoints are
/// running totals maintained by the (future) Sessions/Orders/Loyalty
/// services, not edited directly by the user.
@DataClassName('CustomerRow')
class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get phone => text().withLength(min: 1, max: 20)();
  TextColumn get email => text().nullable()();
  TextColumn get notes => text().nullable()();
  IntColumn get totalVisits => integer().withDefault(const Constant(0))();
  RealColumn get totalSpent => real().withDefault(const Constant(0))();
  IntColumn get loyaltyPoints => integer().withDefault(const Constant(0))();
  // Regular | Silver | Gold | VIP
  TextColumn get customerLevel =>
      text().withDefault(const Constant('Regular'))();
  BoolColumn get isVip => boolean().withDefault(const Constant(false))();
  BoolColumn get active => boolean().withDefault(const Constant(true))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {phone},
      ];
}
