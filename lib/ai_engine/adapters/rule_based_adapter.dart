import 'dart:convert';

import 'package:special_coffee/ai_engine/adapters/inference_adapter.dart';
import 'package:special_coffee/ai_engine/core/rule_engine.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/rules/all_rules.dart';

/// Implementación v1.0 del InferenceAdapter.
/// Usa el RuleEngine basado en reglas Dart embebidas — 100% on-device, sin ML.
/// En v2.0 se añadirá carga dinámica de reglas desde el servidor.
class RuleBasedInferenceAdapter implements InferenceAdapter {
  final RuleEngine _engine;
  bool _ready = false;

  RuleBasedInferenceAdapter({required RuleEngine engine}) : _engine = engine;

  @override
  Future<void> initialize() async {
    _engine.loadRules(AllRules.all, version: AllRules.version);
    _ready = true;
  }

  /// Actualiza las reglas en caliente desde un JSON (para v2 con servidor).
  Future<void> updateRulesFromJson(String jsonString, String version) async {
    try {
      final rulesList = (jsonDecode(jsonString) as List)
          .map((e) => AIRule.fromJson(e as Map<String, dynamic>))
          .toList();
      _engine.loadRules(rulesList, version: version);
    } catch (e) {
      assert(false, '[RuleBasedAdapter] JSON de reglas inválido: $e');
    }
  }

  @override
  Future<List<Recommendation>> infer(AIContext context) async {
    assert(_ready, 'RuleBasedInferenceAdapter: llamar initialize() primero');
    return _engine.evaluate(context);
  }

  @override
  String get version => _engine.rulesVersion;

  @override
  bool get isReady => _ready;
}
