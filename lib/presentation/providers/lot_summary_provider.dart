import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/core/di/providers.dart';
import 'package:special_coffee/domain/entities/lot_insight.dart';

part 'lot_summary_provider.g.dart';

// ── Recent insights (for dashboard) ───────────────────────────────────────

@riverpod
Future<List<LotInsight>> lotInsights(Ref ref, String userId) =>
    ref.watch(batchInsightsLocalRepoProvider).getByOwner();

// ── Generator ─────────────────────────────────────────────────────────────

@riverpod
class LotSummaryNotifier extends _$LotSummaryNotifier {
  @override
  bool build() => false; // isGenerating

  Future<LotInsight?> generateAndSave({
    required String lotId,
    required double scaScore,
    double? fermentationH,
    double? phFinal,
  }) async {
    state = true;
    try {
      final text = _insightText(scaScore, fermentationH, phFinal);
      final insight = await ref.read(batchInsightsLocalRepoProvider).save(
            LotInsight(
              id:           '',
              lotId:        lotId,
              ownerId:      '',        // repo injects real ownerId
              scaScore:     scaScore,
              fermentationH: fermentationH,
              phFinal:       phFinal,
              insightText:  text,
              createdAt:    DateTime.now(),
            ),
          );
      ref.invalidate(lotInsightsProvider);
      return insight;
    } catch (e, st) {
      if (kDebugMode) debugPrint('[LotSummary] generateAndSave: $e\n$st');
      return null;
    } finally {
      state = false;
    }
  }

  static String _insightText(double sca, double? fermH, double? ph) {
    final buf = StringBuffer();
    if (sca >= 86) {
      buf.write('Excelente lote (${sca.toStringAsFixed(1)} pts). ');
      if (fermH != null) {
        buf.write('Fermentación de ${fermH.toStringAsFixed(0)}h fue óptima — '
            'mantén este rango en el siguiente lote.');
      }
    } else if (sca >= 80) {
      buf.write('Buen lote de especialidad (${sca.toStringAsFixed(1)} pts). ');
      if (fermH != null && fermH > 28) {
        buf.write('Considera reducir fermentación 2–4h para ganar más '
            'limpieza en taza.');
      } else if (fermH != null) {
        buf.write('Fermentación de ${fermH.toStringAsFixed(0)}h. '
            'Pequeños ajustes de temperatura pueden mejorar el puntaje.');
      }
    } else {
      buf.write('Lote por debajo de especialidad (${sca.toStringAsFixed(1)} pts). ');
      if (fermH != null) {
        buf.write('Revisa control de temperatura durante las '
            '${fermH.toStringAsFixed(0)}h de fermentación.');
      } else {
        buf.write('Revisa cada etapa del proceso para identificar la causa.');
      }
    }
    if (ph != null) {
      buf.write(' pH final: ${ph.toStringAsFixed(2)}.');
    }
    return buf.toString();
  }
}
