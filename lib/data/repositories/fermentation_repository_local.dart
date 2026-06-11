import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/fermentation_dao.dart';
import 'package:special_coffee/domain/entities/fermentation_session.dart';
import 'package:special_coffee/domain/repositories/fermentation_repository.dart';
import 'package:uuid/uuid.dart';

class FermentationLocalRepository implements FermentationRepository {
  FermentationLocalRepository(this._dao, this._ownerId);

  final FermentationDao _dao;
  final String _ownerId;
  static const _uuid = Uuid();

  @override
  Future<FermentationSession> createSession({
    required String lotId,
    required String processType,
  }) async {
    // Enforce one active session per lot
    final existing = await _dao.getActiveSession(lotId);
    if (existing != null) return _sessionFromRow(existing);

    final now = DateTime.now();
    final id = _uuid.v4();
    await _dao.insertSession(FermentationSessionsCompanion(
      id: Value(id),
      lotId: Value(lotId),
      ownerId: Value(_ownerId),
      processType: Value(processType),
      startedAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
    return FermentationSession(
      id: id,
      lotId: lotId,
      ownerId: _ownerId,
      processType: processType,
      createdAt: now,
      startedAt: now,
    );
  }

  @override
  Future<FermentationSession?> getActiveSession(String lotId) async {
    final row = await _dao.getActiveSession(lotId);
    return row != null ? _sessionFromRow(row) : null;
  }

  @override
  Future<FermentationReadingRecord> addReading({
    required String sessionId,
    required String lotId,
    required int readingNumber,
    required double hoursElapsed,
    required double phValue,
    required double mucilagoTempC,
    String mucilageState = 'liquid',
    double? ambientTempC,
    String aiAlertLevel = 'none',
    String? aiAlertRuleId,
    double? aiProjectedEndH,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _dao.insertReading(FermentationReadingsCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      lotId: Value(lotId),
      ownerId: Value(_ownerId),
      readingNumber: Value(readingNumber),
      hoursElapsed: Value(hoursElapsed),
      phValue: Value(phValue),
      mucilagoTempC: Value(mucilagoTempC),
      ambientTempC: Value(ambientTempC),
      mucilageState: Value(mucilageState),
      aiAlertLevel: Value(aiAlertLevel),
      aiAlertRuleId: Value(aiAlertRuleId),
      aiProjectedEndH: Value(aiProjectedEndH),
      recordedAt: Value(now),
      updatedAt: Value(now),
    ));
    return FermentationReadingRecord(
      id: id,
      sessionId: sessionId,
      lotId: lotId,
      ownerId: _ownerId,
      readingNumber: readingNumber,
      hoursElapsed: hoursElapsed,
      phValue: phValue,
      mucilagoTempC: mucilagoTempC,
      ambientTempC: ambientTempC,
      mucilageState: mucilageState,
      aiAlertLevel: aiAlertLevel,
      aiAlertRuleId: aiAlertRuleId,
      aiProjectedEndH: aiProjectedEndH,
      recordedAt: now,
    );
  }

  @override
  Future<List<FermentationReadingRecord>> getReadings(String sessionId) async {
    final rows = await _dao.getReadings(sessionId);
    return rows.map(_readingFromRow).toList();
  }

  @override
  Future<void> closeSession({
    required String sessionId,
    required String endReason,
    required double actualDurationH,
    required double phFinal,
  }) =>
      _dao.updateSession(
        sessionId,
        FermentationSessionsCompanion(
          endedAt: Value(DateTime.now()),
          endReason: Value(endReason),
          actualDurationH: Value(actualDurationH),
          phFinal: Value(phFinal),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ── Mappers ────────────────────────────────────────────────────────────────

  FermentationSession _sessionFromRow(DbFermentationSession r) =>
      FermentationSession(
        id: r.id,
        lotId: r.lotId,
        ownerId: r.ownerId,
        processType: r.processType,
        createdAt: r.createdAt,
        startedAt: r.startedAt,
        endedAt: r.endedAt,
        actualDurationH: r.actualDurationH,
        endReason: r.endReason,
        phInitial: r.phInitial,
        phFinal: r.phFinal,
      );

  @override
  Future<double> getAvgCompletedDurationH() =>
      _dao.getAvgCompletedDurationH(_ownerId);

  @override
  Future<double> getLastCompletedDurationH() =>
      _dao.getLastCompletedDurationH(_ownerId);

  FermentationReadingRecord _readingFromRow(DbFermentationReading r) =>
      FermentationReadingRecord(
        id: r.id,
        sessionId: r.sessionId,
        lotId: r.lotId,
        ownerId: r.ownerId,
        readingNumber: r.readingNumber,
        hoursElapsed: r.hoursElapsed,
        phValue: r.phValue,
        mucilagoTempC: r.mucilagoTempC,
        ambientTempC: r.ambientTempC,
        mucilageState: r.mucilageState,
        aiAlertLevel: r.aiAlertLevel,
        aiAlertRuleId: r.aiAlertRuleId,
        aiProjectedEndH: r.aiProjectedEndH,
        recordedAt: r.recordedAt,
      );
}
