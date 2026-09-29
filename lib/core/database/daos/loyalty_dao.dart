import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/loyalty_settings_table.dart';
import '../tables/customers_table.dart';

part 'loyalty_dao.g.dart';

@DriftAccessor(tables: [LoyaltySettings, Customers])
class LoyaltyDao extends DatabaseAccessor<AppDatabase> with _$LoyaltyDaoMixin {
  LoyaltyDao(super.db);

  Stream<LoyaltySettingsRow?> watchSettings() =>
      (select(loyaltySettings)..where((s) => s.id.equals(1)))
          .watchSingleOrNull();

  Future<LoyaltySettingsRow?> getSettings() =>
      (select(loyaltySettings)..where((s) => s.id.equals(1)))
          .getSingleOrNull();

  /// The whole program lives in ONE row (id = 1), so saving is always an
  /// upsert — the first save inserts, every later one updates.
  Future<void> upsertSettings(LoyaltySettingsCompanion entry) {
    return transaction(() async {
      final existing = await getSettings();
      if (existing == null) {
        await into(loyaltySettings).insert(entry.copyWith(id: const Value(1)));
      } else {
        await (update(loyaltySettings)..where((s) => s.id.equals(1)))
            .write(entry);
      }
    });
  }

  /// Awards or spends points for a customer (spending never dips below
  /// zero — points can't go negative). Runs inside its own tiny
  /// transaction so the read-modify-write of loyaltyPoints is atomic.
  Future<void> applyPointsDelta(int customerId, int delta) async {
    return transaction(() async {
      final customer = await (select(customers)
            ..where((c) => c.id.equals(customerId)))
          .getSingle();
      final newPoints = (customer.loyaltyPoints + delta).clamp(0, 1 << 20);
      await (update(customers)..where((c) => c.id.equals(customerId))).write(
        CustomersCompanion(
          loyaltyPoints: Value(newPoints),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}