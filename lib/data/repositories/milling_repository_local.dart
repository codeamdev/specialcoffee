import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/milling_dao.dart';
import 'package:special_coffee/domain/entities/milling_session.dart';
import 'package:special_coffee/domain/repositories/milling_repository.dart';
import 'package:uuid/uuid.dart';

class MillingLocalRepository implements MillingRepository {
  MillingLocalRepository(this._dao, this._ownerId);

  final MillingDao _dao;
  final String     _ownerId;
  static const _uuid = Uuid();

  @override
  Future<MillingSession?> getByLotId(String lotId) async {
    final row = await _dao.getByLotId(lotId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<MillingSession> save(MillingSession session) async {
    final now = DateTime.now();
    final id  = session.id.isEmpty ? _uuid.v4() : session.id;
    await _dao.upsert(MillingSessionsCompanion(
      id:               Value(id),
      lotId:            Value(session.lotId),
      ownerId:          Value(_ownerId),
      inputKgParchment: Value(session.inputKgParchment),
      outputKgGreen:    Value(session.outputKgGreen),
      yieldPct:         Value(session.yieldPct),
      aiAlertLevel:     Value(session.aiAlertLevel),
      aiAlertMessage:   Value(session.aiAlertMessage),
      notes:            Value(session.notes),
      createdAt:        Value(session.createdAt),
      updatedAt:        Value(now),
    ));
    return MillingSession(
      id:               id,
      lotId:            session.lotId,
      ownerId:          _ownerId,
      inputKgParchment: session.inputKgParchment,
      outputKgGreen:    session.outputKgGreen,
      yieldPct:         session.yieldPct,
      aiAlertLevel:     session.aiAlertLevel,
      aiAlertMessage:   session.aiAlertMessage,
      notes:            session.notes,
      createdAt:        session.createdAt,
    );
  }

  MillingSession _fromRow(DbMillingSession r) => MillingSession(
        id:               r.id,
        lotId:            r.lotId,
        ownerId:          r.ownerId,
        inputKgParchment: r.inputKgParchment,
        outputKgGreen:    r.outputKgGreen,
        yieldPct:         r.yieldPct,
        aiAlertLevel:     r.aiAlertLevel,
        aiAlertMessage:   r.aiAlertMessage,
        notes:            r.notes,
        createdAt:        r.createdAt,
      );
}
