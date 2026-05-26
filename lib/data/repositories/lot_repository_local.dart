import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/lot_dao.dart';
import 'package:special_coffee/domain/entities/lot.dart';
import 'package:special_coffee/domain/repositories/lot_repository.dart';

class LotLocalRepository implements LotRepository {
  LotLocalRepository(this._dao);

  final LotDao _dao;

  @override
  Future<List<Lot>> getLots(String userId) async {
    final rows = await _dao.findAllByUser(userId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<Lot?> getLotById(String lotId, String userId) async {
    final row = await _dao.findById(lotId, userId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<Lot> saveLot(Lot lot) async {
    await _dao.upsert(LocalLotsCompanion(
      id:                 Value(lot.id),
      userId:             Value(lot.userId),
      varietyId:          Value(lot.varietyId),
      varietyName:        Value(lot.varietyName),
      altitudeMasl:       Value(lot.altitudeMasl),
      region:             Value(lot.region),
      processType:        Value(lot.processType),
      ambientTempC:       Value(lot.ambientTempC),
      ambientHumidityPct: Value(lot.ambientHumidityPct),
      rainProbabilityPct: Value(lot.rainProbabilityPct),
      createdAt:          Value(lot.createdAt),
      status:             Value(lot.status),
      notes:              Value(lot.notes),
    ));
    return lot;
  }

  @override
  Future<void> deleteLot(String lotId) => _dao.softDelete(lotId);

  // ── Mapper ────────────────────────────────────────────────────────────────

  static Lot _fromRow(DbLocalLot r) => Lot(
    id:                 r.id,
    userId:             r.userId,
    varietyId:          r.varietyId,
    varietyName:        r.varietyName,
    altitudeMasl:       r.altitudeMasl,
    region:             r.region,
    processType:        r.processType,
    ambientTempC:       r.ambientTempC  ?? 18.0,
    ambientHumidityPct: r.ambientHumidityPct ?? 70.0,
    rainProbabilityPct: r.rainProbabilityPct,
    createdAt:          r.createdAt,
    status:             r.status,
    notes:              r.notes,
  );
}
