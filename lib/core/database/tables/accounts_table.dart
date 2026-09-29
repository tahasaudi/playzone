import 'package:drift/drift.dart';

/// An accounting category ("بند حساب") — the ledger's lines of business.
/// Revenue/expense transactions are posted automatically to a category
/// via [AccountEntries]; admins can rename the categories freely, which
/// re-labels every historical entry attached to them.
///
/// kind: revenue | expense
@DataClassName('AccountRow')
class Accounts extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Stable code auto-posted by the DAOs: sales, expenses, refunds.
  TextColumn get code => text().unique()();
  TextColumn get name => text()();
  TextColumn get kind => text()(); // revenue | expense
  BoolColumn get system => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}