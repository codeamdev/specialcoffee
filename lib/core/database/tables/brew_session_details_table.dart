import 'package:drift/drift.dart';

@DataClassName('DbBrewSessionDetail')
class BrewSessionDetails extends Table {
  TextColumn get id                => text()();
  TextColumn get brewingSessionId  => text().named('brewing_session_id')();
  TextColumn get coffeeReferenceId => text().named('coffee_reference_id').nullable()();
  TextColumn get waterProfileId    => text().named('water_profile_id').nullable()();

  RealColumn get actualRatioUsed     => real().named('actual_ratio_used').nullable()();
  RealColumn get extractionYieldPct  => real().named('extraction_yield_pct').nullable()();
  RealColumn get measuredTdsPct      => real().named('measured_tds_pct').nullable()();

  TextColumn get notes => text().nullable()();

  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  String? get tableName => 'brew_session_details';

  @override
  Set<Column> get primaryKey => {id};
}
