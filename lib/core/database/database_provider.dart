import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_database.dart';

/// Single shared AppDatabase instance for the whole app's lifetime.
/// Repositories read this provider instead of constructing their own
/// AppDatabase — keeps exactly one SQLite connection open.
final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
