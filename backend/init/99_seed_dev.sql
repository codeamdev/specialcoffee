-- Usuarios de desarrollo — solo para entornos locales.
-- Credenciales: farmer/farmer123  processor/processor123  barista/barista123
-- Este archivo se ejecuta solo cuando el volumen está vacío (primera vez).
INSERT INTO users (email, password_hash, display_name, role, region) VALUES
  ('farmer@test.com',    '$2b$12$Q2EpmWu1YDDb.jGypR83F.KFaHIIp.BgNgsYspxN9hLsBHHM30AxC', 'Test Farmer',    'farmer',    'Huila'),
  ('processor@test.com', '$2b$12$h81hF1qc.YHWQ4FiD/IBQeB.lCvC4DZvzdNtk4ewA/aRh9AGV6D5K', 'Test Processor', 'processor', 'Nariño'),
  ('barista@test.com',   '$2b$12$G29YAGQMLfdvzsGKAx.HwOvI/BM4tvoWj.yzIJQP/PizXPXyDZX7e', 'Test Barista',   'barista',   'Bogotá')
ON CONFLICT (email) DO NOTHING;
