import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';
import '../../core/sync/sync_client.dart';
import '../../core/sync/sync_config.dart';
import '../../core/sync/sync_schema.dart';
import '../../core/sync/sync_server.dart';
import '../../core/sync/sync_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/tv/hard_lock.dart';
import '../../core/widgets/app_buttons.dart';
import '../../core/widgets/glass_card.dart';

/// Settings → المزامنة: which machine owns the database, how the phone
/// finds it, and the wall-network switch that sits next to it.
///
/// Every control here writes a setting and then restarts the sync layer,
/// never reconfigures a running one — a machine that changes sides while
/// queues are in flight is how two databases end up each believing they
/// are the truth.
class SyncSettingsTab extends ConsumerStatefulWidget {
  const SyncSettingsTab({super.key});

  @override
  ConsumerState<SyncSettingsTab> createState() => _SyncSettingsTabState();
}

class _SyncSettingsTabState extends ConsumerState<SyncSettingsTab> {
  final _url = TextEditingController();
  late String _role;
  bool _wall = false;
  bool _busy = false;
  bool _discovering = false;
  bool _checkingFirewall = false;
  int _pending = 0;
  Timer? _ticker;

  AppDatabase get _db => ref.read(appDatabaseProvider);

  String get _effectiveRole => (_role.trim().isEmpty)
      ? SyncService.defaultRole()
      : syncRoleOf(_role) == SyncRole.client
          ? 'client'
          : syncRoleOf(_role) == SyncRole.master
              ? 'master'
              : 'off';

  @override
  void initState() {
    super.initState();
    _role = '';
    _load();
    _ticker = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _url.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final settings = _db.settingsDao;
    final role = await settings.getValue(SyncKeys.role);
    final url = await settings.getValue(SyncKeys.serverUrl);
    final wall = await settings.getValue(SyncKeys.wallNetwork);
    if (!mounted) return;
    setState(() {
      _role = role ?? '';
      _url.text = (url ?? '').trim();
      _wall = wall != '0';
    });
    await _refresh();
  }

  Future<void> _refresh() async {
    var pending = 0;
    try {
      final row = await _db
          .customSelect(
              'SELECT COUNT(*) AS c FROM $syncLogTable WHERE pushed = 0')
          .getSingleOrNull();
      final c = row?.data['c'];
      pending = c is int ? c : 0;
    } catch (_) {}
    if (mounted && pending != _pending) setState(() => _pending = pending);
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
      await _refresh();
    }
  }

  Future<void> _setRole(String value) async {
    await _run(() async {
      await _db.settingsDao.setValue(SyncKeys.role, value);
      setState(() => _role = value);
      await SyncService.instance.restart(_db);
    });
  }

  Future<void> _saveUrl() async {
    await _run(() async {
      await _db.settingsDao.setValue(SyncKeys.serverUrl, _url.text.trim());
      await SyncService.instance.restart(_db);
    });
  }

  Future<void> _discover() async {
    await _run(() async {
      setState(() => _discovering = true);
      final address = await SyncClient.discoverMaster();
      if (!mounted) return;
      if (address == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('مفيش كمبيوتر ردّد على الشبكة — اتأكد إن البرنامج '
                'شغال عليه ومن نفس الواي فاي')));
        return;
      }
      _url.text = 'http://$address:$syncPort';
      await _db.settingsDao.setValue(SyncKeys.serverUrl, _url.text);
      await SyncService.instance.restart(_db);
    }).whenComplete(() {
      if (mounted) setState(() => _discovering = false);
    });
  }

  Future<void> _syncNow() async {
    await _run(() async {
      final client = SyncService.instance.client;
      if (client == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('شغّل دور "التليفون" الأول')));
        return;
      }
      await client.syncNow();
    });
  }

  Future<void> _setWall(bool allowed) async {
    await _run(() async {
      await _db.settingsDao
          .setValue(SyncKeys.wallNetwork, allowed ? '1' : '0');
      WallNetwork.blocked = !allowed;
      setState(() => _wall = allowed);
    });
  }

  /// User-initiated, never automatic: netsh is an elevated program and a
  /// UAC prompt that appears by itself is one people learn to dismiss.
  Future<void> _openFirewall() async {
    await _run(() async {
      setState(() => _checkingFirewall = true);
      SyncRuntime.firewallNote = await SyncServer.ensureFirewallRule();
    }).whenComplete(() {
      if (mounted) setState(() => _checkingFirewall = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final role = _effectiveRole;
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.sync_alt_rounded,
                        color: AppColors.accentSecondary),
                    SizedBox(width: AppSpacing.sm),
                    Text('مزامنة الكافيه على الشبكة المحلية',
                        style: AppTypography.cardTitle),
                  ],
                ),
                SizedBox(height: AppSpacing.sm),
                Text(
                  'الكمبيوتر هو صاحب قاعدة البيانات، والتليفون بيقرا ويكتب عليها. '
                  'أي تعديل على أي جهاز — جلسة، منتج، صنف، إعداد — بيتكرر على '
                  'الالتاني خلال ثواني من غير أي رفع على النت. الشبكة المحل بس، '
                  'مفيش إنترنت مطلوب.',
                  style: AppTypography.secondary,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _section('دور الجهاز', Icons.devices_rounded),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _RoleTile(
                  icon: Icons.desktop_windows_rounded,
                  title: 'الكمبيوتر',
                  subtitle: 'صاحب البيانات — السيرفر شغال عليه',
                  selected: role == 'master',
                  onTap: _busy ? null : () => _setRole('master'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RoleTile(
                  icon: Icons.phone_android_rounded,
                  title: 'التليفون',
                  subtitle: 'بيقرأ وبيكتب على بيانات الكمبيوتر',
                  selected: role == 'client',
                  onTap: _busy ? null : () => _setRole('client'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _RoleTile(
                  icon: Icons.link_off_rounded,
                  title: 'بدون مزامنة',
                  subtitle: 'الجهاز لوحده زي ما هو',
                  selected: role == 'off',
                  onTap: _busy ? null : () => _setRole('off'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (role == 'master') ...[
            _section('عنوان الكمبيوتر على الشبكة', Icons.lan_rounded),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ValueListenableBuilder<String>(
                    valueListenable: SyncRuntime.status,
                    builder: (_, status, __) => Text(
                      status,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'التليفون بيتصل على البورت ده. لازم الفايروول على ويندوز '
                    'يسمح بيه مرة واحدة:',
                    style: TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.glassFill,
                      borderRadius: AppRadius.mediumR,
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: SelectableText(
                      'netsh advfirewall firewall add rule name="PlayZone Sync" '
                      'dir=in action=allow protocol=TCP localport=$syncPort',
                      style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'monospace',
                          color: AppColors.textSecondary),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    children: [
                      SecondaryButton(
                        label: _checkingFirewall
                            ? '...'
                            : 'افتح البورت في فايروول ويندوز',
                        icon: Icons.shield_rounded,
                        onPressed:
                            (_busy || _checkingFirewall) ? null : _openFirewall,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          switch (SyncRuntime.firewallNote) {
                            'open' => 'البورت مفتوح — التليفون يقدر يوصل',
                            'manual' =>
                              'اترفض: شغّل البرنامج كمسؤول أو انسخ الأمر يدويًا',
                            'port' =>
                                'في نسخة تانية من البرنامج ماسكة البورت $syncPort',
                            _ =>
                              'لازم الفايروول يسمح بالبورت ده مرة واحدة قبل ما التليفون يوصل',
                          },
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textTertiary),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else if (role == 'client') ...[
            _section('عنوان الكمبيوتر', Icons.wifi_rounded),
            const SizedBox(height: AppSpacing.sm),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _url,
                    enabled: !_busy,
                    keyboardType: TextInputType.url,
                    decoration: const InputDecoration(
                      labelText: 'http://192.168.1.20:41779',
                      hintText: 'العنوان اللي ظاهر على شاشة الكمبيوتر',
                      filled: true,
                      fillColor: AppColors.glassFill,
                    ),
                    onSubmitted: (_) => _saveUrl(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      PrimaryButton(
                        label: _busy ? '...' : 'حفظ العنوان',
                        icon: Icons.save_rounded,
                        onPressed: _busy ? null : _saveUrl,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SecondaryButton(
                        label: _discovering ? 'ببحث…' : 'ابحث عن الكمبيوتر',
                        icon: Icons.search_rounded,
                        onPressed: (_busy || _discovering) ? null : _discover,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      SecondaryButton(
                        label: 'مزامنة الآن',
                        icon: Icons.sync_rounded,
                        onPressed: _busy ? null : _syncNow,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ] else ...[
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('المزامنة مطفية',
                      style: AppTypography.cardTitle),
                  const SizedBox(height: AppSpacing.sm),
                  const Text(
                    'اختار "الكمبيوتر" على الجهاز اللي فيه قاعدة البيانات، '
                    'و"التليفون" على باقي الأجهزة عشان تبدأ.',
                    style: AppTypography.secondary,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          _section('أوامر الشاشات و IR على الشبكة', Icons.tv_rounded),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('السماح لأوامر الشاشات والريموت',
                          style: AppTypography.cardTitle),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'لما يكون مقفول، مفيش ولا أمر بيتبعت لشاشات الكافيه '
                        'ولا لصندوق الـ IR من الجهاز ده — لا WOL ولا صور ولا '
                        'SSDP. التليفون بيشتغل كأداة تحكّم برضه، بس صور '
                        'الشاشة بتتبعت من الكمبيوتر بس.',
                        style: AppTypography.secondary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Switch(
                  value: _wall,
                  activeThumbColor: AppColors.accentPrimary,
                  onChanged: _busy ? null : (v) => _setWall(v),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          _section('الحالة', Icons.monitor_heart_rounded),
          const SizedBox(height: AppSpacing.sm),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ValueListenableBuilder<String>(
                  valueListenable: SyncRuntime.status,
                  builder: (_, status, __) => Text(status,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                ),
                const SizedBox(height: AppSpacing.xs),
                ValueListenableBuilder<DateTime?>(
                  valueListenable: SyncRuntime.lastExchange,
                  builder: (_, last, __) => Text(
                    last == null
                        ? 'لسه مفيش تبادل بيانات'
                        : 'آخر مزامنة: ${_ago(last)}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textTertiary),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _pending == 0
                      ? 'مفيش تعديلات معلّقة'
                      : '$_pending تعديل مستني يتبعث',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textTertiary),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'معرّف الجهاز: ${SyncRuntime.deviceId.isEmpty ? '—' : SyncRuntime.deviceId}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _ago(DateTime when) {
    final seconds = DateTime.now().difference(when).inSeconds;
    if (seconds < 10) return 'دلوقتي';
    if (seconds < 60) return 'من $seconds ثانية';
    if (seconds < 3600) return 'من ${seconds ~/ 60} دقيقة';
    return 'من ${seconds ~/ 3600} ساعة';
  }

  Widget _section(String title, IconData icon) => Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accentSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary)),
        ],
      );
}

/// One of the three roles, as a selectable card.
class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppTheme.hoverDuration,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accentPrimary.withValues(alpha: 0.14)
              : AppColors.glassFill,
          borderRadius: AppRadius.mediumR,
          border: Border.all(
            color: selected ? AppColors.accentPrimary : AppColors.glassBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon,
                size: 20,
                color: selected
                    ? AppColors.accentPrimary
                    : AppColors.textTertiary),
            const SizedBox(height: AppSpacing.sm),
            Text(title,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected
                        ? AppColors.textPrimary
                        : AppColors.textSecondary)),
            const SizedBox(height: 2),
            Text(subtitle,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textTertiary)),
          ],
        ),
      ),
    );
  }
}
