import 'package:drift/drift.dart';

/// A device category (PS4, PS5, Billiards, VIP...). Admin-managed and NOT
/// hardcoded — new types can be added later without a schema change.
///
/// Two rates per type: [defaultHourlyRate] for "single" mode and
/// [defaultHourlyRateMulti] for "multi" mode. A session can flip between
/// the two mid-session (and flip back) — see SessionDao.switchMode.
@DataClassName('DeviceTypeRow')
class DeviceTypes extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  RealColumn get defaultHourlyRate => real().withDefault(const Constant(0))();
  RealColumn get defaultHourlyRateMulti =>
      real().withDefault(const Constant(0))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {name},
      ];
}
