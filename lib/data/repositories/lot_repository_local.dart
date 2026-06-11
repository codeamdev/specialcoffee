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
      id:             Value(lot.id),
      userId:         Value(lot.userId),
      varietyId:      Value(lot.varietyId),
      varietyName:    Value(lot.varietyName),
      altitudeMasl:   Value(lot.altitudeMasl),
      region:         Value(lot.region),
      processType:    Value(lot.processType),
      latitude:       Value(lot.latitude),
      longitude:      Value(lot.longitude),
      farmAreaHa:     Value(lot.farmAreaHa),
      blendVarietyIds: Value(lot.blendVarietyIds),
      plantAgeYears:  Value(lot.plantAgeYears),
      plantType:      Value(lot.plantType),
      createdAt:      Value(lot.createdAt),
      notes:          Value(lot.notes),
    ));
    return lot;
  }

  @override
  Future<void> deleteLot(String lotId) => _dao.softDelete(lotId);

  // ── Mapper ────────────────────────────────────────────────────────────────

  static Lot _fromRow(DbLocalLot r) => Lot(
    id:              r.id,
    userId:          r.userId,
    varietyId:       r.varietyId,
    varietyName:     r.varietyName,
    altitudeMasl:    r.altitudeMasl,
    region:          r.region,
    processType:     r.processType,
    createdAt:       r.createdAt,
    notes:           r.notes,
    latitude:        r.latitude,
    longitude:       r.longitude,
    farmAreaHa:      r.farmAreaHa,
    blendVarietyIds: r.blendVarietyIds,
    plantAgeYears:   r.plantAgeYears,
    plantType:       r.plantType,
  );
}
