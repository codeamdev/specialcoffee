-- migration: 0004 — FCM push token por usuario
-- Ejecutar: psql -U postgres -d specialcoffee -f 0004_fcm_token.sql

ALTER TABLE users ADD COLUMN IF NOT EXISTS fcm_token TEXT;
