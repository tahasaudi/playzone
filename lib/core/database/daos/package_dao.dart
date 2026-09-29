import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/packages_table.dart';
import '../tables/device_types_table.dart';

part 'package_dao.g.dart';

/// A package joined with its device type — the package picker needs the
/// type name, and the management screen needs it for grouping.
class PackageWithType {
  PackageWithType({required this.package, required this.type});
  final PackageRow package;
  final DeviceTypeRow type;
}

@DriftAccessor(tables: [Packages, DeviceTypes])
class PackageDao extends DatabaseAccessor<AppDatabase>
    with _$PackageDaoMixin {
  PackageDao(super.db);

  Stream<List<PackageWithType>> _watch({required bool activeOnly}) {
    final query = select(packages).join([
      innerJoin(deviceTypes, deviceTypes.id.equalsExp(packages.deviceTypeId)),
    ])
      ..orderBy([OrderingTerm.asc(packages.name)]);
    if (activeOnly) query.where(packages.active.equals(true));
    return query.watch().map((rows) => rows
        .map((row) => PackageWithType(
              package: row.readTable(packages),
              type: row.readTable(deviceTypes),
            ))
        .toList());
  }

  Stream<List<PackageWithType>> watchAllWithType() =>
      _watch(activeOnly: false);

  /// Only sellable packages — what the "بدء بباقة" picker on the
  /// Dashboard shows.
  Stream<List<PackageWithType>> watchActiveWithType() =>
      _watch(activeOnly: true);

  Future<PackageRow?> getById(int id) =>
      (select(packages)..where((p) => p.id.equals(id))).getSingleOrNull();

  Future<int> addPackage(PackagesCompanion entry) =>
      into(packages).insert(entry);

  Future<bool> updatePackage(PackagesCompanion entry) =>
      update(packages).replace(entry);

  Future<void> deletePackage(int id) =>
      (delete(packages)..where((p) => p.id.equals(id))).go();

  Future<void> renamePackage(int id, String name) =>
      (update(packages)..where((p) => p.id.equals(id)))
          .write(PackagesCompanion(name: Value(name)));
}