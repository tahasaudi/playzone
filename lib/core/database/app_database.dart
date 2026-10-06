import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables/employees_table.dart';
import 'tables/device_types_table.dart';
import 'tables/devices_table.dart';
import 'tables/customers_table.dart';
import 'tables/categories_table.dart';
import 'tables/products_table.dart';
import 'tables/sessions_table.dart';
import 'tables/session_events_table.dart';
import 'tables/invoices_table.dart';
import 'tables/invoice_items_table.dart';
import 'tables/audit_logs_table.dart';
import 'tables/shifts_table.dart';
import 'tables/expenses_table.dart';
import 'tables/employee_feature_overrides_table.dart';
import 'tables/reservations_table.dart';
import 'tables/packages_table.dart';
import 'tables/offers_table.dart';
import 'tables/loyalty_settings_table.dart';
import 'tables/app_settings_table.dart';
import 'tables/accounts_table.dart';
import 'tables/account_entries_table.dart';
import 'tables/refunds_table.dart';
import 'tables/stock_counts_table.dart';
import 'tables/employee_transactions_table.dart';
import 'tables/employee_attendance_table.dart';

import 'daos/employee_dao.dart';
import 'daos/device_dao.dart';
import 'daos/customer_dao.dart';
import 'daos/product_dao.dart';
import 'daos/session_dao.dart';
import 'daos/invoice_dao.dart';
import 'daos/audit_log_dao.dart';
import 'daos/shift_dao.dart';
import 'daos/expense_dao.dart';
import 'daos/employee_feature_dao.dart';
import 'daos/reservation_dao.dart';
import 'daos/package_dao.dart';
import 'daos/offer_dao.dart';
import 'daos/loyalty_dao.dart';
import 'daos/settings_dao.dart';
import 'daos/account_dao.dart';
import 'daos/refund_dao.dart';
import 'daos/stock_count_dao.dart';
import '../permissions/pin_hasher.dart';

part 'app_database.g.dart';

/// The single Drift database for the whole app. Reservations/Packages/
/// Loyalty/etc. tables are added in later phases — this covers
/// Phase 1 (foundation) + Phase 2 (Sessions) + Phase 3 (Invoices) +
/// Phase 4 (Audit Logs) + Phase 5 (per-second/mode pricing, Shifts,
/// Expenses, per-employee feature permissions) + Phase 6 (Reservations,
/// Packages & Offers, Loyalty, mixed payment) so far (spec §38).
@DriftDatabase(
  tables: [
    Employees,
    DeviceTypes,
    Devices,
    Customers,
    Categories,
    Products,
    Sessions,
    SessionEvents,
    Invoices,
    InvoiceItems,
    AuditLogs,
    Shifts,
    Expenses,
    EmployeeFeatureOverrides,
    Reservations,
    Packages,
    Offers,
    LoyaltySettings,
    AppSettings,
    Accounts,
    AccountEntries,
    Refunds,
    StockCounts,
    StockCountItems,
    EmployeeTransactions,
    EmployeeAttendance,
  ],
  daos: [
    EmployeeDao,
    DeviceDao,
    CustomerDao,
    ProductDao,
    SessionDao,
    InvoiceDao,
    AuditLogDao,
    ShiftDao,
    ExpenseDao,
    EmployeeFeatureDao,
    ReservationDao,
    PackageDao,
    OfferDao,
    LoyaltyDao,
    SettingsDao,
    AccountDao,
    RefundDao,
    StockCountDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 10;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seed(this);
        },
        onUpgrade: (m, from, to) async {
          // v1 → v2: added the Sessions table (Phase 2).
          if (from < 2) {
            await m.createTable(sessions);
          }
          // v2 → v3: added Invoices + InvoiceItems (Phase 3).
          if (from < 3) {
            await m.createTable(invoices);
            await m.createTable(invoiceItems);
          }
          // v3 → v4: added AuditLogs (Phase 4).
          if (from < 4) {
            await m.createTable(auditLogs);
          }
          // v4 → v5: multi-mode pricing columns, employeeId on Sessions/
          // Invoices, Shifts, Expenses, EmployeeFeatureOverrides (Phase 5).
          if (from < 5) {
            await m.addColumn(deviceTypes, deviceTypes.defaultHourlyRateMulti);
            await m.addColumn(devices, devices.customHourlyRateMulti);
            await m.addColumn(sessions, sessions.employeeId);
            await m.addColumn(sessions, sessions.mode);
            await m.addColumn(sessions, sessions.accumulatedCost);
            await m.addColumn(sessions, sessions.segmentStartAt);
            await m.addColumn(invoices, invoices.employeeId);
            await m.createTable(shifts);
            await m.createTable(expenses);
            await m.createTable(employeeFeatureOverrides);
          }
          // v5 → v6: Reservations, Packages, Offers, Loyalty config + the
          // package-billing columns on Sessions and mixed-payment split
          // on Invoices (Phase 6).
          if (from < 6) {
            await m.createTable(reservations);
            await m.createTable(packages);
            await m.createTable(offers);
            await m.createTable(loyaltySettings);
            await m.addColumn(sessions, sessions.packageId);
            await m.addColumn(sessions, sessions.fixedPrice);
            await m.addColumn(invoices, invoices.paidCash);
            await m.addColumn(invoices, invoices.paidCard);
            // Default loyalty program so existing installs upgrading to
            // v6 don't start with an empty config table.
            await into(loyaltySettings).insert(
              LoyaltySettingsCompanion.insert(
                id: const Value(1),
                pointsPerCurrency: const Value(1.0),
                minimumRedeemPoints: const Value(100),
                pointValueEGP: const Value(1.0),
              ),
            );
          }
          // v6 → v7: Settings store, Accounts/AccountEntries (ledger),
          // Refunds, StockCounts/StockCountItems (periodic inventory).
          if (from < 7) {
            await m.createTable(appSettings);
            await m.createTable(accounts);
            await m.createTable(accountEntries);
            await m.createTable(refunds);
            await m.createTable(stockCounts);
            await m.createTable(stockCountItems);
            await _seedAccounts(this);
            await _seedSettings(this);
          }
          // v7 → v8: partnership + HR — partner flag/share on Employees,
          // employee withdrawals/repayments (مسحوبات/سداد), and the
          // attendance register (حضور وانصراف).
          if (from < 8) {
            await m.addColumn(employees, employees.isPartner);
            await m.addColumn(employees, employees.partnerShare);
            await m.createTable(employeeTransactions);
            await m.createTable(employeeAttendance);
          }
          // v8 → v9: fixed-duration sessions (quick 60/30/15/7 buttons),
          // per-row stock-count tracking, and the corrected device roster
          // (3 × PS4 + 3 × PS5, numbered 1..6).
          if (from < 9) {
            await m.addColumn(sessions, sessions.plannedMinutes);
            await m.addColumn(sessions, sessions.timeUpAt);
            await m.addColumn(stockCountItems, stockCountItems.counted);
            // Keep whatever the cashier already typed in an open count, but
            // stop treating "never touched" rows as a counted zero.
            await customStatement(
                'UPDATE stock_count_items SET counted = 1 WHERE counted_qty != 0');
            // Close any session still ticking on a device that is about to
            // be re-labelled, so no timer is left running against a parked
            // machine.
            final openSessions = await (this.select(this.sessions)
                  ..where((s) => s.status.isNotValue('completed')))
                .get();
            for (final s in openSessions) {
              await (this.update(this.sessions)
                    ..where((x) => x.id.equals(s.id)))
                  .write(SessionsCompanion(
                status: const Value('completed'),
                segmentStartAt: const Value(null),
                endTime: Value(DateTime.now()),
                finalCost: Value(s.accumulatedCost),
              ));
            }
            await _reconcileDevices(this);
          }
          // v10 → the session timeline. One append-only row per thing that
          // happened — paused, resumed, the wall going dark or lit, a mode
          // switch — because the session row only ever keeps the CURRENT
          // answer and the café's question is always "when".
          //
          // Also: the order line's own timestamp, so a drink keeps the moment
          // it was asked for after the drafts are folded into the bill, and the
          // per-mode cost split the detail sheet reads.
          if (from < 10) {
            await m.createTable(sessionEvents);
            await m.addColumn(invoiceItems, invoiceItems.createdAt);
            await m.addColumn(sessions, sessions.singleCost);
            await m.addColumn(sessions, sessions.multiCost);

            // A session already half-run by the old build has money locked in
            // with no record of which rate earned it. Seeding that money into
            // the single bucket keeps `single + multi == accumulatedCost` for
            // the session on the wall right now, so its three numbers still
            // add up as the rest of it accrues. Completed sessions are left at
            // zero and read as unsplit — which is the truth about them.
            final openSessions = await (this.select(this.sessions)
                  ..where((s) => s.status.isNotValue('completed')))
                .get();
            for (final s in openSessions) {
              if (s.accumulatedCost <= 0) continue;
              await (this.update(this.sessions)
                    ..where((x) => x.id.equals(s.id)))
                  .write(SessionsCompanion(
                singleCost: Value(s.accumulatedCost),
              ));
            }
          }
        },
      );
}

/// The café's real roster: 3 PlayStation 4 and 3 PlayStation 5, numbered
/// 1..6 (1-3 = PS4, 4-6 = PS5). Runs on create AND on the v9 upgrade, so
/// an existing install ends up with exactly these six devices: the old
/// rows are soft-deleted (history/invoices keep pointing at them) and six
/// correctly-classified devices take their place.
Future<void> _reconcileDevices(AppDatabase db) async {
  Future<int> typeIdFor(String name, double single, double multi) async {
    final existing = await (db.select(db.deviceTypes)
          ..where((t) => t.name.equals(name)))
        .getSingleOrNull();
    if (existing != null) return existing.id;
    return db.into(db.deviceTypes).insert(DeviceTypesCompanion.insert(
          name: name,
          defaultHourlyRate: Value(single),
          defaultHourlyRateMulti: Value(multi),
        ));
  }

  final ps4 = await typeIdFor('PS4', 20, 30);
  final ps5 = await typeIdFor('PS5', 30, 45);

  // Park the old roster out of the way (soft delete — never break history).
  await db
      .update(db.devices)
      .write(const DevicesCompanion(active: Value(false)));

  for (final entry in [
    (ps4, 1),
    (ps4, 2),
    (ps4, 3),
    (ps5, 4),
    (ps5, 5),
    (ps5, 6),
  ]) {
    final name = entry.$2.toString();
    final clash = await (db.select(db.devices)
          ..where((d) => d.name.equals(name)))
        .getSingleOrNull();
    if (clash != null) {
      await (db.update(db.devices)..where((d) => d.id.equals(clash.id))).write(
        DevicesCompanion(
          deviceTypeId: Value(entry.$1),
          active: const Value(true),
          status: const Value('available'),
          updatedAt: Value(DateTime.now()),
        ),
      );
      continue;
    }
    await db.into(db.devices).insert(DevicesCompanion.insert(
          name: name,
          deviceTypeId: entry.$1,
        ));
  }
}

/// Desktop (Windows) native SQLite connection. The DB file lives in the
/// app's support directory, NOT a hardcoded path (spec §35 principle
/// applied here too — no hardcoded Windows paths).
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'playzone.sqlite'));

    // Apply a staged restore (from the Backup screen) before opening the
    // connection — the only safe moment to swap the database file. Any
    // stale WAL/SHM sidecars from the old file are removed too.
    final pending = File(p.join(dir.path, 'playzone.restore-pending'));
    if (await pending.exists()) {
      try {
        if (await file.exists()) await file.delete();
        await pending.rename(file.path);
      } catch (_) {
        // Fallback if rename fails (e.g. cross-volume): copy then drop.
        await pending.copy(file.path);
        await pending.delete();
      }
      for (final suffix in ['-wal', '-shm']) {
        final side = File('${file.path}$suffix');
        if (await side.exists()) await side.delete();
      }
    }

    // SQLite runs in this isolate, not a background one.
    //
    // It used to run in a background isolate, and this program crashed at least
    // four times in a week with `0xc0000374` — heap corruption reported by
    // ntdll — plus an access violation inside sqlite3.dll itself. Both are
    // native memory faults, not Dart errors: nothing in this app's own code was
    // throwing, the memory under it had already been damaged. Putting SQLite on
    // its own isolate means its native state is driven across an isolate
    // boundary, and that boundary is where the damage showed up.
    //
    // The cost is nil here and the reason is worth saying out loud: this is one
    // till on one machine talking to one local file, where every query is a
    // local read of a few microseconds. Offloading that to another isolate buys
    // nothing measurable and cost stability. If the database ever grows to need
    // background work, this is the line to revisit - with the crash rate in the
    // event log to compare against, not by feel.
    //
    // `setup` runs on the connection before anything else touches it. WAL lets a
    // reader and a writer coexist, and the busy timeout stops a second program
    // - a repair tool reading the same file - from being answered with an
    // immediate failure while the till holds a write lock.
    return NativeDatabase(
      file,
      setup: (db) {
        db.execute('PRAGMA journal_mode = WAL;');
        db.execute('PRAGMA busy_timeout = 5000;');
        db.execute('PRAGMA foreign_keys = ON;');
      },
    );
  });
}

/// First-run seed data. This mirrors the mock data that was already in
/// the UI (dashboard_screen.dart, pos_screen.dart) so switching screens
/// over to the real database doesn't change what the cashier sees.
Future<void> _seed(AppDatabase db) async {
  // The real roster: 3 × PS4 + 3 × PS5 numbered 1..6, with the types and
  // their default rates (PS4 20/30, PS5 30/45) created if missing. Shared
  // with the v9 upgrade so a fresh install and an existing one are
  // identical. Billiards/VIP types are intentionally not seeded — the
  // café runs PS4/PS5 only, and new types can be added from Settings.
  await _reconcileDevices(db);

  // Default admin account for testing PIN login once it's built.
  // PIN "0000" — CHANGE THIS before any real deployment.
  await db.into(db.employees).insert(EmployeesCompanion.insert(
        name: 'أحمد',
        phone: '01000000000',
        role: 'admin',
        pinHash: pinHashFor('0000'),
      ));

  // Café categories + products, matching the old POS mock catalog.
  final categoryIds = <String, int>{};
  for (final name in ['مشروبات', 'قهوة', 'سناكس', 'أكل']) {
    categoryIds[name] = await db
        .into(db.categories)
        .insert(CategoriesCompanion.insert(name: name));
  }

  final seedProducts = [
    ('مياه', 'مشروبات', 15.0, 7.0, 24),
    ('بيبسي', 'مشروبات', 20.0, 11.0, 18),
    ('عصير', 'مشروبات', 25.0, 14.0, 10),
    ('قهوة تركي', 'قهوة', 25.0, 8.0, 30),
    ('كابتشينو', 'قهوة', 35.0, 14.0, 20),
    ('نسكافيه', 'قهوة', 30.0, 10.0, 0),
    ('شيبسي', 'سناكس', 15.0, 8.0, 40),
    ('مكسرات', 'سناكس', 30.0, 18.0, 15),
    ('ساندوتش', 'أكل', 45.0, 22.0, 12),
    ('بيتزا سلايس', 'أكل', 35.0, 16.0, 8),
  ];

  for (final (name, category, sell, cost, stock) in seedProducts) {
    await db.into(db.products).insert(ProductsCompanion.insert(
          name: name,
          categoryId: categoryIds[category]!,
          sellingPrice: Value(sell),
          costPrice: Value(cost),
          stockQuantity: Value(stock),
        ));
  }

  // Default loyalty program (Phase 6) — earn 1 point/EGP, redeem from
  // 100 points at EGP 1 per point.
  await db.into(db.loyaltySettings).insert(
        LoyaltySettingsCompanion.insert(
          id: const Value(1),
          pointsPerCurrency: const Value(1.0),
          minimumRedeemPoints: const Value(100),
          pointValueEGP: const Value(1.0),
        ),
      );

  await _seedAccounts(db);
  await _seedSettings(db);
}

/// Default ledger categories (v7). Posted to automatically by invoices,
/// expenses and refunds; names are editable from the Accounting screen.
Future<void> _seedAccounts(AppDatabase db) async {
  final existing = await db.select(db.accounts).get();
  if (existing.isNotEmpty) return;
  await db.batch((b) {
    b.insert(
        db.accounts,
        AccountsCompanion.insert(
            code: 'sales',
            name: 'مبيعات الألعاب',
            kind: 'revenue',
            system: const Value(true)));
    b.insert(
        db.accounts,
        AccountsCompanion.insert(
            code: 'cafe_sales',
            name: 'مبيعات الكافيه',
            kind: 'revenue',
            system: const Value(true)));
    b.insert(
        db.accounts,
        AccountsCompanion.insert(
            code: 'expenses',
            name: 'المصروفات',
            kind: 'expense',
            system: const Value(true)));
    b.insert(
        db.accounts,
        AccountsCompanion.insert(
            code: 'refunds',
            name: 'المرتجعات',
            kind: 'expense',
            system: const Value(true)));
  });
}

/// Default app settings (v7). The locked-button PIN defaults to 0000 and
/// should be changed from Settings → الأزرار المحمية.
Future<void> _seedSettings(AppDatabase db) async {
  await db.into(db.appSettings).insertOnConflictUpdate(
        AppSettingsCompanion.insert(
          key: SettingsDao.lockedAccessPinKey,
          value: Value(pinHashFor('0000')),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
