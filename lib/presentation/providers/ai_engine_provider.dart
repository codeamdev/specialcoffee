import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:special_coffee/ai_engine/ai_engine.dart';
import 'package:special_coffee/core/config/gemini_config.dart';

part 'ai_engine_provider.g.dart';

/// Singleton AIEngine, kept alive for the app lifetime.
/// Usa Gemini si [GeminiConfig.isConfigured] es true; si no, Rule Engine puro.
@Riverpod(keepAlive: true)
Future<AIEngine> aiEngine(Ref ref) async {
  final engine = GeminiConfig.isConfigured
      ? AIEngine.withGemini(geminiApiKey: GeminiConfig.apiKey)
      : AIEngine.create();
  await engine.initialize();
  return engine;
}

/// Estado actual de Gemini — activo, rate-limited, cuota diaria, u offline.
/// Se consulta para mostrar el banner de fallback en la UI.
@riverpod
Future<GeminiStatus> geminiStatus(Ref ref) async {
  final engine = await ref.watch(aiEngineProvider.future);
  return engine.geminiStatus;
}
