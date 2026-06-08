# Plan de Ejecución — SpecialCoffee AI
> **Última actualización:** 2026-06-05  
> **Tests:** 352/352 ✅ · **Schema:** Drift v15 · **AllRules:** v1.3.0 · **Bloques cerrados:** A, B, C, D, E, F, G, H  
> **Fuente de verdad de deudas:** `AUDIT.md` · Fuente de pendientes: este archivo

---

## Visión

App móvil con trazabilidad completa farm-to-cup para café de especialidad (≥80 pts SCA). La IA guía cada etapa, avisa cuando actuar, y aprende de cada lote. Roles especializados con vistas y permisos diferenciados.

---

## Qué está cerrado (verificado en AUDIT.md)

| Módulo / Bloque | AUDIT ref | Schema |
|-----------------|-----------|--------|
| Cosecha, Clasificación, Despulpado — IA + UI + tests | B-0, C-4 | v1–v6 |
| Fermentación lavado + honey + anaeróbico — 10 reglas | C-2 | v6 |
| Lavado — entidad + 4 reglas + UI | B-1 | v7 |
| Secado — 7 reglas expandidas | C-1 | v7 |
| Trilla + Clasificación física — 2 reglas + UI | B-3 | v10 |
| Catación SCA Classic Form — cupping_sessions | D-9 (CVA post-MVP) | v6 |
| Variedades: 9 en catálogo incl. Cenicafé 1 y Tabí | I-1 | — |
| Dashboard diferenciado: Caficultor / Procesador / Barista | K-1 | — |
| Brewing MVP: BrewRecipeScreen + BrewDiagnosisScreen + Cold Brew | F-1, F-2 | v9 |
| Datos históricos IA: avgFermentationH, lastLotH, userPreferredTds, batch_insights | C-3, Bloque 6 | v11 |
| QR de lote + PDF export | Bloque 9 | — |
| Admin panel + Learning Mode (AdminScreen, LearningCard, SettingsNotifier/Hive) | — | — |
| Auth: JWT refresh, session persistence, rate limiting, security headers | H-1…H-7 | — |
| OneSignal player_id + FCM token endpoint | Bloque 5b | — |
| Backend paridad producción: Nginx :80 unificado, docker-compose sin postgres | — | — |
| Tests: 296/296 ✅ | J-1…J-5 | — |
| Route guard /admin, LearningCard Cosecha+Fermentación, LearningModeIndicator | Bloque A | — |
| coffee_references + water_profiles + brew_session_details (schema v12) | Bloque B | v12 |
| BaristaHomeScreen + BrewSessionWizard + CoffeeReferenceForm | Bloque C | — |
| 14 reglas brewing (freshness/ratio/extraction/water) + ConflictResolver — 346 tests | Bloque D | — |
| lot_stage_log + WorkflowHubScreen + NotificationService timers + ProcessCompletionAnalyzer (schema v13) — 352 tests | Bloque E | v13 |

**Deudas abiertas en AUDIT.md que afectan lo nuevo:**

| ID | Descripción | Acción requerida |
|----|-------------|-----------------|
| H-3 | Purga historial git (`git filter-repo`) — credenciales históricas ya rotadas | Manual por el desarrollador |
| D-9 | Catación: migrar SCA Classic 2004 → CVA | Post-MVP, cuando FNC publique adaptación |
| B-2 | Reposo (etapa sin stepper ni tracking) | Post-MVP |
| B-4 | Empaque (etapa sin stepper) | Post-MVP — `packaged_date` en CoffeeReference lo cubre parcialmente |
| G-1 | Reconciliar `local_lots` vs `lots` (sync PostgREST) | Fase final, no tocar |

---

## Pendiente — Queue de implementación

### ~~Bloque A~~ — ✅ Cerrado (2026-06-04, commit a299776)

| # | Tarea | Archivo destino |
|---|-------|----------------|
| A1 | Route guard `/admin` en GoRouter: si `role != 'admin'` → redirect a `/home` | `app_router.dart` |
| A2 | `LearningModeIndicator` visible para **todos** los roles en ProfileScreen (hoy solo admin) | `profile_screen.dart` |
| A3 | `LearningCard` en HarvestScreen + FermentationScreen como primeras pantallas de proceso | `harvest_screen.dart`, `fermentation_screen.dart` |

---

### ~~Bloque B~~ — ✅ Cerrado (2026-06-04, commit 847e7ad)

> Usar agente `drift-schema` para la migración. Usar `codebase-explorer` antes de tocar brewing.

#### B1 — Tabla `coffee_references`

```
Obligatorios:
  id TEXT PK · owner_id TEXT NOT NULL · name TEXT NOT NULL
  roast_level TEXT NOT NULL   → 'claro' | 'medio' | 'oscuro'
  status TEXT NOT NULL DEFAULT 'active'
    'active'    → visible y usable en preparaciones
    'inactive'  → archivado (oculto en lista principal)
    'depleted'  → café agotado
    'expired'   → superó ventana de consumo (sugerido por la app)
  created_at INTEGER NOT NULL

Opcionales (nullable):
  variety TEXT · origin_farm TEXT · origin_region TEXT · origin_country TEXT
  altitude_masl INTEGER · process_type TEXT
  roast_date INTEGER        ← DateTime en ms — base para calcular días desde tueste
  packaged_date INTEGER     ← fecha de empaque/apertura (más precisa que roast_date)
  roaster_name TEXT · roaster_notes TEXT
  grind_recommendation TEXT → 'muy fina' | 'fina' | 'media' | 'gruesa'
  recommended_brew_methods TEXT  → JSON list
  flavor_descriptors TEXT        → JSON list  (jazmín, panela, frutos rojos…)
  certifications TEXT            → JSON list  (organico, fairtrade…)
  cupping_score REAL · agtron_score INTEGER
  is_public INTEGER NOT NULL DEFAULT 0  → Coffee Master puede compartir
  notes TEXT
```

**Propiedades calculadas en la entidad Dart (no se almacenan):**
```dart
int? get daysSinceRoast {
  final date = roastDate ?? packagedDate;
  return date == null ? null : DateTime.now().difference(date).inDays;
}
bool get isTooFresh    => (daysSinceRoast ?? 999) < 5;
bool get isStaleFilter => (daysSinceRoast ?? 0) > 30;
bool get isStaleEspresso => (daysSinceRoast ?? 0) > 45;
String get freshnessLabel { /* "Tostado hace 12 días — óptimo espresso" */ }
```

#### B2 — Tabla `water_profiles`

```
id TEXT PK · owner_id TEXT NOT NULL · name TEXT NOT NULL
tds_ppm REAL NOT NULL · ph REAL NOT NULL
hardness_mg_l REAL · temp_c REAL · mineral_notes TEXT
is_default INTEGER NOT NULL DEFAULT 0 · created_at INTEGER NOT NULL
```

#### B3 — Tabla `brew_session_details` (complementa `brewing_sessions` sin ALTER)

```
id TEXT PK · brewing_session_id TEXT NOT NULL (FK brewing_sessions)
coffee_reference_id TEXT · water_profile_id TEXT
brew_method TEXT · grind_descriptor TEXT · dose_g REAL · yield_ml REAL
extraction_time_s INTEGER · pressure_bar REAL
extraction_tds REAL · extraction_yield_pct REAL
days_since_roast_at_brew INTEGER  ← snapshot calculado en el momento
score_acidity INTEGER · score_sweetness INTEGER · score_body INTEGER
score_balance INTEGER · score_aroma INTEGER
ai_diagnosis TEXT · created_at INTEGER NOT NULL
```

---

### ~~Bloque C~~ — ✅ Cerrado (2026-06-04, commit 317f288)

> Usar `codebase-explorer` para ver el estado actual de `BrewScreen`, `BrewRecipeScreen`, `BaristaHomeScreen`.

```
BaristaHomeScreen (reemplaza el tile actual del barista en dashboard):
  ├── FAB "Nueva preparación" → BrewSessionWizard
  ├── Sesiones recientes (lista con chip de score)
  ├── CoffeeReferences activas (scroll horizontal, 3–4 cards con freshnessLabel)
  └── Acceso rápido a WaterProfiles guardados

BrewSessionWizard (stepper 3 pasos):
  Paso 1 — Café:
    Seleccionar referencia activa (filtro status=='active')
      O "+ Nueva referencia" → CoffeeReferenceForm (campos opcionales on-the-fly)
    Card de la referencia: variedad · proceso · tueste · freshnessLabel
    IA avisa si isTooFresh o isStaleFilter/isStaleEspresso

  Paso 2 — Agua:
    Seleccionar WaterProfile guardado  O  ingresar valores manualmente
    LearningCard: "TDS óptimo SCA: 75–150 ppm · pH 6.5–7.5"

  Paso 3 — Preparación:
    Método + molienda + dosis + rendimiento + tiempo [+ presión si espresso]
    Ratio sugerido calculado desde roastLevel de la referencia
    Preview en tiempo real: ratio + % extracción estimado

Post-sesión:
    TDS extracto medido (refractómetro, opcional)
    % extracción calculado: (yield_ml × extraction_tds) / (dose_g × 100)
    Score sensorial: acidez | dulzor | cuerpo | balance | aroma (1–5 cada uno)
    → AI diagnóstico Gemini + recomendación de ajuste
    → LearningCard: rango óptimo 18–22%, TDS 1.15–1.35%

CoffeeReferenceForm (pantalla o bottom sheet):
    Campos obligatorios: name + roast_level
    Campos opcionales agrupados en secciones colapsables:
      · Origen: variety, origin_farm, origin_region, altitude_masl
      · Tueste: roast_date (DatePicker), packaged_date, roaster_name, agtron_score
      · Descriptores: flavor_descriptors (chips), certifications, cupping_score
      · Preparación: grind_recommendation, recommended_brew_methods
    Status inicial: 'active'. Acciones de ciclo de vida vía menú contextual.
```

---

### ~~Bloque D~~ — ✅ Cerrado (2026-06-04, commit 1b9ad02)

> Usar agente `rule-engine-dev`.  
> Todos los umbrales van a `CoffeeThresholds` con fuente (SCA Water Standards 2018 + Scott Rao).

```
BREW-FRESH-WARN:       daysSinceRoast < 5              → warning  "Café muy fresco, esperar ≥5 días"
BREW-FRESH-ESPRESSO:   daysSinceRoast < 7 && espresso  → warning  "Espresso óptimo desde día 7"
BREW-STALE-FILTER:     daysSinceRoast > 30 && !espresso → info    "Café puede estar pasado de punto para filtro"
BREW-STALE-ESPRESSO:   daysSinceRoast > 45 && espresso → warning  "Riesgo de oxidación en espresso"
BREW-RATIO-LIGHT-LOW:  roastLevel==claro && ratio<1.15  → warning  "Muy concentrado para tueste claro"
BREW-RATIO-LIGHT-HIGH: roastLevel==claro && ratio>1.17  → info     "Demasiado diluido, pierde acidez"
BREW-RATIO-DARK-LOW:   roastLevel==oscuro && ratio<1.17 → warning  "Riesgo de sobre-extracción"
BREW-RATIO-DARK-HIGH:  roastLevel==oscuro && ratio>1.19 → info     "Muy diluido para tueste oscuro"
BREW-SUB-EXT:          extractionYieldPct < 18          → high     "Sub-extracción: moler fino o subir temp"
BREW-OVER-EXT:         extractionYieldPct > 22          → high     "Sobre-extracción: moler grueso o bajar temp"
BREW-WATER-PURE:       waterTds < 75                    → info     "Agua muy pura: agregar Ca 40–80 ppm"
BREW-WATER-HARD:       waterTds > 250                   → warning  "Agua muy dura: filtrar o diluir"
BREW-WATER-PH-LOW:     waterPh < 6.5                    → info     "pH ácido: puede acentuar amargor"
BREW-WATER-PH-HIGH:    waterPh > 7.5                    → info     "pH alcalino: reduce acidez y sabor"
```

`AIContext` necesita campos nuevos: `roastLevel`, `daysSinceRoast`, `waterTds`, `waterPh`, `extractionYieldPct`, `brewMethod`. Agregar en `ai_context.dart` + `condition_evaluator.dart`.

---

### ~~Bloque E~~ — ✅ Cerrado (2026-06-05, commits b60bc8d…ffdc732)

> Usar `drift-schema` para la migración. Usar `codebase-explorer` para ver `lot_steps_provider.dart`.

#### E1 — Schema + Configuración

```
Tabla: lot_stage_log  (v13, CREATE TABLE aditivo)

  id TEXT PK · lot_id TEXT NOT NULL · stage TEXT NOT NULL
  process_type TEXT
  started_at INTEGER NOT NULL · expected_duration_h REAL
  completed_at INTEGER
  ph_start REAL · ph_end REAL · temp_c REAL · brix_value REAL
  notes TEXT · ai_notes TEXT

WorkflowConfig (constante Dart, no tabla):
  fermentación + lavado:     18–36h
  fermentación + anaeróbico: 48–96h
  fermentación + honey:       0h  (sin tanque, no se registra)
  lavado:                    1–4h
  secado + natural/honey:   15–25 días
  secado + lavado:          12–18 días
  trilla:                   4–8h
```

#### E2 — WorkflowNotifier + WorkflowHubScreen

```
WorkflowNotifier (Riverpod autoDispose, por lotId):
  state: { currentStage, startedAt, expectedH, isOverdue, completedStages[] }
  startStage(stage) → INSERT lot_stage_log
  completeStage(id, inputs) → UPDATE completed_at + parámetros → avanza automáticamente
  fetchCurrentStage(lotId)

WorkflowHubScreen  /lot/:id/workflow:
  Stepper visual: ✅ completado · ⏱ en curso (timer vivo hh:mm) · ○ pendiente
  Badge rojo "Vencida Xh" si isOverdue
  "Completar etapa" → WorkflowCompleteDialog
    Inputs: pH inicio/fin · temperatura · Brix · notas libres
    Confirmar → guarda + avanza etapa
```

#### E3 — StageTimerService

```
Al iniciar etapa: scheduleNotification(T - 15min) + scheduleNotification(T + 2h)
  "Fermentación termina en 15 min — revisa el pH"
  "Fermentación vencida hace 2h — actúa ahora"
Al completar: cancelar notificaciones pendientes del lote
Usar notification_service.dart existente
```

#### E4 — Análisis IA post-lote

```
ProcessCompletionAnalyzer:
  Trigger: CuppingSession guardada con totalScore > 0
  Inputs: lot_stage_log completo + parámetros + cupping score
  Prompt Gemini → 3–5 insights → guarda en batch_insights (tabla ya existe v11)
  RecommendationSet → pre-llena sugerencias para el siguiente lote del mismo proceso
  Mostrar: LotDetailScreen pestaña "Análisis IA" + BatchInsightsCard en dashboard
```

---

### Bloque F — RBAC 4 roles ⚠️ ESPERANDO CONFIRMACIÓN EXPLÍCITA

> No implementar hasta que el usuario confirme. Depende de decisión sobre migración de roles viejos.

**Roles nuevos propuestos:**

| Rol | String | Reemplaza | Permisos |
|-----|--------|-----------|---------|
| Productor | `producer` | `farmer` + `processor` | Cosecha → Trilla |
| Coffee Master | `coffee_master` | nuevo | Análisis físico, tueste, catación SCA formal |
| Brand Manager | `brand_manager` | `entrepreneur` | Inventario, precios, certificaciones |
| Productor Integral | `producer_integral` | nuevo | Productor + Coffee Master |
| Barista | `barista` | sin cambio | Preparaciones, CoffeeReferences |
| Admin | `admin` | sin cambio | Config global |

**Migración backward-compat:** `farmer`/`processor` → `producer` en UI; tokens viejos siguen siendo válidos.

---

### Bloque G — Coffee Master (schema v14) ⚠️ ESPERANDO CONFIRMACIÓN RBAC

```
physical_analyses:
  id, lot_id, analyzed_by, analyzed_at
  green_density_gcm3 REAL   (0.60–0.90 — SCA Defect Handbook)
  moisture_pct REAL         (10–12% — ISO 6673 / Cenicafé)
  water_activity_aw REAL    (0.50–0.65 — SCA Green Coffee Standards)
  defects_primary INTEGER, defects_secondary INTEGER
  defect_types TEXT (JSON SCA codes) · screen_size INTEGER · notes TEXT

roast_profiles:
  id, lot_id, roasted_by, roasted_at
  green_weight_kg REAL, roasted_weight_kg REAL
  roast_loss_pct REAL         ← calculado automáticamente
  charge_temp_c REAL, drop_temp_c REAL
  first_crack_time_s INTEGER, first_crack_temp_c REAL  (195–205°C — Scott Rao)
  development_time_s INTEGER, total_time_s INTEGER
  dtr_pct REAL                ← DTR% = dev/total×100, ref 20–25%
  agtron_whole INTEGER, agtron_ground INTEGER  (25–95 — SCA Roast Color)
  color_label TEXT  ('claro'|'medio'|'oscuro') · roast_notes TEXT

cupping_evaluations:          ← hermana de cupping_sessions, no la reemplaza
  id, lot_id, roast_profile_id?, cupper_id, cupped_at
  fragrance_aroma, flavor, aftertaste, acidity, acidity_intensity
  body, body_texture, balance, uniformity, clean_cup, sweetness, overall REAL
  defects_taint INTEGER, defects_fault INTEGER
  total_score REAL            ← suma + 36 - (2×faults) - (4×taints)
  flavor_descriptors TEXT (JSON) · notes TEXT
```

---

### Bloque H — Brand Manager (schema v15) ⚠️ ESPERANDO CONFIRMACIÓN RBAC

```
green_inventory:
  id, lot_id, weight_kg REAL, sack_type TEXT ('60kg'|'70kg')
  sack_count INTEGER, warehouse_location TEXT, updated_at INTEGER
  ← auto-poblado al cerrar Trilla

roasted_inventory:
  id, roast_profile_id, weight_kg REAL, updated_at INTEGER
  ← calculado: verde × (1 - roast_loss_pct%)

commercial_products:
  id, roasted_inventory_id, name TEXT, description TEXT (storytelling)
  format_g INTEGER (250|500|1000)
  units_produced INTEGER, units_available INTEGER
  cost_usd REAL, price_usd REAL
  packaged_date INTEGER       ← esta fecha alimenta CoffeeReference.packaged_date
  barcode TEXT, created_at INTEGER

lot_certifications:
  id, lot_id
  type TEXT ('organico'|'fairtrade'|'rainforest'|'cup_of_excellence'|'otros')
  issuing_body TEXT, valid_from INTEGER, valid_until INTEGER, certificate_url TEXT

-- Post-MVP: customers, orders, order_items
```

---

## Resumen ejecutivo — Qué falta y en qué orden

```
AHORA (sin dependencias)
  A1  Route guard /admin en GoRouter
  A2  LearningModeIndicator para todos los roles en ProfileScreen
  A3  LearningCard en HarvestScreen + FermentationScreen

SIGUIENTE (base para experiencia barista)
  B1  Tabla coffee_references (schema v12) — usar drift-schema
  B2  Tabla water_profiles (schema v12)
  B3  Tabla brew_session_details (schema v12)
  C   BaristaHomeScreen + BrewSessionWizard + CoffeeReferenceForm
  D   14 reglas brewing + AIContext extendido — usar rule-engine-dev

PARALELO con B/C/D
  E1  Tabla lot_stage_log (schema v13) — usar drift-schema
  E2  WorkflowNotifier + WorkflowHubScreen
  E3  StageTimerService (notificaciones)
  E4  ProcessCompletionAnalyzer (Gemini)

CONDICIONAL (confirmar primero)
  F   RBAC 4 roles → backend + Flutter
  G   Coffee Master: physical_analyses + roast_profiles + cupping_evaluations (v14)
  H   Brand Manager: inventario + comercial + certificaciones (v15)

PENDIENTE MANUAL (acción del desarrollador)
  H-3  git filter-repo — purgar credenciales del historial

POST-MVP (no bloquea piloto)
  D-9  CVA catación, B-2 Reposo, B-4 Empaque, MEJ-1…10
  Firebase FCM, API clima/GPS, Android build
```

---

## Criterio de terminado por bloque

```
Bloque completado cuando:
  flutter analyze   → cero errores
  flutter test      → ≥296 tests verdes (subir baseline si se añaden tests)
  dart run build_runner → sin conflictos
  AUDIT.md          → ítem cerrado con commit y fecha
  Si hay schema nuevo: schemaVersion bumpeado + migración aditiva
  Si hay umbrales nuevos: fuente documental en CoffeeThresholds
```

---

## Piloto objetivo

```
50 usuarios: 10 productores, 5 coffee masters, 5 brand managers, 20 baristas, 10 integrales
4 semanas de uso real → feedback → ajuste de reglas IA
→ Play Store + App Store
```
