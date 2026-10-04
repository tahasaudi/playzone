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
  _LedgerBucket(this.label);
  final String label;
  double subtotal = 0;
  final List<String> items = <String>[];

  /// "مشروبات: مياه ×2، عصير ×1"
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
  });
  final String description;
  final int quantity;
  final double unitPrice;
  final int? productId;

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
  Future<int> createInvoice({
    required List<InvoiceLineInput> lines,
    int? sessionId,
    int? customerId,
    int? employeeId,
    double discount = 0,
    int redeemedPoints = 0,
    double paidCash = 0,
    double paidCard = 0,
  }) {
    return transaction(() async {
      final subtotal = lines.fold<double>(0, (sum, l) => sum + l.total);
      final total = (subtotal - discount).clamp(0, double.infinity).toDouble();

      final splitPayment = paidCash > 0 || paidCard > 0;
      final effectiveCash = splitPayment ? paidCash : total;
      final effectiveCard =
          splitPayment ? (paidCard > 0 ? paidCard : 0.0) : 0.0;
      if (effectiveCash + effectiveCard + 0.001 < total) {
        throw Exception('مبلغ الدفع أقل من الإجمالي المطلوب');
      }
      final paymentMethod =
          effectiveCard > 0 ? (effectiveCash > 0 ? 'mixed' : 'card') : 'cash';

      final invoiceId = await into(invoices).insert(InvoicesCompanion.insert(
        sessionId: Value(sessionId),
        customerId: Value(customerId),
        employeeId: Value(employeeId),
        subtotal: Value(subtotal),
        discount: Value(discount),
        total: Value(total),
        paymentMethod: Value(paymentMethod),
        paidCash: Value(effectiveCash),
        paidCard: Value(effectiveCard),
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
        final bucket = buckets.putIfAbsent(label, () => _LedgerBucket(label));
        bucket.subtotal += line.total;
        bucket.items.add('${line.description} ×${line.quantity}');
      }

      if (customerId != null) {
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

      // Post the sale to the ledger: gaming/session invoices hit the
      // "sales" category, pure café invoices hit "cafe_sales".
      //
      // One entry per bucket, so الحسابات shows exactly what was sold and
      // from which category ("مشروبات: مياه ×2، عصير ×1"). Each entry
      // carries a proportional slice of the FINAL total (after discount)
      // and the last one takes the rounding remainder, so the postings
      // always add up to exactly the invoice total.
      final accountCode = sessionId == null ? 'cafe_sales' : 'sales';
      final account = await (select(accounts)
            ..where((a) => a.code.equals(accountCode)))
          .getSingleOrNull();
      if (account != null && buckets.isNotEmpty) {
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
