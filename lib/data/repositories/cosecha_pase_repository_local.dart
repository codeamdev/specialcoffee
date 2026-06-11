import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/daos/cosecha_pase_dao.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/domain/entities/cosecha_pase.dart';
import 'package:special_coffee/domain/repositories/cosecha_pase_repository.dart';
import 'package:uuid/uuid.dart';

class CosechaPaseLocalRepository implements CosechaPaseRepository {
  CosechaPaseLocalRepository(this._dao);

  final CosechaPaseDao _dao;

  @override
  Future<CosechaPase> create({
    required String lotId,
    required String createdBy,
    required DateTime fechaRecoleccion,
    required double pesoCerezaKg,
    required String tipoProceso,
    DateTime? horaInicio,
    DateTime? horaFin,
    int? numOperarios,
    double? brixPromedio,
    double? pctMadurezVisual,
    String? notas,
  }) async {
    final now = DateTime.now();
    final id  = const Uuid().v4();
    await _dao.upsert(
      CosechaPasesCompanion.insert(
        id:               id,
        lotId:            lotId,
        createdBy:        createdBy,
        fechaRecoleccion: fechaRecoleccion,
        pesoCerezaKg:     pesoCerezaKg,
        tipoProceso:      tipoProceso,
        createdAt:        now,
        updatedAt:        now,
        horaInicio:       Value(horaInicio),
        horaFin:          Value(horaFin),
        numOperarios:     Value(numOperarios),
        brixPromedio:     Value(brixPromedio),
        pctMadurezVisual: Value(pctMadurezVisual),
        notas:            Value(notas),
      ),
    );
    return _map((await _dao.getById(id))!);
  }

  @override
  Future<List<CosechaPase>> getPasesByLot(String lotId) async =>
      (await _dao.getPasesByLot(lotId)).map(_map).toList();

  @override
  Future<CosechaPase?> getById(String id) async {
    final row = await _dao.getById(id);
    return row == null ? null : _map(row);
  }

  @override
  Future<List<CosechaPase>> getActivePases(String userId) async =>
      (await _dao.getActivePasesByUser(userId)).map(_map).toList();

  @override
  Future<List<CosechaPase>> getCompletedPases(String userId) async =>
      (await _dao.getCompletedPasesByUser(userId)).map(_map).toList();

  @override
  Future<void> updateClasificacion(
    String paseId, {
    required double pesoFlotacionKg,
    double? pctFlotacion,
  }) =>
      _dao.updateClasificacion(
        paseId,
        pesoFlotacionKg: pesoFlotacionKg,
        pctFlotacion: pctFlotacion,
      );

  @override
  Future<void> updateDespulpado(
    String paseId, {
    required double pesoPergaminoHumedoKg,
    double? horasHastaDespulpe,
  }) =>
      _dao.updateDespulpado(
        paseId,
        pesoPergaminoHumedoKg: pesoPergaminoHumedoKg,
        horasHastaDespulpe: horasHastaDespulpe,
      );

  @override
  Future<void> advanceEtapa(String paseId, String nuevaEtapa) =>
      _dao.updateStage(paseId, nuevaEtapa);

  @override
  Future<void> completar(String paseId) => _dao.updateStatus(paseId, 'completado');

  @override
  Future<void> abandonar(String paseId) => _dao.updateStatus(paseId, 'abandonado');

  CosechaPase _map(DbCosechaPase r) => CosechaPase(
        id:                   r.id,
        lotId:                r.lotId,
        createdBy:            r.createdBy,
        fechaRecoleccion:     r.fechaRecoleccion,
        horaInicio:           r.horaInicio,
        horaFin:              r.horaFin,
        pesoCerezaKg:         r.pesoCerezaKg,
        numOperarios:         r.numOperarios,
        brixPromedio:         r.brixPromedio,
        pctMadurezVisual:     r.pctMadurezVisual,
        tipoProceso:          r.tipoProceso,
        pesoFlotacionKg:      r.pesoFlotacionKg,
        pctFlotacion:         r.pctFlotacion,
        pesoPergaminoHumedoKg: r.pesoPergaminoHumedoKg,
        horasHastaDespulpe:   r.horasHastaDespulpe,
        etapaActual:          r.etapaActual,
        status:               r.status,
        notas:                r.notas,
        createdAt:            r.createdAt,
        updatedAt:            r.updatedAt,
        deletedAt:            r.deletedAt,
      );
}
