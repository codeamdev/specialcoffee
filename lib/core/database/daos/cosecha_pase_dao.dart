import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/tables/cosecha_pases_table.dart';

part 'cosecha_pase_dao.g.dart';

@DriftAccessor(tables: [CosechaPases])
class CosechaPaseDao extends DatabaseAccessor<AppDatabase>
    with _$CosechaPaseDaoMixin {
  CosechaPaseDao(super.db);

  Future<List<DbCosechaPase>> getPasesByLot(String lotId) =>
      (select(cosechaPases)
            ..where((t) => t.lotId.equals(lotId) & t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<DbCosechaPase?> getById(String id) =>
      (select(cosechaPases)..where((t) => t.id.equals(id))).getSingleOrNull();

  Future<List<DbCosechaPase>> getActivePasesByUser(String createdBy) =>
      (select(cosechaPases)
            ..where(
              (t) =>
                  t.createdBy.equals(createdBy) &
                  t.status.equals('activo') &
                  t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<void> upsert(CosechaPasesCompanion row) =>
      into(cosechaPases).insertOnConflictUpdate(row);

  Future<void> updateStage(String id, String etapa) =>
      (update(cosechaPases)..where((t) => t.id.equals(id))).write(
        CosechaPasesCompanion(
          etapaActual: Value(etapa),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateStatus(String id, String status) =>
      (update(cosechaPases)..where((t) => t.id.equals(id))).write(
        CosechaPasesCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateClasificacion(
    String id, {
    required double pesoFlotacionKg,
    double? pctFlotacion,
  }) =>
      (update(cosechaPases)..where((t) => t.id.equals(id))).write(
        CosechaPasesCompanion(
          pesoFlotacionKg: Value(pesoFlotacionKg),
          pctFlotacion: Value(pctFlotacion),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<void> updateDespulpado(
    String id, {
    required double pesoPergaminoHumedoKg,
    double? horasHastaDespulpe,
  }) =>
      (update(cosechaPases)..where((t) => t.id.equals(id))).write(
        CosechaPasesCompanion(
          pesoPergaminoHumedoKg: Value(pesoPergaminoHumedoKg),
          horasHastaDespulpe: Value(horasHastaDespulpe),
          updatedAt: Value(DateTime.now()),
        ),
      );

  Future<List<DbCosechaPase>> getCompletedPasesByUser(
          String createdBy, {int limit = 20}) =>
      (select(cosechaPases)
            ..where(
              (t) =>
                  t.createdBy.equals(createdBy) &
                  t.status.equals('completado') &
                  t.deletedAt.isNull(),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)])
            ..limit(limit))
          .get();

  Future<void> softDelete(String id) =>
      (update(cosechaPases)..where((t) => t.id.equals(id))).write(
        CosechaPasesCompanion(deletedAt: Value(DateTime.now())),
      );

  Future<List<DbCosechaPase>> getUnsyncedPases() =>
      (select(cosechaPases)
            ..where((t) => t.syncedAt.isNull() & t.deletedAt.isNull()))
          .get();

  Future<void> markPaseSynced(String id) =>
      (update(cosechaPases)..where((t) => t.id.equals(id)))
          .write(CosechaPasesCompanion(syncedAt: Value(DateTime.now().toUtc())));
}
