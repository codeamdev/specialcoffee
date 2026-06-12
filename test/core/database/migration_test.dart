import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3lib;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late sqlite3lib.Database rawDb;
  late AppDatabase db;

  setUp(() {
    rawDb = sqlite3lib.sqlite3.openInMemory();
    _buildV13Schema(rawDb);
    db = AppDatabase.forTesting(NativeDatabase.opened(rawDb));
  });

  tearDown(() => db.close());

  test('v14 — creates physical_analyses, roast_profiles, cupping_evaluations', () async {
    final tables = await _tableNames(db);
    expect(tables, containsAll(['physical_analyses', 'roast_profiles', 'cupping_evaluations']));
  });

  test('v15 — creates green_inventory, roasted_inventory, commercial_products, lot_certifications', () async {
    final tables = await _tableNames(db);
    expect(
      tables,
      containsAll(['green_inventory', 'roasted_inventory', 'commercial_products', 'lot_certifications']),
    );
  });

  test('v16 — deleted_at present on all G/H tables', () async {
    for (final table in [
      'physical_analyses',
      'roast_profiles',
      'cupping_evaluations',
      'green_inventory',
      'roasted_inventory',
      'commercial_products',
      'lot_certifications',
    ]) {
      final cols = await _columnNames(db, table);
      expect(cols, contains('deleted_at'), reason: '$table should have deleted_at after v16');
    }
  });

  test('v17 — creates cosecha_pases', () async {
    final tables = await _tableNames(db);
    expect(tables, contains('cosecha_pases'));
  });

  test('v18 — adds latitude, longitude, farm_area_ha to local_lots', () async {
    final cols = await _columnNames(db, 'local_lots');
    expect(cols, containsAll(['latitude', 'longitude', 'farm_area_ha']));
  });

  test('v19 — adds blend_variety_ids to local_lots', () async {
    final cols = await _columnNames(db, 'local_lots');
    expect(cols, contains('blend_variety_ids'));
  });

  test('v20 — adds plant_age_years and plant_type to local_lots', () async {
    final cols = await _columnNames(db, 'local_lots');
    expect(cols, containsAll(['plant_age_years', 'plant_type']));
  });

  test('v21 — adds synced_at to local_lots', () async {
    final cols = await _columnNames(db, 'local_lots');
    expect(cols, contains('synced_at'));
  });

  test('v21 — synced_at present on cosecha_pases (idempotent: created in v17 or added in v21)', () async {
    final cols = await _columnNames(db, 'cosecha_pases');
    expect(cols, contains('synced_at'));
  });

  test('final schema version is 22', () async {
    final row = await db.customSelect('PRAGMA user_version').getSingle();
    expect(row.read<int>('user_version'), 22);
  });

  test('local_lots retains v13 columns after migration', () async {
    final cols = await _columnNames(db, 'local_lots');
    expect(
      cols,
      containsAll(['id', 'user_id', 'variety_id', 'variety_name', 'altitude_masl', 'created_at']),
    );
  });
}

// ── Helpers ──────────────────────────────────────────────────────────────────

Future<List<String>> _tableNames(AppDatabase db) async {
  final rows = await db
      .customSelect(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name NOT LIKE 'sqlite_%'",
      )
      .get();
  return rows.map((r) => r.read<String>('name')).toList();
}

Future<List<String>> _columnNames(AppDatabase db, String table) async {
  final rows = await db.customSelect('PRAGMA table_info($table)').get();
  return rows.map((r) => r.read<String>('name')).toList();
}

/// Builds the v13 SQLite schema in [rawDb] and stamps user_version = 13.
///
/// Only `local_lots` is created here because it's the only v1-v13 table that
/// migrations v14-v21 modify with ALTER TABLE. All other v1-v13 tables
/// (fermentation_sessions, drying_sessions, etc.) are not touched by those
/// migration blocks, so they are omitted for brevity.
void _buildV13Schema(sqlite3lib.Database rawDb) {
  rawDb.execute('''
    CREATE TABLE local_lots (
      id            TEXT    NOT NULL PRIMARY KEY,
      user_id       TEXT    NOT NULL,
      variety_id    TEXT    NOT NULL,
      variety_name  TEXT    NOT NULL,
      altitude_masl INTEGER NOT NULL,
      region        TEXT    NOT NULL DEFAULT '',
      process_type  TEXT    NOT NULL DEFAULT '',
      created_at    INTEGER NOT NULL,
      notes         TEXT,
      deleted_at    INTEGER
    )
  ''');
  rawDb.execute('PRAGMA user_version = 13');
}
