-- =============================================================================
-- SpecialCoffee AI — PostgreSQL Schema v1.0
-- Compatible: PostgreSQL 13+
-- =============================================================================

-- Extensiones necesarias
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Rol de PostgREST (solo lectura/escritura sobre los datos, sin DDL)
-- Ejecutar como superusuario antes de aplicar este schema:
--   CREATE ROLE anon NOLOGIN;
--   CREATE ROLE authenticated NOLOGIN;
--   CREATE ROLE postgrest_auth LOGIN PASSWORD 'CAMBIAR_PASSWORD';
--   GRANT anon, authenticated TO postgrest_auth;

-- =============================================================================
-- FUNCIÓN: obtener el user_id del JWT actual (para RLS)
-- =============================================================================

CREATE OR REPLACE FUNCTION current_user_id() RETURNS TEXT AS $$
  SELECT NULLIF(
    current_setting('request.jwt.claims', true)::json->>'sub',
    ''
  );
$$ LANGUAGE SQL STABLE;

-- =============================================================================
-- 1. USERS
-- =============================================================================

CREATE TABLE IF NOT EXISTS users (
  id              TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  email           TEXT        UNIQUE NOT NULL,
  display_name    TEXT        NOT NULL,
  password_hash   TEXT        NOT NULL,
  role            TEXT        NOT NULL DEFAULT 'farmer'
                              CHECK (role IN ('farmer','processor','barista','entrepreneur')),
  secondary_roles TEXT[]      NOT NULL DEFAULT '{}',
  region          TEXT        NOT NULL DEFAULT '',
  country         TEXT        NOT NULL DEFAULT 'CO',
  language        TEXT        NOT NULL DEFAULT 'es',
  units           TEXT        NOT NULL DEFAULT 'metric'
                              CHECK (units IN ('metric','imperial')),
  timezone        TEXT        NOT NULL DEFAULT 'America/Bogota',
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  last_active_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_active       BOOLEAN     NOT NULL DEFAULT TRUE
);

-- PostgREST: acceso mínimo (el auth service escribe, la app lee su propio perfil)
GRANT SELECT, UPDATE ON users TO authenticated;

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
CREATE POLICY users_self ON users
  USING (id = current_user_id());

-- =============================================================================
-- 2. AI USER PROFILES
-- =============================================================================

CREATE TABLE IF NOT EXISTS ai_user_profiles (
  user_id                 TEXT        PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
  last_updated_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Barista
  preferred_tds_min       FLOAT,
  preferred_tds_max       FLOAT,
  preferred_yield_min     FLOAT,
  preferred_yield_max     FLOAT,
  acidity_weight          FLOAT       DEFAULT 0.5,
  sweetness_weight        FLOAT       DEFAULT 0.5,
  body_weight             FLOAT       DEFAULT 0.5,
  aftertaste_weight       FLOAT       DEFAULT 0.5,
  dominant_method         TEXT,
  sessions_count          INTEGER     DEFAULT 0,
  avg_overall_score       FLOAT,
  -- Farmer
  avg_fermentation_hours  FLOAT,
  avg_drying_days         INTEGER,
  preferred_process       TEXT,
  lots_completed          INTEGER     DEFAULT 0,
  avg_sca_score           FLOAT,
  sca_score_trend         FLOAT,
  -- Ambos
  ai_trust_score          FLOAT       DEFAULT 0.5,
  last_recommendation_at  TIMESTAMPTZ
);

GRANT SELECT, INSERT, UPDATE ON ai_user_profiles TO authenticated;

ALTER TABLE ai_user_profiles ENABLE ROW LEVEL SECURITY;
CREATE POLICY ai_user_profiles_self ON ai_user_profiles
  USING (user_id = current_user_id());

-- =============================================================================
-- 3. FARM PLOTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS farm_plots (
  id                  TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  owner_id            TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name                TEXT        NOT NULL,
  altitude_masl       INTEGER     NOT NULL,
  area_hectares       FLOAT,
  variety             TEXT        NOT NULL DEFAULT 'unknown',
  latitude            FLOAT,
  longitude           FLOAT,
  soil_type           TEXT        DEFAULT 'unknown'
                                  CHECK (soil_type IN ('volcanic','clay','loam','sandy','unknown')),
  shade_percentage    INTEGER     DEFAULT 0,
  microclimate_notes  TEXT,
  is_active           BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_farm_plots_owner ON farm_plots(owner_id);

GRANT SELECT, INSERT, UPDATE ON farm_plots TO authenticated;

ALTER TABLE farm_plots ENABLE ROW LEVEL SECURITY;
CREATE POLICY farm_plots_owner ON farm_plots
  USING (owner_id = current_user_id());

-- =============================================================================
-- 4. LOTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS lots (
  id                    TEXT        PRIMARY KEY,
  owner_id              TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  plot_id               TEXT        REFERENCES farm_plots(id),
  -- Campos usados por la app Flutter (Lot entity)
  variety_id            TEXT        NOT NULL DEFAULT 'unknown',
  variety_name          TEXT        NOT NULL DEFAULT 'Desconocida',
  altitude_masl         INTEGER     NOT NULL DEFAULT 0,
  region                TEXT        NOT NULL DEFAULT '',
  process_type          TEXT        NOT NULL DEFAULT 'lavado'
                                    CHECK (process_type IN (
                                      'lavado','natural','honey_yellow','honey_red',
                                      'honey_black','anaerobic_lactic','anaerobic_acetic','wet_anaerobic'
                                    )),
  ambient_temp_c        FLOAT       NOT NULL DEFAULT 18.0,
  ambient_humidity_pct  FLOAT       NOT NULL DEFAULT 70.0,
  rain_probability_pct  FLOAT       NOT NULL DEFAULT 0.0,
  status                TEXT        NOT NULL DEFAULT 'pending'
                                    CHECK (status IN (
                                      'pending','harvesting','fermenting','drying',
                                      'stored','closed','rejected'
                                    )),
  notes                 TEXT,
  -- Datos extendidos (DATA_MODEL)
  process_recommended   BOOLEAN     DEFAULT FALSE,
  harvest_weight_kg     FLOAT,
  pergamino_weight_kg   FLOAT,
  process_yield_pct     FLOAT,
  sca_score             FLOAT,
  ai_predicted_score    FLOAT,
  ai_prediction_error   FLOAT,
  is_synced             BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  closed_at             TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_lots_owner_status  ON lots(owner_id, status);
CREATE INDEX IF NOT EXISTS idx_lots_owner_created ON lots(owner_id, created_at DESC);

GRANT SELECT, INSERT, UPDATE, DELETE ON lots TO authenticated;

ALTER TABLE lots ENABLE ROW LEVEL SECURITY;
CREATE POLICY lots_owner ON lots
  USING (owner_id = current_user_id());

-- =============================================================================
-- 5. HARVEST RECORDS
-- =============================================================================

CREATE TABLE IF NOT EXISTS harvest_records (
  id                    TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  lot_id                TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id              TEXT        NOT NULL REFERENCES users(id),
  harvest_date          DATE,
  start_time            TEXT,
  end_time              TEXT,
  num_pickers           INTEGER,
  brix_level            FLOAT,
  cherry_color_pct      INTEGER,
  cherry_color_method   TEXT        DEFAULT 'visual_estimate',
  defect_pct_estimate   FLOAT,
  separation_done       BOOLEAN     DEFAULT FALSE,
  harvest_method        TEXT        DEFAULT 'selective',
  weather_at_harvest    JSONB,
  photo_urls            TEXT[]      DEFAULT '{}',
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_harvest_lot ON harvest_records(lot_id);

GRANT SELECT, INSERT, UPDATE ON harvest_records TO authenticated;

ALTER TABLE harvest_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY harvest_records_owner ON harvest_records
  USING (owner_id = current_user_id());

-- =============================================================================
-- 6. ENVIRONMENTAL SNAPSHOTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS environmental_snapshots (
  id                      TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  lot_id                  TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id                TEXT        NOT NULL REFERENCES users(id),
  stage                   TEXT        NOT NULL,
  source                  TEXT        NOT NULL DEFAULT 'manual',
  temp_ambient_c          FLOAT,
  humidity_relative_pct   FLOAT,
  rain_probability_pct    FLOAT,
  wind_speed_kmh          FLOAT,
  uv_index                FLOAT,
  pressure_hpa            FLOAT,
  condition               TEXT,
  forecast_72h            JSONB,
  recorded_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_env_lot ON environmental_snapshots(lot_id, recorded_at DESC);

GRANT SELECT, INSERT ON environmental_snapshots TO authenticated;

ALTER TABLE environmental_snapshots ENABLE ROW LEVEL SECURITY;
CREATE POLICY env_snapshots_owner ON environmental_snapshots
  USING (owner_id = current_user_id());

-- =============================================================================
-- 7. FERMENTATION SESSIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS fermentation_sessions (
  id                            TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  lot_id                        TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id                      TEXT        NOT NULL REFERENCES users(id),
  process_type                  TEXT        NOT NULL,
  tank_capacity_liters          FLOAT,
  tank_type                     TEXT        DEFAULT 'open_tank',
  -- Protocolo IA
  ai_protocol_duration_min_h    FLOAT,
  ai_protocol_duration_max_h    FLOAT,
  ai_protocol_ph_target_min     FLOAT,
  ai_protocol_ph_target_max     FLOAT,
  ai_protocol_temp_target_min   FLOAT,
  ai_protocol_temp_target_max   FLOAT,
  ai_protocol_reading_freq_h    FLOAT,
  ai_protocol_generated_at      TIMESTAMPTZ,
  ai_protocol_version           TEXT,
  -- Ejecución real
  started_at                    TIMESTAMPTZ,
  ended_at                      TIMESTAMPTZ,
  actual_duration_h             FLOAT,
  end_reason                    TEXT,
  ph_initial                    FLOAT,
  ph_final                      FLOAT,
  deviation_from_protocol       FLOAT,
  notes                         TEXT,
  is_synced                     BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ferm_sessions_lot ON fermentation_sessions(lot_id);

GRANT SELECT, INSERT, UPDATE ON fermentation_sessions TO authenticated;

ALTER TABLE fermentation_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY ferm_sessions_owner ON fermentation_sessions
  USING (owner_id = current_user_id());

-- =============================================================================
-- 8. FERMENTATION READINGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS fermentation_readings (
  id                      TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  session_id              TEXT        NOT NULL REFERENCES fermentation_sessions(id) ON DELETE CASCADE,
  lot_id                  TEXT        NOT NULL REFERENCES lots(id),
  owner_id                TEXT        NOT NULL REFERENCES users(id),
  reading_number          INTEGER     NOT NULL DEFAULT 1,
  hours_elapsed           FLOAT       NOT NULL,
  ph_value                FLOAT       NOT NULL,
  mucilago_temp_c         FLOAT       NOT NULL,
  ambient_temp_c          FLOAT,
  mucilage_state          TEXT        NOT NULL DEFAULT 'liquid',
  gas_presence            BOOLEAN     DEFAULT FALSE,
  aroma_notes             TEXT,
  input_method            TEXT        NOT NULL DEFAULT 'manual',
  -- Evaluación IA
  ai_evaluated            BOOLEAN     NOT NULL DEFAULT FALSE,
  ai_alert_level          TEXT        NOT NULL DEFAULT 'none',
  ai_alert_rule_id        TEXT,
  ai_projected_end_h      FLOAT,
  ai_recommendation_id    TEXT,
  recorded_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced               BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_ferm_readings_session_time
  ON fermentation_readings(session_id, recorded_at DESC);
CREATE INDEX IF NOT EXISTS idx_ferm_readings_lot_alert
  ON fermentation_readings(lot_id, ai_alert_level);
CREATE INDEX IF NOT EXISTS idx_ferm_readings_owner_time
  ON fermentation_readings(owner_id, recorded_at DESC);

GRANT SELECT, INSERT, UPDATE ON fermentation_readings TO authenticated;

ALTER TABLE fermentation_readings ENABLE ROW LEVEL SECURITY;
CREATE POLICY ferm_readings_owner ON fermentation_readings
  USING (owner_id = current_user_id());

-- =============================================================================
-- 9. DRYING SESSIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS drying_sessions (
  id                            TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  lot_id                        TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id                      TEXT        NOT NULL REFERENCES users(id),
  method                        TEXT        NOT NULL DEFAULT 'african_beds',
  -- Protocolo IA
  ai_protocol_duration_min_d    INTEGER,
  ai_protocol_duration_max_d    INTEGER,
  ai_protocol_humidity_target   FLOAT,
  ai_protocol_daily_turns_min   INTEGER,
  ai_protocol_cover_at_rain     BOOLEAN     DEFAULT TRUE,
  ai_protocol_version           TEXT,
  -- Ejecución real
  started_at                    TIMESTAMPTZ,
  ended_at                      TIMESTAMPTZ,
  actual_duration_days          INTEGER,
  humidity_initial_pct          FLOAT,
  humidity_final_pct            FLOAT,
  end_reason                    TEXT,
  is_synced                     BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at                    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

GRANT SELECT, INSERT, UPDATE ON drying_sessions TO authenticated;

ALTER TABLE drying_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY drying_sessions_owner ON drying_sessions
  USING (owner_id = current_user_id());

-- =============================================================================
-- 10. DRYING READINGS
-- =============================================================================

CREATE TABLE IF NOT EXISTS drying_readings (
  id                      TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  session_id              TEXT        NOT NULL REFERENCES drying_sessions(id) ON DELETE CASCADE,
  lot_id                  TEXT        NOT NULL REFERENCES lots(id),
  owner_id                TEXT        NOT NULL REFERENCES users(id),
  day_number              INTEGER     NOT NULL,
  humidity_pct            FLOAT       NOT NULL,
  ambient_temp_c          FLOAT,
  ambient_humidity_pct    FLOAT,
  sun_exposure_hours      FLOAT,
  turns_count             INTEGER     DEFAULT 0,
  covered_from_rain       BOOLEAN     DEFAULT FALSE,
  weight_kg               FLOAT,
  visual_notes            TEXT,
  photo_url               TEXT,
  -- Evaluación IA
  ai_evaluated            BOOLEAN     NOT NULL DEFAULT FALSE,
  ai_alert_level          TEXT        NOT NULL DEFAULT 'none',
  ai_progress_vs_curve    FLOAT,
  ai_days_remaining_est   INTEGER,
  ai_recommendation_id    TEXT,
  recorded_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_synced               BOOLEAN     NOT NULL DEFAULT TRUE
);

CREATE INDEX IF NOT EXISTS idx_drying_readings_session ON drying_readings(session_id, day_number);

GRANT SELECT, INSERT, UPDATE ON drying_readings TO authenticated;

ALTER TABLE drying_readings ENABLE ROW LEVEL SECURITY;
CREATE POLICY drying_readings_owner ON drying_readings
  USING (owner_id = current_user_id());

-- =============================================================================
-- 11. STORAGE RECORDS
-- =============================================================================

CREATE TABLE IF NOT EXISTS storage_records (
  id                      TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  lot_id                  TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id                TEXT        NOT NULL REFERENCES users(id),
  entry_date              DATE,
  storage_location        TEXT,
  bag_type                TEXT        DEFAULT 'grainpro',
  bag_quantity            INTEGER,
  storage_temp_c          FLOAT,
  storage_humidity_pct    FLOAT,
  pergamino_weight_kg     FLOAT,
  rest_days_recommended   INTEGER,
  rest_days_actual        INTEGER,
  cupping_ready_date      DATE,
  notes                   TEXT,
  created_at              TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

GRANT SELECT, INSERT, UPDATE ON storage_records TO authenticated;

ALTER TABLE storage_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY storage_records_owner ON storage_records
  USING (owner_id = current_user_id());

-- =============================================================================
-- 12. SCA EVALUATIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS sca_evaluations (
  id                    TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  lot_id                TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id              TEXT        NOT NULL REFERENCES users(id),
  evaluator_type        TEXT        NOT NULL DEFAULT 'self',
  evaluator_name        TEXT,
  cupping_date          DATE,
  -- Hoja SCA
  fragrance_aroma       FLOAT,
  flavor                FLOAT,
  aftertaste            FLOAT,
  acidity               FLOAT,
  body                  FLOAT,
  balance               FLOAT,
  overall               FLOAT,
  uniformity            FLOAT,
  clean_cup             FLOAT,
  sweetness             FLOAT,
  defects_taint         INTEGER     DEFAULT 0,
  defects_fault         INTEGER     DEFAULT 0,
  total_score           FLOAT,
  -- Perfil sensorial
  flavor_notes          TEXT[]      DEFAULT '{}',
  process_classification TEXT,
  -- Loop IA
  ai_predicted_score    FLOAT,
  prediction_error      FLOAT,
  notes                 TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

GRANT SELECT, INSERT, UPDATE ON sca_evaluations TO authenticated;

ALTER TABLE sca_evaluations ENABLE ROW LEVEL SECURITY;
CREATE POLICY sca_evaluations_owner ON sca_evaluations
  USING (owner_id = current_user_id());

-- =============================================================================
-- 13. BREW SESSIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS brew_sessions (
  id                          TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  user_id                     TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lot_id                      TEXT        REFERENCES lots(id),
  method                      TEXT        NOT NULL
                                          CHECK (method IN (
                                            'v60','chemex','french_press','espresso',
                                            'aeropress','moka','cold_brew','siphon'
                                          )),
  session_number              INTEGER     NOT NULL DEFAULT 1,
  -- Receta IA
  ai_recipe_generated         BOOLEAN     NOT NULL DEFAULT FALSE,
  ai_dose_g                   FLOAT,
  ai_water_g                  FLOAT,
  ai_ratio                    FLOAT,
  ai_water_temp_c             FLOAT,
  ai_grind_setting            FLOAT,
  ai_bloom_g                  FLOAT,
  ai_bloom_seconds            INTEGER,
  ai_total_time_target_s      INTEGER,
  ai_tds_target_min           FLOAT,
  ai_tds_target_max           FLOAT,
  ai_yield_target_min         FLOAT,
  ai_yield_target_max         FLOAT,
  ai_recipe_based_on          JSONB,
  ai_recipe_version           TEXT,
  -- Parámetros reales
  actual_dose_g               FLOAT,
  actual_water_g              FLOAT,
  actual_water_temp_c         FLOAT,
  actual_grind_setting        FLOAT,
  actual_total_time_s         INTEGER,
  followed_ai_recipe          BOOLEAN,
  deviations_from_recipe      JSONB,
  -- Resultado
  tds_pct                     FLOAT,
  extraction_yield_pct        FLOAT,
  tds_in_target               BOOLEAN,
  -- Evaluación sensorial
  sensory_acidity             FLOAT,
  sensory_sweetness           FLOAT,
  sensory_body                FLOAT,
  sensory_aftertaste          FLOAT,
  sensory_overall             FLOAT,
  sensory_notes               TEXT,
  sensory_flavor_tags         TEXT[]      DEFAULT '{}',
  -- Diagnóstico IA
  ai_diagnosis                JSONB,
  ai_adjustment_suggestions   JSONB,
  ai_session_quality          TEXT,
  -- Meta
  is_synced                   BOOLEAN     NOT NULL DEFAULT TRUE,
  created_at                  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_brew_sessions_user_method
  ON brew_sessions(user_id, method, created_at DESC);

GRANT SELECT, INSERT, UPDATE ON brew_sessions TO authenticated;

ALTER TABLE brew_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY brew_sessions_owner ON brew_sessions
  USING (user_id = current_user_id());

-- =============================================================================
-- 14. AI RECOMMENDATIONS
-- =============================================================================

CREATE TABLE IF NOT EXISTS ai_recommendations (
  id                      TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  user_id                 TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lot_id                  TEXT        REFERENCES lots(id),
  brew_session_id         TEXT        REFERENCES brew_sessions(id),
  rule_id                 TEXT        NOT NULL,
  rule_version            TEXT        NOT NULL DEFAULT '1.0.0',
  module                  TEXT        NOT NULL,
  recommendation_type     TEXT        NOT NULL DEFAULT 'guidance',
  action_suggested        TEXT        NOT NULL,
  explanation             TEXT        NOT NULL,
  confidence_score        FLOAT       NOT NULL,
  alert_level             TEXT        NOT NULL DEFAULT 'none',
  parameters              JSONB       DEFAULT '{}',
  context_snapshot        JSONB,
  -- Respuesta del usuario
  user_action             TEXT        DEFAULT 'pending',
  user_action_at          TIMESTAMPTZ,
  was_effective           BOOLEAN,
  generated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at              TIMESTAMPTZ
);

CREATE INDEX IF NOT EXISTS idx_ai_recs_lot ON ai_recommendations(lot_id, generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_recs_user ON ai_recommendations(user_id, generated_at DESC);

GRANT SELECT, INSERT, UPDATE ON ai_recommendations TO authenticated;

ALTER TABLE ai_recommendations ENABLE ROW LEVEL SECURITY;
CREATE POLICY ai_recs_owner ON ai_recommendations
  USING (user_id = current_user_id());

-- =============================================================================
-- 15. ALERT EVENTS
-- =============================================================================

CREATE TABLE IF NOT EXISTS alert_events (
  id                      TEXT        PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  user_id                 TEXT        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  lot_id                  TEXT        REFERENCES lots(id),
  reading_id              TEXT,
  rule_id                 TEXT        NOT NULL,
  alert_type              TEXT        NOT NULL,
  alert_level             TEXT        NOT NULL,
  trigger_value           FLOAT,
  trigger_threshold       FLOAT,
  message_shown           TEXT,
  notification_sent       BOOLEAN     NOT NULL DEFAULT FALSE,
  notification_sent_at    TIMESTAMPTZ,
  acknowledged            BOOLEAN     NOT NULL DEFAULT FALSE,
  acknowledged_at         TIMESTAMPTZ,
  action_taken            TEXT,
  resolved                BOOLEAN     NOT NULL DEFAULT FALSE,
  resolved_at             TIMESTAMPTZ,
  generated_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_alerts_user_active
  ON alert_events(user_id, resolved, generated_at DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_lot
  ON alert_events(lot_id, alert_level, resolved);

GRANT SELECT, INSERT, UPDATE ON alert_events TO authenticated;

ALTER TABLE alert_events ENABLE ROW LEVEL SECURITY;
CREATE POLICY alert_events_owner ON alert_events
  USING (user_id = current_user_id());

-- =============================================================================
-- 16. RULE EFFECTIVENESS (colección global — sin RLS)
-- =============================================================================

CREATE TABLE IF NOT EXISTS rule_effectiveness (
  rule_id                   TEXT        PRIMARY KEY,
  rule_version              TEXT        NOT NULL,
  module                    TEXT        NOT NULL,
  times_fired               INTEGER     NOT NULL DEFAULT 0,
  times_accepted            INTEGER     NOT NULL DEFAULT 0,
  times_ignored             INTEGER     NOT NULL DEFAULT 0,
  times_modified            INTEGER     NOT NULL DEFAULT 0,
  acceptance_rate           FLOAT       GENERATED ALWAYS AS (
                              CASE WHEN times_fired = 0 THEN 0
                              ELSE times_accepted::FLOAT / times_fired END
                            ) STORED,
  avg_sca_when_accepted     FLOAT,
  avg_sca_when_ignored      FLOAT,
  sca_lift                  FLOAT,
  false_positive_count      INTEGER     DEFAULT 0,
  last_evaluated_at         TIMESTAMPTZ DEFAULT NOW(),
  sample_size_for_sca       INTEGER     DEFAULT 0
);

GRANT SELECT ON rule_effectiveness TO authenticated;
GRANT SELECT ON rule_effectiveness TO anon;

-- =============================================================================
-- 17. COFFEE VARIETIES CATALOG (colección global — solo lectura pública)
-- =============================================================================

CREATE TABLE IF NOT EXISTS coffee_varieties_catalog (
  id                          TEXT        PRIMARY KEY,
  name                        TEXT        NOT NULL,
  aliases                     TEXT[]      DEFAULT '{}',
  species                     TEXT        NOT NULL DEFAULT 'arabica',
  origin_country              TEXT[]      DEFAULT '{}',
  typical_altitude_min        INTEGER,
  typical_altitude_max        INTEGER,
  sensitivity_fermentation    TEXT        DEFAULT 'medium',
  recommended_processes       TEXT[]      DEFAULT '{}',
  typical_flavor_profile      TEXT[]      DEFAULT '{}',
  avg_sca_potential           FLOAT,
  fermentation_speed          TEXT        DEFAULT 'medium',
  notes                       TEXT,
  updated_at                  TIMESTAMPTZ DEFAULT NOW()
);

GRANT SELECT ON coffee_varieties_catalog TO authenticated;
GRANT SELECT ON coffee_varieties_catalog TO anon;

-- Datos iniciales — variedades más comunes en Colombia/Perú
INSERT INTO coffee_varieties_catalog (id, name, aliases, sensitivity_fermentation,
  recommended_processes, typical_flavor_profile, avg_sca_potential,
  fermentation_speed, typical_altitude_min, typical_altitude_max) VALUES
('var_castillo',  'Castillo',  '{"Colombia"}',         'low',
  '{"lavado","honey_yellow"}', '{"caramelo","nuez","chocolate"}', 82.0, 'medium', 1200, 2000),
('var_caturra',   'Caturra',   '{}',                   'medium',
  '{"lavado","honey_yellow","natural"}', '{"citrico","frutal","panela"}', 83.5, 'medium', 1200, 1900),
('var_typica',    'Typica',    '{}',                   'medium',
  '{"lavado","natural"}', '{"floral","dulce","suave"}', 85.0, 'slow', 1500, 2200),
('var_bourbon',   'Bourbon',   '{}',                   'medium',
  '{"lavado","natural","honey_red"}', '{"frutal","dulce","chocolate"}', 85.5, 'medium', 1400, 2000),
('var_geisha',    'Geisha',    '{"Gesha"}',             'very_high',
  '{"lavado","anaerobic_lactic","honey_yellow"}', '{"floral","jazmin","durazno","tropical"}', 88.5, 'slow', 1600, 2200),
('var_tabi',      'Tabi',      '{}',                   'low',
  '{"lavado","natural"}', '{"frutal","panela","caramelo"}', 84.0, 'medium', 1500, 2100),
('var_pink_bourbon','Pink Bourbon','{}',               'high',
  '{"anaerobic_lactic","lavado","honey_red"}', '{"frutas_rojas","floral","dulce"}', 87.0, 'slow', 1600, 2200)
ON CONFLICT (id) DO NOTHING;

-- =============================================================================
-- 18. SYNC QUEUE (solo local — para v2 offline; existe en el schema desde v1)
-- =============================================================================

CREATE TABLE IF NOT EXISTS sync_queue (
  id              BIGSERIAL   PRIMARY KEY,
  operation_type  TEXT        NOT NULL CHECK (operation_type IN ('create','update','delete')),
  collection      TEXT        NOT NULL,
  document_id     TEXT        NOT NULL,
  payload         JSONB       NOT NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  retry_count     INTEGER     NOT NULL DEFAULT 0,
  last_error      TEXT,
  is_synced       BOOLEAN     NOT NULL DEFAULT FALSE
);

-- =============================================================================
-- GRANTS FINALES
-- =============================================================================

-- PostgREST necesita poder leer el schema para exponer la API
GRANT USAGE ON SCHEMA public TO anon, authenticated;
