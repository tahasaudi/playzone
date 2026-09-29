import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/permissions/permission_service.dart';
import 'audit_log_repository.dart';

/// A backup file on disk with the metadata the UI shows.
class BackupInfo {
  BackupInfo({
    required this.file,
    required this.createdAt,
    required this.sizeBytes,
  });

  final File file;
  final DateTime createdAt;
  final int sizeBytes;

  String get name => p.basename(file.path);
  double get sizeKb => sizeBytes / 1024;
}

/// Backup & restore — spec § (system). Backups are made with SQLite's
/// `VACUUM INTO`, which writes a fully self-contained, consistent copy
/// of the live database without pausing the app. Restore can't swap the
/// file while a connection is open, so it's *staged*: the chosen copy
/// becomes `playzone.restore-pending` and is applied automatically the
/// next time the app starts (see `_openConnection` in app_database.dart).
class BackupRepository {
  BackupRepository(this._db, this._permissions, this._auditLog);
  final AppDatabase _db;
  final PermissionService _permissions;
  final AuditLogRepository _auditLog;

  static const _dbFileName = 'playzone.sqlite';
  static const _pendingRestoreName = 'playzone.restore-pending';

  bool get canBackupRestore => _permissions.canBackupRestore;

  Future<Directory> _supportDir() => getApplicationSupportDirectory();

  Future<Directory> _backupDir() async {
    final dir = Directory(p.join((await _supportDir()).path, 'backups'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<File> databaseFile() async =>
      File(p.join((await _supportDir()).path, _dbFileName));

  Future<List<BackupInfo>> listBackups() async {
    final dir = await _backupDir();
    final entries = await dir
        .list()
        .where((e) => e is File && e.path.endsWith('.sqlite'))
        .cast<File>()
        .toList();
    final infos = <BackupInfo>[];
    for (final f in entries) {
      final stat = await f.stat();
      infos.add(BackupInfo(
        file: f,
        createdAt: stat.modified,
        sizeBytes: stat.size,
      ));
    }
    infos.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return infos;
  }

  /// Creates a timestamped backup and returns it. Throws
  /// [PermissionDeniedException] for non-admin roles.
  Future<BackupInfo> createBackup() async {
    _permissions.require(_permissions.canBackupRestore, 'إنشاء نسخة احتياطية');
    final dir = await _backupDir();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    final target = File(p.join(dir.path, 'playzone_$stamp.sqlite'));
    // VACUUM INTO needs a string literal path; escape any quote.
    final escaped = target.path.replaceAll("'", "''");
    await _db.customStatement("VACUUM INTO '$escaped'");
    final stat = await target.stat();
    await _auditLog.log(
      action: 'backup_created',
      entityType: 'database',
      newValue: target.path,
    );
    return BackupInfo(
      file: target,
      createdAt: stat.modified,
      sizeBytes: stat.size,
    );
  }

  Future<void> deleteBackup(BackupInfo info) async {
    _permissions.require(_permissions.canBackupRestore, 'حذف نسخة احتياطية');
    if (await info.file.exists()) await info.file.delete();
    await _auditLog.log(
      action: 'backup_deleted',
      entityType: 'database',
      oldValue: info.name,
    );
  }

  /// Stages [info] to be applied on the next launch. Does not touch the
  /// live database (it can't safely, while open).
  Future<void> stageRestore(BackupInfo info) async {
    _permissions.require(_permissions.canBackupRestore, 'استرجاع نسخة احتياطية');
    final pending = File(p.join((await _supportDir()).path, _pendingRestoreName));
    if (await pending.exists()) await pending.delete();
    await info.file.copy(pending.path);
    await _auditLog.log(
      action: 'restore_staged',
      entityType: 'database',
      newValue: info.name,
    );
  }
}

final backupRepositoryProvider = Provider<BackupRepository>((ref) {
  return BackupRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(permissionServiceProvider),
    ref.watch(auditLogRepositoryProvider),
  );
});
