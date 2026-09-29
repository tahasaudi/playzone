import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/offers_table.dart';

part 'offer_dao.g.dart';

@DriftAccessor(tables: [Offers])
class OfferDao extends DatabaseAccessor<AppDatabase> with _$OfferDaoMixin {
  OfferDao(super.db);

  Stream<List<OfferRow>> watchAll() => (select(offers)
        ..orderBy([(o) => OrderingTerm.asc(o.startHour)]))
      .watch();

  /// The active offer whose hour window covers NOW, or null. Filtered
  /// in Dart rather than sqlite's isSmallerOrEqualTo — the operator
  /// spelling differs across drift versions, and the offers list is
  /// tiny enough that this stays trivially cheap.
  Future<OfferRow?> currentActiveOffer() async {
    final now = DateTime.now().hour;
    final all =
        await (select(offers)..where((o) => o.active.equals(true))).get();
    return all.where((o) => o.startHour <= now && o.endHour >= now).firstOrNull;
  }

  Future<int> addOffer(OffersCompanion entry) => into(offers).insert(entry);

  Future<bool> updateOffer(OffersCompanion entry) =>
      update(offers).replace(entry);

  Future<void> deleteOffer(int id) =>
      (delete(offers)..where((o) => o.id.equals(id))).go();

  Future<void> renameOffer(int id, String name) =>
      (update(offers)..where((o) => o.id.equals(id)))
          .write(OffersCompanion(name: Value(name)));
}

extension _FirstOrNullExt<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}