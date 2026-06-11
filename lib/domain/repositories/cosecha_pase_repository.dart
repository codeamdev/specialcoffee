import 'package:special_coffee/domain/entities/cosecha_pase.dart';

abstract class CosechaPaseRepository {
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
  });

  Future<List<CosechaPase>> getPasesByLot(String lotId);
  Future<CosechaPase?> getById(String id);
  Future<List<CosechaPase>> getActivePases(String userId);
  Future<List<CosechaPase>> getCompletedPases(String userId);

  Future<void> updateClasificacion(
    String paseId, {
    required double pesoFlotacionKg,
    double? pctFlotacion,
  });

  Future<void> updateDespulpado(
    String paseId, {
    required double pesoPergaminoHumedoKg,
    double? horasHastaDespulpe,
  });

  Future<void> advanceEtapa(String paseId, String nuevaEtapa);
  Future<void> completar(String paseId);
  Future<void> abandonar(String paseId);
}
