import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/devices_table.dart';
import '../tables/device_types_table.dart';

part 'device_dao.g.dart';

@DriftAccessor(tables: [Devices, DeviceTypes])
class DeviceDao extends DatabaseAccessor<AppDatabase> with _$DeviceDaoMixin {
  DeviceDao(super.db);

  /// Devices joined with their type — this is what the UI actually needs
  /// (name, type label, effective rate), so we avoid a second query per
  /// device from inside a widget build.
  ///
  /// Always ordered by the device NUMBER (1, 2, 3 …) and not by the raw
  /// text: SQLite would sort "10" before "2", and the roster must read
  /// 1→2→3→4→5→6 on every screen. Sorting here (not in a widget) keeps the
  /// Dashboard, the devices list and the reports in the same order.
  Stream<List<DeviceWithType>> watchAllWithType() {
    final query = select(devices).join([
      innerJoin(deviceTypes, deviceTypes.id.equalsExp(devices.deviceTypeId)),
    ])
      ..where(devices.active.equals(true));

    return query.watch().map((rows) => rows
        .map((row) => DeviceWithType(
              device: row.readTable(devices),
              type: row.readTable(deviceTypes),
            ))
        .toList()
      ..sort((a, b) => compareDeviceNumbers(a.device.name, b.device.name)));
  }

  Future<int> insertDevice(DevicesCompanion entry) =>
      into(devices).insert(entry);

  Future<void> updateStatus(int id, String status) =>
      (update(devices)..where((d) => d.id.equals(id))).write(
        DevicesCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> setCustomRate(int id, double? rate) =>
      (update(devices)..where((d) => d.id.equals(id))).write(
        DevicesCompanion(
          customHourlyRate: Value(rate),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> setCustomRateMulti(int id, double? rate) =>
      (update(devices)..where((d) => d.id.equals(id))).write(
        DevicesCompanion(
          customHourlyRateMulti: Value(rate),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> renameDevice(int id, String name) =>
      (update(devices)..where((d) => d.id.equals(id))).write(
        DevicesCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
      );

  /// Re-classifies a device (PS4 ↔ PS5 …). Refused while a session is
  /// live so pricing history can never be re-typed mid-play.
  Future<bool> setDeviceType(int id, int typeId) async {
    final busy = await (select(devices)
          ..where((d) =>
              d.id.equals(id) &
              (d.status.equals('active') | d.status.equals('paused'))))
        .getSingleOrNull();
    if (busy != null) return false;
    await (update(devices)..where((d) => d.id.equals(id))).write(
      DevicesCompanion(
          deviceTypeId: Value(typeId), updatedAt: Value(DateTime.now())),
    );
    return true;
  }

  Future<void> renameType(int id, String name) =>
      (update(deviceTypes)..where((t) => t.id.equals(id)))
          .write(DeviceTypesCompanion(name: Value(name)));

  /// Soft-delete: history (sessions/invoices) keeps the FK intact, but
  /// the device stops appearing in the live roster.
  Future<void> deactivateDevice(int id) =>
      (update(devices)..where((d) => d.id.equals(id))).write(
        DevicesCompanion(
            active: const Value(false), updatedAt: Value(DateTime.now())),
      );

  Future<List<DeviceTypeRow>> allTypes() => select(deviceTypes).get();

  Future<int> insertType(DeviceTypesCompanion entry) =>
      into(deviceTypes).insert(entry);

  Future<void> setTypeDefaultRate(int typeId, double rate) =>
      (update(deviceTypes)..where((t) => t.id.equals(typeId)))
          .write(DeviceTypesCompanion(defaultHourlyRate: Value(rate)));

  Future<void> setTypeDefaultRateMulti(int typeId, double rate) =>
      (update(deviceTypes)..where((t) => t.id.equals(typeId)))
          .write(DeviceTypesCompanion(defaultHourlyRateMulti: Value(rate)));
}

/// A device joined with its type — avoids N+1 queries in the UI.
class DeviceWithType {
  DeviceWithType({required this.device, required this.type});
  final DeviceRow device;
  final DeviceTypeRow type;

  /// Effective hourly rate: device override wins, else the type default
  /// (spec §7 — pricing Level 1 vs Level 2).
  double get effectiveHourlyRate =>
      device.customHourlyRate ?? type.defaultHourlyRate;

  /// The "مالتي" rate, falling back to the single one when it was never
  /// priced (same rule the session billing uses).
  double get effectiveHourlyRateMulti {
    final multi = device.customHourlyRateMulti ?? type.defaultHourlyRateMulti;
    return multi > 0 ? multi : effectiveHourlyRate;
  }

  /// What [minutes] of play costs on this machine, billed per minute
  /// (spec §8: hourly / 60 × minutes, never rounded up to a full hour).
  double costForMinutes(double minutes) =>
      (effectiveHourlyRate / 60) * (minutes < 0 ? 0 : minutes);
}

/// The digits inside a device name ("#03" → 3), or null when it has none.
int? deviceNumberOf(String name) {
  final digits = RegExp(r'\d+').firstMatch(name);
  return digits == null ? null : int.tryParse(digits.group(0)!);
}

/// Ascending by the device number, so the roster always reads 1→2→3…
/// Names without a number keep a stable alphabetical order after the
/// numbered ones.
int compareDeviceNumbers(String a, String b) {
  final na = deviceNumberOf(a);
  final nb = deviceNumberOf(b);
  if (na != null && nb != null) return na.compareTo(nb);
  if (na != null) return -1;
  if (nb != null) return 1;
  return a.compareTo(b);
}

/// The café's own walk order: 1→2→4→5→6→3.
///
/// Not 1→2→3, because machine 3 is the odd one out in the room and the
/// cashier reads the wall by where each machine physically stands. Lives here,
/// next to the number helpers, rather than in the dashboard: the screens page
/// has to answer to the same order, and a second copy of this list is a second
/// order — the day they drift, the two pages describe one café differently and
/// the person who has to notice is the one holding the remote.
const cafeRosterOrder = <int>[1, 2, 4, 5, 6, 3];

/// Where a machine named [name] sits in that walk order. Machines with no
/// number, and numbered machines the café never listed, go to the back but
/// keep a stable place among themselves.
int cafeRosterRankOf(String name) {
  final n = deviceNumberOf(name);
  if (n == null) return 500;
  final i = cafeRosterOrder.indexOf(n);
  return i == -1 ? 400 : i;
}

/// Two device names compared in the café's walk order.
int compareCafeRoster(String a, String b) {
  final rank = cafeRosterRankOf(a).compareTo(cafeRosterRankOf(b));
  return rank != 0 ? rank : compareDeviceNumbers(a, b);
}
