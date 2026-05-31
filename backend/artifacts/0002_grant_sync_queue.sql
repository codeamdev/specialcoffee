-- migration: 0002
-- descripción: GRANTs para sync_queue (tabla de sincronización offline)
-- motivo: la tabla existía sin permisos definidos; PostgREST rechazaría
--         cualquier operación de sync con "permission denied"
-- aplicar: psql -U postgres -d specialcoffee -f 0002_grant_sync_queue.sql

GRANT SELECT, INSERT, UPDATE ON sync_queue TO authenticated;
GRANT USAGE ON SEQUENCE sync_queue_id_seq TO authenticated;
