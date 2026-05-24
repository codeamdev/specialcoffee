import 'package:drift/drift.dart';
import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/harvest_dao.dart';
import 'package:special_coffee/domain/entities/harvest_session.dart';
import 'package:special_coffee/domain/repositories/harvest_repository.dart';
import 'package:uuid/uuid.dart';

class HarvestLocalRepository implements HarvestRepository {
  HarvestLocalRepository(this._dao, this._ownerId);

  final HarvestDao _dao;
  final String _ownerId;
  static const _uuid = Uuid();

  @override
  Future<HarvestSession> createSession({
    required String lotId,
    required String varietyId,
    required double altitudeMasl,
  }) async {
    final existing = await _dao.getActiveSession(lotId);
    if (existing != null) return _sessionFromRow(existing);

    final now = DateTime.now();
    final id = _uuid.v4();
    await _dao.insertSession(HarvestSessionsCompanion(
      id: Value(id),
      lotId: Value(lotId),
      ownerId: Value(_ownerId),
      varietyId: Value(varietyId),
      altitudeMasl: Value(altitudeMasl),
      startedAt: Value(now),
      createdAt: Value(now),
      updatedAt: Value(now),
    ));
    return HarvestSession(
      id: id,
      lotId: lotId,
      ownerId: _ownerId,
      varietyId: varietyId,
      altitudeMasl: altitudeMasl,
      startedAt: now,
      createdAt: now,
    );
  }

  @override
  Future<HarvestSession?> getActiveSession(String lotId) async {
    final row = await _dao.getActiveSession(lotId);
    return row != null ? _sessionFromRow(row) : null;
  }

  @override
  Future<HarvestPass> addPass({
    required String sessionId,
    required String lotId,
    required int passNumber,
    required DateTime passDate,
    required double kgCollected,
    required int pickerCount,
    double? ripenessRipePct,
    double? ripenessGreenPct,
    double? ripenessOverripePct,
    double? ripenesDryPct,
    double? brixDegrees,
    double rainProbabilityPct = 0.0,
    String aiAlertLevel = 'none',
    String? aiAlertMessage,
    String? notes,
  }) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _dao.insertPass(HarvestPassesCompanion(
      id: Value(id),
      sessionId: Value(sessionId),
      lotId: Value(lotId),
      ownerId: Value(_ownerId),
      passNumber: Value(passNumber),
      passDate: Value(passDate),
      kgCollected: Value(kgCollected),
      pickerCount: Value(pickerCount),
      ripenessRipePct: Value(ripenessRipePct),
      ripenessGreenPct: Value(ripenessGreenPct),
      ripenessOverripePct: Value(ripenessOverripePct),
      ripenesDryPct: Value(ripenesDryPct),
      brixDegrees: Value(brixDegrees),
      rainProbabilityPct: Value(rainProbabilityPct),
      aiAlertLevel: Value(aiAlertLevel),
      aiAlertMessage: Value(aiAlertMessage),
      notes: Value(notes),
      recordedAt: Value(now),
      updatedAt: Value(now),
    ));
    return HarvestPass(
      id: id,
      sessionId: sessionId,
      lotId: lotId,
      ownerId: _ownerId,
      passNumber: passNumber,
      passDate: passDate,
      kgCollected: kgCollected,
      pickerCount: pickerCount,
      ripenessRipePct: ripenessRipePct,
      ripenessGreenPct: ripenessGreenPct,
      ripenessOverripePct: ripenessOverripePct,
      ripenesDryPct: ripenesDryPct,
      brixDegrees: brixDegrees,
      rainProbabilityPct: rainProbabilityPct,
      aiAlertLevel: aiAlertLevel,
      aiAlertMessage: aiAlertMessage,
      notes: notes,
      recordedAt: now,
    );
  }

  @override
  Future<List<HarvestPass>> getPasses(String sessionId) async {
    final rows = await _dao.getPasses(sessionId);
    return rows.map(_passFromRow).toList();
  }

  @override
  Future<void> closeSession(String sessionId) =>
      _dao.updateSession(
        sessionId,
        HarvestSessionsCompanion(
          completedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  // ── Interval derivation ────────────────────────────────────────────────────

  /// Returns the recommended days between harvest passes based on
  /// variety and altitude. Calibration by microclimate is D-2 debt.
  static int nextPassIntervalDays(String varietyId, double altitudeMasl) {
    final v = varietyId.toLowerCase();
    // High-altitude varieties tend toward longer intervals
    final altitudeFactor = altitudeMasl >= 1800 ? 2 : 0;
    if (v.contains('castillo')) return 10 + altitudeFactor;
    if (v.contains('caturra')) return 9 + altitudeFactor;
    if (v.contains('colombia')) return 10 + altitudeFactor;
    if (v.contains('geisha') || v.contains('gesha')) return 12 + altitudeFactor;
    return 11 + altitudeFactor; // fallback for Tabí, Borbón, etc.
  }

  // ── Mappers ────────────────────────────────────────────────────────────────

  HarvestSession _sessionFromRow(DbHarvestSession r) => HarvestSession(
        id: r.id,
        lotId: r.lotId,
        ownerId: r.ownerId,
        varietyId: r.varietyId,
        altitudeMasl: r.altitudeMasl,
        startedAt: r.startedAt,
        completedAt: r.completedAt,
        createdAt: r.createdAt,
      );

  HarvestPass _passFromRow(DbHarvestPass r) => HarvestPass(
        id: r.id,
        sessionId: r.sessionId,
        lotId: r.lotId,
        ownerId: r.ownerId,
        passNumber: r.passNumber,
        passDate: r.passDate,
        kgCollected: r.kgCollected,
        pickerCount: r.pickerCount,
        ripenessRipePct: r.ripenessRipePct,
        ripenessGreenPct: r.ripenessGreenPct,
        ripenessOverripePct: r.ripenessOverripePct,
        ripenesDryPct: r.ripenesDryPct,
        brixDegrees: r.brixDegrees,
        rainProbabilityPct: r.rainProbabilityPct,
        aiAlertLevel: r.aiAlertLevel,
        aiAlertMessage: r.aiAlertMessage,
        notes: r.notes,
        recordedAt: r.recordedAt,
      );
}
