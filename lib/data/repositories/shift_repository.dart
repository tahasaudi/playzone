import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

class ShiftRepository {
  ShiftRepository(this._db);
  final AppDatabase _db;

  Stream<List<ShiftRow>> watchRecent({int limit = 30}) =>
      _db.shiftDao.watchRecent(limit: limit);

  Future<int> closeShift({
    required int? employeeId,
    required double openingCash,
    required double expectedCash,
    required double actualCash,
    String? notes,
  }) {
    return _db.shiftDao.closeShift(
      employeeId: employeeId,
      openingCash: openingCash,
      expectedCash: expectedCash,
      actualCash: actualCash,
      notes: notes,
    );
  }
}

final shiftRepositoryProvider = Provider<ShiftRepository>((ref) {
  return ShiftRepository(ref.watch(appDatabaseProvider));
});

final recentShiftsProvider = StreamProvider<List<ShiftRow>>((ref) {
  return ref.watch(shiftRepositoryProvider).watchRecent();
});
