import 'package:drift/drift.dart';

/// Café product category (مشروبات، قهوة، سناكس، أكل...). Admin-managed.
///
/// Soft-delete only (via `active`), like products and devices: hiding a
/// category keeps the row so the products that still point at it (and the
/// invoices pointing back at those products) stay intact. See
/// [ProductRepository.deleteCategory].
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  BoolColumn get active => boolean().withDefault(const Constant(true))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name},
      ];
}
