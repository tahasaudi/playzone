import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/accounts_table.dart';
import '../tables/account_entries_table.dart';

part 'account_dao.g.dart';

/// Ledger categories + the financial movements posted (automatically) to
/// them. DAOs that earn/spend money (invoice, expense, refund) use
/// [accountIdForCode] + [post] so every transaction lands in a category.
@DriftAccessor(tables: [Accounts, AccountEntries])
class AccountDao extends DatabaseAccessor<AppDatabase>
    with _$AccountDaoMixin {
  AccountDao(super.db);

  Stream<List<AccountRow>> watchAll() =>
      (select(accounts)..orderBy([(a) => OrderingTerm.asc(a.kind)]))
          .watch();

  Stream<List<AccountEntryRow>> watchEntries() =>
      (select(accountEntries))
          .watch()
          .map((rows) => rows.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Stream<List<AccountEntryRow>> watchEntriesFor(int accountId) =>
      (select(accountEntries)..where((e) => e.accountId.equals(accountId)))
          .watch()
          .map((rows) => rows.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  /// Movements posted in the [from, to) window, newest first.
  ///
  /// The whole ledger grows without bound — every sale, expense and refund the
  /// shop has ever made — so the screen must not try to render all of it. The
  /// window is filtered in SQL rather than in Dart so the app never pulls the
  /// entire history over the wire to throw most of it away.
  Stream<List<AccountEntryRow>> watchEntriesBetween({
    required DateTime from,
    required DateTime to,
  }) =>
      (select(accountEntries)
            ..where((e) =>
                e.createdAt.isBiggerOrEqualValue(from) &
                e.createdAt.isSmallerThanValue(to)))
          .watch()
          .map((rows) => rows.toList()
            ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<int?> accountIdForCode(String code) async {
    final row = await (select(accounts)..where((a) => a.code.equals(code)))
        .getSingleOrNull();
    return row?.id;
  }

  /// Adds a new ledger category. The code is derived from a slug of the name so
  /// the chart of accounts stays addressable by a stable key, the same way the
  /// seeded books are ('sales', 'expenses', ...). Collisions get a numeric
  /// suffix rather than failing, so two categories may share a display name
  /// without one silently overwriting the other's postings.
  Future<int> createAccount({
    required String name,
    required String kind,
  }) async {
    final base = _slug(name);
    var code = base;
    var n = 2;
    while (await (select(accounts)..where((a) => a.code.equals(code)))
            .getSingleOrNull() !=
        null) {
      code = '$base$n';
      n++;
    }
    return into(accounts).insert(AccountsCompanion.insert(
      code: code,
      name: name,
      kind: kind,
    ));
  }

  /// A URL-safe key from an Arabic or Latin name. Arabic letters are kept as
  /// themselves (SQLite stores UTF-8 happily and the code is only ever compared
  /// for equality), so 'مصاريف نقل' yields a stable, readable code.
  static String _slug(String name) {
    final cleaned = name.trim().toLowerCase().replaceAll(
          RegExp(r'[^\w\u0600-\u06FF]+'),
          '_',
        );
    final trimmed = cleaned.replaceAll(RegExp(r'^_+|_+$'), '');
    return trimmed.isEmpty ? 'account' : trimmed;
  }

  Future<void> updateName(int accountId, String name) =>
      (update(accounts)..where((a) => a.id.equals(accountId)))
          .write(AccountsCompanion(name: Value(name)));

  /// Posts one ledger movement. [direction] is 'in' (adds to the
  /// category total) or 'out' (subtracts). [sourceType] records where
  /// the movement came from (invoice | expense | refund | manual).
  Future<void> post({
    required int accountId,
    required double amount,
    required String direction,
    required String sourceType,
    int? sourceId,
    String? note,
  }) {
    return into(accountEntries).insert(AccountEntriesCompanion.insert(
      accountId: accountId,
      amount: amount,
      direction: direction,
      source: sourceType,
      sourceId: Value(sourceId),
      note: Value(note),
    ));
  }
}