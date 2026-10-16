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

  /// MACs resolved for addresses that are not in the shop's fixed table, so the
  /// label next to an address can follow that address instead of going blank
  /// for anything the table did not happen to list.
  final Map<String, String?> _macCache = {};
  final Set<String> _macPending = <String>{};

  /// True while a "اكتشف الشاشات بالماك" sweep is running, so the button can
  /// say it is working instead of looking dead.
  bool _discovering = false;

  /// Edits one screen's name in a small dialog.
  ///
  /// The name is shown as a label with a pencil rather than as a live text
  /// field: the old inline box looked like plain text, so staff could not tell
  /// it was editable, and typing into it wrote a half-finished name on every
  /// keystroke.
  Future<void> _editName(int index, String current) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.glassFill,
        title: const Text('اسم الشاشة'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: 'مثال: الشاشة الأولى'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    await ref
        .read(tvConfigProvider.notifier)
        .saveSlot(index, name: result.trim());
  }

  /// Edits one screen's address in a small dialog, keeping the same
  /// "this address is already another screen" check the old inline field had.
  ///
  /// Saving the new address is only half the job. Everything the app knew about
  /// this screen — its endpoint, its state, whether it answers — was learned on
  /// the OLD address, and keeping that next to the new one is what made two
  /// screens look mixed up. So the moment the address changes, this runs the
  /// same lookup the "ابحث عن الشاشة" button runs, on the address that was just
  /// typed, and the panel is rebuilt against that.
  Future<void> _editAddress(int index, String current, String name) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.glassFill,
        title: const Text('عنوان الشاشة (IP)'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: '192.168.1.22'),
          onSubmitted: (v) => Navigator.of(ctx).pop(v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text),
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !mounted) return;
    final value = result.trim();
    if (value.isEmpty) return;
    if (value == current.trim()) return;
    if (!_looksLikeAddress(value)) {
      _say('العنوان لازم يكون زي 192.168.1.22');
      return;
    }
    final clash =
        await ref.read(tvConfigProvider.notifier).saveSlot(index, ip: value);
    if (!mounted) return;
    if (clash == -1) {
      _say('العنوان ده مستخدم في شاشة تانية');
      return;
    }
    // Follow the address we were just given: forget the old one's endpoint and
    // look the screen up on the new one, so the panel describes this screen and
    // not whichever screen the old address belonged to.
    unawaited(_search(value, name));
  }

  /// Whether [value] could be a screen address.
  ///
  /// Checked before saving, because an address is the one field where a typo
  /// does not merely look wrong: a half-typed "192.168.1." saved as a real
  /// address points this screen at a wall that does not exist, and the screen
  /// it used to manage keeps answering on the old address — which is exactly
  /// what "الشاشات متلغبطة" looks like from the counter.
  static bool _looksLikeAddress(String value) {
    final parts = value.split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) return false;
    }
    return true;
  }

  /// Looks up the MAC for an address that is not in the fixed table, once,
  /// and rebuilds when it answers. This is what makes the MAC follow the
  /// address: it is never typed, it is looked up from the address on screen.
  void _learnMac(String ip) {
    final clean = ip.trim();
    if (clean.isEmpty) return;
    if (TvPowerService.primaryMacFor(clean) != null) return;
    if (_macCache.containsKey(clean)) return;
    if (!_macPending.add(clean)) return;
    TvPowerService.resolveMac(clean).then((mac) {
      _macPending.remove(clean);
      if (!mounted) return;
      setState(() => _macCache[clean] = mac);
    });
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

  /// When a MAC sweep comes back empty, a bare "not found" leaves everybody
  /// guessing. This shows the whole neighbour table instead, so it is obvious
  /// whether the television is simply absent from the network — and the same
  /// list doubles as the answer to "is this machine even on the network at
  /// all?".
  Future<void> _showNeighbours(Map<String, String> byMac) async {
    if (!mounted) return;
    // byMac is keyed by the hardware address, so the value is the address it
    // answers on right now.
    final rows = byMac.entries.map((e) => '${e.value}   (${e.key})').toList()
      ..sort();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.glassFill,
        title: const Text('مفيش شاشة من شاشاتنا على الشبكة'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(rows.isEmpty
                    ? 'مش شايفين أي جهاز على الشبكة خالص من الجهاز ده.'
                    : 'الأجهزة اللي شايفينها دلوقتي (${rows.length}):'),
                const SizedBox(height: 8),
                for (final row in rows)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(row),
                  ),
                const SizedBox(height: 12),
                const Text(
                  'لو التلفزيون مش في القايمة دي، يبقى مش على نفس الشبكة '
                  '(أو مقفول ومش بيسمع الشبكة وهو مطفي).',
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('تمام'),
          ),
        ],
      ),
    );
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
    final address = ip.trim();
    if (address.isEmpty) {
      _say('$name: اكتب عنوان الشاشة الأول');
      return;
    }
    _say('بندوّر على $name…');
    final found = await TvDisplayService.instance.searchNow(address);
    if (!mounted) return;
    if (found) {
      _say('لقينا $name ✅');
      return;
    }
    // The address typed here can be stale — the router hands out new ones and
    // a wall that moved answers on neither the old address nor this port set.
    // Fall back to hunting by the MAC it kept, which is exactly what
    // "ابحث عن الشاشة" has to mean for a screen that moved.
    _say('$name مش رادّ على العنوان ده — بدوّر عليها بالماك…');
    await _discoverScreens();
  }

  /// Finds every screen by the MAC it kept, not by the address it used to be
  /// on.
  ///
  /// "ابحث عن الشاشة" only searches the address already typed for one panel,
  /// so it cannot find a wall the router moved. A MAC survives that move — a
  /// router hands out addresses, never MACs — so the sweep here reads the
  /// machine's neighbour table, matches each screen's known MAC to whatever
  /// address answers now, and writes the new address back. Run after a router
  /// change, it puts the whole room back on its own.
  Future<void> _discoverScreens() async {
    if (_discovering) return;
    setState(() => _discovering = true);
    _say('بندوّر على الشاشات بالماك… استنى ثانية');
    try {
      final notifier = ref.read(tvConfigProvider.notifier);
      // Keep a screen that has no address yet when we still remember its MAC:
      // that is exactly the screen a moved router leaves behind, and skipping
      // every blank slot was why such a screen could never be found again.
      final slots = <TvScreenSlot>[];
      for (final slot in ref.read(tvConfigProvider).editSlots) {
        if (!slot.isEmpty) {
          slots.add(slot);
          continue;
        }
        if ((await notifier.storedMacsFor(slot.index)).trim().isNotEmpty) {
          slots.add(slot);
        }
      }
      if (slots.isEmpty) {
        _say('مفيش شاشات مضافة');
        return;
      }

      // Work out which MACs we are actually hunting for before touching the
      // network — the sweep stops the instant every one has answered instead of
      // waiting out a fixed budget.
      final candidatesBySlot = <int, Set<String>>{};
      final targets = <String>{};
      for (final slot in slots) {
        // Two sources of truth, together: the MACs the shop's table knows for
        // this address, and the MACs we tied to this screen last time — so a
        // screen found once stays findable on every later move.
        final candidates = <String>{
          ...TvPowerService.knownMacsFor(slot.ip.trim())
              .map((m) => m.toUpperCase()),
          ...(await notifier.storedMacsFor(slot.index))
              .split(',')
              .map((m) => m.trim().toUpperCase())
              .where((m) => m.isNotEmpty),
        };
        candidatesBySlot[slot.index] = candidates;
        targets.addAll(candidates);
      }

      // discoverNeighbours already returns the neighbour table keyed by the
      // hardware address (MAC → IP). It used to be flipped back the wrong way
      // here, so every lookup by MAC missed and the button silently reported
      // "all screens are fine" without ever fetching an address.
      final byMac = await TvPowerService.discoverNeighbours(targets: targets);
      if (!mounted) return;

      var updated = 0;
      var matched = 0;
      final changes = <String>[];
      for (final slot in slots) {
        final current = slot.ip.trim();
        final candidates = candidatesBySlot[slot.index]!;
        if (candidates.isEmpty) {
          // A screen the table never listed: ask its current address once and
          // remember what it answers with, so the next move is covered too.
          final learned = await TvPowerService.resolveMac(current);
          if (learned == null) continue;
          candidates.add(learned.toUpperCase());
        }

        String? foundIp;
        for (final mac in candidates) {
          final ip = byMac[mac];
          if (ip != null) {
            foundIp = ip;
            matched++;
            break;
          }
        }
        // Keep what this screen answers with, so it can be recognised again.
        await notifier.setStoredMacs(slot.index, candidates.join(','));

        if (foundIp == null || foundIp == current) continue;
        final result = await notifier.saveSlot(slot.index, ip: foundIp);
        if (result == -1) continue; // another screen already holds that address
        updated++;
        changes.add('${slot.name}: $current → $foundIp');
      }

      if (!mounted) return;
      if (updated == 0) {
        if (matched == 0) {
          _say('ملقيناش الشاشات على الشبكة — شوف الأجهزة اللي ظاهرة');
          await _showNeighbours(byMac);
        } else {
          _say('كل الشاشات على عناوينها الصح ✅');
        }
      } else if (updated == 1) {
        _say('اتظبطت شاشة: ${changes.first}');
      } else {
        _say('اتظبطت $updated شاشة ✅');
      }
    } catch (e) {
      if (mounted) _say('تعذّر الاكتشاف: $e');
    } finally {
      if (mounted) setState(() => _discovering = false);
    }
  }

  /// Paints this screen's own name across the television, so a person can tell
  /// which wall an entry belongs to without reading MAC addresses off five
  /// TVs. It comes down by itself after a few seconds.
  Future<void> _identify(String ip, String name) async {
    if (ip.trim().isEmpty) {
      _say('اكتب عنوان الشاشة الأول');
      return;
    }
    _say('هنكتب اسم $name على التلفزيون… بص على الشاشة');
    final ok = await TvDisplayService.instance.identify(
      ip.trim(),
      name: name.trim().isEmpty ? ip.trim() : name.trim(),
      mac: TvPowerService.primaryMacFor(ip.trim()),
    );
    _say(ok
        ? 'عرّفنا $name ✅'
        : '$name مردّتش دلوقتي — دوس «ابحث عن الشاشة» وجرّب تاني');
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(tvConfigProvider);
    final reports = ref.watch(tvScreenReportsProvider).valueOrNull ??
        TvDisplayService.instance.reports();
    // In the café's own walk order, matching the board. This list is walked
    // with a remote in one hand and a notepad in the other; a page that read
    // 3, 1, 2 here while the board read 1, 2, 3 made the person configuring a
    // wall check the same machine twice.
    final devices = List.of(ref.watch(devicesWithTypeProvider).valueOrNull ??
        const <DeviceWithType>[])
      ..sort((a, b) => compareDeviceNumbers(a.device.name, b.device.name));
    final deviceNameById = {
      for (final d in devices) d.device.id: d.device.name,
    };

    // Each panel is built by a method rather than inline in the loop. Every
    // button below captures the screen it belongs to, and a closure written
    // inside a `for` body captures the *final* value of the loop variable —
    // which would have made every screen's buttons steer the last screen.
    //
    // Ordered by the machine each screen is bound to, not by the order they
    // were typed in. Screens with nothing bound go to the bottom, because
    // there is no machine to place them by, and tie-break on the storage index
    // so `sort`'s lack of stability cannot shuffle them between rebuilds.
    final panels = <Widget>[
      for (final slot in _slotsInRoomOrder(config.editSlots, deviceNameById))
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
                _say('دوس ✎ عشان تكتب عنوان الشاشة واسمها');
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
        const SizedBox(height: AppSpacing.xs),
        // The nets that find a screen whose address changed. "ابحث عن الشاشة"
        // on a panel only searches the address that panel already has, so after
        // a router hands the room new addresses this is the button that puts it
        // back — matching each screen by the MAC it kept.
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: OutlinedButton.icon(
            onPressed: _discovering ? null : _discoverScreens,
            icon: _discovering
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.wifi_find_rounded, size: 18),
            label: const Text('اكتشف الشاشات بالماك'),
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

  /// [slots] in the order a person walks the room.
  ///
  /// A total order, deliberately: two screens bound to the same machine, or two
  /// bound to nothing, would otherwise tie and be free to swap places on every
  /// rebuild — a list that reorders itself while you are reading it. The
  /// storage index settles those ties, and it is stable for the life of the
  /// slot.
  List<TvScreenSlot> _slotsInRoomOrder(
    List<TvScreenSlot> slots,
    Map<int, String> deviceNameById,
  ) {
    final byRoom = List.of(slots);
    byRoom.sort((a, b) {
      final rank = compareDeviceNumbers(
        deviceNameById[a.deviceId] ?? '',
        deviceNameById[b.deviceId] ?? '',
      );
      return rank != 0 ? rank : a.index.compareTo(b.index);
    });
    return byRoom;
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
    // The MAC belongs to the address, so it is looked up from it. The fixed
    // table answers for the shop's screens instantly; anything else is asked
    // once, in the background, and the panel repaints when it answers.
    final mac = ip.isEmpty
        ? null
        : TvPowerService.primaryMacFor(ip) ?? _macCache[ip];
    if (ip.isNotEmpty) _learnMac(ip);
    return _ScreenPanel(
      index: key,
      report: _findReport(reports, ip),
      identity: identity,
      deviceId: slot.deviceId,
      devices: devices,
      mac: mac,
      expanded: _expanded.contains(ip),
      onToggleExpanded: () => setState(() {
        if (!_expanded.remove(ip)) _expanded.add(ip);
      }),
      onEditName: () => _editName(key, identity.name),
      onEditAddress: () => _editAddress(key, ip, identity.name),
      onIdentify: () => _identify(ip, identity.name),
      onDevice: (id) async {
        if (id == slot.deviceId) return;
        // Whichever screen holds that device now gives it up in exchange — so
        // say so by name, instead of leaving one machine looking like it still
        // drives two walls.
        TvScreenSlot? other;
        if (id != null) {
          for (final s in config.slots) {
            if (s.index != key && s.deviceId == id) {
              other = s;
              break;
            }
          }
        }
        await notifier.moveDevice(key, id);
        if (!mounted) return;
        _say(other != null
            ? 'بدّلنا ${identity.name} مع ${other.name}'
            : (id == null
                ? '${identity.name} مش مربوط بأي جهاز'
                : '${identity.name} اتربط بالجهاز'));
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
          const Icon(Icons.copy_all_rounded,
              size: 18, color: AppColors.warning),
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
                  style:
                      TextStyle(fontSize: 11, color: AppColors.textSecondary),
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

/// The pencil next to a screen's name and address.
///
/// A small, always-visible button, because the value beside it is a label and
/// not a field — the thing that says "this can be changed" has to be the thing
/// you press, not a hint you have to discover by tapping the text.
class _EditButton extends StatelessWidget {
  const _EditButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors.accentPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: AppColors.accentPrimary.withValues(alpha: 0.40),
            ),
          ),
          child: const Icon(Icons.edit_outlined,
              size: 15, color: AppColors.accentPrimary),
        ),
      ),
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
    required this.deviceId,
    required this.devices,
    required this.mac,
    required this.expanded,
    required this.onToggleExpanded,
    required this.onEditName,
    required this.onEditAddress,
    required this.onIdentify,
    required this.onDevice,
    required this.onProbe,
    required this.onSearch,
    required this.onOpen,
    required this.onClose,
  });

  final int index;
  final TvScreenReport? report;
  final TvScreenIdentity identity;
  final int? deviceId;
  final List<DeviceWithType> devices;

  /// The screen's Wi-Fi MAC, shown so a person can match this entry to a
  /// television by reading it off the set's own network page.
  final String? mac;
  final bool expanded;
  final VoidCallback onToggleExpanded;
  final VoidCallback onEditName;
  final VoidCallback onEditAddress;
  final VoidCallback onIdentify;
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
        border: Border.all(color: tone.withValues(alpha: 0.35), width: 1.2),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            identity.name.trim().isEmpty
                                ? 'شاشة بلا اسم'
                                : identity.name.trim(),
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: identity.name.trim().isEmpty
                                  ? AppColors.textTertiary
                                  : AppColors.textPrimary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _EditButton(
                          tooltip: 'عدّل اسم الشاشة',
                          onTap: onEditName,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // One row per screen: the address it is reached at, the
                    // MAC that address resolves to (shown, never typed), and
                    // the machine it follows. These three used to be scattered
                    // across the card, which is what made a person walk the
                    // room just to line them up.
                    Wrap(
                      spacing: AppSpacing.md,
                      runSpacing: AppSpacing.sm,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        // Address — a label with a pencil. Not a live field:
                        // it is decided in a dialog, so a half-typed address is
                        // never written and a screen never vanishes mid-edit.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lan_rounded,
                                size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            Text(
                              identity.ip.trim().isEmpty
                                  ? 'مش محدد'
                                  : identity.ip.trim(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: identity.ip.trim().isEmpty
                                    ? AppColors.textTertiary
                                    : AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(width: 2),
                            _EditButton(
                              tooltip: 'عدّل عنوان الشاشة',
                              onTap: onEditAddress,
                            ),
                          ],
                        ),
                        // The MAC follows the address. Shown, never typed: it
                        // is what the address resolves to, and it is the stable
                        // name a screen is recognised by when the address moves.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.lock_outline_rounded,
                                size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            const Text('الماك',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary)),
                            const SizedBox(width: 4),
                            Text(
                              mac == null || mac!.isEmpty ? 'مش معروف' : mac!,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        // The machine this screen follows, chosen by name right
                        // here. Binding a screen light it up for that machine's
                        // sessions and blacks it on that machine's checkout.
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.videogame_asset_rounded,
                                size: 12, color: AppColors.textTertiary),
                            const SizedBox(width: 4),
                            const Text('الجهاز',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textTertiary)),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: 150,
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<int?>(
                                  value: devices
                                          .any((d) => d.device.id == deviceId)
                                      ? deviceId
                                      : null,
                                  isDense: true,
                                  isExpanded: true,
                                  dropdownColor: AppColors.glassFill,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textPrimary),
                                  items: [
                                    const DropdownMenuItem<int?>(
                                      value: null,
                                      child: Text('مفيش جهاز — هتفضل سودا',
                                          style: TextStyle(fontSize: 12)),
                                    ),
                                    for (final d in devices)
                                      DropdownMenuItem<int?>(
                                        value: d.device.id,
                                        child: Text(
                                          '${d.type.name} — ${d.device.name}',
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                      ),
                                  ],
                                  onChanged: onDevice,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Tooltip(
                          message: 'اكتب اسم الشاشة دي على التلفزيون نفسه',
                          child: InkWell(
                            onTap: onIdentify,
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.accentPrimary
                                    .withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: AppColors.accentPrimary
                                      .withValues(alpha: 0.40),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.wifi_tethering_rounded,
                                      size: 14,
                                      color: AppColors.accentPrimary),
                                  SizedBox(width: 4),
                                  Text(
                                    'عرّفني',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.accentPrimary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
                icon:
                    r == null ? Icons.hourglass_empty_rounded : _reportIcon(r),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),

          // Whether a session is running on the machine this screen follows.
          Row(
            children: [
              _Pill(
                label:
                    identity.sessionRunning ? 'فيه جلسة دلوقتي' : 'مفيش جلسة',
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
              style:
                  const TextStyle(fontSize: 11, color: AppColors.textTertiary),
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
                          fontSize: 12,
                          color: AppColors.textPrimary,
                          height: 1.35),
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
                  label: 'افتح',
                  icon: Icons.power_settings_new_rounded,
                  onTap: onOpen),
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
                        color:
                            e.ok ? AppColors.textSecondary : AppColors.danger,
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
                Icon(widget.icon, size: 14, color: AppColors.textSecondary),
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
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              const Spacer(),
              Switch(
                value: showCards,
                activeThumbColor: AppColors.accentPrimary,
                onChanged: onShowCards,
              ),
              const SizedBox(width: AppSpacing.sm),
              const Text('اعرض كارت الوقت على الشاشة',
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 13)),
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
          icon: running ? Icons.dns_rounded : Icons.power_off_rounded,
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
            label: const Text('افتح السيرفر', style: TextStyle(fontSize: 12)),
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
