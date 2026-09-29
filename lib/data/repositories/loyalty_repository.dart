import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/loyalty_dao.dart';
import '../../core/permissions/permission_service.dart';
import '../../core/loyalty/loyalty_math.dart';
import 'audit_log_repository.dart';

/// Loyalty program — spec. Config CRUD (settings are pricing config →
/// canChangePrice + audit) wrapped around [LoyaltyDao], plus the
/// point-earn/spend helpers that the UI previews and InvoiceDao's
/// transaction rely on (both sharing [LoyaltyMath]).
class LoyaltyRepository {
  LoyaltyRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  /// Fallbacks used when the settings row hasn't been created yet (it is
  /// seeded on first run + created on v6 migration, but a defensive
  /// default never hurts).
  static const double defaultPointsPerCurrency = 1;
  static const int defaultMinimumRedeemPoints = 100;
  static const double defaultPointValueEGP = 1;

  Stream<LoyaltySettingsRow?> watchSettings() => _db.loyaltyDao.watchSettings();

  Future<LoyaltySettingsRow?> getSettings() => _db.loyaltyDao.getSettings();

  /// Saves the three loyalty settings. Pricing-related, so it's gated and
  /// logged just like a price change.
  Future<void> updateSettings({
    required double pointsPerCurrency,
    required int minimumRedeemPoints,
    required double pointValueEGP,
  }) async {
    _permissions.require(_permissions.canChangePrice, 'تعديل إعدادات الولاء');
    await _db.loyaltyDao.upsertSettings(LoyaltySettingsCompanion(
      pointsPerCurrency: Value(pointsPerCurrency),
      minimumRedeemPoints: Value(minimumRedeemPoints),
      pointValueEGP: Value(pointValueEGP),
      updatedAt: Value(DateTime.now()),
    ));
    await _auditLog.log(
      action: 'loyalty_settings_changed',
      entityType: 'loyalty',
      entityId: 1,
      newValue:
          '${pointsPerCurrency.toStringAsFixed(2)} / $minimumRedeemPoints / ${pointValueEGP.toStringAsFixed(2)}',
    );
  }

  Future<double> _pointsPerCurrency() async =>
      (await getSettings())?.pointsPerCurrency ?? defaultPointsPerCurrency;

  Future<int> _minimumRedeemPoints() async =>
      (await getSettings())?.minimumRedeemPoints ?? defaultMinimumRedeemPoints;

  Future<double> _pointValueEGP() async =>
      (await getSettings())?.pointValueEGP ?? defaultPointValueEGP;

  /// How many points an EGP amount earns under current settings.
  Future<int> pointsEarnedFor(double amount) async =>
      LoyaltyMath.pointsEarnedFor(amount, await _pointsPerCurrency());

  /// How much a point balance is worth as a discount today.
  Future<double> redemptionValue(int points) async =>
      LoyaltyMath.redemptionValue(points, await _pointValueEGP());

  /// Whether [points] may be redeemed against [total] (enough points AND
  /// the value covers part of the bill).
  Future<bool> canRedeem({required int points, required double total}) async {
    final value = await redemptionValue(points);
    return LoyaltyMath.canRedeem(
        points, await _minimumRedeemPoints(), value, total);
  }

  /// Awards (+) or spends (−) points for a customer (never below zero).
  Future<void> applyPointsDelta(int customerId, int delta) =>
      _db.loyaltyDao.applyPointsDelta(customerId, delta);
}

final loyaltyRepositoryProvider = Provider<LoyaltyRepository>((ref) {
  return LoyaltyRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

final loyaltySettingsProvider = StreamProvider<LoyaltySettingsRow?>((ref) {
  return ref.watch(loyaltyRepositoryProvider).watchSettings();
});