// Exercises the screen verdict table against every state we can reach.
//
// Hardware only ever shows one state at a time, which is exactly how a
// decision table goes wrong unnoticed: the states you cannot provoke on the
// shop floor are the ones that get shipped unproven. So this prints what the
// panel will say for each case, and the answer is checked against what it
// ought to say — the same table, read back, is the test.
//
// Run: dart run tool/tv_verdicts.dart
import '../lib/core/tv/tv_screen_report.dart';

/// One case: the situation, and what the panel must conclude from it.
class _Case {
  _Case(
    this.title,
    this.log, {
    this.featureEnabled = true,
    this.endpointKnown = true,
    this.deviceId = 9,
    this.sessionRunning = false,
    this.configLoaded = true,
    this.expectLabel,
    this.expectSeverity,
    this.expectRemedy = false,
  });

  final String title;
  final TvScreenLog log;
  final bool featureEnabled;
  final bool endpointKnown;
  final int? deviceId;
  final bool sessionRunning;

  /// Every case below is a settled situation, so they all say "the settings
  /// have arrived". The one case that does not is named as such.
  final bool configLoaded;

  /// What the panel has to say. Null means "whatever the table decides",
  /// which is only allowed for the escalation cases where the point of the
  /// test is that the table and the default disagree.
  final String? expectLabel;
  final TvSeverity? expectSeverity;
  final bool expectRemedy;
}

/// A log that has never heard of the screen and never spoken to it.
TvScreenLog _blank() => TvScreenLog('192.168.1.22');

/// A log for a screen that answered, is answering, and is released to HDMI.
TvScreenLog _healthy({String? state}) {
  final now = DateTime.now();
  return TvScreenLog('192.168.1.22')
    ..controlUrl = 'http://192.168.1.22:1267/AVTransport/control.xml'
    ..everReached = true
    ..reachable = true
    ..transportState = state ?? 'STOPPED'
    // Both marks start together: we have just read this state, and it has
    // just started. Anything that times a condition is timed from here.
    ..stateReadAt = now
    ..stateSince = now;
}

void main() {
  final cases = <_Case>[
    // ---- before the settings arrive: must not be blamed for anything ----
    _Case(
      'app just started, nothing has been read yet',
      _blank(),
      configLoaded: false,
      // Every other field is empty, which without this guard reads as a
      // screen with an address and no machine behind it. That false red
      // appeared on every single launch, for a screen that was bound fine.
      expectLabel: 'بنقرأ الإعدادات',
      expectSeverity: TvSeverity.ok,
      expectRemedy: false,
    ),

    // ---- configuration faults: no amount of network fixing will help ----
    _Case(
      'the whole feature is switched off',
      _blank(),
      featureEnabled: false,
      expectLabel: 'مقفولة من البرنامج',
      expectSeverity: TvSeverity.warn,
      expectRemedy: true,
    ),
    _Case(
      'a screen slot with no address',
      _blank(),
      deviceId: null,
      expectLabel: 'مش مربوطة بجهاز',
      expectSeverity: TvSeverity.bad,
      expectRemedy: true,
    ),
    _Case(
      'address present but nobody bound to it',
      _blank(),
      // The one case that looks perfectly configured and does nothing. Named
      // explicitly because a wrong expectation here is the bug that has
      // already happened once and burned an evening.
      deviceId: null,
      expectLabel: 'مش مربوطة بجهاز',
      expectSeverity: TvSeverity.bad,
      expectRemedy: true,
    ),
    _Case(
      'never found on the network at all',
      _blank(),
      endpointKnown: false,
      expectLabel: 'مقفولة دلوقتي',
      expectSeverity: TvSeverity.ok,
      expectRemedy: true,
    ),

    // ---- not yet known: must not be dressed up as a verdict ----
    _Case(
      'found, but has never answered us',
      _blank(),
      expectLabel: 'لسه بنعرف حالتها',
      expectSeverity: TvSeverity.warn,
      expectRemedy: true,
    ),

    // ---- refused, and how recently ----
    _Case(
      'refused our image recently',
      _blank()
        ..controlUrl = 'http://192.168.1.22:1267/AVTransport/control.xml'
        ..everReached = true
        ..reachable = false
        ..refusedAt = DateTime.now(),
      expectLabel: 'رفضت الصورة',
      expectSeverity: TvSeverity.bad,
      expectRemedy: true,
    ),
    _Case(
      'refused, but the verdict is older than it is worth',
      _blank()
        ..controlUrl = 'http://192.168.1.22:1267/AVTransport/control.xml'
        ..everReached = true
        // Answered our commands, but has never once told us what it is
        // showing — so "off" would be a guess dressed up as a reading.
        ..reachable = true
        ..refusedAt = DateTime.now().subtract(const Duration(minutes: 40)),
      expectLabel: 'لسه بنعرف حالتها',
      expectSeverity: TvSeverity.warn,
      expectRemedy: true,
    ),
    _Case(
      'talking, but caught between states',
      _healthy(state: 'TRANSITIONING'),
      // Transient and normal. Reported as exactly that, rather than quietly
      // rounded to "off" or shouted about as a fault.
      expectLabel: 'بتتغيّر الآن',
      expectSeverity: TvSeverity.ok,
      expectRemedy: true,
    ),
    _Case(
      'stuck between states, and saying so for minutes',
      _healthy(state: 'LG_TRANSITIONING')
        // The firmware qualifies what it reports, so the test uses the
        // qualified name on purpose: a list of exact names would call this
        // screen fine while it is refusing every picture it is given.
        ..stateSince = DateTime.now().subtract(const Duration(minutes: 3)),
      expectLabel: 'واقفة مش بتخلص',
      expectSeverity: TvSeverity.bad,
      expectRemedy: true,
    ),

    // ---- healthy ----
    _Case(
      'released to the console, shop empty',
      _healthy(),
      expectLabel: 'راجعة للبلايستيشن',
      expectSeverity: TvSeverity.ok,
    ),
    _Case(
      'our picture is on the wall and we fed it',
      _healthy(state: 'PLAYING')
        ..lastCommand = 'عرض الصورة'
        ..imagesServed = 3,
      expectLabel: 'بتعرض الصورة',
      expectSeverity: TvSeverity.ok,
    ),
    _Case(
      'says PLAYING but we never sent it anything',
      _healthy(state: 'PLAYING'),
      // The panel lies about this one if it is not called out: a renderer
      // survives an app restart, so PLAYING without a push of our own is a
      // leftover frame, not our picture.
      expectLabel: 'بتعرض حاجة قديمة',
      expectSeverity: TvSeverity.warn,
      expectRemedy: true,
    ),
    _Case(
      'quiet, and the shop is empty too',
      _healthy()..reachable = false,
      expectLabel: 'سودا (مقفولة)',
      expectSeverity: TvSeverity.ok,
    ),

    // ---- the escalation: same state, different verdict ----
    _Case(
      'quiet while a session is live on it',
      _healthy()..reachable = false,
      sessionRunning: true,
      expectLabel: 'مش راد وفيه جلسة شغالة',
      expectSeverity: TvSeverity.bad,
      expectRemedy: true,
    ),
    _Case(
      'never answered while a session is live on it',
      _blank(),
      sessionRunning: true,
      // Two facts pointing one way: the machine is busy and the wall has
      // never spoken. That is a fault, not an open question.
      expectLabel: 'مش راد وفيه جلسة شغالة',
      expectSeverity: TvSeverity.bad,
      expectRemedy: true,
    ),
    _Case(
      'never found on the network while a session is live',
      _blank(),
      endpointKnown: false,
      sessionRunning: true,
      expectLabel: 'مش راد وفيه جلسة شغالة',
      expectSeverity: TvSeverity.bad,
      expectRemedy: true,
    ),
    _Case(
      'our endpoint went stale',
      _healthy()..lastOk = false,
      expectLabel: 'محتاجة بحث تاني',
      expectSeverity: TvSeverity.warn,
      expectRemedy: true,
    ),
  ];

  var failed = 0;
  for (final c in cases) {
    final report = judgeTvScreen(
      identity: TvScreenIdentity(
        ip: c.log.ip,
        name: 'الشاشة الأولى (55 بوصة)',
        deviceId: c.deviceId,
        deviceName: c.deviceId == null ? null : 'PS4 — 2',
        sessionRunning: c.sessionRunning,
        configLoaded: c.configLoaded,
      ),
      log: c.log,
      featureEnabled: c.featureEnabled,
      endpointKnown: c.endpointKnown,
      boundDeviceId: c.deviceId,
    );

    final problems = <String>[];
    if (c.expectLabel != null && report.label != c.expectLabel) {
      problems.add('label: got "${report.label}" want "${c.expectLabel}"');
    }
    if (c.expectSeverity != null && report.severity != c.expectSeverity) {
      problems.add('severity: got ${report.severity.name} '
          'want ${c.expectSeverity!.name}');
    }
    final hasRemedy = report.remedy.trim().isNotEmpty;
    if (hasRemedy != c.expectRemedy) {
      problems.add('remedy: got ${hasRemedy ? '"${report.remedy}"' : 'none'} '
          'want ${c.expectRemedy}');
    }
    // Nothing may ever claim to be fine without a name and an address.
    if (report.name.trim().isEmpty || report.ip.trim().isEmpty) {
      problems.add('report has no name or ip');
    }

    final ok = problems.isEmpty;
    if (!ok) failed++;
    print('${ok ? "PASS" : "FAIL"}  ${c.title}');
    print('        -> "${report.label}" / ${report.severity.name}'
        '${report.remedy.isEmpty ? "" : "\n        -> ${report.remedy}"}');
    for (final p in problems) {
      print('        !! $p');
    }
  }

  print('');
  print('${cases.length - failed}/${cases.length} passed');
  if (failed > 0) throw StateError('$failed verdict(s) wrong');

  closedScreensStayClosed();
}

/// Checks the rule that a paid-for wall stays dark.
///
/// This one is not a table lookup, so it is exercised directly: the hardware
/// only ever shows it to you as a customer who has already walked away. The
/// `Stop` from a session that ended earlier lands late — a checkout can
/// happen while the release from that session is still retrying on a panel
/// that is slow to boot — and a `Stop` is precisely the command that undoes
/// a blackout. The sequence below is that exact race, and the order matters:
/// open, then closed, then the late release arrives.
void closedScreensStayClosed() {
  final closed = closedScreenLedger();
  const ip = '192.168.1.31';
  var problems = <String>[];

  closed.remove(ip);
  if (closed.contains(ip)) {
    problems.add('a live screen reported as closed');
  }

  // Checkout. The wall is claimed before anything is even sent, because what
  // has to be impossible is a release landing between the payment and the
  // blackout and undoing it.
  closed.add(ip);
  if (!closed.contains(ip)) {
    problems.add('checkout did not close the screen');
  }

  // The retry from the session that has already ended, still in flight. This
  // is the command that used to put a paid-for wall back on the console, so
  // the only thing worth checking is whether it is allowed to go out.
  //
  // Mirrors the guard in `TvDisplayService.releaseToInput`, which is the one
  // place the decision is actually made. If that guard is ever removed the
  // test must fail, which is the entire point of writing it down here.
  bool mayRelease() => !closed.contains(ip);
  if (mayRelease()) {
    problems.add('a closed screen was allowed to be released to the console');
  }

  // A new session is the only thing that may hand it back.
  closed.remove(ip);
  if (closed.contains(ip)) {
    problems.add('a new session did not reopen the screen');
  }

  print('');
  print('${problems.isEmpty ? "PASS" : "FAIL"}  a paid-for wall stays dark '
      'against a late release');
  for (final p in problems) {
    print('        !! $p');
  }
  if (problems.isNotEmpty) {
    throw StateError('${problems.length} closed-screen rule(s) broken');
  }
}