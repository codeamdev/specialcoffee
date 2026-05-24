# Arquitectura Técnica — SpecialCoffee AI
## Flutter + AI-Core System Design

**Versión:** 1.0 | **Fecha:** 30 de abril de 2026
**Autor:** Senior Software Architect
**Clasificación:** Documento técnico interno

---

## Decisión de arquitectura en una línea

> Clean Architecture con organización Feature-First, donde el AI Engine es una capa transversal de dominio — no un servicio, no un módulo: es el cerebro que todos los features consultan.

La diferencia crítica frente a una arquitectura típica: la IA no es llamada por los features; los features se construyen *sobre* la IA. El RuleEngine y el AlertEngine son dependencias de dominio, equivalentes en jerarquía a los repositorios.

---

## 1. Vista de 10,000 metros

```
╔══════════════════════════════════════════════════════════════════╗
║                        USUARIO                                    ║
╠══════════════════════════════════════════════════════════════════╣
║                   PRESENTATION LAYER                              ║
║   Widgets · Pages · Riverpod UI Providers · Design System         ║
╠══════════════════════════════════════════════════════════════════╣
║                   APPLICATION LAYER                               ║
║   Use Cases · AI Orchestrator · Event Bus · DTOs                  ║
╠══════════════════╦═══════════════════════════════════════════════╣
║   DOMAIN LAYER   ║           AI ENGINE (CORE)                    ║
║                  ║                                               ║
║   Entities       ║   RuleEngine                                  ║
║   Value Objects  ║   ContextBuilder                              ║
║   Repo Interfaces║   AlertEngine                                 ║
║   Domain Events  ║   RecommendationOrchestrator                  ║
║                  ║   InferenceAdapter (ML boundary)              ║
╠══════════════════╩═══════════════════════════════════════════════╣
║                    DATA LAYER                                     ║
║                                                                   ║
║   ┌─────────────────┐   ┌──────────────┐   ┌─────────────────┐  ║
║   │  Local (Drift)  │   │   Firebase   │   │  External APIs  │  ║
║   │  SQLite offline │   │  Firestore   │   │  Weather, GPS   │  ║
║   │  Hive (rules)   │   │  Auth · FCM  │   │  Remote Config  │  ║
║   └─────────────────┘   └──────────────┘   └─────────────────┘  ║
╚══════════════════════════════════════════════════════════════════╝
```

---

## 2. Clean Architecture: las cuatro capas en detalle

### 2.1 Domain Layer — el núcleo inmutable

La capa de dominio no conoce Flutter, no conoce Firebase, no conoce HTTP. Es Dart puro. Aquí viven las reglas del negocio del café.

```
domain/
├── entities/
│   ├── lot.dart               # Lote de producción
│   ├── farm_plot.dart         # Parcela con altitud, variedad
│   ├── fermentation_reading.dart
│   ├── drying_reading.dart
│   ├── brew_session.dart
│   ├── coffee_profile.dart    # Perfil sensorial
│   └── sca_score.dart        # Entidad de puntaje SCA
│
├── value_objects/
│   ├── brix_level.dart        # Validación: 0–35°, no negativo
│   ├── ph_value.dart          # Validación: 0–14
│   ├── altitude.dart          # msnm con ajustes de ebullición
│   ├── humidity_percentage.dart
│   └── tds_percentage.dart
│
├── repositories/              # Interfaces — no implementaciones
│   ├── i_lot_repository.dart
│   ├── i_brew_session_repository.dart
│   ├── i_weather_repository.dart
│   └── i_rule_repository.dart # Acceso a las reglas del engine
│
└── events/                    # Domain Events para el event bus
    ├── fermentation_alert_triggered.dart
    ├── drying_target_reached.dart
    ├── brew_session_completed.dart
    └── lot_quality_predicted.dart
```

**Por qué Value Objects y no primitivos:**
Un `double` para pH no sabe que no puede ser -1. Un `PhValue` sí. Esto elimina validaciones en capas superiores y hace que las reglas del RuleEngine sean imposibles de llamar con datos inválidos.

```dart
// Mal — pH como double en todos lados
void evaluateFermentation(double ph, double temp) { ... }

// Bien — el compilador rechaza valores inválidos antes de llegar al rule engine
void evaluateFermentation(PhValue ph, CelsiusTemperature temp) { ... }

class PhValue {
  final double value;
  const PhValue._(this.value);

  factory PhValue(double value) {
    if (value < 0 || value > 14) {
      throw DomainException('pH fuera de rango fisiológico: $value');
    }
    return PhValue._(value);
  }

  bool get isCriticalForLavado => value < 3.5;
  bool get isOptimalForAnaerobic => value >= 3.8 && value <= 4.5;
}
```

---

### 2.2 AI Engine Layer — el cerebro transversal

Esta es la diferencia arquitectónica central. El AI Engine vive en la capa de dominio pero es lo suficientemente complejo como para tener su propia sub-arquitectura interna.

```
ai_engine/
├── core/
│   ├── rule_engine.dart               # Evaluador central
│   ├── context_builder.dart           # Ensambla contexto del usuario
│   ├── recommendation_orchestrator.dart
│   └── alert_engine.dart              # Monitor de umbrales en tiempo real
│
├── rules/
│   ├── fermentation_rules.dart        # 80+ reglas de fermentación
│   ├── harvest_rules.dart             # 40+ reglas de cosecha
│   ├── drying_rules.dart              # 50+ reglas de secado
│   ├── brewing_rules.dart             # 120+ reglas de preparación
│   └── storage_rules.dart
│
├── models/
│   ├── ai_rule.dart                   # Estructura de una regla
│   ├── ai_context.dart                # Snapshot de variables en un momento
│   ├── recommendation.dart            # Output del engine
│   └── confidence_score.dart
│
├── adapters/
│   └── inference_adapter.dart         # Boundary para ML futuro (v2.0)
│
└── evaluators/
    ├── condition_evaluator.dart        # Evalúa condiciones individuales
    ├── rule_prioritizer.dart           # Ordena reglas por prioridad/confianza
    └── explanation_builder.dart       # Genera texto en lenguaje natural
```

**Flujo interno del RuleEngine:**

```
INPUT: AIContext (snapshot de todas las variables actuales)
       │
       ▼
ContextBuilder.enrich()    ← agrega clima, GPS, historial
       │
       ▼
RulePrioritizer.rank()     ← ordena reglas aplicables por prioridad
       │
       ▼
ConditionEvaluator.evaluate() ← evalúa condiciones de cada regla
       │
       ├─ reglas que aplican ──────────────────────────────────┐
       │                                                        ▼
       │                                          RecommendationOrchestrator
       │                                          ├── merge conflicting rules
       │                                          ├── calculate confidence
       │                                          └── build explanation
       │
       ▼
OUTPUT: List<Recommendation> ordenadas por confianza + urgencia
```

**Estructura de una regla (AIRule):**

```dart
@freezed
class AIRule with _$AIRule {
  const factory AIRule({
    required String id,
    required String module,        // 'fermentation' | 'drying' | 'brewing'
    required int priority,         // 1=crítica, 5=informativa
    required List<RuleCondition> conditions,
    required RuleLogic logic,      // AND | OR | CUSTOM
    required RuleOutcome outcome,
    required double confidenceBase,
    @Default([]) List<String> tags,
    String? supersedes,            // ID de regla que esta reemplaza
  }) = _AIRule;

  factory AIRule.fromJson(Map<String, dynamic> json) =>
      _$AIRuleFromJson(json);
}

@freezed
class RuleCondition with _$RuleCondition {
  const factory RuleCondition({
    required String variable,
    required ConditionOperator operator,
    required dynamic threshold,
    double? thresholdMax,   // para operador BETWEEN
  }) = _RuleCondition;
}

@freezed
class RuleOutcome with _$RuleOutcome {
  const factory RuleOutcome({
    required String action,
    required AlertLevel alertLevel,
    required Map<UserRole, String> explanationByRole,  // texto por rol
    required List<String> suggestedActions,
    Map<String, dynamic>? parameters,                  // datos extra tipados
  }) = _RuleOutcome;
}
```

**InferenceAdapter — el boundary hacia ML:**

```dart
// Hoy: rule-based puro
// v2.0: el mismo contrato, implementación diferente

abstract class InferenceAdapter {
  Future<QualityPrediction> predictSCAScore(LotContext context);
  Future<ProcessRecommendation> recommendProcess(FarmContext context);
  bool get supportsOfflineInference;
}

// MVP: implementación rule-based
class RuleBasedInferenceAdapter implements InferenceAdapter {
  final RuleEngine _engine;
  // ...
}

// v2.0: misma interfaz, TFLite debajo
class TFLiteInferenceAdapter implements InferenceAdapter {
  final Interpreter _interpreter;
  // ...
}
```

El día que se quiera activar ML, se cambia la implementación registrada en el DI. Cero cambios en capas superiores.

---

### 2.3 Application Layer — los casos de uso

Un use case = una acción del usuario. Sin lógica de UI, sin lógica de datos. Solo orquestación.

```
application/
├── lot_management/
│   ├── create_lot_use_case.dart
│   ├── record_fermentation_reading_use_case.dart
│   ├── record_drying_reading_use_case.dart
│   └── close_lot_with_sca_score_use_case.dart
│
├── ai_recommendations/
│   ├── get_harvest_recommendation_use_case.dart
│   ├── get_fermentation_recommendation_use_case.dart
│   ├── get_process_recommendation_use_case.dart
│   └── get_lot_quality_prediction_use_case.dart
│
├── brewing/
│   ├── start_brew_session_use_case.dart
│   ├── get_brew_recipe_use_case.dart          # llama al AI engine
│   ├── record_brew_result_use_case.dart
│   └── diagnose_extraction_use_case.dart      # post-TDS análisis
│
└── alerts/
    ├── subscribe_to_lot_alerts_use_case.dart
    └── dismiss_alert_use_case.dart
```

**Ejemplo de use case real:**

```dart
class RecordFermentationReadingUseCase {
  final ILotRepository _lotRepo;
  final RuleEngine _ruleEngine;
  final AlertEngine _alertEngine;
  final EventBus _eventBus;

  Future<RecordingResult> execute(FermentationReadingInput input) async {
    // 1. Validar y persistir la lectura
    final reading = FermentationReading(
      ph: PhValue(input.ph),
      temperature: CelsiusTemperature(input.temperature),
      mucilageState: input.mucilageState,
      timestamp: DateTime.now(),
    );
    await _lotRepo.addFermentationReading(input.lotId, reading);

    // 2. Construir contexto completo para la IA
    final lot = await _lotRepo.getLotById(input.lotId);
    final context = AIContext.fromLotAndReading(lot, reading);

    // 3. Evaluar reglas
    final recommendations = await _ruleEngine.evaluate(context);

    // 4. Verificar alertas críticas (siempre, incluso offline)
    final alerts = _alertEngine.checkThresholds(context);
    if (alerts.hasCritical) {
      _eventBus.fire(FermentationAlertTriggered(
        lotId: input.lotId,
        alert: alerts.critical!,
      ));
    }

    return RecordingResult(
      recommendations: recommendations,
      alerts: alerts,
      projectedEndTime: _ruleEngine.projectFermentationEnd(lot),
    );
  }
}
```

---

### 2.4 Presentation Layer

```
presentation/
├── features/
│   ├── lot_management/
│   │   ├── pages/
│   │   ├── widgets/
│   │   └── providers/          # Riverpod providers específicos del feature
│   ├── fermentation/
│   ├── drying/
│   ├── brewing/
│   └── dashboard/
│
├── shared/
│   ├── design_system/
│   │   ├── tokens/             # colores, tipografía, espaciado
│   │   ├── components/         # Button, Card, AlertBanner, etc.
│   │   └── role_theme/         # tema visual por rol de usuario
│   └── widgets/
│       ├── ai_recommendation_card.dart
│       ├── alert_banner.dart
│       └── confidence_indicator.dart
│
└── core/
    ├── router/                 # GoRouter config
    ├── observers/              # NavigatorObserver para analytics
    └── l10n/                  # internacionalización
```

---

## 3. Manejo de Estado: Riverpod 2.x

### Por qué Riverpod sobre Bloc

Esta decisión no es de preferencia sino de fit arquitectónico.

| Criterio | Riverpod | Bloc |
|---|---|---|
| Estado derivado de múltiples fuentes | Nativo (providers compuestos) | Manual, boilerplate alto |
| Async + streams combinados | `AsyncNotifier`, `StreamProvider` | `StreamBloc`, más verboso |
| Contexto de IA que se construye de varias fuentes | Providers anidados naturalmente | Requiere BlocListener chains |
| Acceso fuera del widget tree (use cases) | Sí, `ProviderContainer` | No sin workarounds |
| Testing de providers | `ProviderContainer` aislado | `MockBloc`, más setup |
| Curva de aprendizaje para el equipo | Media | Alta (eventos/estados explícitos) |

**El argumento determinante:** El AIContext se construye a partir de 5–8 fuentes de datos simultáneas (lote, clima, historial, GPS, preferencias de usuario, lecturas en tiempo real). Con Riverpod, esto es un `Provider` que `ref.watch` a otros providers. Con Bloc, serías gestionando BlocListeners de 5 Blocs diferentes y sincronizándolos manualmente. La complejidad cognitiva se dispara.

### Estrategia de providers por capa

```dart
// ── CAPA DE DATOS ──────────────────────────────────────────
// Repositorios: singleton, un provider por repositorio
final lotRepositoryProvider = Provider<ILotRepository>((ref) {
  return LotRepositoryImpl(
    local: ref.watch(localDatabaseProvider),
    remote: ref.watch(firestoreProvider),
    syncQueue: ref.watch(syncQueueProvider),
  );
});

// ── CAPA DE AI ENGINE ───────────────────────────────────────
// El contexto de IA se reconstruye reactivamente cuando cambia cualquier input
final aiContextProvider = FutureProvider.family<AIContext, String>((ref, lotId) async {
  final lot = await ref.watch(lotProvider(lotId).future);
  final weather = await ref.watch(weatherProvider.future);
  final preferences = ref.watch(userPreferencesProvider);

  return AIContext(lot: lot, weather: weather, preferences: preferences);
});

// Las recomendaciones son derivadas del contexto — se recomputan solas
final fermentationRecommendationsProvider =
    FutureProvider.family<List<Recommendation>, String>((ref, lotId) async {
  final context = await ref.watch(aiContextProvider(lotId).future);
  final engine = ref.watch(ruleEngineProvider);
  return engine.evaluate(context);
});

// ── ALERTAS — stream permanente ────────────────────────────
// Corre mientras hay un lote activo, sin importar qué pantalla está visible
final activeLotAlertsProvider =
    StreamProvider.family<List<Alert>, String>((ref, lotId) {
  final alertEngine = ref.watch(alertEngineProvider);
  return alertEngine.watchLot(lotId);   // Stream que evalúa cada nueva lectura
});

// ── PRESENTACIÓN ────────────────────────────────────────────
// Los notifiers de UI consumen use cases, no repositorios directamente
@riverpod
class FermentationController extends _$FermentationController {
  @override
  FermentationState build(String lotId) => FermentationState.initial();

  Future<void> recordReading(FermentationReadingInput input) async {
    state = state.copyWith(isLoading: true);
    final useCase = ref.read(recordFermentationReadingUseCaseProvider);
    final result = await useCase.execute(input);

    state = state.copyWith(
      isLoading: false,
      latestRecommendations: result.recommendations,
      alerts: result.alerts,
      projectedEndTime: result.projectedEndTime,
    );
  }
}
```

### Árbol de providers (diagrama de dependencias)

```
weatherProvider ─────────────────────────────────────────────────┐
userPreferencesProvider ──────────────────────────────────────┐  │
historicalLotsProvider ──────────────────────────────────────┐ │  │
gpsAltitudeProvider ────────────────────────────────────────┐│ │  │
                                                             ││ │  │
lotProvider(id) ────────────────────────────────────────┐   ││ │  │
                                                         │   ││ │  │
                                              aiContextProvider(id)
                                                         │
                          ┌──────────────────────────────┤
                          │                              │
            fermentationRecommendationsProvider    alertEngineProvider
                          │
                 FermentationController (UI)
                          │
                    FermentationPage (Widget)
```

---

## 4. Motor de IA: diseño detallado

### 4.1 Dónde vive el rule engine

**Decisión: 100% en el dispositivo, en Dart puro.**

```
¿Por qué no en el backend?

  Latencia:  Una recomendación que tarda 300ms en un campo sin 4G
             destruye la UX. En device: < 5ms.

  Offline:   El caficultor está en el campo a las 2am con pH en 3.7.
             No hay WiFi. La alerta debe funcionar.

  Costo:     Cada lectura de fermentación (cada 4h por 30h) no puede
             ser un round-trip a un servidor.

  Privacidad: Los datos de la finca del productor no deben salir del
              dispositivo para generar recomendaciones básicas.

¿Entonces el backend no hace nada de IA?

  El backend agrega datos anónimos para calibrar el engine y
  futuramente entrenar modelos ML. Pero la inferencia siempre
  empieza en device.
```

**Arquitectura de actualización de reglas:**

```
Firebase Remote Config
        │
        │ (reglas como JSON versionado)
        ▼
RuleConfigRepository
        │
        │ (al inicio de sesión o una vez al día)
        ▼
Hive (cache local de reglas)
        │
        │ (en memoria durante la sesión)
        ▼
RuleEngine.loadRules()

Ventaja: las reglas se pueden actualizar sin publicar un nuevo
build. Un Q Grader detecta un error en una regla de fermentación
→ se corrige el JSON en Remote Config → todos los usuarios
tienen la regla correcta en su próxima apertura de la app.
```

### 4.2 Estructura JSON de una regla (Remote Config)

```json
{
  "id": "FERM-PH-CRITICAL-001",
  "version": "1.2.0",
  "module": "fermentation",
  "priority": 1,
  "tags": ["critical", "ph", "lavado"],
  "active": true,
  "conditions": [
    {
      "variable": "current_ph",
      "operator": "lt",
      "threshold": 3.5
    },
    {
      "variable": "fermentation_process",
      "operator": "eq",
      "threshold": "lavado"
    },
    {
      "variable": "fermentation_status",
      "operator": "eq",
      "threshold": "active"
    }
  ],
  "logic": "AND",
  "outcome": {
    "action": "STOP_FERMENTATION",
    "alert_level": "critical",
    "confidence_base": 0.97,
    "explanations": {
      "farmer": "El pH bajó demasiado. Detenga la fermentación ahora y lave bien el café con agua limpia.",
      "processor": "pH < 3.5 en proceso lavado. Sobrefermentación activa. Detener y lavar inmediatamente para prevenir defecto vinagre.",
      "barista": "pH crítico en fermentación. Lote en riesgo de defecto acético (vinagre). Requiere intervención inmediata."
    },
    "suggested_actions": [
      "Detener fermentación inmediatamente",
      "Trasladar el café a canal de lavado con agua fresca",
      "Registrar el incidente en el log del lote"
    ],
    "parameters": {
      "urgency_hours": 1,
      "requires_confirmation_to_dismiss": true
    }
  }
}
```

### 4.3 Flujo de evaluación con múltiples reglas

```dart
class RuleEngine {
  List<AIRule> _rules = [];

  Future<List<Recommendation>> evaluate(AIContext context) async {
    // 1. Filtrar reglas aplicables al módulo y estado actual
    final applicableRules = _rules
        .where((r) => r.module == context.module && r.active)
        .toList();

    // 2. Evaluar condiciones de cada regla
    final firedRules = applicableRules
        .where((rule) => _conditionEvaluator.allMet(rule.conditions, context))
        .toList();

    // 3. Resolver conflictos (dos reglas que sugieren acciones opuestas)
    final resolvedRules = _conflictResolver.resolve(firedRules);

    // 4. Calcular confianza ajustada por contexto
    //    (una regla de pH tiene más confianza si también hay datos de temperatura)
    final scored = resolvedRules.map((rule) {
      final contextBonus = _confidenceAdjuster.adjust(rule, context);
      return rule.withConfidence(rule.confidenceBase + contextBonus);
    }).toList();

    // 5. Ordenar: críticas primero, luego por confianza
    scored.sort((a, b) {
      if (a.outcome.alertLevel != b.outcome.alertLevel) {
        return a.outcome.alertLevel.index.compareTo(b.outcome.alertLevel.index);
      }
      return b.confidence.compareTo(a.confidence);
    });

    // 6. Construir Recommendations con texto personalizado por rol del usuario
    return scored.map((rule) =>
      _explanationBuilder.build(rule, context.userRole)
    ).toList();
  }
}
```

### 4.4 AlertEngine — el monitor permanente

```dart
// El AlertEngine corre en segundo plano, independiente de la pantalla activa
class AlertEngine {
  Stream<List<Alert>> watchLot(String lotId) {
    return _lotRepository
        .watchFermentationReadings(lotId)  // Stream de Drift (SQLite)
        .map((readings) {
          if (readings.isEmpty) return <Alert>[];
          final latest = readings.last;
          return _evaluateThresholds(latest, _getLotContext(lotId));
        })
        .distinct();  // Solo emite si las alertas cambian
  }

  List<Alert> _evaluateThresholds(FermentationReading reading, LotContext ctx) {
    final alerts = <Alert>[];

    // Evaluación directa de umbrales — sin pasar por el rule engine completo
    // (más rápido para monitoreo continuo)
    if (reading.ph.isCriticalForProcess(ctx.process)) {
      alerts.add(Alert.critical(
        type: AlertType.phCritical,
        value: reading.ph.value,
        lotId: ctx.lotId,
      ));
    }
    if (reading.temperature.isHighRisk) {
      alerts.add(Alert.high(
        type: AlertType.temperatureHigh,
        value: reading.temperature.value,
      ));
    }

    return alerts;
  }
}
```

---

## 5. Backend: Firebase + arquitectura de sync

### 5.1 Justificación de Firebase sobre alternativas

```
¿Por qué Firebase y no Supabase o backend custom?

SUPABASE:
  ✅ SQL real (más flexible para queries complejos)
  ✅ Open source, sin vendor lock-in
  ❌ Offline sync es responsabilidad del desarrollador
  ❌ FCM (push) requiere integración adicional
  ❌ Remote Config no existe — habría que construirlo
  ❌ El equipo de finca tiene Android variado — necesitamos
     offline robusto desde el día 1, no en v2.0

BACKEND CUSTOM (FastAPI/Node):
  ✅ Control total
  ✅ ML integración nativa
  ❌ 6–8 semanas adicionales de infra antes del primer feature
  ❌ Offline sync es un proyecto entero por sí solo
  ❌ Push notifications, auth, hosting — todo desde cero

FIREBASE:
  ✅ Offline persistence nativo en Firestore SDK
  ✅ FCM integrado — alertas nocturnas sin backend propio
  ✅ Remote Config — actualización de reglas sin build
  ✅ Firebase Auth — multi-provider en días, no semanas
  ✅ Security Rules — lógica de acceso sin servidor
  ❌ Costo escala con lecturas (mitigado con cache local agresivo)
  ❌ Queries complejos limitados (mitigado con Drift local)

DECISIÓN: Firebase para MVP. Diseñar la capa de repositorios con
interfaz abstracta para migración parcial a backend custom en v2.0
cuando el volumen justifique el costo de infraestructura.
```

### 5.2 Arquitectura de sync offline-first

```
ESCRITURA (usuario en campo, sin red):

  UI → UseCase → Repository
                    │
                    ├──▶ Drift (SQLite) local  ← SIEMPRE primero
                    │    [escritura inmediata, UI responde < 10ms]
                    │
                    └──▶ SyncQueue.enqueue()
                              │
                              │ (cuando hay red)
                              ▼
                         FirestoreRepository.sync()
                              │
                         Firestore (cloud)


LECTURA:

  UI → UseCase → Repository
                    │
                    ├──▶ Drift (SQLite) local  ← fuente primaria
                    │    [siempre disponible offline]
                    │
                    └──▶ Firestore (si online + datos stale > threshold)
                              │
                              ▼
                         actualiza Drift → UI recibe via Stream


CONFLICTOS:

  Política: Last-Write-Wins con timestamp del dispositivo
  Excepción: lecturas de fermentación — APPEND ONLY (nunca se sobreescriben)
  En conflicto detectado: notificación al usuario con diff visual
```

**SyncQueue — estructura:**

```dart
@DriftDatabase(tables: [SyncOperations])
class SyncQueue {
  // Cada operación pendiente es una fila en SQLite
  // Si la app se cierra, la cola persiste y continúa al reabrir
}

@DataClassName('SyncOperation')
class SyncOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get operationType => text()();   // 'create' | 'update' | 'delete'
  TextColumn get collection => text()();
  TextColumn get documentId => text()();
  TextColumn get payload => text()();          // JSON serializado
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}
```

### 5.3 Estructura de Firestore

```
firestore/
│
├── users/{userId}
│   ├── role: 'farmer' | 'processor' | 'barista' | 'entrepreneur'
│   ├── region: 'huila' | 'antioquia' | ...
│   ├── preferences: { units, language, notification_schedule }
│   └── ai_profile: { tds_preference_min, tds_preference_max, ... }
│
├── farm_plots/{plotId}                    # Parcelas
│   ├── owner_id: userId
│   ├── name: 'El Paraíso'
│   ├── altitude_masl: 1850
│   ├── variety: 'castillo'
│   ├── area_hectares: 2.3
│   └── location: GeoPoint
│
├── lots/{lotId}                            # Lotes de producción
│   ├── plot_id: plotId
│   ├── owner_id: userId
│   ├── created_at: Timestamp
│   ├── status: 'harvesting'|'fermenting'|'drying'|'stored'|'closed'
│   ├── process_type: 'lavado'|'natural'|'honey'|'anaerobic'
│   ├── harvest_weight_kg: 480
│   ├── sca_score: null | 86.5
│   └── ai_predicted_score: 84.2
│
├── lots/{lotId}/fermentation_readings/{readingId}
│   ├── ph: 4.8
│   ├── temperature_c: 19.2
│   ├── mucilage_state: 'viscous'
│   └── recorded_at: Timestamp
│
├── lots/{lotId}/drying_readings/{readingId}
│   ├── humidity_pct: 38.5
│   ├── ambient_temp_c: 24.0
│   └── recorded_at: Timestamp
│
├── brew_sessions/{sessionId}
│   ├── user_id: userId
│   ├── lot_id: lotId | null
│   ├── method: 'v60' | 'chemex' | 'french_press' | 'espresso' | 'aeropress' | 'moka'
│   ├── dose_g: 20.0
│   ├── water_g: 310.0
│   ├── water_temp_c: 89.0
│   ├── grind_setting: 17.5
│   ├── tds_pct: 1.35
│   ├── extraction_yield_pct: 21.2
│   ├── sensory_scores: { acidity: 7, sweetness: 8, body: 6, aftertaste: 7, overall: 8 }
│   ├── ai_recipe_used: true
│   ├── ai_recommendations_followed: 2    # de 3 sugeridas
│   └── created_at: Timestamp
│
└── rule_effectiveness/{ruleId}            # Colección para calibrar el engine
    ├── rule_id: 'FERM-PH-CRITICAL-001'
    ├── times_fired: 1247
    ├── times_followed: 891
    ├── avg_sca_when_followed: 84.3
    └── avg_sca_when_ignored: 79.1        # dato para justificar ML futuro
```

---

## 6. Base de Datos Local: Drift (SQLite)

### Por qué Drift sobre Hive para datos estructurados

```
HIVE (NoSQL key-value):
  ✅ Extremadamente rápido para lecturas simples
  ✅ Bueno para preferencias y caché
  ❌ Sin relaciones entre entidades
  ❌ Sin queries complejos (no puedes hacer JOIN)
  ❌ Sin migraciones de esquema formales

DRIFT (SQLite + type-safe):
  ✅ Relaciones reales entre tablas (lote → lecturas)
  ✅ Queries con WHERE, ORDER BY, GROUP BY en Dart type-safe
  ✅ Streams reactivos — la UI se actualiza sola cuando cambian los datos
  ✅ Migraciones de esquema versionadas
  ✅ Transacciones atómicas (crítico para operaciones de sync)

USO COMBINADO:
  Drift → datos de negocio (lotes, lecturas, sesiones)
  Hive  → reglas del AI engine (JSON, acceso frecuente, sin relaciones)
          preferencias de usuario, caché de clima
```

### Esquema local (tablas Drift)

```dart
// Tablas principales

class FarmPlots extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  RealColumn get altitudeMasl => real()();
  TextColumn get variety => text()();
  RealColumn get areaHectares => real()();
  TextColumn get ownerId => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class Lots extends Table {
  TextColumn get id => text()();
  TextColumn get plotId => text().references(FarmPlots, #id)();
  TextColumn get status => text()();
  TextColumn get processType => text()();
  RealColumn get harvestWeightKg => real()();
  RealColumn get scaScore => real().nullable()();
  RealColumn get aiPredictedScore => real().nullable()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

class FermentationReadings extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get lotId => text().references(Lots, #id)();
  RealColumn get ph => real()();
  RealColumn get temperatureC => real()();
  TextColumn get mucilageState => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get recordedAt => dateTime()();
}

class BrewSessions extends Table {
  TextColumn get id => text()();
  TextColumn get userId => text()();
  TextColumn get lotId => text().nullable()();
  TextColumn get method => text()();
  RealColumn get doseG => real()();
  RealColumn get waterG => real()();
  RealColumn get waterTempC => real()();
  RealColumn get grindSetting => real()();
  RealColumn get tdsPct => real().nullable()();
  RealColumn get extractionYieldPct => real().nullable()();
  TextColumn get sensoryScoresJson => text().nullable()();  // JSON
  BoolColumn get aiRecipeUsed => boolean().withDefault(const Constant(false))();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
```

**Query reactiva ejemplo — lecturas de fermentación en tiempo real:**

```dart
// Drift genera un Stream — la UI se actualiza automáticamente con cada lectura
Stream<List<FermentationReading>> watchFermentationReadings(String lotId) {
  return (select(fermentationReadings)
    ..where((r) => r.lotId.equals(lotId))
    ..orderBy([(r) => OrderingTerm.asc(r.recordedAt)])
  ).watch();
}
```

---

## 7. Integraciones Externas

### 7.1 API de clima — OpenWeatherMap

```
ESTRATEGIA DE INTEGRACIÓN:

  Online:  GET /forecast?lat={lat}&lon={lon}&cnt=10
           Datos cada 3h para los próximos 5 días
           Caché en Hive por 2 horas

  Offline: Último forecast cacheado
           Si > 24h sin actualizar: banner "Datos de clima desactualizados"
           Fallback: usuario ingresa temperatura manualmente
           (el flujo NUNCA se bloquea por falta de clima)

DATOS QUE USA EL AI ENGINE:
  • temp_c_current     → ajuste inmediato de recomendaciones
  • temp_c_forecast_72h → planificación de secado
  • humidity_pct       → método de secado recomendado
  • rain_probability   → ventana de cosecha (si > 60%: urgencia)
  • uv_index           → exposición solar en camas africanas
```

**Implementación del repositorio con fallback:**

```dart
class WeatherRepositoryImpl implements IWeatherRepository {
  final WeatherApiClient _api;
  final HiveBox _cache;

  @override
  Future<WeatherForecast> getForecast(GeoCoordinates location) async {
    // 1. Intentar red
    try {
      final forecast = await _api.fetchForecast(location);
      await _cache.put('last_forecast', forecast.toJson());
      await _cache.put('forecast_timestamp', DateTime.now().toIso8601String());
      return forecast;
    } catch (e) {
      // 2. Fallback a cache
      final cached = _cache.get('last_forecast');
      if (cached != null) {
        return WeatherForecast.fromJson(cached)
            .copyWith(isStale: true);  // UI puede mostrar advertencia
      }
      // 3. Fallback final — forecast vacío, IA usa solo datos manuales
      return WeatherForecast.empty();
    }
  }
}
```

### 7.2 GPS — Altitud automática

```dart
final gpsAltitudeProvider = FutureProvider<double?>((ref) async {
  try {
    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );
    return position.altitude;
  } catch (_) {
    return null;  // usuario ingresa altitud manualmente
  }
});
```

### 7.3 Firebase Remote Config — actualizaciones de reglas IA

```dart
class RuleConfigRepository {
  final FirebaseRemoteConfig _remoteConfig;
  final HiveBox _rulesCache;

  Future<List<AIRule>> fetchRules() async {
    await _remoteConfig.fetchAndActivate();

    final version = _remoteConfig.getString('rules_version');
    final cachedVersion = _rulesCache.get('version');

    // Solo actualiza si hay nueva versión (evita parsing innecesario)
    if (version == cachedVersion) {
      return _loadFromCache();
    }

    final rulesJson = _remoteConfig.getString('production_rules');
    final rules = (jsonDecode(rulesJson) as List)
        .map((r) => AIRule.fromJson(r))
        .toList();

    await _rulesCache.put('rules', rulesJson);
    await _rulesCache.put('version', version);

    return rules;
  }
}
```

---

## 8. Estructura Completa de Carpetas Flutter

```
lib/
│
├── main.dart
├── app.dart                          # MaterialApp, Router, Providers raíz
│
├── core/                             # Infraestructura compartida
│   ├── di/
│   │   └── providers.dart            # Registro de dependencias Riverpod
│   ├── router/
│   │   ├── app_router.dart           # GoRouter config
│   │   └── routes.dart               # Constantes de rutas
│   ├── error/
│   │   ├── failures.dart             # Clases de error del dominio
│   │   └── error_handler.dart
│   ├── network/
│   │   ├── connectivity_provider.dart
│   │   └── sync_queue.dart
│   ├── storage/
│   │   ├── local_database.dart       # Drift database class
│   │   └── hive_boxes.dart
│   └── utils/
│       ├── date_utils.dart
│       └── unit_converter.dart       # kg/lb, °C/°F
│
├── domain/                           # Capa de dominio — Dart puro
│   ├── entities/
│   ├── value_objects/
│   ├── repositories/
│   └── events/
│
├── ai_engine/                        # Motor de IA — capa transversal
│   ├── core/
│   │   ├── rule_engine.dart
│   │   ├── context_builder.dart
│   │   ├── recommendation_orchestrator.dart
│   │   └── alert_engine.dart
│   ├── rules/
│   │   ├── fermentation_rules.dart
│   │   ├── harvest_rules.dart
│   │   ├── drying_rules.dart
│   │   ├── brewing_rules.dart
│   │   └── storage_rules.dart
│   ├── models/
│   │   ├── ai_rule.dart
│   │   ├── ai_context.dart
│   │   ├── recommendation.dart
│   │   └── alert.dart
│   ├── adapters/
│   │   └── inference_adapter.dart    # Boundary para ML futuro
│   └── evaluators/
│       ├── condition_evaluator.dart
│       ├── rule_prioritizer.dart
│       ├── conflict_resolver.dart
│       └── explanation_builder.dart
│
├── application/                      # Casos de uso
│   ├── lot_management/
│   ├── ai_recommendations/
│   ├── brewing/
│   └── alerts/
│
├── data/                             # Implementaciones de repositorios
│   ├── repositories/
│   │   ├── lot_repository_impl.dart
│   │   ├── brew_session_repository_impl.dart
│   │   ├── weather_repository_impl.dart
│   │   └── rule_config_repository.dart
│   ├── local/
│   │   ├── daos/                     # Data Access Objects de Drift
│   │   │   ├── lots_dao.dart
│   │   │   ├── fermentation_dao.dart
│   │   │   └── brew_sessions_dao.dart
│   │   └── tables/                   # Definición de tablas Drift
│   ├── remote/
│   │   ├── firestore/
│   │   │   ├── firestore_lot_source.dart
│   │   │   └── firestore_session_source.dart
│   │   └── api/
│   │       └── weather_api_client.dart
│   └── mappers/                      # Entity ↔ DTO ↔ DB Model
│       ├── lot_mapper.dart
│       └── brew_session_mapper.dart
│
└── presentation/                     # UI
    ├── features/
    │   ├── onboarding/
    │   │   ├── pages/
    │   │   └── providers/
    │   ├── dashboard/
    │   │   ├── pages/
    │   │   │   └── dashboard_page.dart
    │   │   └── providers/
    │   │       └── dashboard_provider.dart
    │   ├── lot_management/
    │   │   ├── pages/
    │   │   │   ├── lot_list_page.dart
    │   │   │   ├── create_lot_page.dart
    │   │   │   └── lot_detail_page.dart
    │   │   ├── widgets/
    │   │   └── providers/
    │   ├── fermentation/
    │   │   ├── pages/
    │   │   │   └── fermentation_tracking_page.dart
    │   │   ├── widgets/
    │   │   │   ├── ph_chart.dart
    │   │   │   ├── fermentation_timer.dart
    │   │   │   └── recommendation_card.dart
    │   │   └── providers/
    │   │       └── fermentation_controller.dart
    │   ├── drying/
    │   ├── brewing/
    │   │   ├── pages/
    │   │   │   ├── method_selector_page.dart
    │   │   │   ├── brew_guide_page.dart
    │   │   │   └── brew_result_page.dart
    │   │   ├── widgets/
    │   │   │   ├── pour_timer.dart
    │   │   │   └── sensory_slider.dart
    │   │   └── providers/
    │   └── alerts/
    │       └── widgets/
    │           └── critical_alert_overlay.dart
    │
    └── shared/
        ├── design_system/
        │   ├── tokens/
        │   │   ├── colors.dart
        │   │   ├── typography.dart
        │   │   └── spacing.dart
        │   ├── components/
        │   │   ├── sc_button.dart
        │   │   ├── sc_card.dart
        │   │   ├── sc_text_field.dart
        │   │   └── sc_alert_banner.dart
        │   └── role_theme/
        │       └── role_theme_provider.dart   # tema visual por rol
        └── widgets/
            ├── ai_recommendation_card.dart
            ├── confidence_indicator.dart      # barra visual de confianza IA
            ├── offline_indicator.dart
            └── sync_status_badge.dart


test/
├── unit/
│   ├── ai_engine/
│   │   ├── rule_engine_test.dart          # Pruebas críticas
│   │   ├── fermentation_rules_test.dart   # Cada regla tiene su test
│   │   └── alert_engine_test.dart
│   ├── domain/
│   │   └── value_objects_test.dart
│   └── application/
│       └── use_cases_test.dart
├── integration/
│   └── sync_queue_test.dart
└── widget/
    └── recommendation_card_test.dart
```

---

## 9. Diagrama de Flujo: Lectura de Fermentación de Punta a Punta

```
USUARIO INGRESA pH 3.8 + TEMP 29°C (offline, 2am)
│
▼
FermentationTrackingPage
│ (llama al controller)
▼
FermentationController.recordReading()
│
▼
RecordFermentationReadingUseCase.execute()
│
├──[1] FermentationReadingFactory.create()
│       └── PhValue(3.8) → válida ✅
│       └── CelsiusTemperature(29.0) → válida ✅
│
├──[2] LotRepository.addFermentationReading()
│       └── Drift DAO → INSERT en SQLite [< 5ms]
│       └── SyncQueue.enqueue() [para cuando haya red]
│
├──[3] AIContext = ContextBuilder.build(lot, reading)
│       └── lot.processType = 'lavado'
│       └── reading.ph = 3.8
│       └── reading.temperature = 29.0
│       └── weather = [last cached forecast]
│       └── lot.fermentationStartedAt → elapsed = 22h
│
├──[4] RuleEngine.evaluate(context)
│       │
│       ├── FERM-PH-CRITICAL-001: pH < 3.5? → NO (3.8 > 3.5)
│       ├── FERM-PH-HIGH-002: pH < 4.0? → SÍ ⚠️
│       ├── FERM-TEMP-HIGH-001: temp > 27°C? → SÍ ⚠️ (29 > 27)
│       └── FERM-TEMP-CRITICAL-001: temp > 30°C? → NO (29 < 30)
│
│       Recomendaciones resultantes (ordenadas):
│       [1] ⚠️ Alta: "pH llegando a zona límite — revisar en 2h"
│       [2] ⚠️ Alta: "Temperatura elevada — riesgo si sube 1°C más"
│       [3] 🔵 Info: "Fermentación en hora 22 — punto estimado en 2–4h"
│
├──[5] AlertEngine.checkThresholds(context)
│       └── pH 3.8: no crítico (umbral crítico = 3.5) ✅
│       └── Temp 29°C: alerta alta (umbral crítico = 30°C) ⚠️
│       └── NO genera push notification (no es crítico aún)
│       └── Programa revisión: notify en 2h si no hay nueva lectura
│
└──[6] RecordingResult devuelto al Controller
        └── state.latestRecommendations = [las 3 de arriba]
        └── state.projectedEndTime = 02:15 AM (+2h)
        └── state.alerts = [⚠️ temp alta]

PRESENTA EN UI:
  • Gráfico de pH con punto actual marcado (naranja, zona de atención)
  • Banner ⚠️: "Temperatura elevada — monitorear"
  • Card de recomendación con explicación en lenguaje del rol del usuario
  • Countdown: "Próxima lectura recomendada: en 2h (02:15 AM)"
  • [Registrar siguiente lectura] [Ver protocolo completo]

TODO FUNCIONÓ SIN RED. Cero llamadas HTTP.
```

---

## 10. Estrategia de Testing del AI Engine

El rule engine es el componente más crítico del sistema. Un error en una regla de fermentación puede destruir un lote. La estrategia de testing debe ser proporcional a ese riesgo.

```
PIRÁMIDE DE TESTING PARA EL AI ENGINE:

    /\
   /  \  E2E (pocos)
  /────\  Prueba flujos completos con Firebase emulators
 /      \
/────────\ Integration (moderados)
          UseCase + RuleEngine + DAO real (Drift en memoria)
/──────────\
/────────────\ Unit (muchos — CRÍTICO)
              Cada regla individual: condición, outcome, explicación

REGLA: Cada regla de producción tiene al menos 3 tests:
  1. Test de activación — las condiciones correctas la disparan
  2. Test de no-activación — condiciones límite NO la disparan
  3. Test de outcome — el texto de explicación es correcto por rol
```

```dart
// Ejemplo de test de regla crítica
group('FERM-PH-CRITICAL-001 — Fermentación crítica por pH', () {
  late RuleEngine engine;
  late AIContext baseContext;

  setUp(() {
    engine = RuleEngine.withRules([fermentationRules]);
    baseContext = AIContext.forTest(
      module: 'fermentation',
      processType: 'lavado',
      fermentationStatus: 'active',
    );
  });

  test('se activa cuando pH < 3.5 en proceso lavado activo', () async {
    final context = baseContext.copyWith(currentPh: 3.4);
    final recs = await engine.evaluate(context);

    expect(recs.first.ruleId, 'FERM-PH-CRITICAL-001');
    expect(recs.first.alertLevel, AlertLevel.critical);
  });

  test('NO se activa cuando pH = 3.5 (límite exacto no es crítico)', () async {
    final context = baseContext.copyWith(currentPh: 3.5);
    final recs = await engine.evaluate(context);

    expect(recs.any((r) => r.ruleId == 'FERM-PH-CRITICAL-001'), isFalse);
  });

  test('explicación para farmer usa lenguaje simple sin tecnicismos', () async {
    final context = baseContext.copyWith(currentPh: 3.2, userRole: UserRole.farmer);
    final recs = await engine.evaluate(context);

    expect(recs.first.explanation, isNot(contains('ácido acético')));
    expect(recs.first.explanation, contains('Detenga'));
  });
});
```

---

## 11. Escalabilidad hacia ML (v2.0)

### El contrato que mantiene la puerta abierta

```dart
// Este adaptador es el único punto de cambio cuando se active ML
abstract class InferenceAdapter {
  Future<QualityPrediction> predictSCAScore(LotContext context);
  Future<ProcessRecommendation> recommendProcess(FarmContext context);
  bool get supportsOfflineInference;
  String get modelVersion;
}

// v1.0: implementación rule-based
@Riverpod(keepAlive: true)
InferenceAdapter inferenceAdapter(Ref ref) {
  return RuleBasedInferenceAdapter(
    ruleEngine: ref.watch(ruleEngineProvider),
  );
}

// v2.0: misma interfaz, TFLite debajo
// Solo se cambia el provider. Cero cambios en use cases ni UI.
@Riverpod(keepAlive: true)
InferenceAdapter inferenceAdapter(Ref ref) {
  return TFLiteInferenceAdapter(
    interpreter: ref.watch(tfLiteInterpreterProvider),
    fallback: ref.watch(ruleEngineProvider),  // fallback si modelo falla
  );
}
```

### Datos que se colectan hoy para entrenar ML mañana

```
DATO COLECTADO → USO EN ML FUTURO

  lot.processType + fermentation_readings[]
  + lot.scaScore (ground truth)
      → Feature set para predecir puntaje SCA desde variables de proceso

  brew_session.parameters + brew_session.sensoryScores
  + brew_session.aiRecommendationsFollowed
      → Modelo de preferencias personalizado por perfil de usuario

  rule_effectiveness[].avg_sca_when_followed vs ignored
      → Validación empírica de cuáles reglas realmente importan
      → Identificación de reglas incorrectas o de bajo impacto

  weather_at_fermentation_start + fermentation_duration
  + lot.scaScore
      → Correlación clima → proceso → calidad

REQUISITO DE PRIVACIDAD:
  Todos los datos enviados a Firestore para ML son anonimizados.
  El userId se reemplaza por un hash irreversible antes del upload.
  Los datos de geolocalización se redondean a 10km de precisión.
```

---

## 12. Resumen de Decisiones Arquitectónicas

| Decisión | Elegida | Alternativa descartada | Razón principal |
|---|---|---|---|
| Patrón arquitectónico | Clean Architecture + Feature-First | MVC, MVVM simple | Separación de IA como capa de dominio propia |
| State management | Riverpod 2.x | Bloc | Composición de providers para contexto multi-fuente de la IA |
| BD local | Drift (SQLite) | Hive solo | Relaciones entre entidades y queries reactivos |
| Backend | Firebase | Supabase, custom | Offline sync nativo + Remote Config para reglas IA |
| Rule engine ubicación | On-device (Dart) | Backend API | Offline-first no negociable, latencia < 5ms |
| Formato reglas IA | JSON en Remote Config | Hardcoded en Dart | Actualizable sin build, Q Graders pueden ajustar |
| Boundary ML | InferenceAdapter (interfaz) | Implementación directa | Migración a TFLite sin tocar use cases ni UI |
| API clima | OpenWeatherMap + cache Hive | Solo manual | UX mejorada online, sin bloquear offline |

---

*Documento listo para revisión técnica del equipo.*
*Siguiente paso: ADR (Architecture Decision Records) para cada decisión crítica.*

**Próxima revisión:** Sprint 1, semana 2 de desarrollo — validar estructura de carpetas con el equipo Flutter.
