import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';

/// Interfaz que desacopla el RuleEngine del mecanismo de inferencia.
/// v1.0 → RuleBasedInferenceAdapter (reglas Dart, 100% on-device)
/// v2.0 → TFLiteInferenceAdapter (modelo ML, mismo contrato)
///
/// El resto de la app solo conoce esta interfaz — la migración a ML
/// no requiere cambios en los use cases ni en la UI.
abstract class InferenceAdapter {
  /// Carga o actualiza las reglas/modelo.
  Future<void> initialize();

  /// Evalúa el contexto y retorna recomendaciones ordenadas por urgencia.
  Future<List<Recommendation>> infer(AIContext context);

  /// Versión de las reglas o del modelo activo.
  String get version;

  /// Indica si el adaptador está listo para inferir.
  bool get isReady;
}
