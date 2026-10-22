/// Fired on the master the moment a session arrives over sync from a phone.
///
/// A phone that opens a session is starting a machine in the café, so the
/// wall screen bound to that machine has to wake exactly as if the cashier
/// had pressed start at the till. The session row arrives on `/push`; the
/// server calls this hook in the same request, which is what makes the
/// screen wake feel instant instead of waiting a polling cycle.
///
/// A static rather than a constructor argument because the sync server runs
/// outside the widget tree: the shell (the only layer that knows the TV and
/// IR wiring) installs it, the server reads it, and null means nothing is
/// wired — which is always true on a phone, and on a PC with no screens.
typedef RemoteSessionWake = Future<void> Function(int deviceId);

class RemoteSessionHook {
  RemoteSessionHook._();

  static RemoteSessionWake? onRemoteSession;
}
