import 'package:drift/drift.dart';

@DataClassName('DbCoffeeReference')
class CoffeeReferences extends Table {
  TextColumn get id      => text()();
  TextColumn get ownerId => text().named('owner_id')();

  TextColumn get name       => text()();
  TextColumn get origin     => text().nullable()();
  TextColumn get roastLevel => text().named('roast_level')();

  DateTimeColumn get roastDate    => dateTime().named('roast_date').nullable()();
  DateTimeColumn get packagedDate => dateTime().named('packaged_date').nullable()();

  TextColumn get grindNotes => text().named('grind_notes').nullable()();
  TextColumn get tasteNotes => text().named('taste_notes').nullable()();

  // 'active' | 'inactive' | 'depleted' | 'expired'
  TextColumn get status => text().withDefault(const Constant('active'))();

  DateTimeColumn get createdAt => dateTime().named('created_at')();
  DateTimeColumn get updatedAt => dateTime().named('updated_at')();

  @override
  String? get tableName => 'coffee_references';

  @override
  Set<Column> get primaryKey => {id};
}
