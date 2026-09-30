import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/device_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/tv/tv_display_service.dart';
import '../../core/tv/tv_power_service.dart';
import '../../core/widgets/app_buttons.dart';
import '../../data/repositories/device_repository.dart';
import 'tv_mode_screen.dart';

/// TV setup: which LG screen to drive, and whether the push is on.
/// Deliberately tiny — the IP is the only thing the café ever changes.
class TvSettingsCard extends ConsumerStatefulWidget {
  const TvSettingsCard({super.key});

  @override
  ConsumerState<TvSettingsCard> createState() => _TvSettingsCardState();
}

class _TvSettingsCardState extends ConsumerState<TvSettingsCard> {
  late final TextEditingController _ip;

  @override
  void initState() {
    super.initState();
    _ip = TextEditingController(
        text: ref.read(tvConfigProvider).ip);
  }

  @override
  void dispose() {
    _ip.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(tvConfigProvider);
    final notifier = ref.read(tvConfigProvider.notifier);
    final status = ref.watch(tvPushStatusProvider).valueOrNull;
    final service = TvDisplayService.instance;
    final devices = ref.watch(devicesWithTypeProvider).valueOrNull ??
        const <DeviceWithType>[];

    /// True when a screen has somewhere to talk to but nothing tells it when
    /// to act — the one broken state that looks perfectly configured.
    bool unbound(TvConfig c, String address, int? deviceId) =>
        address.trim().isNotEmpty && deviceId == null;

    bool _hasUnboundScreen(TvConfig c) =>
        unbound(c, c.ip, c.deviceId) ||
        (c.hasSecond && unbound(c, c.secondIp, c.secondDeviceId));


    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // A screen with an address but no machine attached is configured,
        // looks fine, and does nothing: it never wakes on a session and never
        // releases when one starts. This is silent otherwise, and it cost an
        // evening of blaming the TV. Say it on the screen instead.
        if (config.enabled && _hasUnboundScreen(config)) ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.sm),
            margin: const EdgeInsets.only(bottom: AppSpacing.sm),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppSpacing.sm),
              border: Border.all(
                  color: AppColors.danger.withValues(alpha: 0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'في شاشة عليها IP بس مش مربوطة بجهاز — '
                    'هتفضل سودا طول الوقت. اختار الجهاز من القايمة.',
                    style: TextStyle(
                        color: AppColors.textPrimary, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
        ],
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ip,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: const InputDecoration(
                  labelText: 'IP التلفزيون',
                  hintText: '192.168.1.22',
                  isDense: true,
                ),
                onSubmitted: notifier.setIp,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SecondaryButton(
              label: 'حفظ',
              icon: Icons.save_rounded,
              onPressed: () => notifier.setIp(_ip.text),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            const Text('الشاشة دي بتاعة جهاز:',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: DropdownButtonFormField<int?>(
                initialValue: config.deviceId,
                isExpanded: true,
                style:
                    const TextStyle(color: AppColors.textPrimary, fontSize: 13),
                dropdownColor: AppColors.bgElevated,
                decoration: const InputDecoration(isDense: true),
                hint: const Text('مفيش جهاز',
                    style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                items: [
                  // Previously this read "كل الأجهزة (اللي شغال)", which is
                  // what it does NOT do: an unbound screen is never steered,
                  // so it stays black through every session while looking
                  // configured. The label now says what actually happens.
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text('مفيش جهاز (الشاشة مش هتتشال)',
                        style: TextStyle(fontSize: 13)),
                  ),
                  for (final d in devices)
                    DropdownMenuItem<int?>(
                      value: d.device.id,
                      child: Text('${d.type.name} — ${d.device.name}',
                          style: const TextStyle(fontSize: 13)),
                    ),
                ],
                onChanged: (v) => notifier.setDevice(v),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ScreenRow(
          title: 'الشاشة الأولى (55 بوصة)',
          ip: config.ip,
          onIp: notifier.setIp,
          deviceId: config.deviceId,
          onDevice: notifier.setDevice,
          devices: devices,
        ),
        const SizedBox(height: AppSpacing.sm),
        _ScreenRow(
          title: 'الشاشة التانية (65 بوصة)',
          ip: config.secondIp,
          onIp: notifier.setSecondIp,
          deviceId: config.secondDeviceId,
          onDevice: notifier.setSecondDevice,
          devices: devices,
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: Text(
                'كل شاشة مربوطة بجهاز واحد: مع بدء جلسته ترجع للبلايستيشن على '
                'الكابل، وبعد تحصيله تتغمّض. هذا التلفزيون لا يقبل الإطفاء '
                'عبر الشبكة، فبعد التحصيل بتبعت إطار أسود بيبان مقفول.',
                style: TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
            ),
            SecondaryButton(
              label: 'جرّب فتح',
              icon: Icons.power_settings_new_rounded,
              onPressed: () {
                TvPowerService.instance.turnOn(config.ip);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('اتبعت أمر التشغيل — الشاشة هتفتح')));
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            SecondaryButton(
              label: 'جرّب إطفاء',
              icon: Icons.power_off_rounded,
              onPressed: () {
                TvPowerService.instance.turnOff(config.ip);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('اتبعت أمر الإطفاء — الشاشة هتغمض')));
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Switch(
              value: config.showCards,
              activeThumbColor: AppColors.accentPrimary,
              onChanged: (v) => notifier.setShowCards(v),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('اعرض كارت الوقت/السعر على التلفزيون',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Switch(
              value: config.enabled,
              activeThumbColor: AppColors.accentPrimary,
              onChanged: (v) => notifier.setEnabled(v),
            ),
            const SizedBox(width: AppSpacing.sm),
            const Text('ابعت الشاشة للتلفزيون',
                style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            const Spacer(),
            SecondaryButton(
              label: 'ابحث عن الشاشة',
              icon: Icons.wifi_find_rounded,
              onPressed: () {
                for (final ip in config.addresses) {
                  service.rediscover(ip);
                }
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('بفتّش على الشاشات… استنى 20 ثانية')));
              },
            ),
            const SizedBox(width: AppSpacing.sm),
            SecondaryButton(
              label: 'افتح السيرفر',
              icon: Icons.play_circle_outline_rounded,
              onPressed: () => service.startServer(),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: AppColors.glassFill,
            borderRadius: AppRadius.smallR,
            border: Border.all(color: AppColors.glassBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'عنوان الجهاز على الشبكة: ${status?.localAddress ?? "…"}  ·  '
                'البورت: ${service.portNumber}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              Text(
                status?.fetched == true
                    ? 'التلفزيون بيجيب الصورة — شغّال ✅'
                    : (status?.error ?? 'في انتظار أول بثّ من التلفزيون…'),
                style: TextStyle(
                  fontSize: 12,
                  color: status?.fetched == true
                      ? AppColors.statusAvailable
                      : AppColors.textTertiary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'لو البثّ المباشر مش ظاهر، اعمل Quit/Restart للتلفزيون مرة واحدة، '
                'وبعدها اضغط "بثّ" تاني. والطريقة المضمونة 100%: Win+K واختار '
                'التلفزيون (بثّ شاشة ويندوز) وأسيب البرنامج على شاشة التلفزيون.',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// One wall screen: where it lives, and which machine it follows.
///
/// The binding is the important part — a screen answers only to its own
/// console, so a checkout on any other machine leaves it alone.
class _ScreenRow extends StatelessWidget {
  const _ScreenRow({
    required this.title,
    required this.ip,
    required this.onIp,
    required this.deviceId,
    required this.onDevice,
    required this.devices,
  });

  final String title;
  final String ip;
  final ValueChanged<String> onIp;
  final int? deviceId;
  final ValueChanged<int?> onDevice;
  final List<DeviceWithType> devices;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.smallR,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 128,
            child: Text(
              title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary),
            ),
          ),
          SizedBox(
            width: 128,
            child: TextFormField(
              initialValue: ip,
              key: ValueKey('tv-ip-$title'),
              style: const TextStyle(fontSize: 12),
              decoration: const InputDecoration(
                isDense: true,
                hintText: '192.168.1.22',
                hintStyle: TextStyle(fontSize: 12),
              ),
              onChanged: onIp,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: DropdownButtonFormField<int?>(
              value: deviceId,
              isDense: true,
              decoration: const InputDecoration(
                isDense: true,
                labelText: 'الجهاز',
                labelStyle: TextStyle(fontSize: 11),
              ),
              items: [
                // An unbound screen is never steered, so it stays black
                // through every session. Say that here rather than letting
                // it look like a valid choice.
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('مفيش جهاز — مش هتتشال',
                      style: TextStyle(fontSize: 12)),
                ),
                for (final d in devices)
                  DropdownMenuItem<int?>(
                    value: d.device.id,
                    child: Text('${d.type.name} — ${d.device.name}',
                        style: const TextStyle(fontSize: 12)),
                  ),
              ],
              onChanged: onDevice,
            ),
          ),
        ],
      ),
    );
  }
}
