import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/database/app_database.dart';
import '../../core/database/database_provider.dart';

/// يُرمى لما تحاول تضيف/تعدّل عميل برقم تليفون مستخدم بالفعل عند عميل تاني.
class DuplicatePhoneException implements Exception {
  const DuplicatePhoneException();
  @override
  String toString() => 'رقم التليفون ده مسجّل بالفعل';
}

class CustomerRepository {
  CustomerRepository(this._db);
  final AppDatabase _db;

  Stream<List<CustomerRow>> watchSearch(String query) =>
      _db.customerDao.watchSearch(query);

  /// Every active customer regardless of the search box — used by POS /
  /// Quick Sale customer pickers and the loyalty profile lookup.
  Stream<List<CustomerRow>> watchAllActive() => _db.customerDao.watchActive();

  Future<CustomerRow?> getById(int id) => _db.customerDao.getById(id);

  /// يضيف عميل جديد. رقم التليفون اختياري — الفاضي بيتخزّن ''، والمُدخَل
  /// بيرمي [DuplicatePhoneException] لو مستخدم قبل كده.
  Future<int> addCustomer({
    required String name,
    String phone = '',
    String? email,
    String? notes,
    bool creditEnabled = false,
    double creditLimit = 0,
  }) async {
    final trimmedPhone = phone.trim();
    if (trimmedPhone.isNotEmpty) {
      final existing = await _db.customerDao.findByPhone(trimmedPhone);
      if (existing != null) throw const DuplicatePhoneException();
    }
    return _db.customerDao.insertCustomer(CustomersCompanion.insert(
      name: name,
      phone: trimmedPhone,
      email: Value(email),
      notes: Value(notes),
      creditEnabled: Value(creditEnabled),
      creditLimit: Value(creditLimit),
    ));
  }

  Future<void> updateCustomer(CustomerRow customer) async {
    final trimmedPhone = customer.phone.trim();
    if (trimmedPhone.isNotEmpty) {
      final existing = await _db.customerDao.findByPhone(trimmedPhone);
      if (existing != null && existing.id != customer.id) {
        throw const DuplicatePhoneException();
      }
    }
    await _db.customerDao.updateCustomer(customer.toCompanion(true).copyWith(
          phone: Value(trimmedPhone),
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

  Stream<List<CreditPaymentRow>> watchPaymentsToday() =>
      _db.customerDao.watchPaymentsToday();

  Stream<List<CreditPaymentRow>> watchPaymentsBetween({
    required DateTime from,
    required DateTime to,
  }) =>
      _db.customerDao.watchPaymentsBetween(from: from, to: to);

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

/// Every collection made against الأجل today, across all customers — the
/// shift drawer adds what actually came in over the counter.
final todayCreditPaymentsProvider =
    StreamProvider<List<CreditPaymentRow>>((ref) {
  return ref.watch(customerRepositoryProvider).watchPaymentsToday();
});