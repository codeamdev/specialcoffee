import 'package:special_coffee/domain/entities/cupping_evaluation.dart';

abstract interface class CuppingEvaluationRepository {
  Future<List<CuppingEvaluation>> getByLotId(String lotId);
  Future<CuppingEvaluation?> getLatestByLotId(String lotId);
  Future<CuppingEvaluation> save(CuppingEvaluation evaluation);
}
