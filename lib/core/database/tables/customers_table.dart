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

  /// الأجل: whether this customer may pay on account (الدفع بالآجل).
  /// Balance is maintained transactionally by InvoiceDao (credit sales)
  /// and CustomerDao (collections/سداد), never typed by hand.
  BoolColumn get creditEnabled => boolean().withDefault(const Constant(false))();
  /// سقف الأجل — 0 means "بدون حد". Editable any time, even if the
  /// customer has already reached it (the owner raises it when needed).
  RealColumn get creditLimit => real().withDefault(const Constant(0))();
  /// المتبقي على العميل — credit sales add, collections subtract.
  RealColumn get creditBalance => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {phone},
      ];
}
