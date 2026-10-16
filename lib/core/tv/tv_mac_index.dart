/// Keeps every screen's MAC tied to the address it answers on right now.
///
/// A router hands out addresses; it never hands out MACs. So the binding that
/// survives a reboot, a lease change or a walk between Wi-Fi and cable is the
/// one anchored on the MAC, with the address derived from it — MAC first, then
/// address.
///
/// This is deliberately a plain in-memory index: it is read on the hot path
/// (every command aimed at a screen) and written by a background refresh, so it
/// must never touch the disk or the network itself. Lookups are map hits.
class TvMacIndex {
  TvMacIndex._();

  static final TvMacIndex instance = TvMacIndex._();

  /// The address each MAC answers on right now, refreshed from the operating
  /// system's neighbour table. Keys are upper-case, colon-separated.
  final Map<String, String> _macToIp = <String, String>{};

  /// Which MACs belong to each known address, so a command aimed at the address
  /// a screen *used* to be on can still find it. Entries are only ever added:
  /// an old address that still resolves is a feature, not a leak — it is what
  /// makes a command sent a second before a move still land.
  final Map<String, Set<String>> _ipToMacs = <String, Set<String>>{};

  /// `aa-bb-cc-dd-ee-ff` and `AA:BB:CC:DD:EE:FF` are the same screen.
  static String normalize(String mac) =>
      mac.trim().replaceAll('-', ':').toUpperCase();

  /// Ties [macs] to [ip]. Replaces whatever was bound to that address before.
  void bind(String ip, Iterable<String> macs) {
    final clean = ip.trim();
    if (clean.isEmpty) return;
    final set = macs.map(normalize).where((m) => m.isNotEmpty).toSet();
    if (set.isEmpty) return;
    _ipToMacs[clean] = set;
  }

  /// Replaces the MAC → address table with a fresh read of the neighbour table.
  void updateTable(Map<String, String> table) {
    final clean = <String, String>{};
    for (final entry in table.entries) {
      final mac = normalize(entry.key);
      final ip = entry.value.trim();
      if (mac.isEmpty || ip.isEmpty) continue;
      clean[mac] = ip;
    }
    _macToIp
      ..clear()
      ..addAll(clean);
  }

  /// The address [ip] really answers on right now, following its MAC.
  ///
  /// Falls back to [ip] itself when the MAC is unknown or the neighbour table
  /// has not seen it — never to null, because a caller with an address is
  /// always better off than a caller with nothing.
  String resolve(String ip) {
    final clean = ip.trim();
    if (clean.isEmpty) return clean;
    final macs = _ipToMacs[clean];
    if (macs == null || macs.isEmpty) return clean;
    for (final mac in macs) {
      final found = _macToIp[mac];
      if (found != null && found.isNotEmpty) return found;
    }
    return clean;
  }

  /// The MACs known for [ip], for callers that need to re-bind a new address.
  Set<String> macsFor(String ip) =>
      Set<String>.of(_ipToMacs[ip.trim()] ?? const <String>{});

  /// Forgets everything. Only used by tests.
  void reset() {
    _macToIp.clear();
    _ipToMacs.clear();
  }
}
