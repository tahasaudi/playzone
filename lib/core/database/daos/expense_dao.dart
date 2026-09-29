import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/expenses_table.dart';
import '../tables/accounts_table.dart';
import '../tables/account_entries_table.dart';

part 'expense_dao.g.dart';

@DriftAccessor(tables: [Expenses, Accounts, AccountEntries])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(super.db);

  Stream<List<ExpenseRow>> watchAll() =>
      (select(expenses)..orderBy([(e) => OrderingTerm.desc(e.createdAt)])).watch();

  /// Filtered in Dart for the same version-safety reason as
  /// InvoiceDao.watchToday.
  Stream<List<ExpenseRow>> watchToday() {
    return select(expenses).watch().map((rows) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      return rows.where((r) => r.createdAt.isAfter(startOfDay)).toList();
    });
  }

  Future<int> addExpense({
    required String category,
    required double amount,
    String? description,
    int? employeeId,
  }) {
    return transaction(() async {
      final id = await into(expenses).insert(ExpensesCompanion.insert(
        category: category,
        amount: amount,
        description: Value(description),
        employeeId: Value(employeeId),
      ));
      await _postToLedger(amount: amount, sourceId: id, note: description);
      return id;
    });
  }

  /// Deletes an expense and reverses its ledger movement so the numbers
  /// stay balanced.
  Future<void> deleteExpense(int id) {
    return transaction(() async {
      final expense =
          await (select(expenses)..where((e) => e.id.equals(id)))
              .getSingleOrNull();
      if (expense == null) return;
      await (delete(expenses)..where((e) => e.id.equals(id))).go();
      await (delete(accountEntries)
            ..where((a) =>
                a.source.equals('expense') & a.sourceId.equals(id)))
          .go();
    });
  }

  Future<void> updateCategory(int id, String category) =>
      (update(expenses)..where((e) => e.id.equals(id))).write(
        ExpensesCompanion(category: Value(category)),
      );

  Stream<List<ExpenseRow>> watchByCategory(String category) =>
      (select(expenses)..where((e) => e.category.equals(category))).watch();

  /// One-shot ranged read (non-stream) — partnership/profit math.
  Future<List<ExpenseRow>> getBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await select(expenses).get();
    return rows
        .where((r) =>
            !r.createdAt.isBefore(from) && r.createdAt.isBefore(to))
        .toList();
  }

  Future<void> _postToLedger({
    required double amount,
    required int sourceId,
    String? note,
  }) async {
    final account = await (select(accounts)
          ..where((a) => a.code.equals('expenses')))
        .getSingleOrNull();
    if (account == null) return;
    await into(accountEntries).insert(AccountEntriesCompanion.insert(
      accountId: account.id,
      amount: amount,
      direction: 'out',
      source: 'expense',
      sourceId: Value(sourceId),
      note: Value(note),
    ));
  }
}
