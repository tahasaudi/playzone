import 'package:drift/drift.dart';
import 'customers_table.dart';
import 'sessions_table.dart';
import 'employees_table.dart';

/// One completed transaction — either a gaming session checkout, a café
/// sale (POS), or both combined. sessionId is nullable because a pure
/// café sale (Quick Sale) has no session attached.
@DataClassName('InvoiceRow')
class Invoices extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get sessionId => integer().nullable().references(Sessions, #id)();
  IntColumn get customerId =>
      integer().nullable().references(Customers, #id)();

  /// The employee who handled this sale — feeds "daily revenue by
  /// employee" on the Dashboard. Nullable so historical invoices from
  /// before this column existed still display fine (shown as "غير محدد").
  IntColumn get employeeId =>
      integer().nullable().references(Employees, #id)();

  RealColumn get subtotal => real().withDefault(const Constant(0))();
  RealColumn get discount => real().withDefault(const Constant(0))();
  RealColumn get total => real().withDefault(const Constant(0))();
  // cash | card | mixed — derived at write time from paidCash/paidCard.
  TextColumn get paymentMethod =>
      text().withDefault(const Constant('cash'))();

  /// Split of what was actually handed over in each tender. Both > 0
  /// means a mixed payment; the shift-close drawer math reads paidCash,
  /// and receipts show the split.
  RealColumn get paidCash => real().withDefault(const Constant(0))();
  RealColumn get paidCard => real().withDefault(const Constant(0))();

  /// المبلغ اللي اتضاف على حساب العميل (الأجل) بدل ما يتقبض كاش/كارت.
  /// paymentMethod becomes 'credit' when the whole total is on account,
  /// or 'mixed' when a part was handed over now and the rest deferred.
  RealColumn get paidOnAccount => real().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}
