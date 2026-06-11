-- ============================================================
-- Migración 004 — Tablas de sync para proceso húmedo
-- Ejecutar: psql -U postgres -d specialcoffee -f 004_cosecha_sync_tables.sql
-- Idempotente: CREATE TABLE IF NOT EXISTS + CREATE INDEX IF NOT EXISTS
--
-- Tablas nuevas:
--   cosecha_pases          — unidad de proceso húmedo por lote
--   washing_sessions       — sesiones de lavado
--   milling_sessions       — sesiones de trilla
--   classification_sessions — sesiones de clasificación/flotación
--
-- Patrón: igual que lots/fermentation_sessions (owner_id + RLS).
-- REVISAR CON PRODUCTO: washing/milling/classification pueden necesitar
--   campos adicionales según el flujo real de calidad SCA.
-- ============================================================


-- =============================================================================
-- cosecha_pases — unidad de proceso húmedo por lote
-- =============================================================================

CREATE TABLE IF NOT EXISTS cosecha_pases (
  id                        TEXT        PRIMARY KEY,
  lot_id                    TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id                  TEXT        NOT NULL REFERENCES users(id),

  -- Recolección
  fecha_recoleccion         TIMESTAMPTZ NOT NULL,
  hora_inicio               TIMESTAMPTZ,
  hora_fin                  TIMESTAMPTZ,
  peso_cereza_kg            FLOAT       NOT NULL,
  num_operarios             INTEGER,
  brix_promedio             FLOAT,
  pct_madurez_visual        FLOAT,

  -- Proceso
  tipo_proceso              TEXT        NOT NULL
                            CHECK (tipo_proceso IN (
                              'lavado','natural','honey_yellow','honey_red',
                              'anaerobic_lactic','anaerobic_carbonic'
                            )),

  -- Clasificación implícita
  peso_flotacion_kg         FLOAT,
  pct_flotacion             FLOAT,

  -- Despulpado implícito
  peso_pergamino_humedo_kg  FLOAT,
  horas_hasta_despulpe      FLOAT,

  -- Workflow
  etapa_actual              TEXT        NOT NULL DEFAULT 'clasificacion'
                            CHECK (etapa_actual IN (
                              'clasificacion','fermentacion','lavado',
                              'secado','trilla','completado'
                            )),
  status                    TEXT        NOT NULL DEFAULT 'activo'
                            CHECK (status IN ('activo','completado','abandonado')),

  notas                     TEXT,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_cosecha_pases_lot     ON cosecha_pases(lot_id);
CREATE INDEX IF NOT EXISTS idx_cosecha_pases_owner   ON cosecha_pases(owner_id, created_at DESC);
CREATE INDEX IF NOT EXISTS idx_cosecha_pases_status  ON cosecha_pases(owner_id, status);

GRANT SELECT, INSERT, UPDATE ON cosecha_pases TO authenticated;

ALTER TABLE cosecha_pases ENABLE ROW LEVEL SECURITY;
CREATE POLICY cosecha_pases_owner ON cosecha_pases
  USING (owner_id = current_user_id());


-- =============================================================================
-- washing_sessions — sesiones de lavado post-fermentación
-- REVISAR CON PRODUCTO: validar campos contra flujo real
-- =============================================================================

CREATE TABLE IF NOT EXISTS washing_sessions (
  id                        TEXT        PRIMARY KEY,
  lot_id                    TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id                  TEXT        NOT NULL REFERENCES users(id),
  fermentation_session_id   TEXT        REFERENCES fermentation_sessions(id),

  water_temp_c              FLOAT       NOT NULL,
  water_changes             INTEGER     NOT NULL,
  effluent_ph_final         FLOAT       NOT NULL,
  duration_h                FLOAT       NOT NULL,
  washed_at                 TIMESTAMPTZ NOT NULL,

  ai_alert_level            TEXT        NOT NULL DEFAULT 'none',
  ai_alert_message          TEXT,

  notes                     TEXT,
  created_at                TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at                TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_washing_sessions_lot   ON washing_sessions(lot_id);
CREATE INDEX IF NOT EXISTS idx_washing_sessions_owner ON washing_sessions(owner_id, created_at DESC);

GRANT SELECT, INSERT, UPDATE ON washing_sessions TO authenticated;

ALTER TABLE washing_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY washing_sessions_owner ON washing_sessions
  USING (owner_id = current_user_id());


-- =============================================================================
-- milling_sessions — sesiones de trilla (despergaminado)
-- REVISAR CON PRODUCTO: validar campos contra flujo real
-- =============================================================================

CREATE TABLE IF NOT EXISTS milling_sessions (
  id                  TEXT        PRIMARY KEY,
  lot_id              TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id            TEXT        NOT NULL REFERENCES users(id),

  input_kg_parchment  FLOAT       NOT NULL,
  output_kg_green     FLOAT       NOT NULL,
  yield_pct           FLOAT       NOT NULL,

  ai_alert_level      TEXT        NOT NULL DEFAULT 'none',
  ai_alert_message    TEXT,

  notes               TEXT,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_milling_sessions_lot   ON milling_sessions(lot_id);
CREATE INDEX IF NOT EXISTS idx_milling_sessions_owner ON milling_sessions(owner_id, created_at DESC);

GRANT SELECT, INSERT, UPDATE ON milling_sessions TO authenticated;

ALTER TABLE milling_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY milling_sessions_owner ON milling_sessions
  USING (owner_id = current_user_id());


-- =============================================================================
-- classification_sessions — flotación y descarte manual
-- REVISAR CON PRODUCTO: validar campos contra flujo real
-- =============================================================================

CREATE TABLE IF NOT EXISTS classification_sessions (
  id                  TEXT        PRIMARY KEY,
  lot_id              TEXT        NOT NULL REFERENCES lots(id) ON DELETE CASCADE,
  owner_id            TEXT        NOT NULL REFERENCES users(id),
  harvest_session_id  TEXT,

  kg_entrada          FLOAT       NOT NULL,
  brix_cereza         FLOAT,
  kg_flotantes        FLOAT       NOT NULL DEFAULT 0,
  kg_descarte_manual  FLOAT       NOT NULL DEFAULT 0,

  ai_alert_level      TEXT        NOT NULL DEFAULT 'none',
  ai_alert_message    TEXT,

  notes               TEXT,
  classified_at       TIMESTAMPTZ NOT NULL,
  created_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_classification_sessions_lot   ON classification_sessions(lot_id);
CREATE INDEX IF NOT EXISTS idx_classification_sessions_owner ON classification_sessions(owner_id, created_at DESC);

GRANT SELECT, INSERT, UPDATE ON classification_sessions TO authenticated;

ALTER TABLE classification_sessions ENABLE ROW LEVEL SECURITY;
CREATE POLICY classification_sessions_owner ON classification_sessions
  USING (owner_id = current_user_id());


-- ── FIN ──────────────────────────────────────────────────────────────────────
-- REVISAR CON PRODUCTO: washing/milling/classification — alinear con SCA y flujo real
-- Deuda: agregar lat/lng/farm_area_ha/blend_variety_ids a lots (hoy quedan solo local)
