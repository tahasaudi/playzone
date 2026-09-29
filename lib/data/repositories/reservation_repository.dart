import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/database/daos/reservation_dao.dart';
import 'session_repository.dart';
import 'audit_log_repository.dart';

/// Thrown (by the repository, not the UI) when the device already has an
/// open reservation overlapping the requested window. The new-reservation
/// dialog catches THIS type to show a clear message.
class ReservationOverlapException implements Exception {
  const ReservationOverlapException();

  @override
  String toString() => 'الجهاز محجوز بالفعل في هذا الوقت';
}

/// Reservations — spec §15. Business logic lives here: the overlap check
/// (so every create path — UI, another screen, a future bulk import —
/// gets the same guard) and the "start session from reservation" flow.
class ReservationRepository {
  ReservationRepository(this._db, this._auditLog);
  final AppDatabase _db;
  final AuditLogRepository _auditLog;

  Stream<List<ReservationWithDetails>> watchOpen() =>
      _db.reservationDao.watchOpen();

  Stream<List<ReservationWithDetails>> watchRecent({int limit = 30}) =>
      _db.reservationDao.watchRecent(limit: limit);

  Future<int> create({
    required int customerId,
    required int deviceId,
    required DateTime startTime,
    required DateTime endTime,
    int? employeeId,
  }) async {
    await _assertNoOverlap(deviceId, startTime, endTime);
    return _db.reservationDao.create(ReservationsCompanion.insert(
      customerId: customerId,
      deviceId: deviceId,
      startTime: startTime,
      endTime: endTime,
      employeeId: Value(employeeId),
    ));
  }

  /// Two bookings overlap when each one starts before the other ends
  /// (start1 < end2 && end1 > start2), on the SAME device. Cancelled and
  /// no-show bookings don't block anything.
  Future<void> _assertNoOverlap(
      int deviceId, DateTime startTime, DateTime endTime) async {
    final open = await _db.reservationDao.getOpen();
    final overlaps = open.any((r) =>
        r.deviceId == deviceId &&
        startTime.isBefore(r.endTime) &&
        endTime.isAfter(r.startTime));
    if (overlaps) throw const ReservationOverlapException();
  }

  Future<void> confirm(int id) => _setStatus(id, 'Confirmed');

  Future<void> markArrived(int id) => _setStatus(id, 'Arrived');

  /// Cancelling and no-showing are destructive — both are logged so the
  /// audit trail explains why a slot opened back up.
  Future<void> cancel(int id) => _setStatus(id, 'Cancelled');

  Future<void> markNoShow(int id) => _setStatus(id, 'NoShow');

  Future<void> markCompleted(int id) => _setStatus(id, 'Completed');

  Future<void> _setStatus(int id, String status) async {
    await _db.reservationDao.updateStatus(id, status);
    if (status == 'Cancelled' || status == 'NoShow') {
      await _auditLog.log(
        action: 'reservation_${status == 'Cancelled' ? 'cancelled' : 'no_show'}',
        entityType: 'reservation',
        entityId: id,
        newValue: status,
      );
    }
  }

  /// "بدء الجلسة" on an arrived reservation: opens a REAL session on the
  /// reserved device (inheriting the same customer + booking employee so
  /// revenue reporting stays correct) and completes the reservation.
  Future<void> startSession(ReservationWithDetails r) async {
    await SessionRepository(_db).start(
      deviceId: r.reservation.deviceId,
      customerId: r.reservation.customerId,
      employeeId: r.reservation.employeeId,
    );
    await markCompleted(r.reservation.id);
  }
}

final reservationRepositoryProvider = Provider<ReservationRepository>((ref) {
  return ReservationRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});

/// The live booking board — open (Pending/Confirmed/Arrived) reservations.
final upcomingReservationsProvider =
    StreamProvider<List<ReservationWithDetails>>((ref) {
  return ref.watch(reservationRepositoryProvider).watchOpen();
});

/// The "recent reservations" history list on the Reservations screen.
final recentReservationsProvider =
    StreamProvider<List<ReservationWithDetails>>((ref) {
  return ref.watch(reservationRepositoryProvider).watchRecent();
});