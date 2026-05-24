import 'dart:convert';

import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:special_coffee/ai_engine/adapters/inference_adapter.dart';
import 'package:special_coffee/ai_engine/adapters/rule_based_adapter.dart';
import 'package:special_coffee/ai_engine/models/ai_context.dart';
import 'package:special_coffee/ai_engine/models/ai_rule.dart';
import 'package:special_coffee/ai_engine/prompts/prompt_builder.dart';
import 'package:special_coffee/core/config/gemini_config.dart';

enum GeminiStatus {
  /// Gemini activo — respondiendo normalmente.
  active,
  /// Cooldown por rate-limit (por minuto). Reintentar pronto.
  rateLimited,
  /// Cuota diaria agotada. No reintentar hasta mañana.
  dailyQuotaExhausted,
  /// Sin conexión / timeout.
  offline,
}

/// Adaptador híbrido: Gemini como motor principal + Rule Engine como fallback.
///
/// Rate limiting integrado:
///   - Mínimo 4 segundos entre llamadas consecutivas (evita ráfagas).
///   - Al recibir 429 por minuto, congela Gemini usando el retryDelay de la API.
///   - Al detectar cuota diaria agotada (PerDay), congela hasta medianoche.
///   - En todos los casos devuelve el último resultado cacheado o el Rule Engine.
class GeminiInferenceAdapter implements InferenceAdapter {
  final GenerativeModel           _model;
  final RuleBasedInferenceAdapter _ruleFallback;
  bool _ready = false;

  // ── Rate limiter ───────────────────────────────────────────────────────────
  DateTime?              _lastCallTime;
  DateTime?              _rateLimitedUntil;
  List<Recommendation>?  _cachedResult;
  GeminiStatus           _status = GeminiStatus.active;

  static const _minInterval       = Duration(seconds: 8);
  static const _defaultRateLimit  = Duration(seconds: 60);
  // Si el retry delay del API supera este umbral, asumimos cuota diaria.
  static const _dailyThreshold    = Duration(minutes: 10);

  GeminiStatus get status => _status;

  GeminiInferenceAdapter({
    required String apiKey,
    required RuleBasedInferenceAdapter ruleFallback,
  })  : _ruleFallback = ruleFallback,
        _model = GenerativeModel(
          model: GeminiConfig.model,
          apiKey: apiKey,
          systemInstruction: Content.system(PromptBuilder.systemInstruction),
          generationConfig: GenerationConfig(
            responseMimeType: 'application/json',
            maxOutputTokens: GeminiConfig.maxOutputTokens,
            temperature: GeminiConfig.temperature,
          ),
        );

  @override
  Future<void> initialize() async {
    await _ruleFallback.initialize();
    _ready = true;
  }

  @override
  Future<List<Recommendation>> infer(AIContext context) async {
    assert(_ready, 'GeminiInferenceAdapter: llamar initialize() primero');

    // Rule Engine siempre (on-device, < 5ms, funciona offline)
    final ruleRecs = await _ruleFallback.infer(context);

    // Si estamos en cooldown por 429, devolver cache o reglas
    final now = DateTime.now();
    if (_rateLimitedUntil != null && now.isBefore(_rateLimitedUntil!)) {
      return _cachedResult ?? ruleRecs;
    }

    // Si la última llamada fue hace menos de [_minInterval], devolver cache
    if (_lastCallTime != null && now.difference(_lastCallTime!) < _minInterval) {
      return _cachedResult ?? ruleRecs;
    }

    // Llamada a Gemini
    List<Recommendation> geminiRecs = [];
    try {
      _lastCallTime = DateTime.now();
      final prompt   = PromptBuilder.build(context);
      final response = await _model
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: GeminiConfig.timeoutSeconds));

      geminiRecs = _parseResponse(response.text);
    } on GenerativeAIException catch (e) {
      if (_isRateLimit(e.message)) {
        _applyQuotaCooldown(e.message);
      }
      // Fallback silencioso → devuelve reglas
    } catch (_) {
      // Timeout, sin conexión u otro error → fallback silencioso
      _status = GeminiStatus.offline;
    }

    if (geminiRecs.isEmpty) return ruleRecs;

    // Gemini primero; reglas no cubiertas al final
    final covered   = geminiRecs.map((r) => r.action).toSet();
    final unique    = ruleRecs.where((r) => !covered.contains(r.action));
    final combined  = [...geminiRecs, ...unique];

    _cachedResult     = combined;
    _rateLimitedUntil = null;
    _status           = GeminiStatus.active;
    return combined;
  }

  @override
  String get version => 'gemini/${GeminiConfig.model}+rules/${_ruleFallback.version}';

  @override
  bool get isReady => _ready;

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool _isRateLimit(String message) {
    final lower = message.toLowerCase();
    return lower.contains('429')
        || lower.contains('quota')
        || lower.contains('rate')
        || lower.contains('resource_exhausted');
  }

  /// Determina si la cuota agotada es diaria (no reintentar hasta mañana)
  /// o por minuto (reintentar según retryDelay indicado por la API).
  void _applyQuotaCooldown(String message) {
    final isDaily = message.contains('PerDay') ||
        message.contains('per_day') ||
        message.contains('limit: 0');

    if (isDaily) {
      // Congelar hasta la medianoche UTC (reset de cuota de Google)
      final now = DateTime.now().toUtc();
      final midnight = DateTime.utc(now.year, now.month, now.day + 1);
      _rateLimitedUntil = midnight;
      _status = GeminiStatus.dailyQuotaExhausted;
      return;
    }

    // Intentar parsear el retryDelay indicado por la API: "retry in 40.7s"
    final parsed = _parseRetryDelay(message);
    final pause  = parsed != null && parsed > _dailyThreshold
        ? parsed          // si el delay es muy largo, también es cuota diaria
        : parsed ?? _defaultRateLimit;

    _rateLimitedUntil = DateTime.now().add(pause);
    _status = parsed != null && parsed > _dailyThreshold
        ? GeminiStatus.dailyQuotaExhausted
        : GeminiStatus.rateLimited;
  }

  /// Extrae el delay de "Please retry in 40.776844234s" → Duration(seconds: 41)
  Duration? _parseRetryDelay(String message) {
    final match = RegExp(r'retry in ([\d.]+)s', caseSensitive: false)
        .firstMatch(message);
    if (match == null) return null;
    final secs = double.tryParse(match.group(1) ?? '');
    if (secs == null) return null;
    // Add 10% buffer so we don't retry right at the limit boundary
    return Duration(milliseconds: ((secs * 1.1) * 1000).round());
  }

  List<Recommendation> _parseResponse(String? text) {
    if (text == null || text.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(text.trim());
      final rawList = switch (decoded) {
        {'recommendations': final List list} => list,
        final List list                      => list,
        _                                    => <dynamic>[],
      };
      return rawList
          .whereType<Map<String, dynamic>>()
          .map(_mapToRecommendation)
          .whereType<Recommendation>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Recommendation? _mapToRecommendation(Map<String, dynamic> r) {
    try {
      final action      = (r['action']      as String?)?.trim() ?? '';
      final levelStr    = (r['alertLevel']  as String?)?.trim() ?? 'info';
      final confidence  = (r['confidence']  as num?)?.toDouble() ?? 0.75;
      final explanation = (r['explanation'] as String?)?.trim() ?? '';
      final rawActions  = r['suggestedActions'];
      final suggested   = rawActions is List
          ? rawActions.whereType<String>().toList()
          : <String>[];

      if (action.isEmpty || explanation.isEmpty) return null;

      return Recommendation(
        ruleId:           'gemini_$action',
        action:           action,
        alertLevel:       _parseAlertLevel(levelStr),
        confidence:       confidence.clamp(0.0, 1.0),
        explanation:      explanation,
        suggestedActions: suggested,
        parameters:       const {},
        generatedAt:      DateTime.now(),
      );
    } catch (_) {
      return null;
    }
  }

  AlertLevel _parseAlertLevel(String raw) => switch (raw.toLowerCase()) {
        'critical' => AlertLevel.critical,
        'high'     => AlertLevel.high,
        'warning'  => AlertLevel.warning,
        'info'     => AlertLevel.info,
        _          => AlertLevel.none,
      };
}
