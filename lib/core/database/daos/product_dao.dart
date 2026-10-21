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
      ..where(products.active.equals(true) & categories.active.equals(true));

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

  /// Live products matching a typed query by name, code (`sku`) or barcode.
  ///
  /// Searched in Dart rather than SQL for the same version-safety reason as
  /// [watchLowStock], and because the catalog is small enough that a scan is
  /// cheaper than getting a `LIKE` across three columns right in every drift
  /// version. An empty query returns everything, so the picker can show the
  /// full list before the cashier types.
  Stream<List<ProductRow>> watchProductsMatching(String query) {
    final needle = query.trim().toLowerCase();
    return (select(products)
          ..where((p) => p.active.equals(true))
          ..orderBy([(p) => OrderingTerm.asc(p.name)]))
        .watch()
        .map((rows) {
      if (needle.isEmpty) return rows;
      return rows.where((p) {
        final name = p.name.toLowerCase();
        final sku = (p.sku ?? '').toLowerCase();
        final barcode = (p.barcode ?? '').toLowerCase();
        return name.contains(needle) ||
            sku.contains(needle) ||
            barcode.contains(needle);
      }).toList();
    });
  }

  /// Every product, active or not — the partnership ledger prices cost of
  /// goods off this, because a soft-deleted product sold months ago still
  /// carries its cost and must not read as free.
  Future<List<ProductRow>> allProducts() => select(products).get();

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

  /// Live categories only — a deleted (soft-deleted) category is hidden
  /// from every picker, list and the category strip.
  Future<List<CategoryRow>> allCategories() =>
      (select(categories)..where((c) => c.active.equals(true))).get();

  /// Live category list — a Stream so the product form's category picker
  /// refreshes the moment a category is added/renamed/deleted, with no
  /// manual invalidation anywhere in the app.
  Stream<List<CategoryRow>> watchAllCategories() => (select(categories)
        ..where((c) => c.active.equals(true))
        ..orderBy([(c) => OrderingTerm.asc(c.name)]))
      .watch();

  Future<CategoryRow?> categoryByName(String name) =>
      (select(categories)..where((c) => c.name.equals(name)))
          .getSingleOrNull();

  /// How many live (visible) products sit under a category — used by the
  /// delete-category confirmation so the cashier sees how many will go.
  Future<int> countProductsInCategory(int categoryId) async {
    final query = selectOnly(products)
      ..addColumns([products.id.count()])
      ..where(products.categoryId.equals(categoryId) &
          products.active.equals(true));
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

  /// Soft-deletes a category (`active = 0`). The row stays so the products
  /// inside it — and the invoice history that points at those products —
  /// keep a live category to reference.
  Future<void> setCategoryActive(int id, bool active) =>
      (update(categories)..where((c) => c.id.equals(id)))
          .write(CategoriesCompanion(active: Value(active)));

  /// Hides (soft-deletes) every product in [categoryId]. Called when the
  /// category itself is deleted, so its products leave the catalog / POS /
  /// inventory immediately without their rows (and invoice lines) vanishing.
  Future<void> deactivateCategoryProducts(int categoryId) =>
      (update(products)..where((p) => p.categoryId.equals(categoryId)))
          .write(const ProductsCompanion(active: Value(false)));

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
