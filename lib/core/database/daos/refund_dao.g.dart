// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refund_dao.dart';

// ignore_for_file: type=lint
mixin _$RefundDaoMixin on DatabaseAccessor<AppDatabase> {
  $DeviceTypesTable get deviceTypes => attachedDatabase.deviceTypes;
  $DevicesTable get devices => attachedDatabase.devices;
  $CustomersTable get customers => attachedDatabase.customers;
  $EmployeesTable get employees => attachedDatabase.employees;
  $PackagesTable get packages => attachedDatabase.packages;
  $SessionsTable get sessions => attachedDatabase.sessions;
  $InvoicesTable get invoices => attachedDatabase.invoices;
  $RefundsTable get refunds => attachedDatabase.refunds;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $InvoiceItemsTable get invoiceItems => attachedDatabase.invoiceItems;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $AccountEntriesTable get accountEntries => attachedDatabase.accountEntries;
  RefundDaoManager get managers => RefundDaoManager(this);
}

class RefundDaoManager {
  final _$RefundDaoMixin _db;
  RefundDaoManager(this._db);
  $$DeviceTypesTableTableManager get deviceTypes =>
      $$DeviceTypesTableTableManager(_db.attachedDatabase, _db.deviceTypes);
  $$DevicesTableTableManager get devices =>
      $$DevicesTableTableManager(_db.attachedDatabase, _db.devices);
  $$CustomersTableTableManager get customers =>
      $$CustomersTableTableManager(_db.attachedDatabase, _db.customers);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$PackagesTableTableManager get packages =>
      $$PackagesTableTableManager(_db.attachedDatabase, _db.packages);
  $$SessionsTableTableManager get sessions =>
      $$SessionsTableTableManager(_db.attachedDatabase, _db.sessions);
  $$InvoicesTableTableManager get invoices =>
      $$InvoicesTableTableManager(_db.attachedDatabase, _db.invoices);
  $$RefundsTableTableManager get refunds =>
      $$RefundsTableTableManager(_db.attachedDatabase, _db.refunds);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$InvoiceItemsTableTableManager get invoiceItems =>
      $$InvoiceItemsTableTableManager(_db.attachedDatabase, _db.invoiceItems);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$AccountEntriesTableTableManager get accountEntries =>
      $$AccountEntriesTableTableManager(
          _db.attachedDatabase, _db.accountEntries);
}
