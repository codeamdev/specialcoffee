-- migration: 0001
-- descripción: índice en drying_sessions(lot_id, started_at DESC)
-- motivo: la consulta más frecuente (getLatestSession por lot_id) hacía full scan
-- aplicar: psql -U postgres -d specialcoffee -f 0001_idx_drying_sessions_lot.sql

CREATE INDEX IF NOT EXISTS idx_drying_sessions_lot
    ON drying_sessions(lot_id, started_at DESC);
