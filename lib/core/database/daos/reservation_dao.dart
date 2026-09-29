import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/reservations_table.dart';
import '../tables/customers_table.dart';
import '../tables/devices_table.dart';

part 'reservation_dao.g.dart';

/// A reservation joined with the customer + device it points at — the
/// screen needs all three to render one row without N+1 queries.
class ReservationWithDetails {
  ReservationWithDetails({
    required this.reservation,
    required this.customer,
    required this.device,
  });
  final ReservationRow reservation;
  final CustomerRow customer;
  final DeviceRow device;
}

@DriftAccessor(tables: [Reservations, Customers, Devices])
class ReservationDao extends DatabaseAccessor<AppDatabase>
    with _$ReservationDaoMixin {
  ReservationDao(super.db);

  Stream<List<ReservationWithDetails>> _joinedRows(OrderingMode mode,
      {bool openOnly = false, int? limit}) {
    final query = select(reservations).join([
      innerJoin(customers, customers.id.equalsExp(reservations.customerId)),
      innerJoin(devices, devices.id.equalsExp(reservations.deviceId)),
    ])
      ..orderBy([
        OrderingTerm(expression: reservations.startTime, mode: mode),
      ]);
    if (limit != null) query.limit(limit);
    // Status filtering happens on the Dart side — the open set is a
    // fixed list of constants, which is simpler and version-proof.
    return query.watch().map((rows) => rows
        .map((row) => ReservationWithDetails(
              reservation: row.readTable(reservations),
              customer: row.readTable(customers),
              device: row.readTable(devices),
            ))
        .where((r) =>
            !openOnly ||
            const {'Pending', 'Confirmed', 'Arrived'}
                .contains(r.reservation.status))
        .toList());
  }

  /// "Open" reservations — everything still actionable: Pending,
  /// Confirmed and Arrived (arrived stays visible until the session
  /// actually starts). Sorted soonest-first for the booking board.
  Stream<List<ReservationWithDetails>> watchOpen() =>
      _joinedRows(OrderingMode.asc, openOnly: true);

  /// Historical reservations regardless of status (latest first).
  Stream<List<ReservationWithDetails>> watchRecent({int limit = 30}) =>
      _joinedRows(OrderingMode.desc, limit: limit);

  /// Flat list of open reservations (no join) — used by the repository's
  /// overlap check without pulling join overhead into it.
  Future<List<ReservationRow>> getOpen() => (select(reservations)
        ..where((r) => r.status.isIn(['Pending', 'Confirmed', 'Arrived'])))
      .get();

  Future<int> create(ReservationsCompanion entry) =>
      into(reservations).insert(entry);

  Future<void> updateStatus(int id, String status) =>
      (update(reservations)..where((r) => r.id.equals(id)))
          .write(ReservationsCompanion(status: Value(status)));

  Future<ReservationRow?> getById(int id) =>
      (select(reservations)..where((r) => r.id.equals(id)))
          .getSingleOrNull();
}