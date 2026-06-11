import 'package:drift/drift.dart';

// Local-first table for lots. Designed to match the Lot domain entity exactly.
//
// Separate from the legacy `lots` table (PostgREST sync target from Sprint 1)
// which has an incompatible schema (lot_code required, variety_name/process_type
// absent). The `lots` table is reserved for Item #14 sync. See D-12.
//
// v18: added latitude, longitude, farm_area_ha (nullable).
// v19: added blend_variety_ids (nullable TEXT, comma-separated variety IDs).
// v20: added plant_age_years (nullable INTEGER), plant_type (nullable TEXT).
// Columns removed from entity (processType, ambientTempC, ambientHumidityPct,
// rainProbabilityPct, status) are orphaned in the DB — Drift ignores extra columns.
@DataClassName('DbLocalLot')
class LocalLots extends Table {
  TextColumn     get id               => text()();
  TextColumn     get userId           => text().named('user_id')();
  TextColumn     get varietyId        => text().named('variety_id')();
  TextColumn     get varietyName      => text().named('variety_name')();
  IntColumn      get altitudeMasl     => integer().named('altitude_masl')();
  TextColumn     get region           => text().withDefault(const Constant(''))();
  // Orphaned NOT NULL column from v1 schema — kept with default to satisfy constraint.
  TextColumn     get processType      => text().named('process_type').withDefault(const Constant(''))();
  // TODO(producto): G-1/D-12 — decidir destino (farm_plots vs lots). Bloqueado en UI. No sincronizar hasta resolución.
  RealColumn     get latitude         => real().nullable()();
  // TODO(producto): G-1/D-12 — decidir destino (farm_plots vs lots). Bloqueado en UI. No sincronizar hasta resolución.
  RealColumn     get longitude        => real().nullable()();
  // TODO(producto): G-1/D-12 — decidir destino (farm_plots vs lots). Bloqueado en UI. No sincronizar hasta resolución.
  RealColumn     get farmAreaHa       => real().named('farm_area_ha').nullable()();
  DateTimeColumn get createdAt        => dateTime().named('created_at')();
  TextColumn     get notes            => text().nullable()();
  DateTimeColumn get deletedAt        => dateTime().named('deleted_at').nullable()();
  // TODO(producto): G-1/D-12 — decidir destino (farm_plots vs lots). Bloqueado en UI. No sincronizar hasta resolución.
  TextColumn     get blendVarietyIds  => text().named('blend_variety_ids').nullable().customConstraint('NULLABLE')();
  // TODO(producto): G-1/D-12 — decidir destino (farm_plots vs lots). Bloqueado en UI. No sincronizar hasta resolución.
  IntColumn      get plantAgeYears    => integer().named('plant_age_years').nullable().customConstraint('NULLABLE')();
  // TODO(producto): G-1/D-12 — decidir destino (farm_plots vs lots). Bloqueado en UI. No sincronizar hasta resolución.
  TextColumn     get plantType        => text().named('plant_type').nullable().customConstraint('NULLABLE')();
  DateTimeColumn get syncedAt         => dateTime().named('synced_at').nullable()();

  @override
  String? get tableName => 'local_lots';

  @override
  Set<Column> get primaryKey => {id};
}
