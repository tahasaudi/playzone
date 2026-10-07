import 'package:drift/drift.dart';
import 'customers_table.dart';
import 'products_table.dart';

/// سعر خاص لمنتج معين لعميل معين. لما العميل ده يتحدد في الكاشير،
/// السعر ده هو اللي يظهر ويترفع في الفاتورة بدل سعر البيع العادي.
/// One row per (customer, product) — the unique key makes re-setting
/// a price an upsert instead of a duplicate row.
@DataClassName('CustomerSpecialPriceRow')
class CustomerSpecialPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get price => real()();
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {customerId, productId},
      ];
}