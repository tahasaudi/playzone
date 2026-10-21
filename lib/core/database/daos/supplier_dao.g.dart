// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'supplier_dao.dart';

// ignore_for_file: type=lint
mixin _$SupplierDaoMixin on DatabaseAccessor<AppDatabase> {
  $SuppliersTable get suppliers => attachedDatabase.suppliers;
  $EmployeesTable get employees => attachedDatabase.employees;
  $PurchasesTable get purchases => attachedDatabase.purchases;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $PurchaseItemsTable get purchaseItems => attachedDatabase.purchaseItems;
  $ExpensesTable get expenses => attachedDatabase.expenses;
  $AccountsTable get accounts => attachedDatabase.accounts;
  $AccountEntriesTable get accountEntries => attachedDatabase.accountEntries;
  SupplierDaoManager get managers => SupplierDaoManager(this);
}

class SupplierDaoManager {
  final _$SupplierDaoMixin _db;
  SupplierDaoManager(this._db);
  $$SuppliersTableTableManager get suppliers =>
      $$SuppliersTableTableManager(_db.attachedDatabase, _db.suppliers);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$PurchasesTableTableManager get purchases =>
      $$PurchasesTableTableManager(_db.attachedDatabase, _db.purchases);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$PurchaseItemsTableTableManager get purchaseItems =>
      $$PurchaseItemsTableTableManager(_db.attachedDatabase, _db.purchaseItems);
  $$ExpensesTableTableManager get expenses =>
      $$ExpensesTableTableManager(_db.attachedDatabase, _db.expenses);
  $$AccountsTableTableManager get accounts =>
      $$AccountsTableTableManager(_db.attachedDatabase, _db.accounts);
  $$AccountEntriesTableTableManager get accountEntries =>
      $$AccountEntriesTableTableManager(
          _db.attachedDatabase, _db.accountEntries);
}
