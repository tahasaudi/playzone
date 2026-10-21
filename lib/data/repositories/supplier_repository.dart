import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/supplier_dao.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// Trims a maybe-empty text field down to null, so an untouched optional field
/// is stored as "nothing said" rather than a blank string that later reads as
/// if someone typed something.
String? _cleanOrNull(String? value) {
  final clean = value?.trim() ?? '';
  return clean.isEmpty ? null : clean;
}

/// A validation problem the user can fix, phrased in Arabic so the form can
/// show it verbatim (matching [ProductValidationException]'s approach).
class SupplierValidationException implements Exception {
  SupplierValidationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Suppliers and their purchase invoices.
///
/// A purchase is a money movement, so writes are gated on the same permission
/// price/stock changes use and every one is audit-logged. Posting a purchase
/// raises stock and writes an expense — that work lives in [SupplierDao]'s
/// transaction, so a failure part-way through leaves nothing behind.
class SupplierRepository {
  SupplierRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<SupplierRow>> watchSuppliers() => _db.supplierDao.watchSuppliers();

  Stream<List<PurchaseRow>> watchPurchases() => _db.supplierDao.watchPurchases();

  Stream<List<PurchaseItemRow>> watchItems(int purchaseId) =>
      _db.supplierDao.watchItems(purchaseId);

  Future<int> addSupplier({
    required String name,
    String? phone,
    String? note,
  }) async {
    _permissions.require(_permissions.canChangePrice, 'إضافة مورد');
    final clean = name.trim();
    if (clean.isEmpty) {
      throw SupplierValidationException('اسم المورد مطلوب');
    }
    final clash = await _db.supplierDao.supplierByName(clean);
    if (clash != null) {
      // A soft-deleted supplier with the same name is brought back rather
      // than duplicated, so history keeps pointing at one row.
      if (clash.active) {
        throw SupplierValidationException('المورد "$clean" موجود بالفعل');
      }
      await _db.supplierDao.updateSupplier(clash
          .copyWith(
            // A row restored before codes existed gets one now; otherwise it
            // keeps the number it already had.
            code: Value(clash.code ??
                await _db.supplierDao.nextSupplierCode(ignoreId: clash.id)),
            active: true,
            phone: Value(_cleanOrNull(phone)),
            note: Value(_cleanOrNull(note)),
            updatedAt: DateTime.now(),
          )
          .toCompanion(true));
      await _auditLog.log(
        action: 'supplier_added',
        entityType: 'supplier',
        entityId: clash.id,
        newValue: clean,
      );
      return clash.id;
    }
    final id = await _db.supplierDao.insertSupplier(SuppliersCompanion.insert(
      code: Value(await _db.supplierDao.nextSupplierCode()),
      name: clean,
      phone: Value(_cleanOrNull(phone)),
      note: Value(_cleanOrNull(note)),
    ));
    await _auditLog.log(
      action: 'supplier_added',
      entityType: 'supplier',
      entityId: id,
      newValue: clean,
    );
    return id;
  }

  Future<void> updateSupplier(SupplierRow supplier,
      {String? name, String? phone, String? note}) async {
    _permissions.require(_permissions.canChangePrice, 'تعديل مورد');
    final clean = (name ?? supplier.name).trim();
    if (clean.isEmpty) {
      throw SupplierValidationException('اسم المورد مطلوب');
    }
    await _db.supplierDao.updateSupplier(supplier
        .copyWith(
          name: clean,
          phone: Value(_cleanOrNull(phone ?? supplier.phone)),
          note: Value(_cleanOrNull(note ?? supplier.note)),
          updatedAt: DateTime.now(),
        )
        .toCompanion(true));
    await _auditLog.log(
      action: 'supplier_updated',
      entityType: 'supplier',
      entityId: supplier.id,
      newValue: clean,
    );
  }

  /// Soft-delete: the row survives so old purchase invoices keep reading
  /// correctly, but the supplier drops out of the picker.
  Future<void> deleteSupplier(SupplierRow supplier) async {
    _permissions.require(_permissions.canChangePrice, 'حذف مورد');
    await _db.supplierDao.setSupplierActive(supplier.id, false);
    await _auditLog.log(
      action: 'supplier_deleted',
      entityType: 'supplier',
      entityId: supplier.id,
      oldValue: supplier.name,
    );
  }

  /// Records a purchase invoice: stock up, cost price updated, expense
  /// written, all in one transaction.
  Future<int> recordPurchase({
    required SupplierRow supplier,
    required DateTime purchaseDate,
    required List<PurchaseLine> lines,
    String? note,
    int? employeeId,
  }) async {
    _permissions.require(_permissions.canAdjustStock, 'تسجيل فاتورة شراء');
    if (lines.isEmpty) {
      throw SupplierValidationException('ضيف بند واحد على الأقل للفاتورة');
    }
    for (final line in lines) {
      if (line.quantity <= 0) {
        throw SupplierValidationException(
            'الكمية لازم تكون أكبر من صفر (${line.productName})');
      }
      if (line.unitCost < 0) {
        throw SupplierValidationException(
            'سعر الشراء مينفعش يكون سالب (${line.productName})');
      }
    }
    final id = await _db.supplierDao.createPurchase(
      supplierId: supplier.id,
      supplierName: supplier.name,
      purchaseDate: purchaseDate,
      lines: lines,
      note: note?.trim().isEmpty ?? true ? null : note!.trim(),
      employeeId: employeeId,
    );
    final total = lines.fold<double>(0, (s, l) => s + l.quantity * l.unitCost);
    await _auditLog.log(
      action: 'purchase_recorded',
      entityType: 'purchase',
      entityId: id,
      newValue: '${supplier.name} - EGP ${total.toStringAsFixed(2)}',
    );
    return id;
  }

  /// Reverses a purchase: stock back down, expense and ledger entry removed.
  Future<void> deletePurchase(PurchaseRow purchase) async {
    _permissions.require(_permissions.canAdjustStock, 'حذف فاتورة شراء');
    await _db.supplierDao.deletePurchase(purchase.id);
    await _auditLog.log(
      action: 'purchase_deleted',
      entityType: 'purchase',
      entityId: purchase.id,
      oldValue:
          '${purchase.supplierName} - EGP ${purchase.total.toStringAsFixed(2)}',
    );
  }
}

final supplierRepositoryProvider = Provider<SupplierRepository>((ref) {
  return SupplierRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

/// Live suppliers for the picker and the list.
final suppliersProvider = StreamProvider<List<SupplierRow>>((ref) {
  return ref.watch(supplierRepositoryProvider).watchSuppliers();
});

/// Every purchase invoice, newest first.
final purchasesProvider = StreamProvider<List<PurchaseRow>>((ref) {
  return ref.watch(supplierRepositoryProvider).watchPurchases();
});

/// The lines of one invoice — read by the detail sheet.
final purchaseItemsProvider =
    StreamProvider.family<List<PurchaseItemRow>, int>((ref, purchaseId) {
  return ref.watch(supplierRepositoryProvider).watchItems(purchaseId);
});

/// Audited supplier/purchase operations, for the log tab.
///
/// Filtered in Dart off the recent trail (the same trick the expenses log
/// uses), so no new DAO query is needed for two entity types at once.
final supplierLogProvider = StreamProvider<List<AuditLogRow>>((ref) {
  return ref.watch(auditLogRepositoryProvider).watchRecent(limit: 400).map(
        (rows) => rows
            .where((r) =>
                r.entityType == 'supplier' || r.entityType == 'purchase')
            .toList(),
      );
});
