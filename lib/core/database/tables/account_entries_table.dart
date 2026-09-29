import 'package:drift/drift.dart';
import 'accounts_table.dart';

/// A single financial movement in the ledger. POS/session invoices post
/// a +amount to a revenue account; expenses post −amount to the expenses
/// account; refunds reverse the original sale. The Accounting screen
/// aggregates these by category.
@DataClassName('AccountEntryRow')
class AccountEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get accountId => integer().references(Accounts, #id)();
  RealColumn get amount => real()();
  // in | out — "in" adds to the account's running total, "out" subtracts.
  TextColumn get direction => text()();
  // invoice | expense | refund | manual
  TextColumn get source => text()();
  IntColumn get sourceId => integer().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}