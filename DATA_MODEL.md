# Modelo de Datos — SpecialCoffee AI
## Diseño optimizado para IA + Firebase + Drift (SQLite local)

**Versión:** 1.0 | **Fecha:** 30 de abril de 2026
**Autor:** Senior Backend Engineer
**Compatibilidad:** Firebase Firestore (cloud) · Drift/SQLite (local offline)

---

## Decisión de diseño en una línea

> Dos capas de datos que se sincronizan: Firestore para persistencia en la nube y colaboración, Drift/SQLite para acceso offline total. El AI Engine solo lee del modelo local — nunca hace round-trips para generar recomendaciones.

---

## Mapa de entidades y relaciones

```
users
  │
  ├──< farm_plots           (1 usuario → N parcelas)
  │       │
  │       └──< lots         (1 parcela → N lotes)
  │               │
  │               ├──── harvest_record        (1 lote → 1 cosecha)
  │               ├──── environmental_snapshot (1 lote → N snapshots clima)
  │               │
  │               ├──── fermentation_session  (1 lote → 1 sesión activa)
  │               │         └──< fermentation_readings (N lecturas)
  │               │
  │               ├──── drying_session        (1 lote → 1 sesión)
  │               │         └──< drying_readings (N lecturas)
  │               │
  │               ├──── storage_record        (1 lote → 1 registro)
  │               └──── sca_evaluation        (1 lote → 1 catación)
  │
  ├──< brew_sessions        (1 usuario → N sesiones de preparación)
  │       └──< brew_step_logs (N pasos por sesión)
  │
  ├──< ai_recommendations   (1 usuario → N recomendaciones generadas)
  ├──< alert_events         (1 usuario → N alertas disparadas)
  └──── ai_user_profile     (1 usuario → 1 perfil aprendido)


rule_effectiveness          (colección global — sin owner)
coffee_varieties_catalog    (colección global — referencia)
```

---

## Entidades detalladas

---

### 1. `users`

**Propósito:** Perfil del usuario, rol, preferencias y punto de entrada a todos sus datos.

```
CAMPOS:

  id                  STRING    PK — UUID generado en creación
  email               STRING    único, indexado
  display_name        STRING
  role                ENUM      'farmer' | 'processor' | 'barista' | 'entrepreneur'
  secondary_roles     STRING[]  roles adicionales del mismo usuario
  region              STRING    'huila' | 'antioquia' | 'nariño' | 'peru_cajamarca' | ...
  country             STRING    ISO 3166-1 alpha-2
  language            STRING    'es' | 'en' | 'pt'
  units               ENUM      'metric' | 'imperial'
  timezone            STRING    IANA timezone (ej: 'America/Bogota')
  created_at          TIMESTAMP
  last_active_at      TIMESTAMP
  is_active           BOOLEAN

AI INPUT (campos que alimentan el motor):
  region              → ajusta reglas por zona geográfica
  role                → determina nivel de explicación en recomendaciones
  secondary_roles     → activa módulos adicionales

EJEMPLO REAL:
{
  "id": "usr_7f3a2b1c",
  "email": "carlos.morales@fincaelparaiso.co",
  "display_name": "Carlos Morales",
  "role": "farmer",
  "secondary_roles": [],
  "region": "huila",
  "country": "CO",
  "language": "es",
  "units": "metric",
  "timezone": "America/Bogota",
  "created_at": "2026-01-15T08:00:00Z",
  "last_active_at": "2026-04-30T06:23:11Z",
  "is_active": true
}
```

---

### 2. `ai_user_profile`

**Propósito:** Perfil aprendido de las preferencias del usuario. Se actualiza tras cada sesión.
Separado de `users` para no contaminar el perfil base con datos mutables.

```
CAMPOS:

  user_id                   STRING    FK → users.id (1:1)
  last_updated_at           TIMESTAMP

  [BARISTA — preferencias aprendidas]
  preferred_tds_min         FLOAT     ej: 1.30
  preferred_tds_max         FLOAT     ej: 1.38
  preferred_yield_min       FLOAT     ej: 19.5
  preferred_yield_max       FLOAT     ej: 21.0
  sensory_weights           JSONB     pesos por atributo sensorial
    acidity_weight          FLOAT     0–1 (qué tanto le importa)
    sweetness_weight        FLOAT
    body_weight             FLOAT
    aftertaste_weight       FLOAT
  dominant_method           STRING    método más usado
  sessions_count            INTEGER   total de sesiones registradas
  avg_overall_score         FLOAT     promedio histórico

  [FARMER — comportamiento aprendido]
  avg_fermentation_hours    FLOAT     promedio real de sus lotes
  avg_drying_days           INTEGER
  preferred_process         STRING    proceso más usado históricamente
  lots_completed            INTEGER
  avg_sca_score             FLOAT     promedio real de sus lotes cerrados
  sca_score_trend           FLOAT     mejora cosecha-sobre-cosecha

  [AMBOS]
  ai_trust_score            FLOAT     % de recomendaciones aceptadas (0–1)
  last_recommendation_at    TIMESTAMP

AI INPUT:
  → Personaliza las recomendaciones basándose en historial real del usuario
  → El ai_trust_score ajusta el tono (si es alto, la IA es más directa)

AI OUTPUT:
  → Se actualiza automáticamente tras cada sesión/lote cerrado

EJEMPLO REAL:
{
  "user_id": "usr_7f3a2b1c",
  "last_updated_at": "2026-04-30T09:00:00Z",
  "avg_fermentation_hours": 24.3,
  "avg_drying_days": 16,
  "preferred_process": "lavado",
  "lots_completed": 4,
  "avg_sca_score": 83.8,
  "sca_score_trend": 2.1,
  "ai_trust_score": 0.78,
  "last_recommendation_at": "2026-04-30T06:30:00Z"
}
```

---

### 3. `farm_plots`

**Propósito:** Unidad productiva del caficultor. Sus atributos son constantes o cambian muy poco — son el contexto base del AI Engine para esa parcela.

```
CAMPOS:

  id                  STRING    PK — UUID
  owner_id            STRING    FK → users.id
  name                STRING    ej: "El Paraíso"
  altitude_masl       INTEGER   metros sobre el nivel del mar
  area_hectares       FLOAT
  variety             STRING    FK → coffee_varieties_catalog.id
  latitude            FLOAT     coordenada GPS (precisión 4 decimales)
  longitude           FLOAT
  soil_type           STRING    'volcanic' | 'clay' | 'loam' | 'sandy' | 'unknown'
  shade_percentage    INTEGER   0–100 — porcentaje de sombra
  microclimate_notes  STRING    notas libres del productor
  is_active           BOOLEAN
  created_at          TIMESTAMP
  updated_at          TIMESTAMP

AI INPUT (campos críticos para el motor):
  altitude_masl  → velocidad de fermentación, tiempo de secado, temp ebullición (barista)
  variety        → proceso recomendado, perfil sensorial esperado
  latitude/long  → pronóstico climático automático, estación del año
  soil_type      → ajuste fino de recomendaciones (v2.0)

EJEMPLO REAL:
{
  "id": "plot_9a2f1e3d",
  "owner_id": "usr_7f3a2b1c",
  "name": "El Paraíso",
  "altitude_masl": 1850,
  "area_hectares": 2.3,
  "variety": "var_castillo",
  "latitude": 1.8726,
  "longitude": -76.0394,
  "soil_type": "volcanic",
  "shade_percentage": 35,
  "microclimate_notes": "Zona de niebla frecuente hasta las 10am",
  "is_active": true,
  "created_at": "2026-01-15T10:00:00Z",
  "updated_at": "2026-01-15T10:00:00Z"
}
```

---

### 4. `lots`

**Propósito:** El lote es el eje central del sistema de producción. Agrupa todo el proceso desde cosecha hasta catación. Su `status` controla qué pantallas y módulos de IA están activos.

```
CAMPOS:

  id                    STRING    PK — formato: {plot_code}-{YYYY}-{MM}-{DD}-{seq}
  plot_id               STRING    FK → farm_plots.id
  owner_id              STRING    FK → users.id (desnormalizado para queries)
  status                ENUM      'harvesting' | 'fermenting' | 'drying' |
                                  'stored' | 'closed' | 'rejected'
  process_type          ENUM      'lavado' | 'natural' | 'honey_yellow' |
                                  'honey_red' | 'honey_black' | 'anaerobic_lactic' |
                                  'anaerobic_acetic' | 'wet_anaerobic'
  process_recommended   BOOLEAN   true si el usuario usó la recomendación IA
  harvest_weight_kg     FLOAT     peso cereza húmeda en kg
  pergamino_weight_kg   FLOAT     peso final pergamino seco (llena en cierre)
  process_yield_pct     FLOAT     calculado: pergamino/cereza × 100
  sca_score             FLOAT     puntaje real post-catación (null hasta catación)
  ai_predicted_score    FLOAT     predicción IA al cierre del secado
  ai_prediction_error   FLOAT     |sca_score - ai_predicted_score| (post-catación)
  qr_code_data          STRING    datos del QR de trazabilidad (JSON serializado)
  notes                 STRING    notas libres del productor
  is_synced             BOOLEAN   para el SyncQueue del offline
  created_at            TIMESTAMP
  updated_at            TIMESTAMP
  closed_at             TIMESTAMP null hasta cierre

AI INPUT:
  process_type     → activa el conjunto de reglas correspondiente
  harvest_weight   → calibra expectativas de rendimiento
  plot.variety     → (via join) proceso y perfil esperados
  plot.altitude    → velocidad de fermentación, secado

AI OUTPUT:
  process_recommended  → registra si el usuario siguió la IA
  ai_predicted_score   → predicción al final del secado
  ai_prediction_error  → alimenta el entrenamiento ML (v2.0)

EJEMPLO REAL:
{
  "id": "LP-2026-04-30-001",
  "plot_id": "plot_9a2f1e3d",
  "owner_id": "usr_7f3a2b1c",
  "status": "fermenting",
  "process_type": "lavado",
  "process_recommended": true,
  "harvest_weight_kg": 480.0,
  "pergamino_weight_kg": null,
  "process_yield_pct": null,
  "sca_score": null,
  "ai_predicted_score": null,
  "ai_prediction_error": null,
  "notes": "10% cereza pintona separada en cosecha",
  "is_synced": true,
  "created_at": "2026-04-30T06:30:00Z",
  "updated_at": "2026-04-30T10:45:00Z",
  "closed_at": null
}
```

---

### 5. `harvest_records`

**Propósito:** Datos de la cosecha. Captura la calidad de la materia prima antes de cualquier proceso.

```
CAMPOS:

  id                    STRING    PK
  lot_id                STRING    FK → lots.id (1:1)
  owner_id              STRING    FK — desnormalizado
  harvest_date          DATE
  start_time            TIME
  end_time              TIME
  num_pickers           INTEGER   número de recolectores
  brix_level            FLOAT     grados Brix medidos (null si no midió)
  cherry_color_pct      INTEGER   % de cerezas rojas (0–100)
  cherry_color_method   ENUM      'visual_estimate' | 'photo_analysis'
  defect_pct_estimate   FLOAT     % estimado de cerezas defectuosas
  separation_done       BOOLEAN   si se separaron cerezas por madurez
  harvest_method        ENUM      'selective' | 'strip' | 'mechanical'
  weather_at_harvest    JSONB     snapshot del clima al momento de cosechar
  photo_urls            STRING[]  fotos de la cosecha
  created_at            TIMESTAMP

AI INPUT (campos críticos):
  brix_level          → decisión go/no-go de cosecha (regla HARV-BRIX-*)
  cherry_color_pct    → confirmación de madurez
  defect_pct_estimate → ajusta expectativa de puntaje SCA
  weather_at_harvest  → contexto para predicciones posteriores

EJEMPLO REAL:
{
  "id": "harv_2c4e8a1f",
  "lot_id": "LP-2026-04-30-001",
  "owner_id": "usr_7f3a2b1c",
  "harvest_date": "2026-04-30",
  "start_time": "06:00",
  "end_time": "14:30",
  "num_pickers": 8,
  "brix_level": 21.8,
  "cherry_color_pct": 82,
  "cherry_color_method": "visual_estimate",
  "defect_pct_estimate": 3.0,
  "separation_done": true,
  "harvest_method": "selective",
  "weather_at_harvest": {
    "temp_c": 18.0,
    "humidity_pct": 78,
    "condition": "partly_cloudy"
  },
  "photo_urls": ["gs://specialcoffee/harvests/LP-2026-04-30-001/1.jpg"],
  "created_at": "2026-04-30T06:30:00Z"
}
```

---

### 6. `environmental_snapshots`

**Propósito:** Capturas del clima en momentos clave del proceso. No es monitoreo continuo — son puntos de datos asociados a decisiones específicas.

```
CAMPOS:

  id                    STRING    PK
  lot_id                STRING    FK → lots.id
  owner_id              STRING    FK — desnormalizado
  stage                 ENUM      'pre_harvest' | 'fermentation_start' |
                                  'fermentation_mid' | 'fermentation_end' |
                                  'drying_start' | 'drying_daily' | 'storage'
  source                ENUM      'api_weather' | 'manual' | 'iot_sensor'
  temp_ambient_c        FLOAT     temperatura ambiente
  humidity_relative_pct FLOAT     humedad relativa (%)
  rain_probability_pct  FLOAT     del pronóstico API (null si es manual)
  wind_speed_kmh        FLOAT
  uv_index              FLOAT
  pressure_hpa          FLOAT
  condition             STRING    'sunny' | 'cloudy' | 'rainy' | 'foggy'
  forecast_72h          JSONB     próximo pronóstico relevante
  recorded_at           TIMESTAMP

AI INPUT:
  temp_ambient_c         → velocidad de fermentación, riesgo de sobrefermentación
  humidity_relative_pct  → método de secado, duración estimada
  rain_probability_pct   → ventana de cosecha, cubrimiento en secado
  uv_index               → exposición en camas africanas

EJEMPLO REAL:
{
  "id": "env_4d1b9c2a",
  "lot_id": "LP-2026-04-30-001",
  "owner_id": "usr_7f3a2b1c",
  "stage": "fermentation_start",
  "source": "api_weather",
  "temp_ambient_c": 18.0,
  "humidity_relative_pct": 78.0,
  "rain_probability_pct": 5.0,
  "wind_speed_kmh": 8.0,
  "uv_index": 3.2,
  "pressure_hpa": 826.0,
  "condition": "partly_cloudy",
  "forecast_72h": {
    "day_1": {"temp_max_c": 21, "temp_min_c": 14, "rain_pct": 10},
    "day_2": {"temp_max_c": 19, "temp_min_c": 13, "rain_pct": 65},
    "day_3": {"temp_max_c": 18, "temp_min_c": 12, "rain_pct": 80}
  },
  "recorded_at": "2026-04-30T10:00:00Z"
}
```

---

### 7. `fermentation_sessions`

**Propósito:** Cabecera de la sesión de fermentación. Una por lote. Contiene el protocolo que la IA generó vs lo que realmente sucedió.

```
CAMPOS:

  id                          STRING    PK
  lot_id                      STRING    FK → lots.id (1:1)
  owner_id                    STRING    FK
  process_type                ENUM      heredado del lote
  tank_capacity_liters        FLOAT
  tank_type                   ENUM      'open_tank' | 'closed_tank' |
                                        'sealed_anaerobic' | 'bag_anaerobic'

  [PROTOCOLO IA GENERADO — qué recomendó la IA al inicio]
  ai_protocol_duration_min_h  FLOAT     mínimo de horas estimado
  ai_protocol_duration_max_h  FLOAT     máximo de horas estimado
  ai_protocol_ph_target_min   FLOAT     pH objetivo de detención
  ai_protocol_ph_target_max   FLOAT
  ai_protocol_temp_target_min FLOAT     rango de temperatura objetivo
  ai_protocol_temp_target_max FLOAT
  ai_protocol_reading_freq_h  FLOAT     cada cuántas horas pide lectura
  ai_protocol_generated_at    TIMESTAMP
  ai_protocol_version         STRING    versión del rule engine

  [EJECUCIÓN REAL]
  started_at                  TIMESTAMP
  ended_at                    TIMESTAMP null hasta finalización
  actual_duration_h           FLOAT     calculado al cerrar
  end_reason                  ENUM      'ai_recommendation' | 'manual_decision' |
                                        'emergency_stop' | 'ph_target_reached' |
                                        'time_limit_reached'
  ph_initial                  FLOAT
  ph_final                    FLOAT
  deviation_from_protocol     FLOAT     % de desviación real vs recomendado
  notes                       STRING
  is_synced                   BOOLEAN

AI INPUT (al generar el protocolo):
  lot.process_type    → conjunto de reglas aplicable
  plot.altitude_masl  → velocidad esperada de fermentación
  env.temp_ambient_c  → ajuste de duración (más frío = más lento)
  plot.variety        → sensibilidad de la variedad

AI OUTPUT (qué guarda la IA):
  ai_protocol_*       → el protocolo generado completo
  deviation_*         → para correlacionar adherencia con puntaje SCA (ML)

EJEMPLO REAL:
{
  "id": "ferm_5e3c7a9b",
  "lot_id": "LP-2026-04-30-001",
  "owner_id": "usr_7f3a2b1c",
  "process_type": "lavado",
  "tank_capacity_liters": 500.0,
  "tank_type": "open_tank",
  "ai_protocol_duration_min_h": 24.0,
  "ai_protocol_duration_max_h": 30.0,
  "ai_protocol_ph_target_min": 4.0,
  "ai_protocol_ph_target_max": 4.5,
  "ai_protocol_temp_target_min": 16.0,
  "ai_protocol_temp_target_max": 20.0,
  "ai_protocol_reading_freq_h": 4.0,
  "ai_protocol_generated_at": "2026-04-30T10:05:00Z",
  "ai_protocol_version": "1.2.3",
  "started_at": "2026-04-30T10:10:00Z",
  "ended_at": null,
  "actual_duration_h": null,
  "end_reason": null,
  "ph_initial": 5.9,
  "ph_final": null,
  "deviation_from_protocol": null,
  "is_synced": true
}
```

---

### 8. `fermentation_readings`

**Propósito:** Serie de tiempo de variables durante la fermentación. Es la tabla de mayor volumen de escritura y la más crítica para el AlertEngine.

```
CAMPOS:

  id                      STRING    PK
  session_id              STRING    FK → fermentation_sessions.id
  lot_id                  STRING    FK — desnormalizado para queries directos
  owner_id                STRING    FK — desnormalizado
  reading_number          INTEGER   secuencial dentro de la sesión (1, 2, 3...)
  hours_elapsed           FLOAT     horas desde inicio de fermentación
  ph_value                FLOAT     lectura actual de pH
  mucilago_temp_c         FLOAT     temperatura del mucílago
  ambient_temp_c          FLOAT     temperatura ambiente al momento
  mucilage_state          ENUM      'liquid' | 'viscous' | 'gelatinous' | 'dry'
  gas_presence            BOOLEAN   presencia de CO₂ (anaeróbico)
  aroma_notes             STRING    descripción de aroma (campo libre)
  input_method            ENUM      'manual' | 'iot_sensor' | 'voice'

  [AI EVALUATION — qué evaluó la IA con esta lectura]
  ai_evaluated            BOOLEAN   si el rule engine procesó esta lectura
  ai_alert_level          ENUM      'none' | 'info' | 'warning' | 'high' | 'critical'
  ai_alert_rule_id        STRING    ID de la regla que disparó la alerta (si aplica)
  ai_projected_end_h      FLOAT     horas estimadas para alcanzar pH objetivo
  ai_recommendation_id    STRING    FK → ai_recommendations.id (si generó una)

  recorded_at             TIMESTAMP tiempo real de la lectura
  is_synced               BOOLEAN

ÍNDICES REQUERIDOS:
  (session_id, recorded_at)    → queries de la gráfica de progreso
  (lot_id, ai_alert_level)     → dashboard de alertas del procesador
  (owner_id, recorded_at)      → timeline del usuario

AI INPUT:
  ph_value           → evaluación de reglas FERM-PH-*
  mucilago_temp_c    → evaluación de reglas FERM-TEMP-*
  mucilage_state     → señal de punto de finalización
  hours_elapsed      → velocidad de fermentación, proyección

AI OUTPUT:
  ai_alert_level          → qué nivel de alerta disparó esta lectura
  ai_alert_rule_id        → qué regla específica se activó
  ai_projected_end_h      → cuándo termina según la IA

EJEMPLO REAL:
{
  "id": "fread_8b2d4f1e",
  "session_id": "ferm_5e3c7a9b",
  "lot_id": "LP-2026-04-30-001",
  "owner_id": "usr_7f3a2b1c",
  "reading_number": 5,
  "hours_elapsed": 20.3,
  "ph_value": 4.3,
  "mucilago_temp_c": 17.0,
  "ambient_temp_c": 16.5,
  "mucilage_state": "viscous",
  "gas_presence": false,
  "aroma_notes": "Frutas tropicales leves, limpio",
  "input_method": "manual",
  "ai_evaluated": true,
  "ai_alert_level": "none",
  "ai_alert_rule_id": null,
  "ai_projected_end_h": 4.2,
  "ai_recommendation_id": "rec_3a1f8c2d",
  "recorded_at": "2026-04-30T22:30:00Z",
  "is_synced": true
}
```

---

### 9. `drying_sessions`

**Propósito:** Cabecera del proceso de secado. Similar a `fermentation_sessions`: captura el plan IA vs la ejecución real.

```
CAMPOS:

  id                          STRING    PK
  lot_id                      STRING    FK → lots.id (1:1)
  owner_id                    STRING    FK
  method                      ENUM      'african_beds' | 'patio' | 'greenhouse' |
                                        'mechanical_silo' | 'raised_patio'

  [PROTOCOLO IA]
  ai_protocol_duration_min_d  INTEGER   días estimados mínimos
  ai_protocol_duration_max_d  INTEGER
  ai_protocol_humidity_target FLOAT     humedad objetivo final (%)
  ai_protocol_daily_turns_min INTEGER   volteos mínimos recomendados por día
  ai_protocol_cover_at_rain   BOOLEAN
  ai_protocol_version         STRING

  [EJECUCIÓN REAL]
  started_at                  TIMESTAMP
  ended_at                    TIMESTAMP
  actual_duration_days        INTEGER
  humidity_initial_pct        FLOAT
  humidity_final_pct          FLOAT
  end_reason                  ENUM      'target_reached' | 'manual_stop' |
                                        'weather_forced'
  is_synced                   BOOLEAN

EJEMPLO REAL:
{
  "id": "dry_7c5e2b9a",
  "lot_id": "LP-2026-04-30-001",
  "owner_id": "usr_7f3a2b1c",
  "method": "african_beds",
  "ai_protocol_duration_min_d": 14,
  "ai_protocol_duration_max_d": 18,
  "ai_protocol_humidity_target": 11.5,
  "ai_protocol_daily_turns_min": 3,
  "ai_protocol_cover_at_rain": true,
  "ai_protocol_version": "1.2.3",
  "started_at": "2026-05-01T07:00:00Z",
  "ended_at": null,
  "actual_duration_days": null,
  "humidity_initial_pct": 52.0,
  "humidity_final_pct": null,
  "end_reason": null,
  "is_synced": true
}
```

---

### 10. `drying_readings`

**Propósito:** Serie de tiempo diaria del secado. Menor frecuencia que fermentación pero igualmente crítica para detectar secado irregular.

```
CAMPOS:

  id                      STRING    PK
  session_id              STRING    FK → drying_sessions.id
  lot_id                  STRING    FK — desnormalizado
  owner_id                STRING    FK — desnormalizado
  day_number              INTEGER   día 1, 2, 3... desde inicio
  humidity_pct            FLOAT     humedad medida
  ambient_temp_c          FLOAT
  ambient_humidity_pct    FLOAT     humedad relativa ambiental
  sun_exposure_hours      FLOAT     horas de sol ese día
  turns_count             INTEGER   volteos realizados ese día
  covered_from_rain       BOOLEAN
  weight_kg               FLOAT     peso actual (opcional, para pérdida de humedad)
  visual_notes            STRING    observaciones visuales del grano
  photo_url               STRING

  [AI EVALUATION]
  ai_evaluated            BOOLEAN
  ai_alert_level          ENUM
  ai_progress_vs_curve    FLOAT     -1 a 1 (negativo = más lento de lo esperado)
  ai_days_remaining_est   INTEGER   días estimados para alcanzar objetivo
  ai_recommendation_id    STRING    FK → ai_recommendations.id

  recorded_at             TIMESTAMP
  is_synced               BOOLEAN

AI INPUT:
  humidity_pct              → progreso vs curva esperada
  sun_exposure_hours        → calibración de velocidad
  ai_progress_vs_curve      → si es negativo, activa reglas de alerta

AI OUTPUT:
  ai_progress_vs_curve      → desviación de la curva ideal
  ai_days_remaining_est     → proyección dinámica de finalización

EJEMPLO REAL:
{
  "id": "dread_1e4b7f3c",
  "session_id": "dry_7c5e2b9a",
  "lot_id": "LP-2026-04-30-001",
  "owner_id": "usr_7f3a2b1c",
  "day_number": 9,
  "humidity_pct": 28.0,
  "ambient_temp_c": 21.0,
  "ambient_humidity_pct": 72.0,
  "sun_exposure_hours": 5.5,
  "turns_count": 3,
  "covered_from_rain": false,
  "weight_kg": 103.2,
  "visual_notes": "Grano uniforme, sin manchas",
  "photo_url": null,
  "ai_evaluated": true,
  "ai_alert_level": "warning",
  "ai_progress_vs_curve": -0.18,
  "ai_days_remaining_est": 7,
  "ai_recommendation_id": "rec_6f2a4d8e",
  "recorded_at": "2026-05-10T16:00:00Z",
  "is_synced": true
}
```

---

### 11. `storage_records`

**Propósito:** Condiciones de almacenamiento del pergamino seco. Cierra la cadena de custodia del lote hasta la catación.

```
CAMPOS:

  id                      STRING    PK
  lot_id                  STRING    FK → lots.id (1:1)
  owner_id                STRING    FK
  entry_date              DATE
  storage_location        STRING    descripción de la bodega
  bag_type                ENUM      'grainpro' | 'jute' | 'polypropylene' |
                                    'hermetic' | 'other'
  bag_quantity            INTEGER
  storage_temp_c          FLOAT     temperatura de la bodega
  storage_humidity_pct    FLOAT     humedad relativa de la bodega
  pergamino_weight_kg     FLOAT     peso al ingresar a bodega
  rest_days_recommended   INTEGER   días de reposo sugeridos por la IA
  rest_days_actual        INTEGER   días reales de reposo (llena en catación)
  cupping_ready_date      DATE      fecha estimada para catación (por IA)
  notes                   STRING
  created_at              TIMESTAMP

AI INPUT:
  process_type (via lot)   → días de reposo recomendados
  fermentation_actual_h    → si fue más larga, más reposo
  humidity_final_pct       → verificación de condición de almacenamiento

AI OUTPUT:
  rest_days_recommended    → días de reposo calculados
  cupping_ready_date       → fecha sugerida para catación

EJEMPLO REAL:
{
  "id": "stor_2f8c1a4e",
  "lot_id": "LP-2026-04-30-001",
  "owner_id": "usr_7f3a2b1c",
  "entry_date": "2026-05-17",
  "storage_location": "Bodega principal, esquina norte",
  "bag_type": "grainpro",
  "bag_quantity": 2,
  "storage_temp_c": 18.0,
  "storage_humidity_pct": 65.0,
  "pergamino_weight_kg": 91.2,
  "rest_days_recommended": 30,
  "rest_days_actual": null,
  "cupping_ready_date": "2026-06-16",
  "notes": "",
  "created_at": "2026-05-17T09:00:00Z"
}
```

---

### 12. `sca_evaluations`

**Propósito:** Puntaje de catación SCA que cierra el ciclo de datos. Es el ground truth que valida o corrige las predicciones de la IA. El campo más valioso para entrenar ML.

```
CAMPOS:

  id                          STRING    PK
  lot_id                      STRING    FK → lots.id (1:1)
  owner_id                    STRING    FK
  evaluator_type              ENUM      'self' | 'q_grader' | 'buyer' | 'lab'
  evaluator_name              STRING    nombre del catador (opcional)
  cupping_date                DATE

  [PROTOCOLO SCA — hoja de catación]
  fragrance_aroma             FLOAT     6–10
  flavor                      FLOAT
  aftertaste                  FLOAT
  acidity                     FLOAT
  body                        FLOAT
  balance                     FLOAT
  overall                     FLOAT
  uniformity                  FLOAT
  clean_cup                   FLOAT
  sweetness                   FLOAT
  defects_taint               INTEGER   × 2 puntos
  defects_fault               INTEGER   × 4 puntos
  total_score                 FLOAT     suma calculada — el campo más importante

  [PERFIL SENSORIAL LIBRE]
  flavor_notes                STRING[]  ej: ["durazno", "caramelo", "cítrico"]
  process_classification      ENUM      'specialty' | 'premium' | 'commodity'

  [LOOP DE IA]
  ai_predicted_score          FLOAT     lo que predijo la IA (copia de lots.ai_predicted_score)
  prediction_error            FLOAT     |total_score - ai_predicted_score|
  notes                       STRING
  created_at                  TIMESTAMP

AI OUTPUT (este campo alimenta el ML):
  prediction_error → mide la precisión del rule engine, lote por lote
  total_score + todo el historial del lote → dataset de entrenamiento ML (v2.0)

EJEMPLO REAL:
{
  "id": "sca_4b2e9f1a",
  "lot_id": "LP-2026-04-30-001",
  "owner_id": "usr_7f3a2b1c",
  "evaluator_type": "q_grader",
  "evaluator_name": "Sofía Rodríguez CQI#3421",
  "cupping_date": "2026-06-18",
  "fragrance_aroma": 8.5,
  "flavor": 8.25,
  "aftertaste": 8.0,
  "acidity": 8.25,
  "body": 7.75,
  "balance": 8.0,
  "overall": 8.0,
  "uniformity": 10.0,
  "clean_cup": 10.0,
  "sweetness": 10.0,
  "defects_taint": 0,
  "defects_fault": 0,
  "total_score": 86.75,
  "flavor_notes": ["durazno", "maracuyá", "panela", "acidez málica"],
  "process_classification": "specialty",
  "ai_predicted_score": 84.5,
  "prediction_error": 2.25,
  "created_at": "2026-06-18T14:30:00Z"
}
```

---

### 13. `brew_sessions`

**Propósito:** Sesión completa de preparación de café. Contiene tanto la receta que generó la IA como los resultados reales. Es el eje del módulo barista.

```
CAMPOS:

  id                          STRING    PK
  user_id                     STRING    FK → users.id
  lot_id                      STRING    FK → lots.id (null si no se trazó)
  coffee_catalog_id           STRING    FK → coffee_catalog.id (si no es lote propio)
  method                      ENUM      'v60' | 'chemex' | 'french_press' |
                                        'espresso' | 'aeropress' | 'moka' |
                                        'cold_brew' | 'siphon'
  session_number              INTEGER   secuencial por usuario + método

  [RECETA GENERADA POR IA]
  ai_recipe_generated         BOOLEAN
  ai_dose_g                   FLOAT
  ai_water_g                  FLOAT
  ai_ratio                    FLOAT     calculado: water/dose
  ai_water_temp_c             FLOAT     ajustado por altitud
  ai_grind_setting            FLOAT     escala del usuario
  ai_bloom_g                  FLOAT
  ai_bloom_seconds            INTEGER
  ai_total_time_target_s      INTEGER   tiempo total objetivo en segundos
  ai_tds_target_min           FLOAT
  ai_tds_target_max           FLOAT
  ai_yield_target_min         FLOAT
  ai_yield_target_max         FLOAT
  ai_recipe_based_on          JSONB     qué datos usó la IA para generar la receta
  ai_recipe_version           STRING

  [PARÁMETROS REALES USADOS]
  actual_dose_g               FLOAT
  actual_water_g              FLOAT
  actual_water_temp_c         FLOAT
  actual_grind_setting        FLOAT
  actual_total_time_s         INTEGER
  followed_ai_recipe          BOOLEAN
  deviations_from_recipe      JSONB     qué parámetros cambió el usuario

  [RESULTADO]
  tds_pct                     FLOAT     medido con refractómetro (null si no midió)
  extraction_yield_pct        FLOAT     calculado automáticamente
  tds_in_target               BOOLEAN   calculado

  [EVALUACIÓN SENSORIAL]
  sensory_acidity             FLOAT     1–10
  sensory_sweetness           FLOAT
  sensory_body                FLOAT
  sensory_aftertaste          FLOAT
  sensory_overall             FLOAT
  sensory_notes               STRING    nota de voz transcrita o texto libre
  sensory_flavor_tags         STRING[]  ej: ["chocolate", "nuez", "caramelo"]

  [AI DIAGNOSIS — generado post-sesión]
  ai_diagnosis                JSONB     diagnóstico completo
  ai_adjustment_suggestions   JSONB[]   ajustes sugeridos ordenados por impacto
  ai_session_quality          ENUM      'optimal' | 'good' | 'acceptable' |
                                        'needs_adjustment'

  created_at                  TIMESTAMP
  is_synced                   BOOLEAN

AI INPUT (para generar la receta):
  lot.variety + lot.process_type + coffee.roast_level
  plot.altitude_masl          → ajuste de temperatura
  user.ai_user_profile        → personalización de ratio y perfil
  env.temp_ambient_c          → ajuste fino de temperatura

AI OUTPUT:
  ai_recipe_*                 → receta completa generada
  ai_diagnosis                → análisis post-extracción
  ai_adjustment_suggestions   → recomendaciones de mejora

EJEMPLO REAL:
{
  "id": "brew_9e3f1c7a",
  "user_id": "usr_barista_2b",
  "lot_id": "LP-2026-04-30-001",
  "method": "v60",
  "session_number": 24,
  "ai_recipe_generated": true,
  "ai_dose_g": 20.0,
  "ai_water_g": 310.0,
  "ai_ratio": 15.5,
  "ai_water_temp_c": 89.0,
  "ai_grind_setting": 17.0,
  "ai_bloom_g": 45.0,
  "ai_bloom_seconds": 45,
  "ai_total_time_target_s": 195,
  "ai_tds_target_min": 1.25,
  "ai_tds_target_max": 1.40,
  "ai_yield_target_min": 19.0,
  "ai_yield_target_max": 21.0,
  "ai_recipe_based_on": {
    "variety": "geisha",
    "process": "anaerobic_lactic",
    "roast_days": 15,
    "altitude_masl": 2600,
    "water_hardness_ppm": 120,
    "user_tds_preference": "1.30-1.38"
  },
  "ai_recipe_version": "1.2.3",
  "actual_dose_g": 20.0,
  "actual_water_g": 310.0,
  "actual_water_temp_c": 89.0,
  "actual_grind_setting": 17.0,
  "actual_total_time_s": 198,
  "followed_ai_recipe": true,
  "deviations_from_recipe": {},
  "tds_pct": 1.38,
  "extraction_yield_pct": 20.8,
  "tds_in_target": true,
  "sensory_acidity": 7.0,
  "sensory_sweetness": 8.0,
  "sensory_body": 6.0,
  "sensory_aftertaste": 7.5,
  "sensory_overall": 8.5,
  "sensory_notes": "Durazno claro en retrogusto, muy limpia",
  "sensory_flavor_tags": ["durazno", "maracuyá", "miel"],
  "ai_diagnosis": {
    "status": "optimal",
    "tds_assessment": "En tu rango óptimo personal",
    "yield_assessment": "Extracción equilibrada",
    "key_observation": "Bloom extendido de 45s fue determinante"
  },
  "ai_adjustment_suggestions": [],
  "ai_session_quality": "optimal",
  "created_at": "2026-04-30T10:15:00Z",
  "is_synced": true
}
```

---

### 14. `ai_recommendations`

**Propósito:** Log completo de toda recomendación generada por el rule engine. Permite auditoría, debugging y alimenta el entrenamiento ML al correlacionar recomendaciones seguidas vs resultados obtenidos.

```
CAMPOS:

  id                      STRING    PK
  user_id                 STRING    FK → users.id
  lot_id                  STRING    FK → lots.id (null si es de brewing)
  brew_session_id         STRING    FK → brew_sessions.id (null si es de producción)
  rule_id                 STRING    ID de la regla que la generó
  rule_version            STRING    versión del rule engine
  module                  ENUM      'harvest' | 'fermentation' | 'drying' |
                                    'storage' | 'brewing' | 'process_selection'
  stage                   STRING    sub-etapa específica
  recommendation_type     ENUM      'process_selection' | 'protocol' | 'alert' |
                                    'adjustment' | 'prediction' | 'guidance'

  [CONTENIDO]
  action_suggested        STRING    código de acción (ej: 'STOP_FERMENTATION')
  explanation_simple      TEXT      texto para caficultor
  explanation_advanced    TEXT      texto para barista/procesador
  confidence_score        FLOAT     0–1
  alert_level             ENUM      'none' | 'info' | 'warning' | 'high' | 'critical'
  parameters              JSONB     parámetros específicos de la recomendación
  context_snapshot        JSONB     snapshot del AIContext que usó la IA para decidir

  [RESPUESTA DEL USUARIO]
  user_action             ENUM      'accepted' | 'modified' | 'ignored' | 'pending'
  user_action_at          TIMESTAMP
  user_modification       JSONB     qué cambió el usuario si modificó
  was_effective           BOOLEAN   null hasta poder evaluarse (post-catación/sesión)

  generated_at            TIMESTAMP
  expires_at              TIMESTAMP null si no expira, timestamp si es urgente

AI OUTPUT (este es el output completo que se persiste):
  Todo el registro de la recomendación, con el contexto que la generó.
  Permite reproducir exactamente por qué la IA dijo lo que dijo.

ML TRAINING USE:
  user_action = 'accepted' + was_effective = true  → refuerza la regla
  user_action = 'ignored'  + sca_score_improved    → sugiere que la regla no era necesaria
  user_action = 'accepted' + was_effective = false → identifica regla incorrecta

EJEMPLO REAL:
{
  "id": "rec_3a1f8c2d",
  "user_id": "usr_7f3a2b1c",
  "lot_id": "LP-2026-04-30-001",
  "brew_session_id": null,
  "rule_id": "FERM-PH-OPT-PROJECT-003",
  "rule_version": "1.2.3",
  "module": "fermentation",
  "stage": "mid_fermentation",
  "recommendation_type": "guidance",
  "action_suggested": "CONTINUE_WITH_ALARM",
  "explanation_simple": "El café va bien. Pon una alarma para las 2 AM — ese es el mejor momento para revisar.",
  "explanation_advanced": "pH descendiendo 0.07/h. Proyección: pH 4.1–4.2 en 4.2h. Continuar hasta punto óptimo con monitoreo.",
  "confidence_score": 0.84,
  "alert_level": "none",
  "parameters": {
    "projected_end_hours": 4.2,
    "projected_ph": 4.15,
    "alarm_suggestion": "02:00"
  },
  "context_snapshot": {
    "current_ph": 4.3,
    "ph_rate": -0.07,
    "hours_elapsed": 20.3,
    "mucilago_temp_c": 17.0,
    "process_type": "lavado",
    "altitude_masl": 1850
  },
  "user_action": "accepted",
  "user_action_at": "2026-04-30T22:35:00Z",
  "user_modification": null,
  "was_effective": null,
  "generated_at": "2026-04-30T22:31:00Z",
  "expires_at": "2026-05-01T04:00:00Z"
}
```

---

### 15. `alert_events`

**Propósito:** Log de alertas disparadas por el AlertEngine, separado de `ai_recommendations` porque las alertas tienen un ciclo de vida diferente (críticas, sin expiración, requieren confirmación).

```
CAMPOS:

  id                      STRING    PK
  user_id                 STRING    FK → users.id
  lot_id                  STRING    FK → lots.id (null si es de brewing)
  reading_id              STRING    FK → fermentation_readings.id o drying_readings.id
  rule_id                 STRING    regla que disparó la alerta
  alert_type              ENUM      'ph_critical' | 'ph_high' | 'temp_critical' |
                                    'temp_high' | 'humidity_drying' | 'brix_low' |
                                    'brew_tds_out_of_range' | 'reading_overdue'
  alert_level             ENUM      'info' | 'warning' | 'high' | 'critical'
  trigger_value           FLOAT     valor que disparó la alerta
  trigger_threshold       FLOAT     umbral que se cruzó
  message_shown           TEXT      mensaje exacto que vio el usuario
  notification_sent       BOOLEAN   si se envió push notification
  notification_sent_at    TIMESTAMP
  acknowledged            BOOLEAN   si el usuario la vio y actuó
  acknowledged_at         TIMESTAMP
  action_taken            STRING    qué acción reportó el usuario
  resolved                BOOLEAN
  resolved_at             TIMESTAMP
  generated_at            TIMESTAMP

ÍNDICES REQUERIDOS:
  (user_id, resolved, generated_at)   → alertas activas del usuario
  (lot_id, alert_level, resolved)     → alertas activas por lote (dashboard procesador)

EJEMPLO REAL:
{
  "id": "alert_7d3c5e1b",
  "user_id": "usr_7f3a2b1c",
  "lot_id": "LP-2026-04-30-001",
  "reading_id": "fread_9c1a3e7f",
  "rule_id": "FERM-TEMP-HIGH-001",
  "alert_type": "temp_high",
  "alert_level": "high",
  "trigger_value": 29.0,
  "trigger_threshold": 27.0,
  "message_shown": "Temperatura alta en fermentación. Mucílago a 29°C. Riesgo si sube 1°C más.",
  "notification_sent": true,
  "notification_sent_at": "2026-04-30T14:00:00Z",
  "acknowledged": true,
  "acknowledged_at": "2026-04-30T14:07:00Z",
  "action_taken": "Cubrí el tanque con yute húmedo",
  "resolved": true,
  "resolved_at": "2026-04-30T16:00:00Z",
  "generated_at": "2026-04-30T14:00:00Z"
}
```

---

### 16. `rule_effectiveness` (colección global)

**Propósito:** Colección anónima y agregada que mide qué tan efectivas son las reglas del engine. No pertenece a ningún usuario. Alimenta directamente el entrenamiento ML en v2.0.

```
CAMPOS:

  rule_id                       STRING    PK = rule_id
  rule_version                  STRING
  module                        STRING
  times_fired                   INTEGER   total de veces que se activó
  times_accepted                INTEGER   veces que el usuario la aceptó
  times_ignored                 INTEGER
  times_modified                INTEGER
  acceptance_rate               FLOAT     calculado: accepted/fired
  avg_sca_when_accepted         FLOAT     promedio SCA cuando se siguió (lotes cerrados)
  avg_sca_when_ignored          FLOAT     promedio SCA cuando se ignoró
  sca_lift                      FLOAT     diferencia: accepted - ignored (+ = regla efectiva)
  avg_tds_when_accepted         FLOAT     para reglas de brewing
  avg_overall_when_accepted     FLOAT
  false_positive_count          INTEGER   alertas aceptadas pero sin problema real
  last_evaluated_at             TIMESTAMP
  sample_size_for_sca           INTEGER   lotes con catación que contribuyeron al avg

ML TRAINING USE:
  sca_lift > 2.0 pts   → regla confirmada como valiosa, aumentar weight en ML
  sca_lift < 0.5 pts   → regla de bajo impacto, revisar o eliminar
  false_positive_rate  → calibración de umbrales de alerta

EJEMPLO REAL:
{
  "rule_id": "FERM-PH-CRITICAL-001",
  "rule_version": "1.2.3",
  "module": "fermentation",
  "times_fired": 1247,
  "times_accepted": 981,
  "times_ignored": 201,
  "times_modified": 65,
  "acceptance_rate": 0.786,
  "avg_sca_when_accepted": 84.3,
  "avg_sca_when_ignored": 78.6,
  "sca_lift": 5.7,
  "avg_tds_when_accepted": null,
  "avg_overall_when_accepted": null,
  "false_positive_count": 23,
  "last_evaluated_at": "2026-04-30T00:00:00Z",
  "sample_size_for_sca": 342
}
```

---

### 17. `coffee_varieties_catalog` (colección global de referencia)

**Propósito:** Catálogo de variedades con atributos que el AI Engine usa para personalizar recomendaciones.

```
CAMPOS:

  id                          STRING    PK — ej: 'var_geisha'
  name                        STRING    'Geisha'
  aliases                     STRING[]  ['Gesha', 'Panamá Geisha']
  species                     ENUM      'arabica' | 'robusta' | 'liberica'
  origin_country              STRING[]  países de origen
  typical_altitude_min        INTEGER   msnm
  typical_altitude_max        INTEGER
  sensitivity_fermentation    ENUM      'low' | 'medium' | 'high' | 'very_high'
  recommended_processes       STRING[]  procesos donde mejor expresa su perfil
  typical_flavor_profile      STRING[]  notas de sabor características
  avg_sca_potential           FLOAT     techo de calidad promedio de la variedad
  fermentation_speed          ENUM      'slow' | 'medium' | 'fast'
  notes                       TEXT      información agronómica relevante para la IA
  updated_at                  TIMESTAMP

AI INPUT:
  sensitivity_fermentation → ajusta umbrales de alerta de pH
  recommended_processes    → filtra qué procesos se muestran como recomendados
  fermentation_speed       → ajusta la duración estimada de fermentación
  avg_sca_potential        → calibra la predicción de puntaje SCA

EJEMPLO REAL:
{
  "id": "var_geisha",
  "name": "Geisha",
  "aliases": ["Gesha"],
  "species": "arabica",
  "origin_country": ["ET", "PA", "CO", "CR"],
  "typical_altitude_min": 1600,
  "typical_altitude_max": 2200,
  "sensitivity_fermentation": "very_high",
  "recommended_processes": ["lavado", "anaerobic_lactic", "honey_yellow"],
  "typical_flavor_profile": ["floral", "jasmine", "bergamot", "peach", "tropical"],
  "avg_sca_potential": 88.5,
  "fermentation_speed": "slow",
  "notes": "Variedad de alta complejidad aromática. Muy sensible a sobrefermentación. Temperatura < 20°C produce mejores perfiles.",
  "updated_at": "2026-03-01T00:00:00Z"
}
```

---

## Flujo de datos en la IA: input → proceso → output

```
═══════════════════════════════════════════════════════════════
CASO: RECOMENDACIÓN DE PROCESO AL CREAR UN LOTE
═══════════════════════════════════════════════════════════════

INPUT (qué datos lee la IA):
┌─────────────────────────────────────────────────────────────┐
│ farm_plots.altitude_masl          = 1850                    │
│ farm_plots.variety                = 'var_castillo'          │
│ coffee_varieties_catalog.          fermentation_speed = 'medium'
│ coffee_varieties_catalog.          recommended_processes = ['lavado', 'honey']
│ environmental_snapshots.           temp_ambient_c = 18.0    │
│ environmental_snapshots.           humidity_relative_pct = 78
│ environmental_snapshots.           forecast_72h.day_2.rain_pct = 65
│ harvest_records.brix_level        = 21.8                    │
│ harvest_records.cherry_color_pct  = 82                      │
│ users.region                      = 'huila'                 │
│ ai_user_profile.preferred_process = 'lavado'               │
│ ai_user_profile.avg_sca_score     = 83.8                   │
└─────────────────────────────────────────────────────────────┘

PROCESO (rule engine evalúa):
  PROC-SELECT-001: altitud > 1800 AND variedad.speed = 'medium'
                   AND temp < 20°C → LAVADO FAVORECIDO
  PROC-SELECT-002: forecast_rain > 60% en 48h AND method = 'natural'
                   → NATURAL DESFAVORECIDO (secado en riesgo)
  PROC-SELECT-003: usuario.preferred = 'lavado' → BOOST CONFIANZA

OUTPUT (qué se persiste):
┌─────────────────────────────────────────────────────────────┐
│ lots.process_type                 = 'lavado'                │
│ lots.process_recommended          = true                    │
│ ai_recommendations.action         = 'SELECT_LAVADO'        │
│ ai_recommendations.confidence     = 0.91                   │
│ ai_recommendations.context_snapshot = { todos los inputs } │
│ ai_recommendations.explanation_simple = "..."              │
└─────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════
CASO: ALERTA DE FERMENTACIÓN EN TIEMPO REAL
═══════════════════════════════════════════════════════════════

INPUT (lectura nueva ingresada):
┌─────────────────────────────────────────────────────────────┐
│ fermentation_readings.ph_value        = 3.4                 │
│ fermentation_readings.mucilago_temp_c = 29.0               │
│ fermentation_sessions.process_type    = 'lavado'            │
│ fermentation_sessions.hours_elapsed   = 22.5               │
│ fermentation_sessions.ai_protocol_ph_target_min = 4.0      │
└─────────────────────────────────────────────────────────────┘

PROCESO:
  FERM-PH-CRITICAL-001: ph < 3.5 AND process = 'lavado' → CRÍTICO
  FERM-TEMP-HIGH-001: temp > 27°C → ALTO

OUTPUT:
┌─────────────────────────────────────────────────────────────┐
│ fermentation_readings.ai_alert_level = 'critical'           │
│ fermentation_readings.ai_alert_rule_id = 'FERM-PH-CR-001'  │
│ alert_events.alert_level              = 'critical'          │
│ alert_events.trigger_value            = 3.4                 │
│ alert_events.notification_sent        = true                │
│ ai_recommendations.action             = 'STOP_FERMENTATION' │
│ [push notification enviada al dispositivo]                  │
└─────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════
CASO: RECETA DE PREPARACIÓN PARA BARISTA
═══════════════════════════════════════════════════════════════

INPUT:
┌─────────────────────────────────────────────────────────────┐
│ brew_sessions.method                = 'v60'                 │
│ lots.process_type                   = 'anaerobic_lactic'   │
│ coffee_varieties_catalog.name       = 'Geisha'             │
│ [roast_days calculado]              = 15                   │
│ farm_plots.altitude_masl [barista]  = 2600 (Bogotá, GPS)  │
│ ai_user_profile.preferred_tds_min   = 1.30                 │
│ ai_user_profile.preferred_tds_max   = 1.38                 │
│ ai_user_profile.sensory_weights.sweetness = 0.85          │
│ environmental.temp_ambient_c        = 15.0                 │
└─────────────────────────────────────────────────────────────┘

PROCESO:
  BREW-TEMP-ALTITUDE-001: altitude > 2400 → subtract 2°C from base temp
  BREW-BLOOM-ROAST-002: roast_days < 20 → extend bloom +15s
  BREW-RATIO-PROFILE-003: user_sweetness_weight > 0.8 → ratio 1:15.5 (más concentrado)
  BREW-TEMP-ANAEROBIC-004: process = 'anaerobic' → -1°C (más delicado)

OUTPUT:
┌─────────────────────────────────────────────────────────────┐
│ brew_sessions.ai_dose_g            = 20.0                  │
│ brew_sessions.ai_water_g           = 310.0                 │
│ brew_sessions.ai_ratio             = 15.5                  │
│ brew_sessions.ai_water_temp_c      = 89.0                  │
│ brew_sessions.ai_bloom_seconds     = 45                    │
│ brew_sessions.ai_tds_target_min    = 1.25                  │
│ brew_sessions.ai_tds_target_max    = 1.40                  │
│ brew_sessions.ai_recipe_based_on   = { todos los inputs }  │
└─────────────────────────────────────────────────────────────┘
```

---

## Estructura en Firebase Firestore

```
firestore/
│
├── users/{userId}                          # Documento plano
│   └── [campos de users]
│
├── ai_user_profiles/{userId}               # 1:1 con users
│   └── [campos de ai_user_profile]
│
├── farm_plots/{plotId}                     # Parcelas
│   └── [campos de farm_plots]
│
├── lots/{lotId}                            # Lotes — colección raíz
│   └── [campos de lots]                   # (no subcolección de plots)
│                                           # → queries cross-user más simples
│
├── harvest_records/{lotId}                 # 1:1 con lots
│   └── [campos de harvest_records]
│
├── environmental_snapshots/{snapshotId}    # N por lot
│   └── [campos + lot_id como campo]
│
├── fermentation_sessions/{sessionId}       # 1:1 con lots
│   └── [campos de fermentation_sessions]
│
├── fermentation_readings/{readingId}       # N por session
│   └── [campos + lot_id, session_id]
│
├── drying_sessions/{sessionId}
├── drying_readings/{readingId}
├── storage_records/{lotId}
├── sca_evaluations/{lotId}
│
├── brew_sessions/{sessionId}              # Colección raíz
│   └── [campos de brew_sessions]
│
├── ai_recommendations/{recId}             # Log completo de IA
├── alert_events/{alertId}
│
├── rule_effectiveness/{ruleId}            # Colección global
└── coffee_varieties_catalog/{varietyId}  # Colección global
```

**Por qué colecciones raíz en lugar de subcolecciones:**
Las subcolecciones en Firestore no se pueden consultar cross-parent sin Collection Group queries. Al tener `fermentation_readings` como colección raíz con `lot_id` como campo, el procesador puede consultar "todas las lecturas con alerta crítica de todos mis lotes" en una sola query.

---

## Esquema Drift (SQLite local) — tablas espejo

```sql
-- Drift espeja Firestore pero optimizado para queries offline frecuentes

CREATE TABLE farm_plots (
  id TEXT PRIMARY KEY,
  owner_id TEXT NOT NULL,
  name TEXT NOT NULL,
  altitude_masl INTEGER NOT NULL,
  area_hectares REAL,
  variety TEXT NOT NULL,
  latitude REAL,
  longitude REAL,
  soil_type TEXT,
  shade_percentage INTEGER,
  is_active INTEGER DEFAULT 1,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  is_synced INTEGER DEFAULT 0
);

CREATE TABLE lots (
  id TEXT PRIMARY KEY,
  plot_id TEXT NOT NULL REFERENCES farm_plots(id),
  owner_id TEXT NOT NULL,
  status TEXT NOT NULL,
  process_type TEXT NOT NULL,
  process_recommended INTEGER DEFAULT 0,
  harvest_weight_kg REAL,
  pergamino_weight_kg REAL,
  sca_score REAL,
  ai_predicted_score REAL,
  notes TEXT,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  closed_at TEXT,
  is_synced INTEGER DEFAULT 0
);

CREATE TABLE fermentation_readings (
  id TEXT PRIMARY KEY,
  session_id TEXT NOT NULL,
  lot_id TEXT NOT NULL REFERENCES lots(id),
  owner_id TEXT NOT NULL,
  reading_number INTEGER NOT NULL,
  hours_elapsed REAL NOT NULL,
  ph_value REAL NOT NULL,
  mucilago_temp_c REAL NOT NULL,
  ambient_temp_c REAL,
  mucilage_state TEXT NOT NULL,
  ai_evaluated INTEGER DEFAULT 0,
  ai_alert_level TEXT DEFAULT 'none',
  ai_alert_rule_id TEXT,
  ai_projected_end_h REAL,
  ai_recommendation_id TEXT,
  recorded_at TEXT NOT NULL,
  is_synced INTEGER DEFAULT 0
);

-- Índices críticos para el AI Engine offline
CREATE INDEX idx_ferm_readings_lot_time
  ON fermentation_readings(lot_id, recorded_at DESC);

CREATE INDEX idx_ferm_readings_alert
  ON fermentation_readings(lot_id, ai_alert_level);

CREATE INDEX idx_lots_owner_status
  ON lots(owner_id, status);

-- Tabla de sync queue (no existe en Firestore)
CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  operation_type TEXT NOT NULL,  -- 'create' | 'update' | 'delete'
  collection TEXT NOT NULL,
  document_id TEXT NOT NULL,
  payload TEXT NOT NULL,         -- JSON serializado
  created_at TEXT NOT NULL,
  retry_count INTEGER DEFAULT 0,
  last_error TEXT,
  is_synced INTEGER DEFAULT 0
);
```

---

## Estrategia de índices Firestore

```javascript
// firestore.indexes.json

{
  "indexes": [
    // Lotes activos de un usuario ordenados por fecha
    {
      "collectionGroup": "lots",
      "fields": [
        {"fieldPath": "owner_id", "order": "ASCENDING"},
        {"fieldPath": "status", "order": "ASCENDING"},
        {"fieldPath": "created_at", "order": "DESCENDING"}
      ]
    },
    // Dashboard procesador: lotes con alertas activas
    {
      "collectionGroup": "alert_events",
      "fields": [
        {"fieldPath": "user_id", "order": "ASCENDING"},
        {"fieldPath": "resolved", "order": "ASCENDING"},
        {"fieldPath": "alert_level", "order": "DESCENDING"},
        {"fieldPath": "generated_at", "order": "DESCENDING"}
      ]
    },
    // Lecturas de fermentación por lote y tiempo (gráfica)
    {
      "collectionGroup": "fermentation_readings",
      "fields": [
        {"fieldPath": "lot_id", "order": "ASCENDING"},
        {"fieldPath": "recorded_at", "order": "ASCENDING"}
      ]
    },
    // Sesiones de brewing por usuario y método
    {
      "collectionGroup": "brew_sessions",
      "fields": [
        {"fieldPath": "user_id", "order": "ASCENDING"},
        {"fieldPath": "method", "order": "ASCENDING"},
        {"fieldPath": "created_at", "order": "DESCENDING"}
      ]
    },
    // Recomendaciones IA por lote (log de decisiones)
    {
      "collectionGroup": "ai_recommendations",
      "fields": [
        {"fieldPath": "lot_id", "order": "ASCENDING"},
        {"fieldPath": "generated_at", "order": "DESCENDING"}
      ]
    },
    // Efectividad de reglas por módulo (para calibración)
    {
      "collectionGroup": "rule_effectiveness",
      "fields": [
        {"fieldPath": "module", "order": "ASCENDING"},
        {"fieldPath": "sca_lift", "order": "DESCENDING"}
      ]
    }
  ]
}
```

---

## Ciclo de vida de los datos

```
DATOS CALIENTES (acceso frecuente, en SQLite local):
  → Lotes con status ≠ 'closed' y 'rejected'
  → Lecturas de fermentación de las últimas 72h
  → Lecturas de secado de las últimas 48h
  → Sesiones de brewing de los últimos 30 días
  → Alertas no resueltas
  → Perfil IA del usuario

DATOS TIBIOS (en Firestore, cargados on-demand):
  → Lotes cerrados hace < 6 meses
  → Historial de sesiones de brewing del año actual
  → Evaluaciones SCA del año actual

DATOS FRÍOS (Firestore archivado o BigQuery para ML):
  → Lotes de cosechas anteriores (> 1 año)
  → Historial completo de recomendaciones anonimizadas
  → rule_effectiveness aggregations históricas

POLÍTICA DE RETENCIÓN:
  Datos personales:        5 años desde última actividad (GDPR/LGPD)
  rule_effectiveness:      indefinido (anonimizado, valor para ML)
  alert_events resueltos:  1 año en Firestore, luego BigQuery
  sca_evaluations:         indefinido (ground truth irremplazable)
```

---

## Dataset de entrenamiento ML (v2.0)

La colección final que alimenta el modelo predictivo se construye agregando:

```
VISTA PARA ML: lot_ml_dataset (agregación en BigQuery)

Por cada lote con sca_evaluation:

  FEATURES (input del modelo):
  ─────────────────────────────
  plot.altitude_masl
  plot.variety → variety_catalog.fermentation_speed (encoded)
  plot.variety → variety_catalog.sensitivity (encoded)
  harvest.brix_level
  harvest.cherry_color_pct
  env_fermentation.temp_ambient_c
  env_fermentation.humidity_relative_pct
  fermentation.process_type (one-hot encoded)
  fermentation.actual_duration_h
  fermentation.ph_initial
  fermentation.ph_final
  fermentation.deviation_from_protocol
  drying.method (one-hot encoded)
  drying.actual_duration_days
  drying.humidity_final_pct
  [ratio de recomendaciones aceptadas en este lote]

  TARGET (output del modelo):
  ────────────────────────────
  sca_evaluation.total_score

  DATOS DE CALIDAD DEL DATASET:
  ──────────────────────────────
  Solo lotes con evaluador_type IN ('q_grader', 'lab')
  Solo lotes donde todos los campos de features están completos
  Estimación inicial: ~3.000 lotes para v2.0 útil
                      ~10.000 lotes para precisión > 85%
```

---

## Resumen: tablas por capa

```
CAPA LOCAL (Drift/SQLite) — 12 tablas:
  users, ai_user_profiles, farm_plots, lots,
  harvest_records, fermentation_sessions, fermentation_readings,
  drying_sessions, drying_readings, storage_records,
  brew_sessions, sync_queue

CAPA CLOUD (Firestore) — 17 colecciones:
  users, ai_user_profiles, farm_plots, lots,
  harvest_records, environmental_snapshots,
  fermentation_sessions, fermentation_readings,
  drying_sessions, drying_readings, storage_records,
  sca_evaluations, brew_sessions, brew_step_logs,
  ai_recommendations, alert_events,
  rule_effectiveness, coffee_varieties_catalog

CAPA ANALYTICS/ML (BigQuery, v2.0):
  lot_ml_dataset (vista materializada)
  rule_effectiveness_history
  brew_sessions_anonymized
```

---

*Próximo paso: definir Firebase Security Rules por colección y estrategia de migración de schema entre versiones.*

**Autor:** Senior Backend Engineer | SpecialCoffee AI
