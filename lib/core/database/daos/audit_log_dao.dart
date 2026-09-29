import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/audit_logs_table.dart';

part 'audit_log_dao.g.dart';

@DriftAccessor(tables: [AuditLogs])
class AuditLogDao extends DatabaseAccessor<AppDatabase> with _$AuditLogDaoMixin {
  AuditLogDao(super.db);

  Stream<List<AuditLogRow>> watchRecent({int limit = 100}) =>
      (select(auditLogs)
            ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
            ..limit(limit))
          .watch();

  /// Recent log rows whose entityType or action matches — used by the
  /// expense operations-log screen (entityType 'expense').
  Stream<List<AuditLogRow>> watchFor({String? entityType, String? action, int limit = 200}) {
    final query = select(auditLogs)
      ..orderBy([(a) => OrderingTerm.desc(a.createdAt)])
      ..limit(limit);
    if (entityType != null) query.where((a) => a.entityType.equals(entityType));
    if (action != null) query.where((a) => a.action.equals(action));
    return query.watch();
  }

  Future<void> log({
    required String action,
    required String entityType,
    int? entityId,
    String? oldValue,
    String? newValue,
    String? reason,
    required String performedByRole,
  }) {
    return into(auditLogs).insert(AuditLogsCompanion.insert(
      action: action,
      entityType: entityType,
      entityId: Value(entityId),
      oldValue: Value(oldValue),
      newValue: Value(newValue),
      reason: Value(reason),
      performedByRole: performedByRole,
    ));
  }
}
