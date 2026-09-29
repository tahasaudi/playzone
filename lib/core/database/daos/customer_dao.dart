import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/customers_table.dart';

part 'customer_dao.g.dart';

@DriftAccessor(tables: [Customers])
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
}
