import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whichever screen currently has a non-route overlay open (like the
/// Session Details Panel, which is a Stack overlay, not a
/// Navigator route) registers a close callback here. The global ESC
/// handler in AppShell checks this FIRST, then falls back to popping a
/// real dialog/route if nothing registered a callback.
///
/// Screens must clear this (set it back to null) whenever they close
/// the panel through any OTHER means (a button, tapping outside, etc.)
/// so ESC doesn't call a stale closer.
final escCloseHandlerProvider = StateProvider<VoidCallback?>((ref) => null);
