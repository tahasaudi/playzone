import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// Happy-hour / promo offers. Like packages, they're pricing config, so
/// writes are canChangePrice-gated and audit-logged.
class OfferRepository {
  OfferRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  Stream<List<OfferRow>> watchAll() => _db.offerDao.watchAll();

  Future<OfferRow?> currentActiveOffer() => _db.offerDao.currentActiveOffer();

  Future<int> addOffer({
    required String name,
    required String discountType,
    required double discountValue,
    required int startHour,
    required int endHour,
  }) async {
    _permissions.require(_permissions.canChangePrice, 'إضافة عرض');
    final id = await _db.offerDao.addOffer(OffersCompanion.insert(
      name: name,
      discountType: discountType,
      discountValue: Value(discountValue),
      startHour: Value(startHour),
      endHour: Value(endHour),
    ));
    await _auditLog.log(
      action: 'offer_added',
      entityType: 'offer',
      entityId: id,
      newValue: name,
    );
    return id;
  }

  Future<void> updateOffer(OfferRow offer) async {
    _permissions.require(_permissions.canChangePrice, 'تعديل عرض');
    await _db.offerDao.updateOffer(offer.toCompanion(true));
    await _auditLog.log(
      action: 'offer_updated',
      entityType: 'offer',
      entityId: offer.id,
      newValue: offer.name,
    );
  }

  Future<void> deleteOffer(int id) async {
    _permissions.require(_permissions.canChangePrice, 'حذف عرض');
    await _db.offerDao.deleteOffer(id);
    await _auditLog.log(
      action: 'offer_deleted',
      entityType: 'offer',
      entityId: id,
    );
  }

  Future<void> renameOffer(int id, String name) async {
    _permissions.require(_permissions.canChangePrice, 'تعديل اسم العرض');
    await _db.offerDao.renameOffer(id, name);
    await _auditLog.log(
      action: 'renamed',
      entityType: 'offer',
      entityId: id,
      newValue: name,
    );
  }
}

final offerRepositoryProvider = Provider<OfferRepository>((ref) {
  return OfferRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final allOffersProvider = StreamProvider<List<OfferRow>>((ref) {
  return ref.watch(offerRepositoryProvider).watchAll();
});

/// The offer (if any) whose hour window covers right now — could drive an
/// on-screen "ساعة العرض" banner later; kept live for that.
final currentActiveOfferProvider = FutureProvider<OfferRow?>((ref) {
  return ref.watch(offerRepositoryProvider).currentActiveOffer();
});