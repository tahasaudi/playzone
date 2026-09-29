import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/products_table.dart';
import '../tables/categories_table.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, Categories])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(super.db);

  Stream<List<ProductWithCategory>> watchAllWithCategory() {
    final query = select(products).join([
      innerJoin(categories, categories.id.equalsExp(products.categoryId)),
    ])
      ..where(products.active.equals(true));

    return query.watch().map((rows) => rows
        .map((row) => ProductWithCategory(
              product: row.readTable(products),
              category: row.readTable(categories),
            ))
        .toList());
  }

  /// Products at or below their minimum stock — feeds the Dashboard's
  /// Low Stock widget (spec §19) and the notification center (spec §25).
  /// Filtered in Dart rather than SQL: comparing two columns of the same
  /// row needs a raw Expression comparison whose exact API name varies
  /// across drift versions, and this table is small enough that
  /// filtering client-side is simpler and version-proof.
  Stream<List<ProductRow>> watchLowStock() => (select(products)
        ..where((p) => p.active.equals(true)))
      .watch()
      .map((rows) =>
          rows.where((r) => r.stockQuantity <= r.minimumStock).toList());

  Future<int> insertProduct(ProductsCompanion entry) =>
      into(products).insert(entry);

  Future<bool> updateProduct(ProductsCompanion entry) =>
      update(products).replace(entry);

  Future<void> setSellingPrice(int id, double price) =>
      (update(products)..where((p) => p.id.equals(id))).write(
        ProductsCompanion(
            sellingPrice: Value(price), updatedAt: Value(DateTime.now())),
      );

  Future<void> adjustStock(int id, int newQuantity) =>
      (update(products)..where((p) => p.id.equals(id))).write(
        ProductsCompanion(
            stockQuantity: Value(newQuantity),
            updatedAt: Value(DateTime.now())),
      );

  Future<List<CategoryRow>> allCategories() => select(categories).get();

  /// Live category list — a Stream so the product form's category picker
  /// refreshes the moment a category is added/renamed/deleted, with no
  /// manual invalidation anywhere in the app.
  Stream<List<CategoryRow>> watchAllCategories() =>
      (select(categories)..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();

  Future<CategoryRow?> categoryByName(String name) =>
      (select(categories)..where((c) => c.name.equals(name)))
          .getSingleOrNull();

  /// How many products live under a category — the delete guard, so a
  /// category is never removed while products still point at it.
  Future<int> countProductsInCategory(int categoryId) async {
    final query = selectOnly(products)
      ..addColumns([products.id.count()])
      ..where(products.categoryId.equals(categoryId));
    final row = await query.getSingle();
    return row.read(products.id.count()) ?? 0;
  }

  Future<int> insertCategory(CategoriesCompanion entry) =>
      into(categories).insert(entry);

  /// Products are never hard-deleted (the table doc comment is explicit:
  /// invoice history must keep pointing at them) — they go `active = 0`
  /// and disappear from Inventory / Catalog / POS immediately.
  Future<void> setProductActive(int id, bool active) =>
      (update(products)..where((p) => p.id.equals(id))).write(
        ProductsCompanion(
            active: Value(active), updatedAt: Value(DateTime.now())),
      );

  Future<void> deleteCategory(int id) =>
      (delete(categories)..where((c) => c.id.equals(id))).go();

  Future<void> renameProduct(int id, String name) =>
      (update(products)..where((p) => p.id.equals(id))).write(
        ProductsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
      );

  Future<void> renameCategory(int id, String name) =>
      (update(categories)..where((c) => c.id.equals(id)))
          .write(CategoriesCompanion(name: Value(name)));
}

class ProductWithCategory {
  ProductWithCategory({required this.product, required this.category});
  final ProductRow product;
  final CategoryRow category;

  double get profit => product.sellingPrice - product.costPrice;
  bool get isLowStock =>
      product.stockQuantity > 0 &&
      product.stockQuantity <= product.minimumStock;
  bool get isOutOfStock => product.stockQuantity == 0;
}
