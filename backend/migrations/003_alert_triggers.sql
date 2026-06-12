-- ============================================================
-- Migración 003 — Triggers de evaluación de umbrales en tiempo real
-- Ejecutar: psql -U postgres -d specialcoffee -f 003_alert_triggers.sql
-- Idempotente: CREATE OR REPLACE + DROP IF EXISTS garantizan re-ejecución segura
--
-- Umbrales sincronizados con lib/ai_engine/constants/coffee_thresholds.dart
-- y lib/core/constants/app_constants.dart · 2026-06-03
-- · pH crítico bajo:   3.5   (anaerobicPhCritical / AppConstants.phCriticalLow)
-- · pH crítico alto:   5.5   (washingEffluentPhWarn — proxy; TODO calibrar con Cenicafé)
-- · Temp crítica:      30.0  (AppConstants.tempCriticalHigh; regla FERM-TEMP-CRITICAL-001)
-- · Humedad crítica:   85.0  (dryingCritAmbHumidityPct)
-- Pendiente calibración Cenicafé: D-5, D-6, D-7, D-13, D-14 en AUDIT.md
-- ============================================================

-- ── FUNCIÓN AUXILIAR: inserta alerta solo si no hay duplicado en 30 min ────────

CREATE OR REPLACE FUNCTION insert_alert_if_new(
    p_user_id        TEXT,
    p_lot_id         TEXT,
    p_reading_id     TEXT,
    p_alert_type     TEXT,
    p_alert_level    TEXT,
    p_trigger_value  FLOAT,
    p_threshold      FLOAT,
    p_message        TEXT
) RETURNS VOID LANGUAGE plpgsql AS $$
BEGIN
    -- Anti-duplicado: salta si ya existe una alerta del mismo tipo no notificada
    -- para el mismo lote en los últimos 30 minutos.
    IF EXISTS (
        SELECT 1 FROM alert_events
        WHERE alert_type       = p_alert_type
          AND lot_id           = p_lot_id
          AND notification_sent = FALSE
          AND generated_at     > NOW() - INTERVAL '30 minutes'
    ) THEN
        RETURN;
    END IF;

    INSERT INTO alert_events (
        id, user_id, lot_id, reading_id,
        rule_id, alert_type, alert_level,
        trigger_value, trigger_threshold, message_shown,
        notification_sent, resolved, generated_at
    ) VALUES (
        gen_random_uuid()::TEXT,
        p_user_id, p_lot_id, p_reading_id,
        p_alert_type,          -- reutilizamos alert_type como rule_id de referencia
        p_alert_type,
        p_alert_level,
        p_trigger_value, p_threshold, p_message,
        FALSE, FALSE, NOW()
    );
END;
$$;


-- ── TRIGGER FERMENTACIÓN ──────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_check_fermentation_alerts()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_ph_critical_low   CONSTANT FLOAT := 3.5;   -- anaerobicPhCritical / phCriticalLow
    v_ph_critical_high  CONSTANT FLOAT := 5.5;   -- washingEffluentPhWarn (proxy)
    v_temp_critical_c   CONSTANT FLOAT := 30.0;  -- AppConstants.tempCriticalHigh
BEGIN
    -- pH demasiado bajo → sobrefermentación inminente
    IF NEW.ph_value < v_ph_critical_low THEN
        PERFORM insert_alert_if_new(
            NEW.owner_id, NEW.lot_id, NEW.id,
            'PH_CRITICAL_LOW', 'critical',
            NEW.ph_value, v_ph_critical_low,
            'pH ' || NEW.ph_value || ' — demasiado ácido. Detenga la fermentación ahora.'
        );
    END IF;

    -- pH demasiado alto → fermentación posiblemente estancada o contaminada
    IF NEW.ph_value > v_ph_critical_high THEN
        PERFORM insert_alert_if_new(
            NEW.owner_id, NEW.lot_id, NEW.id,
            'PH_CRITICAL_HIGH', 'critical',
            NEW.ph_value, v_ph_critical_high,
            'pH ' || NEW.ph_value || ' — demasiado alcalino. Revisa si la fermentación inició.'
        );
    END IF;

    -- Temperatura del mucílago crítica → riesgo de proliferación bacteriana
    IF NEW.mucilago_temp_c > v_temp_critical_c THEN
        PERFORM insert_alert_if_new(
            NEW.owner_id, NEW.lot_id, NEW.id,
            'TEMP_CRITICAL_HIGH', 'critical',
            NEW.mucilago_temp_c, v_temp_critical_c,
            'Temperatura ' || NEW.mucilago_temp_c || '°C — riesgo de sobre-fermentación. Enfría el tanque.'
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_fermentation_alerts ON fermentation_readings;
CREATE TRIGGER trg_fermentation_alerts
    AFTER INSERT ON fermentation_readings
    FOR EACH ROW EXECUTE FUNCTION fn_check_fermentation_alerts();


-- ── TRIGGER SECADO ────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_check_drying_alerts()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
DECLARE
    v_humidity_critical CONSTANT FLOAT := 85.0;  -- dryingCritAmbHumidityPct
BEGIN
    -- Humedad ambiental crítica → riesgo de hongos (Aspergillus, Fusarium)
    IF NEW.humidity_pct > v_humidity_critical THEN
        PERFORM insert_alert_if_new(
            NEW.owner_id, NEW.lot_id, NEW.id,
            'HUMIDITY_CRITICAL_HIGH', 'critical',
            NEW.humidity_pct, v_humidity_critical,
            'Humedad ' || NEW.humidity_pct || '% — riesgo de hongos en el secado. Cubre el café.'
        );
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_drying_alerts ON drying_readings;
CREATE TRIGGER trg_drying_alerts
    AFTER INSERT ON drying_readings
    FOR EACH ROW EXECUTE FUNCTION fn_check_drying_alerts();


-- ── ÍNDICE PARA CONSULTAS DEL DISPATCHER ────────────────────────────────────

-- El dispatcher FastAPI consulta alert_events WHERE notification_sent = FALSE
-- con frecuencia. Este índice parcial acelera esas queries.
CREATE INDEX IF NOT EXISTS idx_alert_events_pending
    ON alert_events (generated_at)
    WHERE notification_sent = FALSE;

-- ── FIN ──────────────────────────────────────────────────────────────────────
-- Umbrales sincronizados con coffee_thresholds.dart · 2026-06-03
-- Pendiente calibración Cenicafé: D-5, D-6, D-7, D-13, D-14 en AUDIT.md
