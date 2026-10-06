import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/database/app_database.dart';
import '../../core/database/daos/device_dao.dart';
import '../../core/database/daos/session_dao.dart';
import '../../core/database/database_provider.dart';
import '../../core/tv/tv_display_service.dart';
import '../../core/tv/tv_screen_report.dart';
import '../../data/repositories/device_repository.dart';
import '../../data/repositories/session_repository.dart';

/// One configured wall screen: where it is, what the staff call it, and which
/// machine it belongs to.
///
/// A list of these rather than a pair of named fields, because the café's
/// screens are not fixed at two. With the shape hardcoded to two, a third
/// television could be *found* on the network but never saved — so it stayed a
/// TV in the room that nothing could turn off at checkout.
class TvScreenSlot {
  const TvScreenSlot({
    required this.index,
    required this.ip,
    required this.name,
    this.deviceId,
  });

  /// Which setting keys this slot is stored under.
  ///
  /// Carried on the slot rather than taken from its position in the list,
  /// because a slot keeps its keys even when an earlier one is cleared. Index
  /// numbering restarts at the screen after an empty gap, which is what keeps a
  /// café set up before this existed from reading its two screens as empty.
  final int index;

  final String ip;
  final String name;
  final int? deviceId;

  bool get isEmpty => ip.trim().isEmpty;

  TvScreenIdentity get identity =>
      TvScreenIdentity(ip: ip.trim(), name: name, deviceId: deviceId);

  TvScreenSlot copyWith({
    String? ip,
    String? name,
    int? deviceId,
    bool clearDevice = false,
  }) =>
      TvScreenSlot(
        index: index,
        ip: ip ?? this.ip,
        name: name ?? this.name,
        deviceId: clearDevice ? null : (deviceId ?? this.deviceId),
      );
}

/// Settings for the wall screens, persisted in the app's settings table.
///
/// The café's screens: a 55" by the PS4 corner, a 65" by the PS5 corner, and
/// whatever else is plugged in. Each is bound to one machine, so a checkout
/// anywhere else in the shop never touches it.
class TvConfig {
  const TvConfig({
    this.ip = '192.168.1.22',
    this.enabled = true,
    this.mirror = true,
    this.showCards = false,
    this.deviceId,
    this.secondIp = '',
    this.secondDeviceId,
    this.name = 'الشاشة الأولى (55 بوصة)',
    this.secondName = 'الشاشة التانية (65 بوصة)',
    this.extras = const <TvScreenSlot>[],
    this.loaded = false,
  });

  final String ip;
  final bool enabled;

  /// Also show a "cast me" hint (Windows Win+K) — the guaranteed path.
  final bool mirror;

  /// Show the session cards ON the TV. Off by default: the wall screen is
  /// used as a power switch (it wakes with the session and sleeps when it
  /// ends), not as a customer-facing timer.
  final bool showCards;

  /// Which device this wall screen belongs to. Null = show every running
  /// session. When set (e.g. PS4 #2), the TV keeps showing THAT machine
  /// only — running or idle, so a screen in the PS4 corner belongs to a
  /// single console.
  final int? deviceId;

  /// The second wall screen, same idea. An empty [secondIp] disables it.
  final String secondIp;
  final int? secondDeviceId;

  /// What the staff call each screen.
  ///
  /// Stored, not hardcoded, because "the screen" is ambiguous the moment
  /// there are two of them and every fault report has to name one. A name
  /// the café chose is also the only thing that survives being read out over
  /// the counter: "الشاشة التانية" beats "192.168.1.31".
  final String name;
  final String secondName;

  /// Screens past the second. Held apart so the first two keep their original
  /// keys untouched — a café that was configured before had three screens
  /// would otherwise come back to a program that had forgotten two of them.
  final List<TvScreenSlot> extras;

  /// True once the saved settings have been read.
  ///
  /// The notifier starts on hardcoded defaults and replaces them with whatever
  /// is in the database, so a settings field cannot be seeded before this is
  /// true without showing the wrong address. Seeding on the flag is what stops
  /// a field from being typed over mid-edit.
  final bool loaded;

  /// How many screens the café may have at once.
  ///
  /// A ceiling rather than an open list because the room has a fixed number of
  /// walls: past this the additions are more likely to be a mistake than a
  /// plan, and a screen that is saved but never checked is worse than one that
  /// was never added.
  static const maxSlots = 6;

  bool get hasSecond => secondIp.trim().isNotEmpty;

  /// Every configured screen, in a stable order, each already carrying its
  /// name, its machine and the keys it lives under.
  ///
  /// This is the one list the whole TV layer agrees on. A screen that is not
  /// in here does not exist as far as the status page, the health panel and
  /// the session buttons are concerned — which is what stops the app from
  /// quietly steering a TV nobody can identify.
  List<TvScreenSlot> get slots => [
        TvScreenSlot(index: 0, ip: ip, name: name, deviceId: deviceId),
        if (hasSecond)
          TvScreenSlot(
            index: 1,
            ip: secondIp,
            name: secondName,
            deviceId: secondDeviceId,
          ),
        ...extras.where((s) => !s.isEmpty),
      ];

  /// Screens as the rest of the app refers to them.
  List<TvScreenIdentity> get identities =>
      slots.map((s) => s.identity).toList(growable: false);

  /// Whether another screen may be added.
  bool get canAddSlot => slots.length < maxSlots;

  /// The address of the screen that follows [deviceId], or null when no
  /// screen is bound to that machine.
  ///
  /// One machine, one screen. If two slots ever held the same machine the
  /// answer would depend on list order, so a checkout would blank one wall and
  /// leave the other showing a finished session — and the staff would see a
  /// screen that did not respond and blame the screen.
  String? screenFor(int deviceId) {
    if (!enabled) return null;
    for (final slot in slots) {
      if (slot.isEmpty) continue;
      if (slot.deviceId == deviceId) return slot.ip.trim();
    }
    return null;
  }

  /// Every address we may need to talk to, for eager discovery.
  Iterable<String> get addresses =>
      slots.where((s) => !s.isEmpty).map((s) => s.ip.trim());

  TvConfig copyWith({
    String? ip,
    bool? enabled,
    bool? mirror,
    bool? showCards,
    int? deviceId,
    String? secondIp,
    int? secondDeviceId,
    String? name,
    String? secondName,
    List<TvScreenSlot>? extras,
    bool? loaded,
    bool clearDevice = false,
    bool clearSecondDevice = false,
  }) =>
      TvConfig(
        ip: ip ?? this.ip,
        enabled: enabled ?? this.enabled,
        mirror: mirror ?? this.mirror,
        showCards: showCards ?? this.showCards,
        deviceId: clearDevice ? null : (deviceId ?? this.deviceId),
        secondIp: secondIp ?? this.secondIp,
        secondDeviceId:
            clearSecondDevice ? null : (secondDeviceId ?? this.secondDeviceId),
        name: name ?? this.name,
        secondName: secondName ?? this.secondName,
        extras: extras ?? this.extras,
        loaded: loaded ?? this.loaded,
      );
}

class TvConfigNotifier extends StateNotifier<TvConfig> {
  TvConfigNotifier(this._db) : super(const TvConfig());

  final AppDatabase _db;

  static const ipKey = 'tv_ip';
  static const enabledKey = 'tv_enabled';
  static const deviceKey = 'tv_device_id';
  static const cardsKey = 'tv_show_cards';
  static const secondIpKey = 'tv_ip_2';
  static const secondDeviceKey = 'tv_device_id_2';
  static const nameKey = 'tv_name';
  static const secondNameKey = 'tv_name_2';

  /// The setting keys one screen is stored under.
  ///
  /// The first screen keeps its original unnumbered keys and the second keeps
  /// its `_2` keys, because those are what a café configured before this had
  /// more than two screens already has written. Numbering everything from one
  /// place means the third screen is not a special case that someone has to
  /// remember to wire up.
  static String ipKeyFor(int slot) => slot == 0 ? ipKey : 'tv_ip_${slot + 1}';
  static String deviceKeyFor(int slot) =>
      slot == 0 ? deviceKey : 'tv_device_id_${slot + 1}';
  static String nameKeyFor(int slot) =>
      slot == 0 ? nameKey : 'tv_name_${slot + 1}';

  /// The next storage index free for a new screen.
  ///
  /// Skips indexes already taken rather than counting the slots that exist, so
  /// clearing one screen in the middle does not hand its keys to the next one
  /// added — two screens would then trade places in the settings and one of
  /// them would silently become the other.
  int get _nextFreeIndex {
    final used = <int>{
      0,
      if (state.hasSecond) 1,
      ...state.extras.map((s) => s.index),
    };
    for (var i = 0; i < TvConfig.maxSlots; i++) {
      if (!used.contains(i)) return i;
    }
    return used.length;
  }

  Future<void> load() async {
    final ip = await _db.settingsDao.getValue(ipKey);
    final enabled = await _db.settingsDao.getValue(enabledKey);
    final device = await _db.settingsDao.getValue(deviceKey);
    final cards = await _db.settingsDao.getValue(cardsKey);
    final ip2 = await _db.settingsDao.getValue(secondIpKey);
    final device2 = await _db.settingsDao.getValue(secondDeviceKey);
    final name = await _db.settingsDao.getValue(nameKey);
    final name2 = await _db.settingsDao.getValue(secondNameKey);

    // Read the third screen onwards. Bounded by the same ceiling the UI uses,
    // and each screen read independently so one missing key does not cost the
    // others their settings.
    final extras = <TvScreenSlot>[];
    for (var i = 2; i < TvConfig.maxSlots; i++) {
      final eIp = await _db.settingsDao.getValue(ipKeyFor(i));
      if (eIp == null || eIp.trim().isEmpty) continue;
      final eDevice = await _db.settingsDao.getValue(deviceKeyFor(i));
      final eName = await _db.settingsDao.getValue(nameKeyFor(i));
      extras.add(TvScreenSlot(
        index: i,
        ip: eIp.trim(),
        // An empty stored name falls back to a default rather than to an empty
        // string: a screen with no name is a screen nobody can point at, which
        // is the exact problem naming is meant to solve.
        name: (eName == null || eName.trim().isEmpty)
            ? 'شاشة ${i + 1}'
            : eName.trim(),
        deviceId: _parseDevice(eDevice),
      ));
    }

    if (ip != null && ip.isNotEmpty) {
      state = state.copyWith(
        ip: ip,
        enabled: enabled != '0',
        showCards: cards == '1',
        deviceId: _parseDevice(device),
        secondIp: ip2 ?? '',
        secondDeviceId: _parseDevice(device2),
        name: (name == null || name.trim().isEmpty) ? null : name.trim(),
        secondName:
            (name2 == null || name2.trim().isEmpty) ? null : name2.trim(),
        extras: extras,
      );
    } else {
      // First run: remember the detected TV so the push starts on its own.
      setIp(state.ip);
      setEnabled(true);
    }
    state = state.copyWith(loaded: true);
  }

  static int? _parseDevice(String? raw) =>
      (raw == null || raw.isEmpty || raw == 'all') ? null : int.tryParse(raw);

  /// Writes any screen, whichever one it is.
  ///
  /// One entry point rather than a set-then-set-second-then-set-third, because
  /// three copies of the same save is three places for the "one machine drives
  /// one screen" rule to be forgotten — and the failure is invisible: the app
  /// would happily blank two walls at one checkout.
  ///
  /// Returns the machine it refused, or null when the save went through.
  Future<int?> saveSlot(
    int index, {
    String? ip,
    String? name,
    int? deviceId,
    bool clearDevice = false,
  }) async {
    // Refused before anything is written, so a rejected save cannot leave the
    // address changed and the machine still pointing at the old screen.
    if (deviceId != null) {
      final clash = state.slots
          .any((s) => s.index != index && !s.isEmpty && s.deviceId == deviceId);
      if (clash) return deviceId;
    }
    final cleanIp = ip?.trim();
    if (cleanIp != null && cleanIp.isNotEmpty) {
      final clash = state.slots
          .any((s) => s.index != index && !s.isEmpty && s.ip.trim() == cleanIp);
      if (clash) return -1;
    }

    if (index == 0) {
      if (cleanIp != null) setIp(cleanIp);
      if (name != null) setName(name);
      if (clearDevice) {
        setDevice(null);
      } else if (deviceId != null) {
        setDevice(deviceId);
      }
      return null;
    }
    if (index == 1) {
      if (cleanIp != null) setSecondIp(cleanIp);
      if (name != null) setSecondName(name);
      if (clearDevice) {
        setSecondDevice(null);
      } else if (deviceId != null) {
        setSecondDevice(deviceId);
      }
      return null;
    }

    // Screens past the second live in the extras list.
    final existing = state.extras.where((s) => s.index == index).firstOrNull;
    final cleanName = (name == null || name.trim().isEmpty)
        ? (existing?.name ?? 'شاشة ${index + 1}')
        : name.trim();
    final updated = TvScreenSlot(
      index: index,
      ip: cleanIp ?? existing?.ip ?? '',
      name: cleanName,
      deviceId: clearDevice
          ? null
          : (deviceId ?? (clearDevice ? null : existing?.deviceId)),
    );
    final next = [
      for (final s in state.extras)
        if (s.index == index) updated else s,
      if (existing == null) updated,
    ];
    state = state.copyWith(extras: next);
    await _db.settingsDao.setValue(ipKeyFor(index), updated.ip);
    await _db.settingsDao.setValue(nameKeyFor(index), updated.name);
    await _db.settingsDao
        .setValue(deviceKeyFor(index), updated.deviceId?.toString() ?? 'all');
    return null;
  }

  /// Adds an empty screen and returns its storage index, or null when the
  /// café is already at [TvConfig.maxSlots].
  int? addSlot() {
    if (!state.canAddSlot) return null;
    final index = _nextFreeIndex;
    state = state.copyWith(extras: [
      ...state.extras,
      TvScreenSlot(index: index, ip: '', name: 'شاشة ${index + 1}'),
    ]);
    _db.settingsDao.setValue(ipKeyFor(index), '');
    return index;
  }

  /// Clears a screen. Slot 0 is never removable: it is the one the pusher
  /// starts on, and a program with no screen at all cannot be recovered from
  /// the settings page.
  Future<void> removeSlot(int index) async {
    if (index == 0) return;
    if (index == 1) {
      setSecondIp('');
      setSecondDevice(null);
      return;
    }
    state = state.copyWith(
        extras: state.extras.where((s) => s.index != index).toList());
    await _db.settingsDao.setValue(ipKeyFor(index), '');
    await _db.settingsDao.setValue(deviceKeyFor(index), 'all');
  }

  /// Show the session cards on the TV itself (off = it is only a power
  /// switch for the wall screen).
  void setShowCards(bool value) {
    state = state.copyWith(showCards: value);
    _db.settingsDao.setValue(cardsKey, value ? '1' : '0');
  }

  /// Binds the first wall screen to one device (null = every session).
  void setDevice(int? deviceId) {
    state = state.copyWith(
      deviceId: deviceId,
      clearDevice: deviceId == null,
    );
    _db.settingsDao.setValue(deviceKey, deviceId?.toString() ?? 'all');
  }

  /// Binds the second wall screen to one device.
  void setSecondDevice(int? deviceId) {
    state = state.copyWith(
      secondDeviceId: deviceId,
      clearSecondDevice: deviceId == null,
    );
    _db.settingsDao.setValue(secondDeviceKey, deviceId?.toString() ?? 'all');
  }

  void setSecondIp(String value) {
    final clean = value.trim();
    state = state.copyWith(secondIp: clean);
    _db.settingsDao.setValue(secondIpKey, clean);
  }

  /// What the staff call the first screen. An empty name is stored as the
  /// default rather than as nothing, so the screen can never end up nameless.
  void setName(String value) {
    final clean = value.trim().isEmpty ? 'الشاشة الأولى' : value.trim();
    state = state.copyWith(name: clean);
    _db.settingsDao.setValue(nameKey, clean);
  }

  /// What the staff call the second screen.
  void setSecondName(String value) {
    final clean = value.trim().isEmpty ? 'الشاشة التانية' : value.trim();
    state = state.copyWith(secondName: clean);
    _db.settingsDao.setValue(secondNameKey, clean);
  }

  void setIp(String value) {
    final clean = value.trim();
    state = state.copyWith(ip: clean);
    _db.settingsDao.setValue(ipKey, clean);
  }

  void setEnabled(bool value) {
    state = state.copyWith(enabled: value);
    _db.settingsDao.setValue(enabledKey, value ? '1' : '0');
  }
}

final tvConfigProvider =
    StateNotifierProvider<TvConfigNotifier, TvConfig>((ref) {
  final notifier = TvConfigNotifier(ref.watch(appDatabaseProvider));
  // Without this the notifier keeps its in-memory defaults forever, so the
  // saved screen bindings are ignored and no screen ever matches a machine.
  unawaited(notifier.load());
  return notifier;
});

/// A live, named verdict for every wall screen.
///
/// Deliberately auto-disposed: the probes only run while somebody is actually
/// looking at the page, so closing it puts the network completely quiet. The
/// tick is one second because "3 minutes ago" must be true on screen, and the
/// real transport read is far rarer — one request per screen every fifteen
/// seconds, in the background, so a session start never waits for it.
final tvScreenReportsProvider =
    StreamProvider.autoDispose<List<TvScreenReport>>((ref) async* {
  final service = TvDisplayService.instance;
  final config = ref.watch(tvConfigProvider);
  // Which machines are busy right now. This is what separates "the panel is
  // asleep, which is normal" from "the panel is asleep while somebody pays".
  final sessions = ref.watch(activeSessionsProvider).valueOrNull ??
      const <SessionBoardEntry>[];
  final running = {
    for (final s in sessions) s.device.id,
  };
  final devices = ref.watch(devicesWithTypeProvider).valueOrNull ??
      const <DeviceWithType>[];

  List<TvScreenIdentity> buildIdentities() => [
        for (final slot in config.identities)
          TvScreenIdentity(
            ip: slot.ip,
            name: slot.name,
            deviceId: slot.deviceId,
            deviceName: slot.deviceId == null
                ? null
                : devices
                    .where((d) => d.device.id == slot.deviceId)
                    .map((d) => '${d.type.name} — ${d.device.name}')
                    .firstOrNull,
            sessionRunning:
                slot.deviceId != null && running.contains(slot.deviceId),
          ),
      ];

  TvDisplayService.screenIdentities = buildIdentities();
  TvDisplayService.featureEnabled = config.enabled;

  var sinceProbe = Duration.zero;
  while (true) {
    // Keep the injected identities fresh so a rename or a re-bind shows up
    // without a restart.
    TvDisplayService.screenIdentities = buildIdentities();
    if (sinceProbe >= const Duration(seconds: 15)) {
      sinceProbe = Duration.zero;
      unawaited(service.probeAll(
        config.addresses.toList(growable: false),
      ));
    }
    yield service.reports();
    await Future<void>.delayed(const Duration(seconds: 1));
    sinceProbe += const Duration(seconds: 1);
  }
});
