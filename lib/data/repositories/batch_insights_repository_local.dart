import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/batch_insights_dao.dart';
import 'package:special_coffee/domain/entities/lot_insight.dart';
import 'package:uuid/uuid.dart';

class BatchInsightsLocalRepository {
  BatchInsightsLocalRepository(this._dao, this._ownerId);

  final BatchInsightsDao _dao;
  final String           _ownerId;
  static const _uuid = Uuid();

  Future<LotInsight> save(LotInsight insight) async {
    final id = insight.id.isEmpty ? _uuid.v4() : insight.id;
    await _dao.insert(BatchInsightsCompanion(
      id:           Value(id),
      lotId:        Value(insight.lotId),
      ownerId:      Value(_ownerId),
      scaScore:     Value(insight.scaScore),
      fermentationH: Value(insight.fermentationH),
      phFinal:      Value(insight.phFinal),
      insightText:  Value(insight.insightText),
      createdAt:    Value(insight.createdAt),
    ));
    return LotInsight(
      id:           id,
      lotId:        insight.lotId,
      ownerId:      _ownerId,
      scaScore:     insight.scaScore,
      fermentationH: insight.fermentationH,
      phFinal:      insight.phFinal,
      insightText:  insight.insightText,
      createdAt:    insight.createdAt,
    );
  }

  Future<List<LotInsight>> getByOwner() async {
    final rows = await _dao.getByOwner(_ownerId);
    return rows.map(_fromRow).toList();
  }

  Future<LotInsight?> getByLotId(String lotId) async {
    final row = await _dao.getByLotId(lotId);
    return row != null ? _fromRow(row) : null;
  }

  LotInsight _fromRow(DbLotInsight r) => LotInsight(
        id:           r.id,
        lotId:        r.lotId,
        ownerId:      r.ownerId,
        scaScore:     r.scaScore,
        fermentationH: r.fermentationH,
        phFinal:      r.phFinal,
        insightText:  r.insightText,
        createdAt:    r.createdAt,
      );
}
