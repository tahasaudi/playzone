import '../database/app_database.dart';

/// The single place where the café's money rules live.
///
/// Every screen that shows revenue, cost, expenses, refunds or profit goes
/// through here. Keeping one definition is what stops "الإيراد" meaning one
/// thing on the dashboard and something else in the partnership ledger —
/// a disagreement a shop owner cannot afford, because two partners dividing
/// a profit that the app cannot even agree on is worse than no split at all.
///
/// The agreed definition of the café's numbers:
///
///   صافي الربح = الإيراد (المسدَّد) − تكلفة البضاعة − المصروفات − المرتجعات
///
/// * **الإيراد** counts only *settled* bills — anything whose payment method
///   is not `'unpaid'`. A café order rung up during a live session is a
///   **draft**: it moved stock, but no money changed hands, so it is not
///   revenue until the bill that settles it is written.
/// * **المسدَّد** includes cash, card, mixed and الأجل (الدفع على الحساب):
///   charging a bill to a customer's account settles *that bill* even though
///   the cash arrives later. Collecting that account later (سداد) is a cash
///   movement, never revenue again — otherwise the same money would be
///   counted twice.
/// * **تكلفة البضاعة** is `costPrice × الكمية` for the product lines sold.
/// * **المرتجعات** come back off both the revenue and the books as a cost.
class Accounting {
  Accounting._();

  /// A bill that has been rung up but not paid for — a live session's open
  /// café tab. Never revenue, and never money in the drawer.
  static const String unpaidMethod = 'unpaid';

  /// Whether [invoice] has actually been paid for. `'unpaid'` is the only
  /// value that means "not yet"; every real tender (cash/card/mixed/credit)
  /// counts as settled, including الأجل.
  static bool isSettled(InvoiceRow invoice) =>
      invoice.paymentMethod != unpaidMethod;

  /// Just the settled bills — the ones that are real revenue.
  static List<InvoiceRow> settledOnly(Iterable<InvoiceRow> invoices) =>
      invoices.where(isSettled).toList(growable: false);

  /// الإيراد — the total of the bills that have actually been paid for.
  static double revenue(Iterable<InvoiceRow> invoices) =>
      settledOnly(invoices).fold(0.0, (sum, i) => sum + i.total);

  /// The revenue of the period, split into the two sides of the shop, with the
  /// discount called out so the three figures reconcile to the piastre:
  ///
  ///   gaming + cafe − discounts == revenue
  ///
  /// * **gaming** — the PlayStation side: every settled «وقت اللعب» line (a line
  ///   with no product behind it). This is the shop's biggest earner and it has
  ///   to read as its own number, not be diluted into the café's.
  /// * **cafe** — everything the café actually sold, by the line's own total.
  /// * **discounts** — what was knocked off the bills. Kept as its own figure so
  ///   the breakdown adds up exactly instead of leaving a gap someone has to
  ///   guess at ("الألعاب + الكافيه مش بيساوي الإيراد ليه؟").
  ///
  /// A bill with no lines at all (an old or hand-inserted row) falls on the café
  /// side whole, so nothing is ever dropped from the total.
  static ({double gaming, double cafe, double discounts, double revenue})
      revenueBreakdown({
    required Iterable<InvoiceRow> invoices,
    required Iterable<InvoiceItemRow> items,
  }) {
    final byInvoice = <int, List<InvoiceItemRow>>{};
    for (final item in items) {
      byInvoice.putIfAbsent(item.invoiceId, () => <InvoiceItemRow>[]).add(item);
    }

    var gaming = 0.0;
    var cafe = 0.0;
    for (final invoice in settledOnly(invoices)) {
      final lines = byInvoice[invoice.id];
      if (lines == null || lines.isEmpty) {
        cafe += invoice.subtotal;
        continue;
      }
      for (final line in lines) {
        if (line.productId == null) {
          gaming += line.total;
        } else {
          cafe += line.total;
        }
      }
    }

    final settledRevenue = revenue(invoices);
    final discounts = gaming + cafe - settledRevenue;
    return (
      gaming: gaming,
      cafe: cafe,
      // The gross can only ever be ≥ the net (total = subtotal − discount), but
      // clamp so a hand-edited row can never render a negative discount.
      discounts: discounts < 0 ? 0.0 : discounts,
      revenue: settledRevenue,
    );
  }

  /// What was handed over as cash (the drawer's side of the money).
  static double cash(Iterable<InvoiceRow> invoices) =>
      settledOnly(invoices).fold(0.0, (sum, i) => sum + i.paidCash);

  /// What was taken on the card terminal.
  static double card(Iterable<InvoiceRow> invoices) =>
      settledOnly(invoices).fold(0.0, (sum, i) => sum + i.paidCard);

  /// The part of the settled bills that went onto customers' accounts (الأجل).
  static double onAccount(Iterable<InvoiceRow> invoices) =>
      settledOnly(invoices).fold(0.0, (sum, i) => sum + i.paidOnAccount);

  static double expenses(Iterable<ExpenseRow> expenses) =>
      expenses.fold(0.0, (sum, e) => sum + e.amount);

  static double refunds(Iterable<RefundRow> refunds) =>
      refunds.fold(0.0, (sum, r) => sum + r.amount);

  /// تكلفة البضاعة — the cost of the products actually sold on [items], each
  /// priced at its product's [costByProduct]. A "وقت اللعب" line has no
  /// product behind it and therefore no goods cost.
  ///
  /// Priced at the product's *current* cost, which is the agreed basis: the
  /// app deliberately keeps no historical cost snapshot per line, so reporting
  /// always answers "what would this stock cost us today", not "what it cost
  /// the day it was sold".
  static double costOfGoods(
    Iterable<InvoiceItemRow> items,
    Map<int, double> costByProduct,
  ) =>
      items.fold(0.0, (sum, i) {
        final id = i.productId;
        if (id == null) return sum;
        return sum + (costByProduct[id] ?? 0) * i.quantity;
      });

  /// صافي الربح, by the agreed definition.
  static double netProfit({
    required double revenue,
    double costOfGoods = 0,
    double expenses = 0,
    double refunds = 0,
  }) =>
      revenue - costOfGoods - expenses - refunds;
}
