import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/cupping_evaluation_dao.dart';
import 'package:special_coffee/domain/entities/cupping_evaluation.dart';
import 'package:special_coffee/domain/repositories/cupping_evaluation_repository.dart';
import 'package:uuid/uuid.dart';

class CuppingEvaluationLocalRepository implements CuppingEvaluationRepository {
  CuppingEvaluationLocalRepository(this._dao, this._cupperId);

  final CuppingEvaluationDao _dao;
  final String _cupperId;
  static const _uuid = Uuid();

  @override
  Future<List<CuppingEvaluation>> getByLotId(String lotId) async {
    final rows = await _dao.getByLotId(lotId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<CuppingEvaluation?> getLatestByLotId(String lotId) async {
    final row = await _dao.getLatestByLotId(lotId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<CuppingEvaluation> save(CuppingEvaluation evaluation) async {
    final id = evaluation.id.isEmpty ? _uuid.v4() : evaluation.id;
    await _dao.upsert(CuppingEvaluationsCompanion(
      id:               Value(id),
      lotId:            Value(evaluation.lotId),
      roastProfileId:   Value(evaluation.roastProfileId),
      cupperId:         Value(_cupperId),
      cuppedAt:         Value(evaluation.cuppedAt),
      fragranceAroma:   Value(evaluation.fragranceAroma),
      flavor:           Value(evaluation.flavor),
      aftertaste:       Value(evaluation.aftertaste),
      acidity:          Value(evaluation.acidity),
      acidityIntensity: Value(evaluation.acidityIntensity),
      body:             Value(evaluation.body),
      bodyTexture:      Value(evaluation.bodyTexture),
      balance:          Value(evaluation.balance),
      uniformity:       Value(evaluation.uniformity),
      cleanCup:         Value(evaluation.cleanCup),
      sweetness:        Value(evaluation.sweetness),
      overall:          Value(evaluation.overall),
      defectsTaint:     Value(evaluation.defectsTaint),
      defectsFault:     Value(evaluation.defectsFault),
      totalScore:       Value(evaluation.totalScore),
      flavorDescriptors: Value(evaluation.flavorDescriptors),
      notes:            Value(evaluation.notes),
    ));
    return CuppingEvaluation(
      id:               id,
      lotId:            evaluation.lotId,
      cupperId:         _cupperId,
      cuppedAt:         evaluation.cuppedAt,
      roastProfileId:   evaluation.roastProfileId,
      fragranceAroma:   evaluation.fragranceAroma,
      flavor:           evaluation.flavor,
      aftertaste:       evaluation.aftertaste,
      acidity:          evaluation.acidity,
      acidityIntensity: evaluation.acidityIntensity,
      body:             evaluation.body,
      bodyTexture:      evaluation.bodyTexture,
      balance:          evaluation.balance,
      uniformity:       evaluation.uniformity,
      cleanCup:         evaluation.cleanCup,
      sweetness:        evaluation.sweetness,
      overall:          evaluation.overall,
      defectsTaint:     evaluation.defectsTaint,
      defectsFault:     evaluation.defectsFault,
      totalScore:       evaluation.totalScore,
      flavorDescriptors: evaluation.flavorDescriptors,
      notes:            evaluation.notes,
    );
  }

  CuppingEvaluation _fromRow(DbCuppingEvaluation r) => CuppingEvaluation(
        id:               r.id,
        lotId:            r.lotId,
        cupperId:         r.cupperId,
        cuppedAt:         r.cuppedAt,
        roastProfileId:   r.roastProfileId,
        fragranceAroma:   r.fragranceAroma,
        flavor:           r.flavor,
        aftertaste:       r.aftertaste,
        acidity:          r.acidity,
        acidityIntensity: r.acidityIntensity,
        body:             r.body,
        bodyTexture:      r.bodyTexture,
        balance:          r.balance,
        uniformity:       r.uniformity,
        cleanCup:         r.cleanCup,
        sweetness:        r.sweetness,
        overall:          r.overall,
        defectsTaint:     r.defectsTaint,
        defectsFault:     r.defectsFault,
        totalScore:       r.totalScore,
        flavorDescriptors: r.flavorDescriptors,
        notes:            r.notes,
      );
}
