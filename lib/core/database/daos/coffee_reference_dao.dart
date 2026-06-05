import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/coffee_references_table.dart';

part 'coffee_reference_dao.g.dart';

@DriftAccessor(tables: [CoffeeReferences])
class CoffeeReferenceDao extends DatabaseAccessor<AppDatabase>
    with _$CoffeeReferenceDaoMixin {
  CoffeeReferenceDao(super.db);

  Future<List<DbCoffeeReference>> getByOwner(String ownerId) =>
      (select(coffeeReferences)
            ..where((t) => t.ownerId.equals(ownerId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Stream<List<DbCoffeeReference>> watchByOwner(String ownerId) =>
      (select(coffeeReferences)
            ..where((t) => t.ownerId.equals(ownerId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Future<DbCoffeeReference?> getById(String id) =>
      (select(coffeeReferences)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<void> upsert(CoffeeReferencesCompanion entry) =>
      into(coffeeReferences).insertOnConflictUpdate(entry);

  Future<void> updateStatus(String id, String status) =>
      (update(coffeeReferences)..where((t) => t.id.equals(id))).write(
        CoffeeReferencesCompanion(
          status:    Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
