import 'package:drift/drift.dart';

// Local-first table for lots. Designed to match the Lot domain entity exactly.
//
// Separate from the legacy `lots` table (PostgREST sync target from Sprint 1)
// which has an incompatible schema (lot_code required, variety_name/process_type
// absent). The `lots` table is reserved for Item #14 sync. See D-12.
@DataClassName('DbLocalLot')
class LocalLots extends Table {
  TextColumn     get id                 => text()();
  TextColumn     get userId             => text().named('user_id')();
  TextColumn     get varietyId          => text().named('variety_id')();
  TextColumn     get varietyName        => text().named('variety_name')();
  IntColumn      get altitudeMasl       => integer().named('altitude_masl')();
  TextColumn     get region             => text().withDefault(const Constant(''))();
  TextColumn     get processType        => text().named('process_type')();
  RealColumn     get ambientTempC       => real().named('ambient_temp_c').nullable()();
  RealColumn     get ambientHumidityPct => real().named('ambient_humidity_pct').nullable()();
  RealColumn     get rainProbabilityPct => real().named('rain_probability_pct').withDefault(const Constant(0.0))();
  DateTimeColumn get createdAt          => dateTime().named('created_at')();
  TextColumn     get status             => text().withDefault(const Constant('pending'))();
  TextColumn     get notes              => text().nullable()();
  DateTimeColumn get deletedAt          => dateTime().named('deleted_at').nullable()();

  @override
  String? get tableName => 'local_lots';

  @override
  Set<Column> get primaryKey => {id};
}
