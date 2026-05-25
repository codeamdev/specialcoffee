import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/cupping_dao.dart';
import 'package:special_coffee/domain/entities/cupping_session.dart';
import 'package:special_coffee/domain/repositories/cupping_repository.dart';
import 'package:uuid/uuid.dart';

class CuppingLocalRepository implements CuppingRepository {
  CuppingLocalRepository(this._dao, this._ownerId);

  final CuppingDao _dao;
  final String     _ownerId;
  static const _uuid = Uuid();

  @override
  Future<CuppingSession?> getByLotId(String lotId) async {
    final row = await _dao.getByLotId(lotId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<List<CuppingSession>> getAllByOwner(String ownerId) async {
    final rows = await _dao.getAllByOwner(ownerId);
    return rows.map(_fromRow).toList();
  }

  @override
  Future<CuppingSession> save(CuppingSession session) async {
    final now = DateTime.now();
    final id  = session.id.isEmpty ? _uuid.v4() : session.id;
    await _dao.upsert(CuppingSessionsCompanion(
      id:               Value(id),
      lotId:            Value(session.lotId),
      ownerId:          Value(_ownerId),
      cuppedAt:         Value(session.cuppedAt),
      fragranceAroma:   Value(session.fragranceAroma),
      flavor:           Value(session.flavor),
      aftertaste:       Value(session.aftertaste),
      acidity:          Value(session.acidity),
      acidityIntensity: Value(session.acidityIntensity),
      body:             Value(session.body),
      bodyLevel:        Value(session.bodyLevel),
      balance:          Value(session.balance),
      uniformityCups:   Value(session.uniformityCups),
      cleanCupCups:     Value(session.cleanCupCups),
      sweetnessCups:    Value(session.sweetnessCups),
      overall:          Value(session.overall),
      defectsCat1Count: Value(session.defectsCat1Count),
      defectsCat2Count: Value(session.defectsCat2Count),
      aiAlertLevel:     Value(session.aiAlertLevel),
      aiAlertMessage:   Value(session.aiAlertMessage),
      totalScore:       Value(session.totalScore),
      notes:            Value(session.notes),
      createdAt:        Value(session.createdAt),
      updatedAt:        Value(now),
    ));
    return CuppingSession(
      id:               id,
      lotId:            session.lotId,
      ownerId:          _ownerId,
      cuppedAt:         session.cuppedAt,
      fragranceAroma:   session.fragranceAroma,
      flavor:           session.flavor,
      aftertaste:       session.aftertaste,
      acidity:          session.acidity,
      acidityIntensity: session.acidityIntensity,
      body:             session.body,
      bodyLevel:        session.bodyLevel,
      balance:          session.balance,
      uniformityCups:   session.uniformityCups,
      cleanCupCups:     session.cleanCupCups,
      sweetnessCups:    session.sweetnessCups,
      overall:          session.overall,
      defectsCat1Count: session.defectsCat1Count,
      defectsCat2Count: session.defectsCat2Count,
      aiAlertLevel:     session.aiAlertLevel,
      aiAlertMessage:   session.aiAlertMessage,
      totalScore:       session.totalScore,
      notes:            session.notes,
      createdAt:        session.createdAt,
    );
  }

  CuppingSession _fromRow(DbCuppingSession r) => CuppingSession(
    id:               r.id,
    lotId:            r.lotId,
    ownerId:          r.ownerId,
    cuppedAt:         r.cuppedAt,
    fragranceAroma:   r.fragranceAroma,
    flavor:           r.flavor,
    aftertaste:       r.aftertaste,
    acidity:          r.acidity,
    acidityIntensity: r.acidityIntensity,
    body:             r.body,
    bodyLevel:        r.bodyLevel,
    balance:          r.balance,
    uniformityCups:   r.uniformityCups,
    cleanCupCups:     r.cleanCupCups,
    sweetnessCups:    r.sweetnessCups,
    overall:          r.overall,
    defectsCat1Count: r.defectsCat1Count,
    defectsCat2Count: r.defectsCat2Count,
    aiAlertLevel:     r.aiAlertLevel,
    aiAlertMessage:   r.aiAlertMessage,
    totalScore:       r.totalScore,
    notes:            r.notes,
    createdAt:        r.createdAt,
  );
}
