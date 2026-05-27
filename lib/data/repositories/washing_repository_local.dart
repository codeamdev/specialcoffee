import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/washing_dao.dart';
import 'package:special_coffee/domain/entities/washing_session.dart';
import 'package:special_coffee/domain/repositories/washing_repository.dart';
import 'package:uuid/uuid.dart';

class WashingLocalRepository implements WashingRepository {
  WashingLocalRepository(this._dao, this._ownerId);

  final WashingDao _dao;
  final String     _ownerId;
  static const _uuid = Uuid();

  @override
  Future<WashingSession?> getByLotId(String lotId) async {
    final row = await _dao.getByLotId(lotId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<WashingSession> save(WashingSession session) async {
    final now = DateTime.now();
    final id  = session.id.isEmpty ? _uuid.v4() : session.id;
    await _dao.upsert(WashingSessionsCompanion(
      id:                    Value(id),
      lotId:                 Value(session.lotId),
      ownerId:               Value(_ownerId),
      fermentationSessionId: Value(session.fermentationSessionId),
      waterTempC:            Value(session.waterTempC),
      waterChanges:          Value(session.waterChanges),
      effluentPhFinal:       Value(session.effluentPhFinal),
      durationH:             Value(session.durationH),
      washedAt:              Value(session.washedAt),
      aiAlertLevel:          Value(session.aiAlertLevel),
      aiAlertMessage:        Value(session.aiAlertMessage),
      notes:                 Value(session.notes),
      createdAt:             Value(session.createdAt),
      updatedAt:             Value(now),
    ));
    return WashingSession(
      id:                    id,
      lotId:                 session.lotId,
      ownerId:               _ownerId,
      fermentationSessionId: session.fermentationSessionId,
      waterTempC:            session.waterTempC,
      waterChanges:          session.waterChanges,
      effluentPhFinal:       session.effluentPhFinal,
      durationH:             session.durationH,
      washedAt:              session.washedAt,
      aiAlertLevel:          session.aiAlertLevel,
      aiAlertMessage:        session.aiAlertMessage,
      notes:                 session.notes,
      createdAt:             session.createdAt,
    );
  }

  WashingSession _fromRow(DbWashingSession r) => WashingSession(
        id:                    r.id,
        lotId:                 r.lotId,
        ownerId:               r.ownerId,
        fermentationSessionId: r.fermentationSessionId,
        waterTempC:            r.waterTempC,
        waterChanges:          r.waterChanges,
        effluentPhFinal:       r.effluentPhFinal,
        durationH:             r.durationH,
        washedAt:              r.washedAt,
        aiAlertLevel:          r.aiAlertLevel,
        aiAlertMessage:        r.aiAlertMessage,
        notes:                 r.notes,
        createdAt:             r.createdAt,
      );
}
