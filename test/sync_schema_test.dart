import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:matcher/matcher.dart' as m;
import 'package:playzone/core/database/app_database.dart';
import 'package:playzone/core/database/tables/devices_table.dart';
import 'package:playzone/core/database/tables/products_table.dart';
import 'package:playzone/core/sync/sync_config.dart';
import 'package:playzone/core/sync/sync_schema.dart';

bool _deviceLocal(String table, Map<String, Object?> row) =>
    table == 'app_settings' && SyncKeys.localOnly.contains('${row['key']}');

/// The sync engine, driven the way the real client and server drive it:
/// a "till" and a "phone", each on its own in-memory database that starts
/// from the same seed.
void main() {
  late AppDatabase till;
  late AppDatabase phone;

  setUp(() async {
    till = AppDatabase.forTesting(NativeDatabase.memory());
    phone = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await till.close();
    await phone.close();
  });

  Future<void> bootstrapPhone() async {
    final snap = await snapshot(till);
    await withoutForeignKeys(
        phone, () => applySnapshot(phone, snap, skip: _deviceLocal));
    await setIdBand(phone, syncBandStart);
  }

  /// Exactly what [SyncClient] pulls: the till's whole feed, replayed
  /// behind the guard so nothing echoes back.
  Future<void> pullToPhone() async {
    final feed = await syncFeed(till);
    if (feed.isEmpty) return;
    await withoutForeignKeys(phone, () async {
      await applyingRemote(phone, () async {
        for (final raw in feed) {
          final pk = await primaryKeyFor(phone, raw.table);
          if (pk == null) continue;
          final data = raw.op == 'D'
              ? null
              : await readRow(till, raw.table, pk, raw.rowPk);
          await applyRemoteRow(
            phone,
            table: raw.table,
            op: raw.op,
            pkColumn: pk,
            pkValue: raw.rowPk,
            data: data,
          );
        }
      });
    });
  }

  /// Exactly what [SyncClient] pushes: the phone's un-sent queue replayed
  /// WITHOUT the guard (so the till re-broadcasts), then the till's ids are
  /// clamped back under the phone's band.
  Future<void> pushFromPhone() async {
    final queue = await pendingChanges(phone);
    if (queue.isEmpty) return;
    await withoutForeignKeys(till, () async {
      for (final raw in queue) {
        final pk = await primaryKeyFor(till, raw.table);
        if (pk == null) continue;
        final data = raw.op == 'D'
            ? null
            : await readRow(phone, raw.table, pk, raw.rowPk);
        await applyRemoteRow(
          till,
          table: raw.table,
          op: raw.op,
          pkColumn: pk,
          pkValue: raw.rowPk,
          data: data,
        );
      }
      await setIdBand(till, 0, ceiling: syncBandCap);
    });
    // The real client hands the server its whole pending batch and only
    // marks it pushed once the server acks. Same here.
    await phone.customStatement('UPDATE sync_log SET pushed = 1 WHERE pushed = 0');
  }

  test('bootstrap brings the till data and starts the phone band', () async {
    await bootstrapPhone();

    expect((await till.select(till.devices).get()).length, 6);
    expect((await phone.select(phone.devices).get()).length, 6);

    final phoneId = await phone.into(phone.devices).insert(
        DevicesCompanion.insert(name: 'من التليفون', deviceTypeId: 1));
    expect(phoneId, greaterThanOrEqualTo(syncBandStart),
        reason: 'phoned-created rows must live in the phone band');
  });

  test('an edit on the phone reaches the till and is not echoed back',
      () async {
    await bootstrapPhone();
    final product = (await (phone.select(phone.products)..limit(1)).get()).single;
    await (phone.update(phone.products)..where((t) => t.id.equals(product.id)))
        .write(ProductsCompanion(sellingPrice: const Value(999)));

    expect(await pendingChanges(phone), isNotEmpty);
    await pushFromPhone();

    final onTill =
        await (till.select(till.products)..where((t) => t.id.equals(product.id)))
            .getSingle();
    expect(onTill.sellingPrice, 999);

    // The till re-logged it, the phone pulls it behind the guard, and the
    // phone's queue stays empty — otherwise every cycle would re-send it.
    await pullToPhone();
    expect(await pendingChanges(phone), isEmpty,
        reason: 'a pulled row must never be queued for re-pushing');
    final back = await (phone.select(phone.products)
          ..where((t) => t.id.equals(product.id)))
        .getSingle();
    expect(back.sellingPrice, 999);
  });

  test('a delete on the till removes the row on the phone', () async {
    await bootstrapPhone();
    final product = (await (till.select(till.products)..limit(1)).get()).single;
    await (till.delete(till.products)..where((t) => t.id.equals(product.id)))
        .go();

    await pullToPhone();
    final gone = await (phone.select(phone.products)
          ..where((t) => t.id.equals(product.id)))
        .getSingleOrNull();
    expect(gone, m.isNull);
  });

  test('pushed phone rows cannot be re-issued by either allocator', () async {
    await bootstrapPhone();
    final phoneId = await phone.into(phone.devices)
        .insert(DevicesCompanion.insert(name: 'تليفون ١', deviceTypeId: 1));
    await pushFromPhone();

    // The till stored the phone's row and continues upward from what it has.
    final tillHasPhone = await (till.select(till.devices)
          ..where((t) => t.id.equals(phoneId)))
        .get();
    expect(tillHasPhone, isNotEmpty);
    final tillId = await till.into(till.devices)
        .insert(DevicesCompanion.insert(name: 'كمبيوتر ١', deviceTypeId: 1));
    expect(tillId, isNot(equals(phoneId)));
    // The till's allocator marches past the pushed id — SQLite will not
    // hand the same number out twice once it has ever used it.

    // Pull the till's row back: the phone adopts the till's newest id, so
    // its own next allocation lands strictly above rather than re-issuing it.
    await pullToPhone();
    final nextPhoneId = await phone.into(phone.devices)
        .insert(DevicesCompanion.insert(name: 'تليفون ٢', deviceTypeId: 1));
    expect(nextPhoneId, greaterThan(tillId));
    expect(nextPhoneId, greaterThan(phoneId));
  });

  test('device-local settings stay on the machine that wrote them',
      () async {
    await till.settingsDao.setValue(SyncKeys.wallNetwork, '1');
    await bootstrapPhone();
    expect(await phone.settingsDao.getValue(SyncKeys.wallNetwork), m.isNull,
        reason: 'wall switch is per-machine and must not travel');
  });
}

class _Change {
  const _Change(this.table, this.rowPk, this.op);
  final String table;
  final String rowPk;
  final String op;
}

Future<List<_Change>> pendingChanges(AppDatabase db) async {
  final rows = await db.customSelect(
      'SELECT tbl, row_pk, op FROM sync_log WHERE pushed = 0 ORDER BY seq').get();
  return [
    for (final r in rows)
      _Change('${r.data['tbl']}', '${r.data['row_pk']}', '${r.data['op']}'),
  ];
}

Future<List<_Change>> syncFeed(AppDatabase db) async {
  final rows = await db.customSelect(
      'SELECT tbl, row_pk, op FROM sync_log ORDER BY seq').get();
  return [
    for (final r in rows)
      _Change('${r.data['tbl']}', '${r.data['row_pk']}', '${r.data['op']}'),
  ];
}