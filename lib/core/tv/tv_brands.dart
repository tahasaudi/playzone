/// Which televisions are NOT LG webOS sets.
///
/// The café mixes brands: the LG walls answer LG's own control socket
/// (SSAP), but every other make — ATA and the like — answers only plain
/// DLNA. Talking SSAP at a non-LG set is needless waiting followed by
/// silence: the wake burned fourteen seconds trying sockets that would never
/// open, and the cashier read all of that as «شاشة مش بتقبل أوامر».
///
/// This is the one small table both the power path and the settings page
/// agree on. It is filled from the screen configuration when the program
/// starts and whenever a screen is saved: a screen flagged "غير LG" here
/// gets the plain-DLNA road and nothing else.
class TvBrands {
  TvBrands._();

  /// Addresses the shop has marked as non-LG.
  static final Set<String> _nonLg = <String>{};

  /// Marks [ip] as a non-LG screen (or clears that mark).
  static void setNonLg(String? ip, bool nonLg) {
    final key = ip?.trim() ?? '';
    if (key.isEmpty) return;
    if (nonLg) {
      _nonLg.add(key);
    } else {
      _nonLg.remove(key);
    }
  }

  /// Whether [ip] is a non-LG screen: plain DLNA only, no SSAP, no NetCast.
  static bool isNonLg(String? ip) {
    final key = ip?.trim() ?? '';
    if (key.isEmpty) return false;
    return _nonLg.contains(key);
  }

  static void forgetAll() => _nonLg.clear();
}
