// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'stock_count_dao.dart';

// ignore_for_file: type=lint
mixin _$StockCountDaoMixin on DatabaseAccessor<AppDatabase> {
  $EmployeesTable get employees => attachedDatabase.employees;
  $StockCountsTable get stockCounts => attachedDatabase.stockCounts;
  $CategoriesTable get categories => attachedDatabase.categories;
  $ProductsTable get products => attachedDatabase.products;
  $StockCountItemsTable get stockCountItems => attachedDatabase.stockCountItems;
  StockCountDaoManager get managers => StockCountDaoManager(this);
}

class StockCountDaoManager {
  final _$StockCountDaoMixin _db;
  StockCountDaoManager(this._db);
  $$EmployeesTableTableManager get employees =>
      $$EmployeesTableTableManager(_db.attachedDatabase, _db.employees);
  $$StockCountsTableTableManager get stockCounts =>
      $$StockCountsTableTableManager(_db.attachedDatabase, _db.stockCounts);
  $$CategoriesTableTableManager get categories =>
      $$CategoriesTableTableManager(_db.attachedDatabase, _db.categories);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$StockCountItemsTableTableManager get stockCountItems =>
      $$StockCountItemsTableTableManager(
          _db.attachedDatabase, _db.stockCountItems);
}
