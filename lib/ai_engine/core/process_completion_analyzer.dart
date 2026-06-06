import 'package:special_coffee/core/database/app_database.dart';
import 'package:special_coffee/core/database/daos/batch_insights_dao.dart';
import 'package:special_coffee/domain/entities/lot_stage_log.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

/// Generates process insights from lot stage data after cupping is recorded.
///
/// Uses a rule-based template when Gemini is unavailable.
/// Saves results to batch_insights so they appear in LotDetailScreen.
class ProcessCompletionAnalyzer {
  ProcessCompletionAnalyzer(this._dao);

  final BatchInsightsDao _dao;
  final _uuid = const Uuid();

  Future<void> analyze({
    required String            lotId,
    required String            ownerId,
    required List<LotStageLog> stages,
    required double            scaScore,
  }) async {
    if (scaScore <= 0) return;

    final insights = _buildInsights(stages, scaScore);
    await _dao.insert(BatchInsightsCompanion(
      id:           Value(_uuid.v4()),
      lotId:        Value(lotId),
      ownerId:      Value(ownerId),
      scaScore:     Value(scaScore),
      fermentationH: Value(_fermentationH(stages)),
      phFinal:      Value(_phFinal(stages)),
      insightText:  Value(insights),
      createdAt:    Value(DateTime.now()),
    ));
  }

  String _buildInsights(List<LotStageLog> stages, double scaScore) {
    final buf = StringBuffer();

    if (scaScore >= 85) {
      buf.writeln('✅ Lote de especialidad: ${scaScore.toStringAsFixed(1)} pts SCA.');
    } else if (scaScore >= 80) {
      buf.writeln('☕ Lote sobre el umbral de especialidad: ${scaScore.toStringAsFixed(1)} pts SCA.');
    } else {
      buf.writeln('⚠️ Lote por debajo del umbral de especialidad: ${scaScore.toStringAsFixed(1)} pts SCA.');
    }

    final ferm = stages.where((s) => s.stage == 'fermentation').firstOrNull;
    if (ferm != null && ferm.isCompleted && ferm.expectedDurationH != null) {
      final elapsedH = ferm.completedAt!.difference(ferm.startedAt).inMinutes / 60.0;
      if (elapsedH > ferm.expectedDurationH! * 1.1) {
        buf.writeln('⏱ Fermentación extendida (${elapsedH.toStringAsFixed(1)}h vs '
            '${ferm.expectedDurationH!.toStringAsFixed(0)}h esperadas) — '
            'puede haber contribuido a mayor complejidad o acidez.');
      } else {
        buf.writeln('✓ Fermentación completada en rango (${elapsedH.toStringAsFixed(1)}h).');
      }
    }

    final phEnd = _phFinal(stages);
    if (phEnd != null) {
      if (phEnd < 3.8) {
        buf.writeln('🔬 pH final bajo (${phEnd.toStringAsFixed(2)}) — revisar si hay notas de vinagre en catación.');
      } else if (phEnd <= 4.5) {
        buf.writeln('✓ pH final en rango adecuado (${phEnd.toStringAsFixed(2)}).');
      }
    }

    final overdueStages = stages.where((s) => s.isOverdue).map((s) => s.stage).toList();
    if (overdueStages.isNotEmpty) {
      buf.writeln('⚠️ Etapas con tiempo excedido: ${overdueStages.join(", ")}. '
          'Considerar ajustar parámetros en el próximo lote.');
    }

    if (scaScore >= 85) {
      buf.writeln('💡 Recomendación: Replicar este proceso en el siguiente lote.');
    } else {
      buf.writeln('💡 Recomendación: Revisar tiempos de fermentación y temperatura.');
    }

    return buf.toString().trim();
  }

  double? _fermentationH(List<LotStageLog> stages) {
    final ferm = stages.where((s) => s.stage == 'fermentation' && s.isCompleted).firstOrNull;
    if (ferm == null) return null;
    return ferm.completedAt!.difference(ferm.startedAt).inMinutes / 60.0;
  }

  double? _phFinal(List<LotStageLog> stages) {
    for (final s in stages.reversed) {
      if (s.phEnd != null) return s.phEnd;
    }
    return null;
  }
}
