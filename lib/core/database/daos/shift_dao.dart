import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/shifts_table.dart';

part 'shift_dao.g.dart';

@DriftAccessor(tables: [Shifts])
class ShiftDao extends DatabaseAccessor<AppDatabase> with _$ShiftDaoMixin {
  ShiftDao(super.db);

  Stream<List<ShiftRow>> watchRecent({int limit = 30}) =>
      (select(shifts)
            ..orderBy([(s) => OrderingTerm.desc(s.closedAt)])
            ..limit(limit))
          .watch();

  Future<int> closeShift({
    required int? employeeId,
    required double openingCash,
    required double expectedCash,
    required double actualCash,
    String? notes,
  }) {
    return into(shifts).insert(ShiftsCompanion.insert(
      employeeId: Value(employeeId),
      openingCash: Value(openingCash),
      expectedCash: Value(expectedCash),
      actualCash: Value(actualCash),
      difference: Value(actualCash - expectedCash),
      notes: Value(notes),
    ));
  }
}
