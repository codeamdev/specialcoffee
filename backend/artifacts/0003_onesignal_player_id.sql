-- Migración 0003 — OneSignal player ID por usuario
-- Ejecutar: psql -U postgres -d specialcoffee -f 0003_onesignal_player_id.sql
-- Idempotente: IF NOT EXISTS garantiza que se puede re-ejecutar sin error.

ALTER TABLE users ADD COLUMN IF NOT EXISTS onesignal_player_id TEXT;
