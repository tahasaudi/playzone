import 'package:drift/drift.dart';

/// Café product category (مشروبات، قهوة، سناكس، أكل...). Admin-managed.
@DataClassName('CategoryRow')
class Categories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name},
      ];
}
