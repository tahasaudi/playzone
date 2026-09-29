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

  Future<int?> accountIdForCode(String code) async {
    final row = await (select(accounts)..where((a) => a.code.equals(code)))
        .getSingleOrNull();
    return row?.id;
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