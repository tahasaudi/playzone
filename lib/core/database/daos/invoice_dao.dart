import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/invoices_table.dart';
import '../tables/invoice_items_table.dart';
import '../tables/products_table.dart';
import '../tables/categories_table.dart';
import '../tables/customers_table.dart';
import '../tables/loyalty_settings_table.dart';
import '../tables/accounts_table.dart';
import '../tables/account_entries_table.dart';
import '../../loyalty/loyalty_math.dart';

part 'invoice_dao.g.dart';

/// One "what was sold" bucket for the ledger: the café category (or the
/// gaming-time line) plus the individual items inside it. This is what
/// makes the Accounting screen answer "اتباع من اي؟" without opening
/// the invoice.
class _LedgerBucket {
  _LedgerBucket(this.label, {required this.isGaming});
  final String label;

  /// True for the gaming-time line, false for anything the café sold.
  ///
  /// Carried on the bucket because it decides the ACCOUNT the money lands in,
  /// and the café and the PlayStation are two separate books: a table that
  /// played for an hour and drank two waters has to read as a PlayStation hour
  /// and two drinks, not as one anonymous lump.
  final bool isGaming;
  double subtotal = 0;
  final List<String> items = <String>[];

  /// "وقت اللعب: بليستيشن ×1، بلايستيشن 2 ×1"
  String get note => items.isEmpty ? label : '$label: ${items.join('، ')}';
}

/// One line the caller wants on the invoice — used for both a POS cart
/// line (productId set) and a session's "gaming time" line (productId
/// null).
class InvoiceLineInput {
  InvoiceLineInput({
    required this.description,
    required this.quantity,
    required this.unitPrice,
    this.productId,
    this.createdAt,
  });
  final String description;
  final int quantity;
  final double unitPrice;
  final int? productId;

  /// When this line was actually asked for.
  ///
  /// Left null by ordinary callers, which means "now" — that is the truthful
  /// answer for anything rung up at the moment of writing. The one place it is
  /// set is the fold from a café draft onto the bill: those drinks were poured
  /// hours ago and their time must survive the trip, or the receipt would
  /// claim the customer ordered everything at checkout.
  final DateTime? createdAt;

  double get total => unitPrice * quantity;
}

@DriftAccessor(tables: [
  Invoices,
  InvoiceItems,
  Products,
  Categories,
  Customers,
  LoyaltySettings,
  Accounts,
  AccountEntries
])
class InvoiceDao extends DatabaseAccessor<AppDatabase> with _$InvoiceDaoMixin {
  InvoiceDao(super.db);

  Stream<List<InvoiceRow>> watchRecent({int limit = 50}) => (select(invoices)
        ..orderBy([(i) => OrderingTerm.desc(i.createdAt)])
        ..limit(limit))
      .watch();

  /// Today's invoices — used for the Dashboard's daily revenue KPI and
  /// the per-employee breakdown (grouping happens in the repository,
  /// not here, since it's plain Dart list math and stays simpler that
  /// way than a raw SQL GROUP BY).
  ///
  /// Filtered in Dart rather than SQL — this table is small enough that
  /// it's simpler and more version-proof than relying on a drift
  /// datetime-comparison operator name that may differ across versions.
  Stream<List<InvoiceRow>> watchToday() {
    return select(invoices).watch().map((rows) {
      final now = DateTime.now();
      final startOfDay = DateTime(now.year, now.month, now.day);
      return rows.where((r) => r.createdAt.isAfter(startOfDay)).toList();
    });
  }

  /// Creates an invoice with its line items in one transaction:
  /// decrements stock for any product lines, updates the customer's
  /// running totals (including loyalty points earned/spent) if a
  /// customer is attached, and writes the invoice + items. This is the
  /// single path both POS and session Checkout go through, so stock,
  /// customer totals and loyalty points stay consistent everywhere.
  ///
  /// [paidCash]/[paidCard] split the tender — if both are zero the whole
  /// [total] defaults to cash (legacy callers). [redeemedPoints] spends
  /// the customer's points against the bill (subtracted from total via
  /// their configured point value); points are always earned on the
  /// final total when a customer is attached.
  ///
  /// [settled] false writes a bill that has been rung up but not paid for —
  /// a café order taken during a session, waiting to go on the one bill at
  /// checkout. Stock still moves, because the drinks left the shelf; the
  /// customer's visit, their loyalty points and the ledger entry wait for the
  /// real bill, because no money has changed hands yet. Those drafts are
  /// folded into the session's final bill by [removeSessionOrders].
  Future<int> createInvoice({
    required List<InvoiceLineInput> lines,
    int? sessionId,
    int? customerId,
    int? employeeId,
    double discount = 0,
    int redeemedPoints = 0,
    double paidCash = 0,
    double paidCard = 0,
    bool settled = true,
  }) {
    return transaction(() async {
      final subtotal = lines.fold<double>(0, (sum, l) => sum + l.total);
      final total = (subtotal - discount).clamp(0, double.infinity).toDouble();

      final splitPayment = paidCash > 0 || paidCard > 0;
      final effectiveCash = splitPayment ? paidCash : total;
      final effectiveCard =
          splitPayment ? (paidCard > 0 ? paidCard : 0.0) : 0.0;
      if (settled && effectiveCash + effectiveCard + 0.001 < total) {
        throw Exception('مبلغ الدفع أقل من الإجمالي المطلوب');
      }
      final paymentMethod = !settled
          ? 'unpaid'
          : effectiveCard > 0
              ? (effectiveCash > 0 ? 'mixed' : 'card')
              : 'cash';

      final invoiceId = await into(invoices).insert(InvoicesCompanion.insert(
        sessionId: Value(sessionId),
        customerId: Value(customerId),
        employeeId: Value(employeeId),
        subtotal: Value(subtotal),
        discount: Value(discount),
        total: Value(total),
        paymentMethod: Value(paymentMethod),
        paidCash: Value(settled ? effectiveCash : 0),
        paidCard: Value(settled ? effectiveCard : 0),
      ));

      // Bucket every line by where it came from — the café category for
      // products, "وقت اللعب" for the session's gaming time — so the
      // ledger can say WHAT was sold and FROM which category.
      final buckets = <String, _LedgerBucket>{};
      final categoryNameOf = <int, String>{};

      for (final line in lines) {
        await into(invoiceItems).insert(InvoiceItemsCompanion.insert(
          invoiceId: invoiceId,
          productId: Value(line.productId),
          description: line.description,
          quantity: Value(line.quantity),
          unitPrice: line.unitPrice,
          total: line.total,
          createdAt: Value(line.createdAt ?? DateTime.now()),
        ));

        if (line.productId != null) {
          final product = await (select(products)
                ..where((p) => p.id.equals(line.productId!)))
              .getSingle();
          await (update(products)..where((p) => p.id.equals(line.productId!)))
              .write(ProductsCompanion(
            stockQuantity: Value(product.stockQuantity - line.quantity),
            updatedAt: Value(DateTime.now()),
          ));
          final category = await (select(categories)
                ..where((c) => c.id.equals(product.categoryId)))
              .getSingleOrNull();
          categoryNameOf[product.id] = category?.name ?? 'أصناف';
        }

        final label = line.productId == null
            ? 'وقت اللعب'
            : categoryNameOf[line.productId] ?? 'أصناف';
        final bucket = buckets.putIfAbsent(
          label,
          () => _LedgerBucket(label, isGaming: line.productId == null),
        );
        bucket.subtotal += line.total;
        bucket.items.add('${line.description} ×${line.quantity}');
      }

      if (customerId != null && settled) {
        final customer = await (select(customers)
              ..where((c) => c.id.equals(customerId)))
            .getSingle();

        // Loyalty: earn on the final total, spend if points redeemed.
        // Net delta can be negative (spend only) or positive (earn only)
        // — applyPointsDelta clamps at 0, so the balance never goes below.
        final settings = await (select(loyaltySettings)
              ..where((s) => s.id.equals(1)))
            .getSingleOrNull();
        final pointsPerCurrency = settings?.pointsPerCurrency ?? 1.0;
        final earned = LoyaltyMath.pointsEarnedFor(total, pointsPerCurrency);
        final netDelta = earned - redeemedPoints;

        await (update(customers)..where((c) => c.id.equals(customerId)))
            .write(CustomersCompanion(
          totalVisits: Value(customer.totalVisits + 1),
          totalSpent: Value(customer.totalSpent + total),
          loyaltyPoints:
              Value((customer.loyaltyPoints + netDelta).clamp(0, 1 << 20)),
          updatedAt: Value(DateTime.now()),
        ));
      }

      // Post the sale to the ledger: one entry per bucket, and each bucket
      // lands in the book that owns it. Gaming time goes to "sales" (the
      // PlayStation side), every drink to "cafe_sales" (the café side), so one
      // bill reads as an hour of play AND a café order — which is what lets
      // الحسابات answer "how much did each side take" without anyone splitting
      // the ticket by hand.
      //
      // Each entry carries a proportional slice of the FINAL total (after
      // discount) and the last one takes the rounding remainder, so the
      // postings always add up to exactly the invoice total.
      //
      // An unsettled draft posts nothing: no money has changed hands yet, and
      // the entry that counts arrives with the bill that settles it.
      if (settled && buckets.isNotEmpty) {
        final gamingAccount = await _accountByCode('sales');
        final cafeAccount = await _accountByCode('cafe_sales');
        final ordered = buckets.values.toList()
          ..sort((a, b) => b.subtotal.compareTo(a.subtotal));
        var allocated = 0.0;
        for (var i = 0; i < ordered.length; i++) {
          final isLast = i == ordered.length - 1;
          final raw = isLast
              ? total - allocated
              : (subtotal == 0 ? 0.0 : total * ordered[i].subtotal / subtotal);
          // Two decimals per entry; the last entry absorbs the remainder.
          final amount = isLast ? raw : (raw * 100).roundToDouble() / 100;
          allocated += amount;
          final account = ordered[i].isGaming ? gamingAccount : cafeAccount;
          if (account == null) continue;
          await into(accountEntries).insert(AccountEntriesCompanion.insert(
            accountId: account.id,
            amount: amount < 0 ? 0.0 : amount,
            direction: 'in',
            source: 'invoice',
            sourceId: Value(invoiceId),
            note: Value(ordered[i].note),
          ));
        }
      }

      return invoiceId;
    });
  }

  /// The ledger book with this [code], or null when the chart of accounts has
  /// no such line — a missing book must not silently swallow a sale.
  Future<AccountRow?> _accountByCode(String code) {
    return (select(accounts)..where((a) => a.code.equals(code)))
        .getSingleOrNull();
  }

  /// Folds a session's café drafts into the bill that settles them.
  ///
  /// Each order taken during a sitting was rung up on its own so the stock
  /// moved and the drinks were recorded the moment they were asked for. Those
  /// drafts carry no payment — the money is taken once, at checkout — so if they
  /// were left standing they would count every drink a second time in the day's
  /// revenue, on top of the bill that already includes them.
  ///
  /// Only drafts are touched: identified by `paymentMethod == 'unpaid'`, so the
  /// settled bill that replaces them is never in scope.
  ///
  /// Call this AFTER the final bill is written. The other order loses nothing
  /// worth keeping if the delete fails (a visible double count that can be
  /// repaired by hand); this order never risks losing the record of what was
  /// ordered.
  Future<void> removeSessionOrders(int sessionId) async {
    final drafts = await (select(invoices)
          ..where((i) =>
              i.sessionId.equals(sessionId) & i.paymentMethod.equals('unpaid')))
        .get();
    if (drafts.isEmpty) return;

    final ids = drafts.map((d) => d.id).toList();
    for (final id in ids) {
      // Unsettled drafts post no ledger entry, but clearing any that exist
      // keeps this safe to run against a database written by an older build.
      await (delete(accountEntries)..where((e) => e.sourceId.equals(id))).go();
      await (delete(invoiceItems)..where((l) => l.invoiceId.equals(id))).go();
    }
    await (delete(invoices)..where((i) => i.id.isIn(ids))).go();
  }

  /// Invoices created inside [from]..[to] — feeds the per-employee
  /// performance report and date-ranged totals. Filtered in Dart like
  /// watchToday; consistent and version-proof.
  Stream<List<InvoiceRow>> watchBetween({
    required DateTime from,
    required DateTime to,
  }) {
    return select(invoices).watch().map((rows) => rows
        .where((r) => !r.createdAt.isBefore(from) && r.createdAt.isBefore(to))
        .toList());
  }

  /// Every invoice line whose parent invoice falls inside [from]..[to] —
  /// feeds the Statistics screen's top-products ranking. Joined so the
  /// date filter travels with each line, then filtered in Dart to match
  /// the rest of the ranged reads.
  Stream<List<InvoiceItemRow>> watchItemsBetween({
    required DateTime from,
    required DateTime to,
  }) {
    final query = select(invoiceItems).join([
      innerJoin(invoices, invoices.id.equalsExp(invoiceItems.invoiceId)),
    ]);
    return query.watch().map((rows) => rows
        .where((r) {
          final invoice = r.readTable(invoices);
          return !invoice.createdAt.isBefore(from) &&
              invoice.createdAt.isBefore(to);
        })
        .map((r) => r.readTable(invoiceItems))
        .toList());
  }

  /// Invoices already linked to a live session — café orders placed
  /// against it. Feeds the session panel's "الطلبات" row.
  Stream<List<InvoiceRow>> watchForSession(int sessionId) =>
      (select(invoices)..where((i) => i.sessionId.equals(sessionId))).watch();

  /// The individual lines behind those invoices — "مياه ×2، عصير ×1".
  ///
  /// A separate read from [watchForSession] on purpose: the panel needs the
  /// sum AND the names, and the names only exist on the lines. Filtering in
  /// SQL rather than pulling the whole table, because a busy evening's worth of
  /// invoice lines is not something to hand to a widget that will show one
  /// session's worth of it.
  Stream<List<InvoiceItemRow>> watchItemsForSession(int sessionId) {
    final query = select(invoiceItems).join([
      innerJoin(invoices, invoices.id.equalsExp(invoiceItems.invoiceId)),
    ]);
    return query.watch().map((rows) => rows
        .where((r) => r.readTable(invoices).sessionId == sessionId)
        .map((r) => r.readTable(invoiceItems))
        .toList());
  }

  /// The café lines of a session's unpaid drafts, ready to be copied onto the
  /// bill that settles them.
  ///
  /// Read as lines rather than as money because the bill is rebuilt from them:
  /// the drinks keep their own names and prices on the customer's one ticket,
  /// instead of collapsing into a single "طلبات الكافيه" figure they never
  /// wrote.
  Future<List<InvoiceLineInput>> draftLinesForSession(int sessionId) async {
    final drafts = await (select(invoices)
          ..where((i) =>
              i.sessionId.equals(sessionId) & i.paymentMethod.equals('unpaid')))
        .get();
    if (drafts.isEmpty) return const [];

    final byId = <int, InvoiceRow>{
      for (final d in drafts) d.id: d,
    };
    final query = select(invoiceItems).join([
      innerJoin(invoices, invoices.id.equalsExp(invoiceItems.invoiceId)),
    ])
      ..where(invoiceItems.invoiceId.isIn(byId.keys.toList()));
    final rows = await query.get();

    // Newest draft first, then its own line order — the drinks come back in the
    // order they were asked for rather than by id, which the caller has no way
    // to know.
    rows.sort((a, b) {
      final ai = byId[a.readTable(invoices).id]!.createdAt;
      final bi = byId[b.readTable(invoices).id]!.createdAt;
      final byDraft = bi.compareTo(ai);
      return byDraft != 0
          ? byDraft
          : a
              .readTable(invoiceItems)
              .id
              .compareTo(b.readTable(invoiceItems).id);
    });
    return rows.map((r) {
      final line = r.readTable(invoiceItems);
      return InvoiceLineInput(
        productId: line.productId,
        description: line.description,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        // The drink's own moment travels with it onto the bill. Drop it here
        // and the receipt would answer "متى طلب المياه" with "when you paid",
        // which is the exact fact the drafts were holding on to.
        createdAt: line.createdAt ?? byId[r.readTable(invoices).id]!.createdAt,
      );
    }).toList();
  }

  /// One-shot ranged read (non-stream) — used by the partnership ledger
  /// to compute period profit without holding a subscription open.
  Future<List<InvoiceRow>> getBetween({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows = await select(invoices).get();
    return rows
        .where((r) => !r.createdAt.isBefore(from) && r.createdAt.isBefore(to))
        .toList();
  }

  Future<List<InvoiceItemRow>> itemsForInvoice(int invoiceId) =>
      (select(invoiceItems)..where((i) => i.invoiceId.equals(invoiceId))).get();
}
