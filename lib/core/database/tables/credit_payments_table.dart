import 'package:drift/drift.dart';
import 'customers_table.dart';
import 'employees_table.dart';

/// دفعة من عميل على حسابه (سداد من الأجل) — سجل مرجعي لكل تحصيل.
/// Each insert atomically lowers the customer's creditBalance.
@DataClassName('CreditPaymentRow')
class CreditPayments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  /// How much the customer handed over (جزء أو كل المتبقي).
  RealColumn get amount => real()();
  /// cash | card
  TextColumn get method => text().withDefault(const Constant('cash'))();
  IntColumn get employeeId =>
      integer().nullable().references(Employees, #id)();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}