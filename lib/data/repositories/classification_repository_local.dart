import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/classification_dao.dart';
import 'package:special_coffee/domain/entities/classification_session.dart';
import 'package:special_coffee/domain/repositories/classification_repository.dart';
import 'package:uuid/uuid.dart';

class ClassificationLocalRepository implements ClassificationRepository {
  ClassificationLocalRepository(this._dao, this._ownerId);

  final ClassificationDao _dao;
  final String            _ownerId;
  static const _uuid = Uuid();

  @override
  Future<ClassificationSession?> getByLotId(String lotId) async {
    final row = await _dao.getByLotId(lotId);
    return row != null ? _fromRow(row) : null;
  }

  @override
  Future<ClassificationSession> save(ClassificationSession session) async {
    final now = DateTime.now();
    final id  = session.id.isEmpty ? _uuid.v4() : session.id;
    await _dao.upsert(ClassificationSessionsCompanion(
      id:               Value(id),
      lotId:            Value(session.lotId),
      ownerId:          Value(_ownerId),
      harvestSessionId: Value(session.harvestSessionId),
      kgEntrada:        Value(session.kgEntrada),
      brixCereza:       Value(session.brixCereza),
      kgFlotantes:      Value(session.kgFlotantes),
      kgDescarteManual: Value(session.kgDescarteManual),
      aiAlertLevel:     Value(session.aiAlertLevel),
      aiAlertMessage:   Value(session.aiAlertMessage),
      notes:            Value(session.notes),
      classifiedAt:     Value(session.classifiedAt),
      createdAt:        Value(session.createdAt),
      updatedAt:        Value(now),
    ));
    return ClassificationSession(
      id:               id,
      lotId:            session.lotId,
      ownerId:          _ownerId,
      harvestSessionId: session.harvestSessionId,
      kgEntrada:        session.kgEntrada,
      brixCereza:       session.brixCereza,
      kgFlotantes:      session.kgFlotantes,
      kgDescarteManual: session.kgDescarteManual,
      aiAlertLevel:     session.aiAlertLevel,
      aiAlertMessage:   session.aiAlertMessage,
      notes:            session.notes,
      classifiedAt:     session.classifiedAt,
      createdAt:        session.createdAt,
    );
  }

  // ── Mapper ────────────────────────────────────────────────────────────────

  ClassificationSession _fromRow(DbClassificationSession r) =>
      ClassificationSession(
        id:               r.id,
        lotId:            r.lotId,
        ownerId:          r.ownerId,
        harvestSessionId: r.harvestSessionId,
        kgEntrada:        r.kgEntrada,
        brixCereza:       r.brixCereza,
        kgFlotantes:      r.kgFlotantes,
        kgDescarteManual: r.kgDescarteManual,
        aiAlertLevel:     r.aiAlertLevel,
        aiAlertMessage:   r.aiAlertMessage,
        notes:            r.notes,
        classifiedAt:     r.classifiedAt,
        createdAt:        r.createdAt,
      );
}
