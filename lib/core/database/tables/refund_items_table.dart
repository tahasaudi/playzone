import 'package:drift/drift.dart';
import 'refunds_table.dart';
import 'invoice_items_table.dart';

/// One line of a refund: which invoice line came back and how many units.
///
/// Recorded so the refunds screen knows what has already been returned —
/// you can hand back a single product off a bill, and it cannot be handed
/// back twice beyond what was actually sold.
@DataClassName('RefundItemRow')
class RefundItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get refundId => integer().references(Refunds, #id)();
  IntColumn get invoiceItemId => integer().references(InvoiceItems, #id)();
  IntColumn get quantity => integer()();
  RealColumn get amount => real().withDefault(const Constant(0))();
}
