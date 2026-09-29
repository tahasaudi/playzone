import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/employees_table.dart';
import '../tables/employee_transactions_table.dart';
import '../tables/employee_attendance_table.dart';

part 'employee_dao.g.dart';

@DriftAccessor(
    tables: [Employees, EmployeeTransactions, EmployeeAttendance])
class EmployeeDao extends DatabaseAccessor<AppDatabase>
    with _$EmployeeDaoMixin {
  EmployeeDao(super.db);

  Stream<List<EmployeeRow>> watchActive() =>
      (select(employees)..where((e) => e.active.equals(true))).watch();

  /// Partners (شركاء) only — eligible for a profit share. All-time list
  /// (includes disabled partners so history stays visible).
  Stream<List<EmployeeRow>> watchPartners() =>
      (select(employees)..where((e) => e.isPartner.equals(true))).watch();

  Future<EmployeeRow?> getByPhone(String phone) =>
      (select(employees)..where((e) => e.phone.equals(phone)))
          .getSingleOrNull();

  Future<List<EmployeeRow>> getPartners() => (select(employees)
        ..where((e) => e.isPartner.equals(true)))
      .get();

  Future<int> insertEmployee(EmployeesCompanion entry) =>
      into(employees).insert(entry);

  Future<bool> updateEmployee(EmployeesCompanion entry) =>
      update(employees).replace(entry);

  /// Soft-disable — we never hard-delete an employee (their history must
  /// remain traceable in shifts/audit logs).
  Future<void> deactivate(int id) => (update(employees)
        ..where((e) => e.id.equals(id)))
      .write(const EmployeesCompanion(active: Value(false)));

  Future<void> reactivate(int id) => (update(employees)
        ..where((e) => e.id.equals(id)))
      .write(const EmployeesCompanion(active: Value(true)));

  Future<void> setPartner(int id, {required bool isPartner, double? share}) =>
      (update(employees)..where((e) => e.id.equals(id))).write(
        EmployeesCompanion(
          isPartner: Value(isPartner),
          partnerShare: Value(share),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ── مسحوبات / سداد ────────────────────────────────────────────────
  Future<int> insertTransaction(EmployeeTransactionsCompanion entry) =>
      into(employeeTransactions).insert(entry);

  Future<void> deleteTransaction(int id) =>
      (delete(employeeTransactions)..where((t) => t.id.equals(id))).go();

  Stream<List<EmployeeTransactionRow>> watchTransactions() =>
      (select(employeeTransactions)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<EmployeeTransactionRow>> watchTransactionsForEmployee(
          int employeeId) =>
      (select(employeeTransactions)..where((t) => t.employeeId.equals(employeeId)))
          .watch();

  Future<List<EmployeeTransactionRow>> getTransactionsBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await select(employeeTransactions).get();
    return rows
        .where((t) =>
            !t.createdAt.isBefore(from) && t.createdAt.isBefore(to))
        .toList();
  }

  // ── حضور وانصراف ────────────────────────────────────────────────
  /// The employee's currently-open record (checkOut == null), if any.
  Future<EmployeeAttendanceRow?> openAttendanceFor(int employeeId) =>
      (select(employeeAttendance)
            ..where((a) => a.employeeId.equals(employeeId) &
                a.checkOut.isNull()))
          .getSingleOrNull();

  Future<int> insertAttendance(EmployeeAttendanceCompanion entry) =>
      into(employeeAttendance).insert(entry);

  Future<void> markCheckOut(int id, DateTime checkOut) =>
      (update(employeeAttendance)..where((a) => a.id.equals(id))).write(
        EmployeeAttendanceCompanion(checkOut: Value(checkOut)),
      );

  Stream<List<EmployeeAttendanceRow>> watchAttendance({int limit = 100}) =>
      (select(employeeAttendance)
            ..orderBy([(a) => OrderingTerm.desc(a.checkIn)])
            ..limit(limit))
          .watch();
}
