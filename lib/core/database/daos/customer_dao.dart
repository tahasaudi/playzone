import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/customers_table.dart';
import '../tables/customer_special_prices_table.dart';
import '../tables/credit_payments_table.dart';

part 'customer_dao.g.dart';

@DriftAccessor(
    tables: [Customers, CustomerSpecialPrices, CreditPayments])
class CustomerDao extends DatabaseAccessor<AppDatabase>
    with _$CustomerDaoMixin {
  CustomerDao(super.db);

  Stream<List<CustomerRow>> watchActive() => (select(customers)
        ..where((c) => c.active.equals(true))
        ..orderBy([(c) => OrderingTerm.desc(c.updatedAt)]))
      .watch();

  /// Simple name/phone search — spec §9 "Search".
  Stream<List<CustomerRow>> watchSearch(String query) {
    if (query.trim().isEmpty) return watchActive();
    final like = '%$query%';
    return (select(customers)
          ..where((c) =>
              c.active.equals(true) &
              (c.name.like(like) | c.phone.like(like))))
        .watch();
  }

  Future<CustomerRow?> getById(int id) =>
      (select(customers)..where((c) => c.id.equals(id))).getSingleOrNull();

  Future<int> insertCustomer(CustomersCompanion entry) =>
      into(customers).insert(entry);

  Future<bool> updateCustomer(CustomersCompanion entry) =>
      update(customers).replace(entry);

  /// Soft-delete — a customer with session/order history should never be
  /// hard-deleted (spec §9 "Delete customer where allowed").
  Future<void> deactivate(int id) => (update(customers)
        ..where((c) => c.id.equals(id)))
      .write(const CustomersCompanion(active: Value(false)));

  // ── الأسعار الخاصة (سعر منتج بعينه لعميل بعينه) ──────────────────────

  /// Watch every special price a customer has — the POS reads this when a
  /// customer is attached, so the grid and the cart price by the deal.
  Stream<List<CustomerSpecialPriceRow>> watchSpecialPrices(int customerId) {
    final query = select(customerSpecialPrices).join([
      innerJoin(products, products.id.equalsExp(customerSpecialPrices.productId)),
    ])
      ..where(customerSpecialPrices.customerId.equals(customerId))
      ..orderBy([OrderingTerm.asc(products.name)]);
    return query.watch().map(
        (rows) => rows.map((r) => r.readTable(customerSpecialPrices)).toList());
  }

  /// One-shot map productId → special price for a customer (POS checkout).
  Future<Map<int, double>> specialPriceMap(int customerId) async {
    final rows = await (select(customerSpecialPrices)
          ..where((s) => s.customerId.equals(customerId)))
        .get();
    return {for (final r in rows) r.productId: r.price};
  }

  /// Set (or overwrite) a product's special price for a customer.
  Future<void> setSpecialPrice({
    required int customerId,
    required int productId,
    required double price,
  }) {
    return into(customerSpecialPrices).insertOnConflictUpdate(
      CustomerSpecialPricesCompanion.insert(
        customerId: customerId,
        productId: productId,
        price: price,
      ),
    );
  }

  Future<void> deleteSpecialPrice({
    required int customerId,
    required int productId,
  }) {
    return (delete(customerSpecialPrices)
          ..where((s) =>
              s.customerId.equals(customerId) &
              s.productId.equals(productId)))
        .go();
  }

  // ── الأجل: دفعات التحصيل (سداد من المتبقي) ──────────────────────────

  Stream<List<CreditPaymentRow>> watchCreditPayments(int customerId) =>
      (select(creditPayments)
            ..where((p) => p.customerId.equals(customerId))
            ..orderBy([(p) => OrderingTerm.desc(p.createdAt)]))
          .watch();

  /// Records a collection (سداد) and lowers the customer's المتبقي in the
  /// same transaction — the balance is never left out of step with its
  /// journal. Clamped at 0, so an over-payment settles the account.
  Future<void> collectCreditPayment({
    required int customerId,
    required double amount,
    String method = 'cash',
    int? employeeId,
    String? note,
  }) {
    return transaction(() async {
      final customer = await (select(customers)
            ..where((c) => c.id.equals(customerId)))
          .getSingle();
      await into(creditPayments).insert(CreditPaymentsCompanion.insert(
        customerId: customerId,
        amount: amount,
        method: Value(method),
        employeeId: Value(employeeId),
        note: Value(note),
      ));
      final remaining = (customer.creditBalance - amount).clamp(0.0, 1e9);
      await (update(customers)..where((c) => c.id.equals(customerId))).write(
        CustomersCompanion(
          creditBalance: Value(remaining),
          updatedAt: Value(DateTime.now()),
        ),
      );
    });
  }
}