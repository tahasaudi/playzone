import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Hashes a PIN with SHA-256. Used by both DB seeding and the (future)
/// PIN login screen so an employee's stored pinHash and a login attempt
/// are always computed the same way.
///
/// NOTE: SHA-256 alone has no per-user salt yet — good enough for a
/// 4-6 digit offline PIN in Phase 1, but if this app ever handles
/// higher-stakes auth, move to a salted hash (e.g. bcrypt-style) instead.
String pinHashFor(String pin) {
  final bytes = utf8.encode(pin);
  return sha256.convert(bytes).toString();
}
