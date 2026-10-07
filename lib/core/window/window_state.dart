import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

/// Window utilities for the POS desktop app.
///
/// Lives outside the widget tree so both the keyboard shortcut (F11 in
/// AppShell) and the top-bar button flip the same state, and so the
/// `/status` server can report the current mode for remote debugging.
class WindowState {
  WindowState._();

  /// Whether the POS is currently showing in true full screen (no window
  /// frame, over the taskbar). Mirrored here so `/status` can print it.
  static bool fullScreen = false;

  // --- user32 bindings ---------------------------------------------------
  //
  // The toggle is done by hand instead of by a plugin because the plugins
  // (window_manager included) fail the one thing that matters here: they
  // leave WS_CAPTION on the frame, so a "full screen" POS keeps a title bar
  // with the window title painted on top of the app. On a counter machine
  // that bar is exactly what the owner asked to be rid of. All of these
  // calls are trivial, thread-safe, and instantly verifiable at runtime.

  static final _user32 = DynamicLibrary.open('user32.dll');

  static final _getWindowLongW = _user32.lookupFunction<
      Int32 Function(IntPtr, Int32), int Function(int, int)>('GetWindowLongW');
  static final _setWindowLongW = _user32.lookupFunction<
      Int32 Function(IntPtr, Int32, Int32),
      int Function(int, int, int)>('SetWindowLongW');
  static final _getWindowPlacement = _user32.lookupFunction<
      Int32 Function(IntPtr, Pointer<_WindowPlacement>),
      int Function(int, Pointer<_WindowPlacement>)>('GetWindowPlacement');
  static final _setWindowPlacement = _user32.lookupFunction<
      Int32 Function(IntPtr, Pointer<_WindowPlacement>),
      int Function(int, Pointer<_WindowPlacement>)>('SetWindowPlacement');
  static final _getSystemMetrics =
      _user32.lookupFunction<Int32 Function(Int32), int Function(int)>(
          'GetSystemMetrics');
  static final _setWindowPos = _user32.lookupFunction<
      Int32 Function(IntPtr, IntPtr, Int32, Int32, Int32, Int32, Uint32),
      int Function(int, int, int, int, int, int, int)>('SetWindowPos');

  static const _gwlStyle = -16;
  static const _wsCaption = 0x00C00000; // border + dialog frame = title bar
  static const _wsThickFrame = 0x00040000;
  static const _wsSysMenu = 0x00080000;
  static const _wsMinimizeBox = 0x00020000;
  static const _wsMaximizeBox = 0x00010000;
  static const _wsPopup = 0x80000000;
  static const _wsVisible = 0x10000000;

  // The POS runs on a single screen; GetSystemMetrics is the screen size in
  // the same physical pixels the window moves in (the runner is DPI aware).
  static const _smCxScreen = 0;
  static const _smCyScreen = 1;
  static const _hwndTopmost = -1;
  static const _hwndNotTopmost = -2;
  static const _swpNoMove = 0x0002;
  static const _swpNoSize = 0x0001;
  static const _swpNoZOrder = 0x0004;
  static const _swpNoOwnerZOrder = 0x0200;
  static const _swpFrameChanged = 0x0020;
  static const _swpShowWindow = 0x0040;

  /// Our own top-level window handle, read once and cached.
  static int? _hwnd;

  /// The frame style the window had before full screen, so leaving it is an
  /// exact round trip (border, resize grip, system menu, min/max buttons).
  static int _savedStyle = 0;

  /// The position/size/show-state (maximized or not) before full screen.
  static Pointer<_WindowPlacement>? _savedPlacement;

  /// True full screen <-> windowed, tracked by our own flag, so a double-tap
  /// (F11 or the top-bar button) is always an exact round trip.
  ///
  /// Full screen means: no title bar (the caption bits are stripped from the
  /// frame) and the window stretched over the whole monitor — including the
  /// taskbar, which is guaranteed by always-on-top while in this mode. On the
  /// way out the previous style, bounds and maximized state all come back.
  static Future<void> toggleFullScreen() async {
    try {
      if (_hwnd == null) {
        final raw = await windowManager.getId();
        if (raw == 0) return;
        _hwnd = raw;
      }
      final hwnd = _hwnd!;
      if (!fullScreen) {
        // Remember the frame we are about to remove.
        _savedStyle = _getWindowLongW(hwnd, _gwlStyle);
        final placement = calloc<_WindowPlacement>();
        placement.ref.length = sizeOf<_WindowPlacement>();
        _getWindowPlacement(hwnd, placement);
        _savedPlacement = placement;

        // Strip every affordance the window frame owns: the caption bar,
        // the resizing border, the system menu, the min/max buttons.
        final style = (_savedStyle | _wsPopup | _wsVisible) &
            ~(_wsCaption |
                _wsThickFrame |
                _wsSysMenu |
                _wsMinimizeBox |
                _wsMaximizeBox);
        _setWindowLongW(hwnd, _gwlStyle, style);

        // Cover the whole screen — topmost so nothing, the taskbar included,
        // can paint over the POS.
        _setWindowPos(
            hwnd,
            _hwndTopmost,
            0,
            0,
            _getSystemMetrics(_smCxScreen),
            _getSystemMetrics(_smCyScreen),
            _swpFrameChanged | _swpShowWindow | _swpNoOwnerZOrder);
      } else {
        // Give the frame back, then the exact size/state it had before.
        _setWindowLongW(hwnd, _gwlStyle, _savedStyle);
        final placement = _savedPlacement;
        if (placement != null) {
          _setWindowPlacement(hwnd, placement);
          calloc.free(placement);
          _savedPlacement = null;
        }
        _setWindowPos(
            hwnd,
            _hwndNotTopmost,
            0,
            0,
            0,
            0,
            _swpFrameChanged |
                _swpNoMove |
                _swpNoSize |
                _swpNoZOrder |
                _swpNoOwnerZOrder |
                _swpShowWindow);
      }
      fullScreen = !fullScreen;
    } catch (_) {
      // user32 or channel not ready (tests / odd startup) — no-op then.
    }
  }
}

final class _Rect extends Struct {
  @Int32()
  external int left;
  @Int32()
  external int top;
  @Int32()
  external int right;
  @Int32()
  external int bottom;
}

final class _Point extends Struct {
  @Int32()
  external int x;
  @Int32()
  external int y;
}

final class _WindowPlacement extends Struct {
  @Uint32()
  external int length;
  @Uint32()
  external int flags;
  @Uint32()
  external int showCmd;
  external _Point ptMinPosition;
  external _Point ptMaxPosition;
  external _Rect rcNormalPosition;
  external _Rect rcDevicePosition;
}

/// Live mirror of [WindowState.fullScreen] for widgets (top-bar icon/tooltip).
class WindowFullScreenNotifier extends Notifier<bool> {
  @override
  bool build() => WindowState.fullScreen;

  /// Flips the window and republishes — the single entry point used by both
  /// the F11 shortcut and the top-bar button.
  Future<void> toggle() async {
    await WindowState.toggleFullScreen();
    state = WindowState.fullScreen;
  }
}

final windowFullScreenProvider =
    NotifierProvider<WindowFullScreenNotifier, bool>(
        WindowFullScreenNotifier.new);
