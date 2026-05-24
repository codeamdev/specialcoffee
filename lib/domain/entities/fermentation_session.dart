// Entidades de dominio para fermentación.
// Distintas de las clases del AI Engine (alert.dart) que son solo para cálculo.

class FermentationSession {
  final String id;
  final String lotId;
  final String ownerId;
  final String processType;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final double? actualDurationH;
  final String? endReason;
  final double? phInitial;
  final double? phFinal;

  const FermentationSession({
    required this.id,
    required this.lotId,
    required this.ownerId,
    required this.processType,
    required this.createdAt,
    this.startedAt,
    this.endedAt,
    this.actualDurationH,
    this.endReason,
    this.phInitial,
    this.phFinal,
  });

  factory FermentationSession.fromJson(Map<String, dynamic> json) =>
      FermentationSession(
        id:             json['id']           as String,
        lotId:          json['lot_id']        as String,
        ownerId:        json['owner_id']      as String,
        processType:    json['process_type']  as String,
        createdAt:      DateTime.parse(json['created_at'] as String),
        startedAt:      json['started_at'] != null
            ? DateTime.parse(json['started_at'] as String)
            : null,
        endedAt:        json['ended_at'] != null
            ? DateTime.parse(json['ended_at'] as String)
            : null,
        actualDurationH: json['actual_duration_h'] as double?,
        endReason:       json['end_reason']        as String?,
        phInitial:       json['ph_initial']        as double?,
        phFinal:         json['ph_final']           as double?,
      );
}

/// Lectura individual de fermentación persistida en el servidor.
/// No confundir con `FermentationReading` del AI engine (solo para regresión lineal).
class FermentationReadingRecord {
  final String id;
  final String sessionId;
  final String lotId;
  final String ownerId;
  final int    readingNumber;
  final double hoursElapsed;
  final double phValue;
  final double mucilagoTempC;
  final double? ambientTempC;
  final String mucilageState;
  final String aiAlertLevel;
  final String? aiAlertRuleId;
  final double? aiProjectedEndH;
  final DateTime recordedAt;

  const FermentationReadingRecord({
    required this.id,
    required this.sessionId,
    required this.lotId,
    required this.ownerId,
    required this.readingNumber,
    required this.hoursElapsed,
    required this.phValue,
    required this.mucilagoTempC,
    this.ambientTempC,
    this.mucilageState = 'liquid',
    this.aiAlertLevel  = 'none',
    this.aiAlertRuleId,
    this.aiProjectedEndH,
    required this.recordedAt,
  });

  factory FermentationReadingRecord.fromJson(Map<String, dynamic> json) =>
      FermentationReadingRecord(
        id:              json['id']             as String,
        sessionId:       json['session_id']      as String,
        lotId:           json['lot_id']           as String,
        ownerId:         json['owner_id']         as String,
        readingNumber:   json['reading_number']   as int,
        hoursElapsed:    (json['hours_elapsed']   as num).toDouble(),
        phValue:         (json['ph_value']        as num).toDouble(),
        mucilagoTempC:   (json['mucilago_temp_c'] as num).toDouble(),
        ambientTempC:    (json['ambient_temp_c']  as num?)?.toDouble(),
        mucilageState:   json['mucilage_state']   as String? ?? 'liquid',
        aiAlertLevel:    json['ai_alert_level']   as String? ?? 'none',
        aiAlertRuleId:   json['ai_alert_rule_id'] as String?,
        aiProjectedEndH: (json['ai_projected_end_h'] as num?)?.toDouble(),
        recordedAt:      DateTime.parse(json['recorded_at'] as String),
      );
}
