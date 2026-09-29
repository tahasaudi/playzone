import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/product_dao.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// A validation problem the user can actually fix, phrased in Arabic so
/// the form dialogs can render it verbatim (unlike a raw SqliteException,
/// whose message is an English SQLite constraint string).
class ProductValidationException implements Exception {
  ProductValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ProductRepository {
  ProductRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<ProductWithCategory>> watchAllWithCategory() =>
      _db.productDao.watchAllWithCategory();

  Stream<List<ProductRow>> watchLowStock() => _db.productDao.watchLowStock();

  Future<List<CategoryRow>> allCategories() => _db.productDao.allCategories();

  Stream<List<CategoryRow>> watchAllCategories() =>
      _db.productDao.watchAllCategories();

  Future<int> countProductsInCategory(int categoryId) =>
      _db.productDao.countProductsInCategory(categoryId);

  /// Enforced here too, not just hidden in Settings — spec §22.
  Future<void> setSellingPrice(int productId, double price) {
    _permissions.require(_permissions.canChangePrice, 'تغيير سعر المنتج');
    return _db.productDao.setSellingPrice(productId, price);
  }

  Future<void> adjustStock(int productId, int newQuantity) {
    _permissions.require(_permissions.canAdjustStock, 'تعديل المخزون');
    return _db.productDao.adjustStock(productId, newQuantity);
  }

  Future<int> addProduct({
    required String name,
    required int categoryId,
    required double costPrice,
    required double sellingPrice,
    int stockQuantity = 0,
    int minimumStock = 5,
    String? sku,
    String unit = 'قطعة',
  }) async {
    _permissions.require(_permissions.canChangePrice, 'إضافة منتج');
    final clean = name.trim();
    if (clean.isEmpty) {
      throw ProductValidationException('اسم المنتج مطلوب');
    }
    final id = await _db.productDao.insertProduct(ProductsCompanion.insert(
      name: clean,
      categoryId: categoryId,
      costPrice: Value(costPrice),
      sellingPrice: Value(sellingPrice),
      stockQuantity: Value(stockQuantity),
      minimumStock: Value(minimumStock),
      sku: Value(sku?.trim().isEmpty ?? true ? null : sku!.trim()),
      unit: Value(unit.trim().isEmpty ? 'قطعة' : unit.trim()),
    ));
    await _auditLog.log(
      action: 'product_added',
      entityType: 'product',
      entityId: id,
      newValue: clean,
    );
    return id;
  }

  /// Full-row update. [product] is expected to already carry the edited
  /// fields (the dialog passes `row.copyWith(...)`).
  Future<void> updateProduct(ProductRow product) async {
    _permissions.require(_permissions.canChangePrice, 'تعديل منتج');
    final clean = product.name.trim();
    if (clean.isEmpty) {
      throw ProductValidationException('اسم المنتج مطلوب');
    }
    await _db.productDao.updateProduct(
      product.copyWith(name: clean, updatedAt: DateTime.now()).toCompanion(true),
    );
    await _auditLog.log(
      action: 'product_updated',
      entityType: 'product',
      entityId: product.id,
      newValue: clean,
    );
  }

  /// Soft delete (spec §17): the row survives for invoice history, but it
  /// drops out of Inventory, the catalog and the POS cart grid at once.
  Future<void> deleteProduct(ProductRow product) async {
    _permissions.require(_permissions.canChangePrice, 'حذف منتج');
    await _db.productDao.setProductActive(product.id, false);
    await _auditLog.log(
      action: 'product_deleted',
      entityType: 'product',
      entityId: product.id,
      oldValue: product.name,
    );
  }

  Future<void> renameProduct(int id, String name) async {
    _permissions.require(_permissions.canChangePrice, 'تغيير اسم المنتج');
    final clean = name.trim();
    if (clean.isEmpty) {
      throw ProductValidationException('اسم المنتج مطلوب');
    }
    await _db.productDao.renameProduct(id, clean);
    await _auditLog.log(
      action: 'renamed',
      entityType: 'product',
      entityId: id,
      newValue: clean,
    );
  }

  Future<int> addCategory(String name) async {
    _permissions.require(_permissions.canChangePrice, 'إضافة تصنيف');
    final clean = name.trim();
    if (clean.isEmpty) {
      throw ProductValidationException('اسم التصنيف مطلوب');
    }
    if (clean.length > 50) {
      throw ProductValidationException('اسم التصنيف طويل أوي (الحد 50 حرف)');
    }
    if (await _db.productDao.categoryByName(clean) != null) {
      throw ProductValidationException('التصنيف "$clean" موجود بالفعل');
    }
    final id = await _db.productDao.insertCategory(
        CategoriesCompanion.insert(name: clean));
    await _auditLog.log(
      action: 'category_added',
      entityType: 'category',
      entityId: id,
      newValue: clean,
    );
    return id;
  }

  Future<void> renameCategory(int id, String name) async {
    _permissions.require(_permissions.canChangePrice, 'تغيير اسم التصنيف');
    final clean = name.trim();
    if (clean.isEmpty) {
      throw ProductValidationException('اسم التصنيف مطلوب');
    }
    final clash = await _db.productDao.categoryByName(clean);
    if (clash != null && clash.id != id) {
      throw ProductValidationException('التصنيف "$clean" موجود بالفعل');
    }
    await _db.productDao.renameCategory(id, clean);
    await _auditLog.log(
      action: 'renamed',
      entityType: 'category',
      entityId: id,
      newValue: clean,
    );
  }

  /// Only an empty category can go — otherwise the products pointing at it
  /// would be orphaned.
  Future<void> deleteCategory(CategoryRow category) async {
    _permissions.require(_permissions.canChangePrice, 'حذف تصنيف');
    final used = await _db.productDao.countProductsInCategory(category.id);
    if (used > 0) {
      throw ProductValidationException(
          'مينفعش تحذف التصنيف لوجود $used منتج جواه — انقل المنتجات أو احذفها الأول');
    }
    await _db.productDao.deleteCategory(category.id);
    await _auditLog.log(
      action: 'category_deleted',
      entityType: 'category',
      entityId: category.id,
      oldValue: category.name,
    );
  }
}

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final productsWithCategoryProvider =
    StreamProvider<List<ProductWithCategory>>((ref) {
  return ref.watch(productRepositoryProvider).watchAllWithCategory();
});

final lowStockProductsProvider = StreamProvider<List<ProductRow>>((ref) {
  return ref.watch(productRepositoryProvider).watchLowStock();
});

/// Live category list for pickers and the category manager row.
final allCategoriesProvider = StreamProvider<List<CategoryRow>>((ref) {
  return ref.watch(productRepositoryProvider).watchAllCategories();
});
