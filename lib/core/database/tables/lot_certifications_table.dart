import 'package:drift/drift.dart';

@DataClassName('DbLotCertification')
class LotCertifications extends Table {
  TextColumn get id             => text()();
  TextColumn get lotId          => text().named('lot_id')();
  // 'organico'|'fairtrade'|'rainforest'|'cup_of_excellence'|'otros'
  TextColumn get type           => text()();
  TextColumn get issuingBody    => text().named('issuing_body').nullable()();
  DateTimeColumn get validFrom  => dateTime().named('valid_from').nullable()();
  DateTimeColumn get validUntil => dateTime().named('valid_until').nullable()();
  TextColumn get certificateUrl => text().named('certificate_url').nullable()();

  @override
  String? get tableName => 'lot_certifications';

  @override
  Set<Column> get primaryKey => {id};
}
