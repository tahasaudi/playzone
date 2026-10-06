import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/utils/time_format.dart';
import '../../core/widgets/glass_card.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/permissions/permission_service.dart';
import '../../data/repositories/backup_repository.dart';

/// Backup & restore — admin only. Create self-contained database
/// snapshots, browse/delete old ones, and stage a restore that takes
/// effect on the next launch (the live DB can't be swapped while open).
class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  List<BackupInfo>? _backups;
  bool _busy = false;
  String? _dbPath;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<void> _refresh() async {
    final repo = ref.read(backupRepositoryProvider);
    final file = await repo.databaseFile();
    final list = await repo.listBackups();
    if (mounted) {
      setState(() {
        _dbPath = file.path;
        _backups = list;
      });
    }
  }

  Future<void> _run(Future<void> Function() action, String success) async {
    setState(() => _busy = true);
    try {
      await action();
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(success)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final canBackup = ref.watch(permissionServiceProvider).canBackupRestore;

    if (!canBackup) {
      return const Center(
        child: Text('النسخ الاحتياطي متاح للمدير فقط',
            style: TextStyle(color: AppColors.textTertiary)),
      );
    }

    final backups = _backups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('النسخ الاحتياطي', style: AppTypography.sectionTitle),
                  SizedBox(height: 2),
                  Text('نسخ آمنة من قاعدة البيانات مع الاسترجاع',
                      style: AppTypography.secondary),
                ],
              ),
            ),
            SizedBox(
              width: 200,
              child: PrimaryButton(
                label: _busy ? 'جارٍ النسخ...' : 'نسخة احتياطية الآن',
                icon: Icons.backup_rounded,
                expand: true,
                onPressed: _busy
                    ? null
                    : () => _run(
                          () => ref
                              .read(backupRepositoryProvider)
                              .createBackup()
                              .then((_) {}),
                          'تم إنشاء نسخة احتياطية',
                        ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (_dbPath != null)
          GlassCard(
            child: Row(
              children: [
                const Icon(Icons.storage_rounded,
                    color: AppColors.accentSecondary, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text('قاعدة البيانات: $_dbPath',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ),
              ],
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Expanded(
          child: backups == null
              ? const Center(child: CircularProgressIndicator())
              : backups.isEmpty
                  ? const Center(
                      child: Text('لا توجد نسخ احتياطية بعد',
                          style: TextStyle(color: AppColors.textTertiary)),
                    )
                  : ListView.separated(
                      itemCount: backups.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) => _BackupRow(
                        info: backups[i],
                        busy: _busy,
                        onDelete: () => _confirmDelete(backups[i]),
                        onRestore: () => _confirmRestore(backups[i]),
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(BackupInfo info) async {
    final ok = await _confirm(
      'حذف النسخة',
      'هل تريد حذف النسخة "${info.name}"؟',
    );
    if (ok != true) return;
    await _run(
      () => ref.read(backupRepositoryProvider).deleteBackup(info),
      'تم حذف النسخة',
    );
  }

  Future<void> _confirmRestore(BackupInfo info) async {
    final ok = await _confirm(
      'استرجاع النسخة',
      'سيتم استرجاع "${info.name}" عند إعادة تشغيل التطبيق. هل تريد المتابعة؟',
    );
    if (ok != true) return;
    await _run(
      () => ref.read(backupRepositoryProvider).stageRestore(info),
      'تم تجهيز الاسترجاع — أعد تشغيل التطبيق',
    );
  }

  Future<bool?> _confirm(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.bgElevated,
        title: Text(title, style: AppTypography.cardTitle),
        content: Text(message, style: AppTypography.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('تأكيد',
                style: TextStyle(color: AppColors.accentSecondary)),
          ),
        ],
      ),
    );
  }
}

class _BackupRow extends StatelessWidget {
  const _BackupRow({
    required this.info,
    required this.busy,
    required this.onDelete,
    required this.onRestore,
  });
  final BackupInfo info;
  final bool busy;
  final VoidCallback onDelete;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      child: Row(
        children: [
          const Icon(Icons.save_rounded,
              color: AppColors.accentSecondary, size: 20),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name, style: AppTypography.cardTitle),
                const SizedBox(height: 2),
                Text(
                  '${_fmtDateTime(info.createdAt)} · ${info.sizeKb.toStringAsFixed(0)} KB',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
          SecondaryButton(
            label: 'استرجاع',
            icon: Icons.restore_rounded,
            onPressed: busy ? null : onRestore,
          ),
          const SizedBox(width: AppSpacing.sm),
          IconButton(
            tooltip: 'حذف',
            icon: const Icon(Icons.delete_outline_rounded,
                size: 18, color: AppColors.danger),
            onPressed: busy ? null : onDelete,
          ),
        ],
      ),
    );
  }
}

String _fmtDateTime(DateTime d) => stampOf(d);
