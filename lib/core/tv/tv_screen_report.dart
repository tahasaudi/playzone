/// What a wall screen is doing, described in the café's own language.
///
/// The whole reason this file exists: there must be exactly ONE place that
/// knows what a screen's condition *means*. Until now a sleeping panel, a
/// screen nobody bound to a machine, and a panel that refused our image all
/// collapsed into the same line of status text — and telling those three
/// apart at the counter is what the evening of blaming the TV was spent on.
///
/// So every condition here carries three things together, and they are never
/// split apart: what it is called, how bad it is, and what to do about it.
/// Pure Dart on purpose — no Flutter — so the same words serve the settings
/// page and the `/status` endpoint without either one drifting.
library;

import '../utils/time_format.dart';

/// How a wall screen is doing. Ordered from "most broken" to "healthy", so
/// the settings page can show the worst news first.
enum TvScreenState {
  /// The settings have not been read yet, so we cannot say anything about the
  /// screen — including that it is broken.
  ///
  /// Settings load asynchronously, and during that window every screen looks
  /// like it has an address and no machine behind it. Reporting that as
  /// [unbound] flashes a red fault on every single launch, and a fault that
  /// always appears is a fault nobody reads.
  loading,

  /// The whole TV feature is switched off in the app's settings.
  disabled,

  /// A screen slot exists but has no address to talk to.
  noAddress,

  /// A screen with an address that no machine was ever attached to.
  ///
  /// This is the one state that looks perfectly configured and does nothing:
  /// it never wakes on a session and never releases when one starts, because
  /// nothing ever tells it to.
  unbound,

  /// Nothing on the network answered.
  unreachable,

  /// Answered, but said no — the UPnP fault number is in the report.
  refused,

  /// We found it on the network, but it has never once answered us, so we
  /// honestly do not know yet.
  ///
  /// This state exists because "we have not checked yet" and "we checked and
  /// it is broken" are not the same thing, and reporting the first as the
  /// second sends whoever is fixing it looking for a fault that is not there.
  unknown,

  /// We hold an address, but the last command through it did not land.
  suspect,

  /// Healthy: our picture is playing, i.e. the cards are on the screen.
  showing,

  /// The panel says it is playing, but not anything from this run.
  ///
  /// It kept a `PLAYING` renderer across an app restart and is still holding
  /// the address it was given last time. Reporting this as [showing] would
  /// claim we are driving a screen we have never fed in this session — the
  /// exact kind of comfortable lie a status panel exists to prevent.
  stalePlayback,

  /// Healthy: the screen let go and the console has the picture.
  released,

  /// The panel is mid-change and has not settled.
  ///
  /// Normal, and over in a moment. Reported as precisely that rather than
  /// rounded to "off" — which is what a panel that has just woken up looks
  /// like, and rounding it there would claim it is dark while it is in fact
  /// about to answer.
  transitioning,

  /// Mid-change, and staying there.
  ///
  /// A panel stuck part-way through a change will not take a new picture: it
  /// ignores the request, and reports the refusal in a way identical to a
  /// panel that simply will not cooperate. The two need opposite repairs — one
  /// needs a nudge, the other needs a man to walk over — so they must not
  /// share a verdict.
  wedged,

  /// Healthy: the screen is dark. This TV cannot be powered off over the
  /// network, so a black frame is what "off" looks like.
  dark,
}

/// How loudly a state should shout. Decoupled from [TvScreenState] on
/// purpose: a sleeping TV is completely normal between sessions and must not
/// look like a failure, while a screen with nobody bound to it is a real
/// fault and must not look like one of those.
enum TvSeverity { ok, warn, bad }

/// Plain-Arabic wording for every state, kept in one place so a screen can
/// never be described two different ways on two different screens.
extension TvScreenStateWords on TvScreenState {
  String get label => switch (this) {
        TvScreenState.loading => 'بنقرأ الإعدادات',
        TvScreenState.disabled => 'مقفولة من البرنامج',
        TvScreenState.noAddress => 'من غير IP',
        TvScreenState.unbound => 'مش مربوطة بجهاز',
        TvScreenState.unreachable => 'مقفولة دلوقتي',
        TvScreenState.refused => 'رفضت الصورة',
        TvScreenState.suspect => 'محتاجة بحث تاني',
        TvScreenState.unknown => 'لسه بنعرف حالتها',
        TvScreenState.showing => 'بتعرض الصورة',
        TvScreenState.stalePlayback => 'بتعرض حاجة قديمة',
        TvScreenState.released => 'راجعة للبلايستيشن',
        TvScreenState.transitioning => 'بتتغيّر الآن',
        TvScreenState.wedged => 'واقفة مش بتخلص',
        TvScreenState.dark => 'سودا (مقفولة)',
      };

  TvSeverity get severity => switch (this) {
        // A screen with no machine behind it will never do anything at all.
        TvScreenState.unbound => TvSeverity.bad,
        TvScreenState.refused => TvSeverity.bad,

        // It will not take a picture, and it will not say so.
        TvScreenState.wedged => TvSeverity.bad,
        // Quiet, but somebody has to type an address / flip a switch.
        TvScreenState.noAddress => TvSeverity.warn,
        TvScreenState.disabled => TvSeverity.warn,
        TvScreenState.suspect => TvSeverity.warn,
        // Nothing to act on yet, and nothing wrong either. Anything louder
        // would make a launch look like a fault.
        TvScreenState.loading => TvSeverity.ok,
        // Something is on the wall that we did not put there this session.
        TvScreenState.stalePlayback => TvSeverity.warn,
        // Unproven is not proven-good. Saying nothing about a screen counts
        // as saying it is fine, which is how an unchecked screen stays black
        // all night.
        TvScreenState.unknown => TvSeverity.warn,
        // Not being answered is what a TV between sessions looks like.
        TvScreenState.unreachable => TvSeverity.ok,
        TvScreenState.showing ||
        TvScreenState.released ||
        TvScreenState.transitioning ||
        TvScreenState.dark =>
          TvSeverity.ok,
      };
}

/// Who a screen is, as far as the TV layer is concerned.
///
/// Injected by the shell because the names live in the settings tables. The
/// core must be able to say "the 65-inch in the PS5 corner" without importing
/// the database.
class TvScreenIdentity {
  const TvScreenIdentity({
    required this.ip,
    this.name = '',
    this.deviceId,
    this.deviceName,

    /// Is this screen's machine running a session right now?
    ///
    /// This is the difference between a panel that is peacefully asleep and a
    /// panel that is asleep while somebody is paying for a game — a fault the
    /// café must know about, versus the normal state of a closed shop.
    this.sessionRunning = false,

    /// Have the settings actually been read yet?
    ///
    /// Settings arrive asynchronously, so for the first moments of the
    /// program every screen looks like it has an address and no machine
    /// behind it. Left unchecked, that is reported as [unbound] — a red
    /// "not bound" fault for a screen that is perfectly bound, on every
    /// launch, for which the only real fix is to ignore the red.
    this.configLoaded = false,
  });

  final String ip;

  /// 'الشاشة الأولى (55 بوصة)'.
  final String name;

  final int? deviceId;

  /// 'PS4 - 2'.
  final String? deviceName;
  final bool sessionRunning;

  /// False until the settings behind [deviceId] and [name] have arrived.
  final bool configLoaded;
}

/// One line in a screen's own history: what we did, whether it worked, and
/// how long it took. This is what lets someone answer "did it work last
/// night?" without opening a terminal.
class TvScreenEvent {
  const TvScreenEvent(this.at, this.text, this.ok);

  final DateTime at;
  final String text;
  final bool ok;
}

/// Per-screen bookkeeping. One of these exists per address for the life of the
/// process, which is what makes two screens independently diagnosable.
class TvScreenLog {
  TvScreenLog(this.ip);

  final String ip;

  /// The AVTransport endpoint we believe this screen answers on.
  String? controlUrl;
  DateTime? discoveredAt;

  /// The last thing we asked this screen to do, in the café's words.
  String? lastCommand;
  DateTime? lastCommandAt;
  String? lastResult;
  bool lastOk = true;
  int? lastTookMs;

  /// The last UPnP fault or transport error, verbatim.
  String? fault;
  DateTime? faultAt;

  /// When this screen last said no to our image (a 10-minute verdict).
  DateTime? refusedAt;

  /// How many times this specific screen pulled our frame.
  int imagesServed = 0;

  /// How many times it asked how big the picture is before pulling it.
  ///
  /// A screen that asks and never takes is telling us something different from
  /// one that never asks at all, and the count is what tells the two apart:
  /// the first got as far as our server and then stalled, the second never
  /// reached us and the problem is on the network.
  int headRequests = 0;

  DateTime? lastFetchAt;

  /// The transport state read back FROM the screen.
  String? transportState;
  DateTime? stateReadAt;

  /// Whether this screen actually pulled our picture since the last time we
  /// asked it anything, sampled as a difference in [imagesServed].
  ///
  /// The panel's own transport state is a claim, and on these webOS boxes it is
  /// sometimes a stale one: right after a `Stop` — which is the release that
  /// hands a wall back to the console and is therefore the whole point of
  /// checkout — the renderer keeps answering `PLAYING` while it has stopped
  /// asking for anything. Believing that claim puts a red "playing" on a wall
  /// that is in fact showing the game, which is worse than reporting nothing:
  /// it sends someone to fix a screen that is working.
  ///
  /// So the two are kept apart and reported together. A screen that says
  /// `PLAYING` and has not fetched is a disagreement worth showing, not a state
  /// worth believing. `null` until there have been two samples to compare.
  bool? showingOurs;

  /// Pictures this screen pulled between the two most recent probes.
  int fetchedSinceLastProbe = 0;

  /// When the screen first started reporting *this* state.
  ///
  /// Deliberately not [stateReadAt]. That is when we last heard from the
  /// screen, and we ask every few seconds, so it is always fresh — measuring
  /// "how long has it been like this" against it is measuring our own
  /// curiosity instead of the screen's condition, and a screen stuck for an
  /// hour would be reported as one that has just started. It moves only when
  /// the reported value actually changes.
  DateTime? stateSince;
  int? pingMs;

  /// Is it answering *right now*?
  bool reachable = false;

  /// Has it ever answered us since the app started?
  ///
  /// Kept apart from [reachable] on purpose. A panel we have never spoken to
  /// is an open question, not a fault, and a panel that answered a moment ago
  /// and has gone quiet is a fault. Collapsing the two is what made a screen
  /// that was simply never asked to look exactly like one that had failed.
  bool everReached = false;

  /// True while a status read is in flight, so the panel can show a spinner
  /// instead of a stale answer pretending to be current.
  bool probing = false;

  /// The address we last told this screen to show.
  ///
  /// Recorded because this string is the whole question when a push fails: it
  /// is the only place the answer is written down. A television that will not
  /// fetch a frame either cannot reach the address in here — a firewall, a
  /// wrong interface, a stale server address — or is refusing the request
  /// itself, and those two need opposite fixes.
  String lastPushedUri = '';

  /// The last [_logLimit] things that happened to this screen.
  final List<TvScreenEvent> events = [];

  static const _logLimit = 14;

  void note(String text, {bool ok = true}) {
    events.insert(0, TvScreenEvent(DateTime.now(), text, ok));
    if (events.length > _logLimit) events.removeLast();
  }
}

/// Everything the settings page renders for one screen.
class TvScreenReport {
  const TvScreenReport({
    required this.identity,
    required this.state,
    required this.label,
    required this.severity,
    required this.remedy,
    required this.events,
    this.endpoint = '',
    this.deviceId,
    this.deviceName,
    this.lastCommand,
    this.lastCommandAt,
    this.lastResult,
    this.lastOk = true,
    this.lastTookMs,
    this.fault,
    this.faultAt,
    this.imagesServed = 0,
    this.lastFetchAt,
    this.transportState,
    this.stateReadAt,
    this.pingMs,
    this.reachable = false,
    this.everReached = false,
    this.probing = false,
    this.lastPushedUri = '',
    this.headRequests = 0,
    this.showingOurs,
    this.fetchedSinceLastProbe = 0,
  });

  final TvScreenIdentity identity;
  final TvScreenState state;

  /// What to call it, which is not always [TvScreenState.label]: a dark screen
  /// is a dark screen, unless somebody is playing on it — and then it is a
  /// fault that says so.
  final String label;

  final TvSeverity severity;

  /// What to actually do about it, or '' when there is nothing to do.
  final String remedy;

  final List<TvScreenEvent> events;
  final String endpoint;
  final int? deviceId;
  final String? deviceName;
  final String? lastCommand;
  final DateTime? lastCommandAt;
  final String? lastResult;
  final bool lastOk;
  final int? lastTookMs;
  final String? fault;
  final DateTime? faultAt;
  final int imagesServed;
  final DateTime? lastFetchAt;
  final String? transportState;
  final DateTime? stateReadAt;
  final int? pingMs;
  final bool reachable;
  final bool everReached;
  final bool probing;
  final String lastPushedUri;
  final int headRequests;

  /// See [TvScreenLog.showingOurs]: `true`/`false` once there are two samples,
  /// `null` before that.
  final bool? showingOurs;
  final int fetchedSinceLastProbe;

  /// The panel's claim and the evidence disagreeing, in one sentence the staff
  /// can act on, or '' when they agree or there is nothing to compare yet.
  String get claimVsEvidence {
    if (showingOurs == null) return '';
    if (showingOurs == true) return '';
    if (!(transportState ?? '').toUpperCase().contains('PLAYING')) return '';
    return 'الشاشة بتقول إنها شغالة بس ماحدش جاب الصورة — على الأرجح رجعت للجهاز';
  }

  String get ip => identity.ip;
  String get name =>
      identity.name.trim().isEmpty ? 'شاشة $ip' : identity.name.trim();

  /// A screen is only healthy if it is both bound and answering. A bound
  /// screen that is asleep between sessions is still healthy.
  bool get healthy => severity == TvSeverity.ok;
}

/// Decides a screen's state from what we know about it.
///
/// Pure on purpose: one function, one truth, so the page, the summary line
/// and the log can never disagree about whether a screen is fine.
TvScreenReport judgeTvScreen({
  required TvScreenIdentity identity,
  required TvScreenLog log,
  required bool featureEnabled,
  required bool endpointKnown,
  int? boundDeviceId,
}) {
  /// Is the panel telling us it is in the middle of something?
  ///
  /// Matched on the word rather than on a fixed list, because these panels
  /// qualify what they report — one says `LG_TRANSITIONING`, another
  /// `TRANSITIONING` — and a list of exact names would call half of them
  /// healthy while they are stuck.
  bool _midChange(String? state) {
    final s = (state ?? '').toUpperCase();
    return s.contains('TRANSITION') ||
        s.contains('LOADING') ||
        s.contains('BUFFERING');
  }

  /// Has it been saying the same thing for longer than a change ever takes?
  ///
  /// Timed from [TvScreenLog.stateSince] — when the condition started — not
  /// from when we last looked.
  bool _heldTooLong(DateTime? since) {
    if (since == null) return false;
    return DateTime.now().difference(since) > const Duration(seconds: 45);
  }

  String remedyFor(TvScreenState s) => switch (s) {
        // Nothing to do, on purpose. Saying "check the wiring" for a screen
        // that is mid-load would send someone to a television that is fine.
        TvScreenState.loading => '',
        TvScreenState.disabled =>
          'شغّل «ابعت الشاشات للتلفزيون» من تحت — دلوقتي الشاشات كلها متوقفة.',
        TvScreenState.noAddress =>
          'اكتب IP الشاشة في كارت بتاعها، من غيره مفيش طريقة نتكلم معاها.',
        TvScreenState.unbound =>
          'اختار الجهاز اللي الشاشة دي بتاعة من القايمة. من غير كده هتفضل '
              'سودا طول اليوم لأن مفيش حاجة بتقول لها اشتغلي.',
        TvScreenState.unreachable =>
          'مفيش حد رد عليها من الأساس. تأكد إن التلفزيون متوصل في نفس '
              'الشبكة وبورته مفتوح، وبعدين اضغط «ابحث عن الشاشة».',
        TvScreenState.refused =>
          'الشاشة جابت خطأ ومش هتبعد الصورة. معناها غالباً إن جهازنا مش '
              'سايبلها توصل — الفايروول. اضغط «ابحث عن الشاشة»، وبعدين «فحص كل '
              'الشاشات».',
        TvScreenState.suspect =>
          'العنوان اللي عندنا بقى قديم (الشاشة اتغير بورتها). اضغط «ابحث عن '
              'الشاشة» — مش محتاج تقفل البرنامج.',
        TvScreenState.unknown =>
          'لسه ما ردتش علينا. استنى ثانية، ولو فضلت كده اضغط «فحص».',
        TvScreenState.stalePlayback =>
          'الشاشة لسه بتعرض صورة قديمة من قبل ما البرنامج يفتح. ده بيحصل لو '
              'الشاشة اتقفلت من غير تحصيل. ابدأ جلسة على ${identity.deviceName ?? "الجهاز"} أو دوس «غمّض» عشان ترجع مظبوطة.',
        TvScreenState.transitioning =>
          'الشاشة بتتغيّر دلوقتي. ثواني وتثبت. لو فضلت كده طويل، اضغط «فحص».',
        TvScreenState.wedged =>
          'الشاشة واقفة في نص تغيير ومش بتخلص، فمش هتاخد أي صورة جديدة. '
              'دوس «ابحث عن الشاشة» الأول — لو رجعت، تمام. لو مرجعتش، لازم '
              'حد يقرب منها ويوقّعها (الفياز فيها)، وبعد دقيقة هترجع لوحدها.',
        TvScreenState.showing ||
        TvScreenState.released ||
        TvScreenState.dark =>
          '',
      };

  final state = switch (null) {
    // Before everything, because until the settings are in we know nothing
    // about this screen — and "nothing" must never be reported as a fault.
    _ when !identity.configLoaded => TvScreenState.loading,
    // Order matters: a configuration fault outranks a network fault, because
    // no amount of network fixing will help a screen nobody is bound to.
    _ when !featureEnabled => TvScreenState.disabled,
    _ when identity.ip.trim().isEmpty => TvScreenState.noAddress,
    _ when boundDeviceId == null => TvScreenState.unbound,
    _ when !endpointKnown => TvScreenState.unreachable,
    // Found on the network, never once answered. An open question, not a
    // verdict — so it is not dressed up as one.
    _ when !log.everReached => TvScreenState.unknown,
    _ when log.refusedAt != null && !_refusalExpired(log.refusedAt!) =>
      TvScreenState.refused,
    _ when !log.reachable && identity.sessionRunning =>
      TvScreenState.unreachable,
    _ when !log.reachable => TvScreenState.dark,
    _ when !log.lastOk => TvScreenState.suspect,
    // It talks to us but has never said what it is showing, so every verdict
    // about what is on the wall would be a guess. Say so instead.
    _ when (log.transportState ?? '').trim().isEmpty => TvScreenState.unknown,
    _ when (log.transportState ?? '').toUpperCase().contains('PLAYING') =>
      // PLAYING only means "ours" if we actually sent something this run.
      // The panel carries a renderer across an app restart, so an unclaimed
      // PLAYING is a stale frame — a different thing, and reported as one.
      log.lastCommand == null && log.imagesServed == 0
          ? TvScreenState.stalePlayback
          : TvScreenState.showing,
    _ when (log.transportState ?? '').toUpperCase().contains('STOPPED') =>
      TvScreenState.released,
    // Anything else the panel reports — TRANSITIONING, PAUSED, and whatever
    // this firmware invents next — is named as itself rather than folded
    // into "off", so a screen mid-wake is not filed as a dark screen.
    //
    // Unless it has been reporting itself mid-change for long enough that
    // "mid-change" has stopped being a temporary condition. A change that is
    // not resolving is the reason a screen silently refuses every picture it
    // is given, and a fault that hides behind a harmless-looking label is a
    // fault nobody goes and fixes.
    _ when _midChange(log.transportState) && _heldTooLong(log.stateSince) =>
      TvScreenState.wedged,
    _ => TvScreenState.transitioning,
  };

  // One rule, applied once, on top of whatever the state worked out to.
  //
  // Every "the screen is not talking to us" state is perfectly normal while
  // the shop is empty — a TV between customers is a dark TV. It stops being
  // normal the moment the machine behind it has a live session, because then
  // somebody is paying for a game on a wall that is showing them nothing.
  // Applying this as a single escalation on top of the state is what stops
  // each of those states from needing to know about sessions individually.
  final liveGap = switch (state) {
    // `unknown` counts here because a session removes the doubt: we know the
    // machine is busy and we know the panel has never once answered, which is
    // two facts pointing the same way — a fault, not an open question.
    TvScreenState.unreachable ||
    TvScreenState.dark ||
    TvScreenState.unknown =>
      identity.sessionRunning,
    _ => false,
  };
  final label = liveGap ? 'مش راد وفيه جلسة شغالة' : state.label;
  final severity = liveGap ? TvSeverity.bad : state.severity;
  final remedy = liveGap
      ? 'فيه جلسة شغالة على ${identity.deviceName ?? "الجهاز"} والشاشة مش '
          'راد. اتأكد إن التلفزيون متوصل في نفس الشبكة، وبعدين اضغط «ابحث '
          'عن الشاشة».'
      : remedyFor(state);

  // A raw error is only worth showing when the verdict says something is
  // actually wrong. These panels log a scary "HTTP 500" while playing the
  // picture correctly, so printing the error next to a healthy verdict would
  // train whoever reads this panel to ignore the part that matters.
  final showFault = severity != TvSeverity.ok &&
      state != TvScreenState.unbound &&
      state != TvScreenState.noAddress &&
      state != TvScreenState.disabled;

  return TvScreenReport(
    identity: identity,
    state: state,
    label: label,
    severity: severity,
    remedy: remedy,
    events: List.unmodifiable(log.events),
    endpoint: log.controlUrl == null
        ? ''
        : Uri.tryParse(log.controlUrl!)?.origin ?? '',
    deviceId: boundDeviceId,
    deviceName: identity.deviceName,
    lastCommand: log.lastCommand,
    lastCommandAt: log.lastCommandAt,
    lastResult: log.lastResult,
    lastOk: log.lastOk,
    lastTookMs: log.lastTookMs,
    fault: showFault ? log.fault : null,
    faultAt: log.faultAt,
    imagesServed: log.imagesServed,
    lastFetchAt: log.lastFetchAt,
    transportState: log.transportState,
    stateReadAt: log.stateReadAt,
    pingMs: log.pingMs,
    reachable: log.reachable,
    everReached: log.everReached,
    probing: log.probing,
    lastPushedUri: log.lastPushedUri,
    headRequests: log.headRequests,
    showingOurs: log.showingOurs,
    fetchedSinceLastProbe: log.fetchedSinceLastProbe,
  );
}

bool _refusalExpired(DateTime at) =>
    DateTime.now().difference(at) > const Duration(minutes: 10);

/// "الآن" / "من ٣ د" / "من ساعة و٢٠ د" — an age a person can read at a
/// glance, which is the whole point of showing times in a status panel.
String tvAge(DateTime? at, {DateTime? now}) {
  if (at == null) return '—';
  final delta = (now ?? DateTime.now()).difference(at);
  if (delta.isNegative) return 'الآن';
  if (delta.inSeconds < 10) return 'الآن';
  if (delta.inMinutes < 1) return 'من ${delta.inSeconds} ثانية';
  if (delta.inMinutes < 60) return 'من ${delta.inMinutes} دقيقة';
  if (delta.inHours < 24) {
    final rest = delta.inMinutes % 60;
    return rest == 0
        ? 'من ${delta.inHours} ساعة'
        : 'من ${delta.inHours} ساعة و$rest د';
  }
  return 'من ${delta.inDays} يوم';
}

/// The screens that are closed and must stay dark.
///
/// A `Stop` is the one command that undoes a blackout, and a blackout is the
/// last thing that should happen to a customer who has already paid. So being
/// closed is a rule this file decides rather than a flag the network layer
/// sets: while a screen is in here, no release may reach it.
///
/// This is not a theoretical guard. Session start hands the wall back to the
/// console, but a panel that is still booting does not answer straight away,
/// so that release keeps being retried for several seconds after the button is
/// pressed. A checkout landing inside that window used to win — and then the
/// retry arrived afterwards and put the wall back on the console. That is a
/// screen going dark on payment and springing back to life a second later,
/// which is exactly what it looks like to the customer who just paid.
///
/// It lives here rather than beside the SOAP calls so it can be tested without
/// a television. This rule decides whether a paid-for wall stays dark, and
/// that is not something to verify by waiting for a customer to find out.
Set<String> closedScreenLedger() => <String>{};

/// `2:02:28 م` — a wall-clock stamp for the per-screen event trail.
String tvClock(DateTime? at) => at == null ? '—' : clockWithSecondsOf(at);
