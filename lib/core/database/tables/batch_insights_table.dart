import 'package:drift/drift.dart';

@DataClassName('DbLotInsight')
class BatchInsights extends Table {
  TextColumn get id       => text()();
  TextColumn get lotId    => text().named('lot_id')();
  TextColumn get ownerId  => text().named('owner_id')();
  RealColumn get scaScore => real().named('sca_score')();
  RealColumn get fermentationH => real().named('fermentation_h').nullable()();
  RealColumn get phFinal       => real().named('ph_final').nullable()();
  TextColumn get insightText   => text().named('insight_text')();
  DateTimeColumn get createdAt => dateTime().named('created_at')();

  @override
  String? get tableName => 'batch_insights';

  @override
  Set<Column> get primaryKey => {id};
}
