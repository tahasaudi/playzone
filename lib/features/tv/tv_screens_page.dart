import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/daos/device_dao.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_theme.dart';
import '../../core/theme/app_tokens.dart';
import '../../core/tv/tv_display_service.dart';
import '../../core/tv/tv_power_service.dart';
import '../../core/tv/tv_screen_report.dart';
import '../../data/repositories/device_repository.dart';
import 'tv_mode_screen.dart';

/// Every wall screen, by name, with a live verdict on it.
///
/// This page exists because "the TV" stopped being a single thing. With two
/// screens, an address in a log line and a counter in a status blob are not
/// enough to answer the only question that matters mid-shift: *which* screen,
/// and what about it. So each screen gets a panel of its own, named the way
/// the café names it, showing its state, the last thing we did to it, and —
/// when something is wrong — the one action that fixes it.
class TvScreensPage extends ConsumerStatefulWidget {
  const TvScreensPage({super.key});

  @override
  ConsumerState<TvScreensPage> createState() => _TvScreensPageState();
}

class _TvScreensPageState extends ConsumerState<TvScreensPage> {
  /// Which panels have their technical details open, by address.
  final Set<String> _expanded = <String>{};

  final Map<String, TextEditingController> _nameFields = {};
  final Map<String, TextEditingController> _ipFields = {};
  bool _seeded = false;

  @override
  void dispose() {
    for (final c in _nameFields.values) {
      c.dispose();
    }
    for (final c in _ipFields.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Fills the text fields once, from the saved settings.
  ///
  /// Seeded behind the config's `loaded` flag: the notifier starts on
  /// hardcoded defaults, and a field seeded from those would then be wrong —
  /// worse, it would fight the person typing in it.
  void _seed(TvConfig config) {
    if (_seeded || !config.loaded) return;
    // Seeded per screen from that screen's own slot, keyed by its storage
    // index. Keying by list position instead would hand the first screen's
    // text to whichever screen moved into its place after a screen was cleared.
    for (final slot in config.slots) {
      _nameFields['name${slot.index}'] ??=
          TextEditingController(text: slot.name);
      _ipFields['ip${slot.index}'] ??=
          TextEditingController(text: slot.ip.trim());
    }
    _seeded = true;
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 3),
      ));
  }

  /// Reads the true state of one screen, right now, without touching the
  /// network beyond a single request. This is the fast button: it answers in
  /// well under a second, so nobody has to guess or wait.
  Future<void> _probe(String ip, String name) async {
    final service = TvDisplayService.instance;
    _say('بنفحص $name…');
    final ok = await service.probeTransport(ip);
    if (!ok) {
      // No endpoint yet means "we have never found this screen", which is a
      // search problem rather than a state problem — say which it is.
      final known = service.hasControlUrlFor(ip);
      _say(known
          ? '$name مش بترد دلوقتي'
          : '$name لسه متعرفناش — دوس «ابحث عن الشاشة»');
    } else {
      _say('$name ردت ✅');
    }
  }

  Future<void> _search(String ip, String name) async {
    _say('بندوّر على $name… استنى ثانية');
    TvDisplayService.instance.rediscover(ip);
    // A sweep takes the best part of ten seconds; tell the truth about the
    // wait instead of leaving a button that looks broken.
    Future<void>.delayed(const Duration(seconds: 12), () {
      if (mounted) _say('خلصنا البحث عن $name');
    });
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(tvConfigProvider);
    _seed(config);
    final reports = ref.watch(tvScreenReportsProvider).valueOrNull ??
        TvDisplayService.instance.reports();
    final devices = ref.watch(devicesWithTypeProvider).valueOrNull ??
        const <DeviceWithType>[];

    // Each panel is built by a method rather than inline in the loop. Every
    // button below captures the screen it belongs to, and a closure written
    // inside a `for` body captures the *final* value of the loop variable —
    // which would have made every screen's buttons steer the last screen.
    final panels = <Widget>[
      for (final slot in config.slots)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: _panel(slot, config, reports, devices),
        ),
    ];

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        // Two copies of this program on one machine used to fail silently: the
        // second one could not open the picture port, said nothing, and then
        // argued with the first one over who owns each wall. The staff saw a
        // screen that went black when it should have shown the game, and back
        // when it should have been black, and neither half of that is
        // explainable from the page they were looking at. Said once, plainly,
        // at the top, because it is the one fault on this page that the person
        // using it can fix by closing a window.
        if (TvDisplayService.instance.anotherCopyRunning)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _DuplicateCopyWarning(),
          ),
        _Header(reports: reports, enabled: config.enabled),
        const SizedBox(height: AppSpacing.md),
        ...panels,
        const SizedBox(height: AppSpacing.xs),
        // A television that is on the wall but not in this list cannot be
        // switched off at checkout, so adding one is a normal thing to do and
        // not something to hide behind a repair manual. Hidden at the ceiling
        // because past that the additions are more likely a mistake than a
        // plan.
        if (config.canAddSlot)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('＋ شاشة جديدة'),
              onPressed: () {
                final index = ref.read(tvConfigProvider.notifier).addSlot();
                if (index == null) {
                  _say('وصلنا للحد الأقصى');
                  return;
                }
                // Re-seeded so the new panel's fields appear with the screen
                // already named, instead of two blank boxes to fill in.
                setState(() {
                  _seeded = false;
                  _seed(ref.read(tvConfigProvider));
                });
                _say('ضيف عنوان الشاشة واسمها');
              },
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Text(
              'وصلنا لحد ${TvConfig.maxSlots} شاشات — وده كل اللي في المحل.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        _Switches(
          enabled: config.enabled,
          showCards: config.showCards,
          onEnabled: ref.read(tvConfigProvider.notifier).setEnabled,
          onShowCards: ref.read(tvConfigProvider.notifier).setShowCards,
        ),
        const SizedBox(height: AppSpacing.md),
        _Footer(
          enabled: config.enabled,
          running: TvDisplayService.instance.isRunning,
          localAddress: TvDisplayService.instance.localAddress,
          port: TvDisplayService.instance.portNumber,
          onStartServer: () => TvDisplayService.instance.startServer(),
        ),
      ],
    );
  }

  /// The panel for one configured screen, wired to that screen and to no other.
  ///
  /// Everything below is written against the slot rather than against "the
  /// first screen" or "the second screen", so a third television is built by
  /// exactly the same code and cannot be wired to the wrong screen's settings.
  Widget _panel(
    TvScreenSlot slot,
    TvConfig config,
    List<TvScreenReport> reports,
    List<DeviceWithType> devices,
  ) {
    final notifier = ref.read(tvConfigProvider.notifier);
    final identity = slot.identity;
    final ip = identity.ip.trim();
    // Keyed by the slot's own storage index, not by its position in the list,
    // so the text fields keep following their screen when an earlier one is
    // cleared.
    final key = slot.index;
    return _ScreenPanel(
      index: key,
      report: _findReport(reports, ip),
      identity: identity,
      nameField: _nameFields['name$key'],
      ipField: _ipFields['ip$key'],
      deviceId: slot.deviceId,
      devices: devices,
      expanded: _expanded.contains(ip),
      onToggleExpanded: () => setState(() {
        if (!_expanded.remove(ip)) _expanded.add(ip);
      }),
      onName: (v) => notifier.saveSlot(key, name: v),
      onIp: (v) async {
        final clash = await notifier.saveSlot(key, ip: v);
        if (clash == -1) _say('العنوان ده مستخدم في شاشة تانية');
      },
      onDevice: (id) async {
        final clash = await notifier.saveSlot(
          key,
          deviceId: id,
          clearDevice: id == null,
        );
        // Said plainly and by name, because the alternative is a machine that
        // quietly drives two walls and a checkout that blanks the wrong one.
        if (clash != null) {
          final other = config.slots
              .where((s) => s.index != key && s.deviceId == clash)
              .firstOrNull;
          _say('الجهاز ده مربوط بالفعل بـ${other?.name ?? 'شاشة تانية'}');
        }
      },
      onProbe: () => _probe(ip, identity.name),
      onSearch: () => _search(ip, identity.name),
      onOpen: () {
        TvPowerService.instance.turnOn(ip);
        _say('بتفتح ${identity.name}');
      },
      onClose: () {
        TvPowerService.instance.turnOff(ip);
        _say('بتغمّض ${identity.name}');
      },
    );
  }

  /// A panel and a report can end up describing different addresses when the
  /// settings change under a live provider, so match on the address and fall
  /// back to judging on the spot rather than showing another screen's facts.
  TvScreenReport? _findReport(List<TvScreenReport> reports, String ip) {
    for (final r in reports) {
      if (r.ip == ip.trim()) return r;
    }
    return null;
  }
}

/// One line for the whole shop: how many screens are fine, and — when one is
/// not — which one, by name, before anybody has to read anything else.
/// Shown only when this program found the picture port already taken.
///
/// The wording is deliberately blunt and names the fix, because the person
/// reading it cannot see the cause from where they are standing and will
/// otherwise go looking for a television problem that does not exist.
class _DuplicateCopyWarning extends StatelessWidget {
  const _DuplicateCopyWarning();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: AppRadius.mediumR,
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.copy_all_rounded, size: 18, color: AppColors.warning),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'البرنامج مفتوح مرتين',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.warning,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'اقفل النسخة القديمة وافتح نسخة واحدة بس — النسخة اللي '
                  'فاتحة هي اللي بتحكم الشاشات.',
                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.reports, required this.enabled});

  final List<TvScreenReport> reports;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final total = reports.length;
    final bad = reports.where((r) => r.severity == TvSeverity.bad).toList();
    final warn = reports.where((r) => r.severity == TvSeverity.warn).toList();
    final good = total - bad.length - warn.length;
    final clean = bad.isEmpty && warn.isEmpty;

    final Color tone = !enabled
        ? AppColors.textTertiary
        : bad.isNotEmpty
            ? AppColors.danger
            : warn.isNotEmpty
                ? AppColors.warning
                : AppColors.statusAvailable;
    final IconData icon = !enabled
        ? Icons.pause_circle_outline_rounded
        : bad.isNotEmpty
            ? Icons.error_outline_rounded
            : warn.isNotEmpty
                ? Icons.warning_amber_rounded
                : Icons.verified_rounded;

    final String headline = !enabled
        ? 'شاشات التلفزيون متوقفة'
        : clean
            ? 'كل الشاشات تمام ($good من $total)'
            : '${bad.length + warn.length} شاشة محتاجة انتباه من $total';
    final String? named = bad.isNotEmpty
        ? bad.map((r) => r.name).join('، ')
        : warn.isNotEmpty
            ? warn.map((r) => r.name).join('، ')
            : null;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.10),
        borderRadius: AppRadius.mediumR,
        border: Border.all(color: tone.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Icon(icon, color: tone, size: 22),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  headline,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (named != null) ...[
                  const SizedBox(height: 2),
                  Text('فيها مشكلة: $named',
                      style: TextStyle(color: tone, fontSize: 12)),
                ],
              ],
            ),
          ),
          // Dots per screen, in the same order as the panels below, so the
          // header and the list can never be read against each other.
          Row(
            children: [
              for (final r in reports.reversed)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: '${r.name}: ${r.label}',
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _toneFor(r.severity),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.25)),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

Color _toneFor(TvSeverity severity) => switch (severity) {
      TvSeverity.ok => AppColors.statusAvailable,
      TvSeverity.warn => AppColors.warning,
      TvSeverity.bad => AppColors.danger,
    };

IconData _iconFor(TvScreenState state) => switch (state) {
      TvScreenState.loading => Icons.hourglass_empty_rounded,
      TvScreenState.disabled => Icons.pause_circle_outline_rounded,
      TvScreenState.noAddress => Icons.help_outline_rounded,
      TvScreenState.unbound => Icons.link_off_rounded,
      TvScreenState.unreachable => Icons.nightlight_round,
      TvScreenState.refused => Icons.block_rounded,
      TvScreenState.suspect => Icons.sync_problem_rounded,
      TvScreenState.unknown => Icons.hourglass_top_rounded,
      TvScreenState.showing => Icons.slideshow_rounded,
      TvScreenState.stalePlayback => Icons.history_rounded,
      TvScreenState.released => Icons.sports_esports_rounded,
      TvScreenState.transitioning => Icons.autorenew_rounded,
      TvScreenState.wedged => Icons.report_problem_rounded,
      TvScreenState.dark => Icons.brightness_2_rounded,
    };

/// The icon for a report rather than a bare state, because the wording can be
/// escalated above the state: a dark screen during an empty shop and a dark
/// screen with somebody playing on it share a state and must not share an
/// icon that says "nothing to see here".
IconData _reportIcon(TvScreenReport r) => r.severity == TvSeverity.bad &&
        (r.state == TvScreenState.unreachable ||
            r.state == TvScreenState.dark ||
            r.state == TvScreenState.unknown)
    ? Icons.error_outline_rounded
    : _iconFor(r.state);

/// A status chip. Colour alone is never the message here: the icon and the
/// words carry it, so it still reads correctly for someone who cannot tell
/// amber from red — which is exactly the moment a status light matters most.
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.tone, required this.icon});

  final String label;
  final Color tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: tone.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tone),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tone,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

/// A small labelled fact. Used instead of free text so the panel reads as the
/// same shape for every screen and nothing is left to interpretation.
class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {this.tone});

  final String label;
  final String value;
  final Color? tone;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textTertiary, height: 1.1)),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: tone ?? AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// One screen: its name, its state, its history, and the buttons that act on
/// that screen alone.
class _ScreenPanel extends StatelessWidget {
  const _ScreenPanel({
    required this.index,
    required this.report,
    required this.identity,
    required this.nameField,
    required this.ipField,
    required this.deviceId,
    required this.devices,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onName,
    required this.onIp,
    required this.onDevice,
    required this.onProbe,
    required this.onSearch,
    required this.onOpen,
    required this.onClose,
  });

  final int index;
  final TvScreenReport? report;
  final TvScreenIdentity identity;
  final TextEditingController? nameField;
  final TextEditingController? ipField;
  final int? deviceId;
  final List<DeviceWithType> devices;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final ValueChanged<String> onName;
  final ValueChanged<String> onIp;
  final ValueChanged<int?> onDevice;
  final VoidCallback onProbe;
  final VoidCallback onSearch;
  final VoidCallback onOpen;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final tone = r == null ? AppColors.textTertiary : _toneFor(r.severity);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.mediumR,
        border: Border.all(
            color: tone.withValues(alpha: 0.35), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameField,
                      key: ValueKey('tv-name-$index'),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                        hintText: 'اسم الشاشة',
                        hintStyle: TextStyle(
                            fontSize: 15, color: AppColors.textTertiary),
                      ),
                      onChanged: onName,
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.lan_rounded,
                            size: 12, color: AppColors.textTertiary),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 132,
                          child: TextFormField(
                            controller: ipField,
                            key: ValueKey('tv-ip-$index'),
                            style: const TextStyle(fontSize: 12),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: '192.168.1.22',
                              hintStyle: TextStyle(
                                  fontSize: 12, color: AppColors.textTertiary),
                            ),
                            onChanged: onIp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _Pill(
                label: r?.label ?? 'بنفحص…',
                tone: tone,
                icon: r == null
                    ? Icons.hourglass_empty_rounded
                    : _reportIcon(r),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Which machine this screen follows. The single most important
          // setting on the panel, so it gets a full row and a name that
          // explains itself when it is empty.
          Row(
            children: [
              const Text('مربوطة بجهاز:',
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textTertiary)),
              const SizedBox(width: AppSpacing.sm),
              SizedBox(
                width: 210,
                child: DropdownButtonFormField<int?>(
                  initialValue: deviceId,
                  isDense: true,
                  isExpanded: true,
                  dropdownColor: AppColors.bgElevated,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textPrimary),
                  decoration: const InputDecoration(isDense: true),
                  items: [
                    // Unbound is a fault, not a choice, and it used to be
                    // labelled as if it meant "every device" when it means
                    // "none" — which is how a wall screen sat black all night
                    // while the page looked configured.
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('مفيش جهاز — هتفضل سودا',
                          style: TextStyle(fontSize: 12)),
                    ),
                    for (final d in devices)
                      DropdownMenuItem<int?>(
                        value: d.device.id,
                        child: Text('${d.type.name} — ${d.device.name}',
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12)),
                      ),
                  ],
                  onChanged: onDevice,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              _Pill(
                label: identity.sessionRunning ? 'فيه جلسة دلوقتي' : 'مفيش جلسة',
                tone: identity.sessionRunning
                    ? AppColors.statusActive
                    : AppColors.textTertiary,
                icon: identity.sessionRunning
                    ? Icons.timer_rounded
                    : Icons.nightlight_outlined,
              ),
            ],
          ),

          // Shown only when the panel's own answer and what it actually did disagree.
          // Saying so is the whole point: a wall that reports "playing" while it
          // has not fetched anything is on the console, and reading the claim
          // instead of the evidence is how a working screen gets reported as
          // broken and somebody walks over to a television that was fine.
          if (r != null && r.claimVsEvidence.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              r.claimVsEvidence,
              style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
            ),
          ],
          // The one action that fixes it, when there is one. This is the
          // difference between a status page and a tool: it never stops at
          // naming the problem.
          if (r != null && r.remedy.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: tone.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(AppRadius.small),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline_rounded, size: 15, color: tone),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      r.remedy,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textPrimary, height: 1.35),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (r != null && r.fault != null && r.fault!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text('خطأ: ${r.fault}  (${tvAge(r.faultAt)})',
                style: const TextStyle(fontSize: 11, color: AppColors.danger)),
          ],

          const SizedBox(height: AppSpacing.sm),
          _Divider(),
          const SizedBox(height: AppSpacing.sm),

          // The facts, in a fixed shape so two screens are directly
          // comparable at a glance.
          Wrap(
            spacing: AppSpacing.xl,
            runSpacing: AppSpacing.sm,
            children: [
              _Fact(
                'آخر أمر',
                r == null || r.lastCommand == null
                    ? 'لسه'
                    : '${r.lastCommand} → ${r.lastResult ?? "؟"}',
                tone: r == null
                    ? null
                    : r.lastOk
                        ? AppColors.statusAvailable
                        : AppColors.danger,
              ),
              _Fact(
                'وقته',
                r?.lastTookMs == null ? '—' : '${r?.lastTookMs} مللي',
              ),
              _Fact(
                'جابت الصورة',
                r == null ? '—' : '${r.imagesServed} مرة',
              ),
              // What the wall is showing, as measured rather than as claimed.
              // The panel keeps answering "playing" for a while after it has
              // been handed back to the console, and reporting that as the
              // state would send someone to fix a screen that is working.
              _Fact(
                'بتعرض إيه',
                r == null || r.showingOurs == null
                    ? 'مش متأكد'
                    : r.showingOurs!
                        ? 'الصورة بتاعتنا'
                        : 'رجعت للجهاز',
              ),
              _Fact('آخر مرة', tvAge(r?.lastFetchAt)),
              _Fact(
                'عنوانها',
                r == null || r.endpoint.isEmpty
                    ? 'لسه'
                    : Uri.tryParse(r.endpoint)?.authority ?? r.endpoint,
              ),
              _Fact('ردّت في', r?.pingMs == null ? '—' : '${r?.pingMs} مللي'),
            ],
          ),

          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ActionChip(
                  label: 'افتح', icon: Icons.power_settings_new_rounded, onTap: onOpen),
              const SizedBox(width: 6),
              _ActionChip(
                  label: 'غمّض',
                  icon: Icons.brightness_2_rounded,
                  onTap: onClose),
              const SizedBox(width: 6),
              _ActionChip(
                label: 'فحص',
                icon: Icons.network_check_rounded,
                onTap: onProbe,
                busy: r?.probing ?? false,
              ),
              const SizedBox(width: 6),
              _ActionChip(
                  label: 'ابحث عن الشاشة',
                  icon: Icons.wifi_find_rounded,
                  onTap: onSearch),
              const Spacer(),
              if (r != null && r.events.isNotEmpty)
                TextButton.icon(
                  onPressed: onToggleExpanded,
                  icon: Icon(
                      expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: AppColors.textSecondary),
                  label: Text(
                    expanded ? 'اخفي السجل' : 'سجل الشاشة (${r.events.length})',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                  ),
                ),
            ],
          ),

          if (expanded && r != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _EventLog(events: r.events),
          ],
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        height: 1,
        color: AppColors.glassBorder,
      );
}

/// The screen's own history, newest first, with the clock time on every line.
///
/// This is what answers "did it work last night?" without a terminal — the
/// question that used to need a port scan and a log file to answer at all.
class _EventLog extends StatelessWidget {
  const _EventLog({required this.events});

  final List<TvScreenEvent> events;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(AppRadius.small),
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in events)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  SizedBox(
                    width: 62,
                    child: Text(
                      tvClock(e.at),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textTertiary,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Icon(
                    e.ok
                        ? Icons.check_circle_outline_rounded
                        : Icons.error_outline_rounded,
                    size: 13,
                    color: e.ok ? AppColors.statusAvailable : AppColors.danger,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      e.text,
                      style: TextStyle(
                        fontSize: 11,
                        color: e.ok
                            ? AppColors.textSecondary
                            : AppColors.danger,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// A compact action. Deliberately smaller than the shared button: four of
/// these have to sit on one row beside a name and a status.
class _ActionChip extends StatefulWidget {
  const _ActionChip({
    required this.label,
    required this.icon,
    required this.onTap,
    this.busy = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool busy;

  @override
  State<_ActionChip> createState() => _ActionChipState();
}

class _ActionChipState extends State<_ActionChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.busy;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: AppTheme.hoverDuration,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: _hover && enabled
                ? AppColors.glassFillStrong
                : AppColors.glassFill,
            borderRadius: BorderRadius.circular(AppRadius.small),
            border: Border.all(
                color: _hover && enabled
                    ? AppColors.glassBorderPurple
                    : AppColors.glassBorder),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.busy)
                const SizedBox(
                  width: 13,
                  height: 13,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(widget.icon,
                    size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(
                widget.label,
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Switches extends StatelessWidget {
  const _Switches({
    required this.enabled,
    required this.showCards,
    required this.onEnabled,
    required this.onShowCards,
  });

  final bool enabled;
  final bool showCards;
  final ValueChanged<bool> onEnabled;
  final ValueChanged<bool> onShowCards;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.glassFill,
        borderRadius: AppRadius.mediumR,
        border: Border.all(color: AppColors.glassBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Switch(
                value: enabled,
                activeThumbColor: AppColors.accentPrimary,
                onChanged: onEnabled,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('ابعت الشاشات للتلفزيون',
                  style:
                      TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              const Spacer(),
              Switch(
                value: showCards,
                activeThumbColor: AppColors.accentPrimary,
                onChanged: onShowCards,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('اعرض كارت الوقت على الشاشة',
                  style:
                      TextStyle(color: AppColors.textPrimary, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'كل شاشة مربوطة بجهاز واحد: مع بدء جلسته ترجع للبلايستيشن على '
            'الكابل، وبعد تحصيله تتغمّض. الشاشات دي ما بتقبلش إطفاء كهربائي '
            'عبر الشبكة، فبعد التحصيل بتبعت إطار أسود بيبان مقفول.',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
          ),
        ],
      ),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer({
    required this.enabled,
    required this.running,
    required this.localAddress,
    required this.port,
    required this.onStartServer,
  });

  final bool enabled;
  final bool running;
  final String? localAddress;
  final int port;
  final VoidCallback onStartServer;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _Pill(
          label: running ? 'السيرفر شغال' : 'السيرفر واقف',
          tone: running ? AppColors.statusAvailable : AppColors.warning,
          icon: running
              ? Icons.dns_rounded
              : Icons.power_off_rounded,
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(
          'عنوان الجهاز على الشبكة: ${localAddress ?? "…"}  ·  البورت: $port',
          style: const TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        const Spacer(),
        if (!running)
          TextButton.icon(
            onPressed: onStartServer,
            icon: const Icon(Icons.play_circle_outline_rounded, size: 15),
            label: const Text('افتح السيرفر',
                style: TextStyle(fontSize: 12)),
          ),
        if (!enabled)
          const Padding(
            padding: EdgeInsets.only(right: 8),
            child: Text('الشاشات متوقفة دلوقتي',
                style: TextStyle(fontSize: 11, color: AppColors.warning)),
          ),
      ],
    );
  }
}
