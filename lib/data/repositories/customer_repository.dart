import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

class CustomerRepository {
  CustomerRepository(this._db);
  final AppDatabase _db;

  Stream<List<CustomerRow>> watchSearch(String query) =>
      _db.customerDao.watchSearch(query);

  /// Every active customer regardless of the search box — used by POS /
  /// Quick Sale customer pickers and the loyalty profile lookup.
  Stream<List<CustomerRow>> watchAllActive() => _db.customerDao.watchActive();

  Future<CustomerRow?> getById(int id) => _db.customerDao.getById(id);

  Future<int> addCustomer({
    required String name,
    required String phone,
    String? email,
    String? notes,
    bool creditEnabled = false,
    double creditLimit = 0,
  }) {
    return _db.customerDao.insertCustomer(CustomersCompanion.insert(
      name: name,
      phone: phone,
      email: Value(email),
      notes: Value(notes),
      creditEnabled: Value(creditEnabled),
      creditLimit: Value(creditLimit),
    ));
  }

  Future<void> updateCustomer(CustomerRow customer) {
    return _db.customerDao.updateCustomer(customer.toCompanion(true).copyWith(
          updatedAt: Value(DateTime.now()),
        ));
  }

  Future<void> deactivate(int id) => _db.customerDao.deactivate(id);

  // ── الأسعار الخاصة ────────────────────────────────────────────────────

  Stream<List<CustomerSpecialPriceRow>> watchSpecialPrices(int customerId) =>
      _db.customerDao.watchSpecialPrices(customerId);

  Future<Map<int, double>> specialPriceMap(int customerId) =>
      _db.customerDao.specialPriceMap(customerId);

  Future<void> setSpecialPrice({
    required int customerId,
    required int productId,
    required double price,
  }) =>
      _db.customerDao.setSpecialPrice(
        customerId: customerId,
        productId: productId,
        price: price,
      );

  Future<void> deleteSpecialPrice({
    required int customerId,
    required int productId,
  }) =>
      _db.customerDao.deleteSpecialPrice(
        customerId: customerId,
        productId: productId,
      );

  // ── الأجل ────────────────────────────────────────────────────────────

  Stream<List<CreditPaymentRow>> watchCreditPayments(int customerId) =>
      _db.customerDao.watchCreditPayments(customerId);

  Future<void> collectCreditPayment({
    required int customerId,
    required double amount,
    String method = 'cash',
    int? employeeId,
    String? note,
  }) =>
      _db.customerDao.collectCreditPayment(
        customerId: customerId,
        amount: amount,
        method: method,
        employeeId: employeeId,
        note: note,
      );
}

final customerRepositoryProvider = Provider<CustomerRepository>((ref) {
  return CustomerRepository(ref.watch(appDatabaseProvider));
});

/// Drives the customers screen's search box — the query string is kept
/// in a plain StateProvider so the list rebuilds as the user types.
final customerSearchQueryProvider = StateProvider<String>((ref) => '');

final customersProvider = StreamProvider<List<CustomerRow>>((ref) {
  final query = ref.watch(customerSearchQueryProvider);
  return ref.watch(customerRepositoryProvider).watchSearch(query);
});

/// Full active customer list, independent of the search box — the POS
/// customer picker, checkout loyalty panel and quick sale all watch this.
final allActiveCustomersProvider = StreamProvider<List<CustomerRow>>((ref) {
  return ref.watch(customerRepositoryProvider).watchAllActive();
});

/// One customer by id — for the checkout modal's loyalty section.
final customerByIdProvider =
    FutureProvider.family<CustomerRow?, int>((ref, id) {
  return ref.watch(customerRepositoryProvider).getById(id);
});

/// A customer's special prices (سعر خاص لكل منتج) — the POS watches this
/// when the customer is attached, the customer card edits it.
final specialPricesForCustomerProvider =
    StreamProvider.family<List<CustomerSpecialPriceRow>, int>((ref, id) {
  return ref.watch(customerRepositoryProvider).watchSpecialPrices(id);
});

/// A customer's سداد journal — the collections made against their الأجل.
final creditPaymentsProvider =
    StreamProvider.family<List<CreditPaymentRow>, int>((ref, id) {
  return ref.watch(customerRepositoryProvider).watchCreditPayments(id);
});