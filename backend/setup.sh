#!/usr/bin/env bash
# =============================================================================
# SpecialCoffee AI — Server Setup Script
# Probado en: Ubuntu 22.04 LTS
# Ejecutar como root o con sudo
# Uso: sudo bash setup.sh
# =============================================================================

set -e  # salir ante cualquier error

echo "========================================"
echo "  SpecialCoffee AI — Server Setup"
echo "========================================"

# ── Variables a configurar ANTES de ejecutar ──────────────────────────────
DB_NAME="specialcoffee"
DB_USER="postgrest_auth"
DB_PASSWORD="CAMBIAR_PASSWORD"          # ← cambiar
JWT_SECRET="CAMBIAR_JWT_SECRET_32_CHARS" # ← cambiar (mismo en postgrest.conf y .env)
AUTH_PORT=8000
POSTGREST_PORT=3000
DOMAIN=""                                # ← tu dominio o IP pública

# ── 1. Sistema base ───────────────────────────────────────────────────────
echo ""
echo "[1/8] Actualizando sistema..."
apt-get update -qq && apt-get upgrade -y -qq

# ── 2. PostgreSQL ─────────────────────────────────────────────────────────
echo ""
echo "[2/8] Verificando PostgreSQL..."
if ! command -v psql &>/dev/null; then
  echo "  Instalando PostgreSQL..."
  apt-get install -y postgresql postgresql-contrib
fi

# Crear base de datos y roles
echo "  Configurando base de datos '$DB_NAME'..."
sudo -u postgres psql <<SQL
-- Base de datos
CREATE DATABASE $DB_NAME;

-- Roles para PostgREST
DO \$\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
    CREATE ROLE $DB_USER LOGIN PASSWORD '$DB_PASSWORD';
    GRANT anon, authenticated TO $DB_USER;
  END IF;
END
\$\$;

-- Permisos
GRANT CONNECT ON DATABASE $DB_NAME TO $DB_USER;
SQL

# Aplicar schema
echo "  Aplicando schema SQL..."
sudo -u postgres psql -d $DB_NAME -f "$(dirname "$0")/schema.sql"

echo "  PostgreSQL configurado."

# ── 3. Python + Auth service ──────────────────────────────────────────────
echo ""
echo "[3/8] Instalando Python y dependencias del auth service..."
apt-get install -y python3 python3-pip python3-venv

AUTH_DIR="$(dirname "$0")/auth"
python3 -m venv "$AUTH_DIR/venv"
"$AUTH_DIR/venv/bin/pip" install --quiet -r "$AUTH_DIR/requirements.txt"

# Crear .env si no existe
if [ ! -f "$AUTH_DIR/.env" ]; then
  cat > "$AUTH_DIR/.env" <<ENV
DATABASE_URL=postgresql://postgres:$(sudo -u postgres psql -t -c "SHOW hba_file;" | head -1 | xargs dirname)/specialcoffee
DATABASE_URL=postgresql://$DB_USER:$DB_PASSWORD@localhost:5432/$DB_NAME
JWT_SECRET=$JWT_SECRET
JWT_ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=60
REFRESH_TOKEN_EXPIRE_DAYS=30
AUTH_PORT=$AUTH_PORT
ENV
  echo "  .env creado en $AUTH_DIR"
fi

# ── 4. PostgREST ──────────────────────────────────────────────────────────
echo ""
echo "[4/8] Instalando PostgREST..."
PGREST_VERSION="v12.0.2"
PGREST_BIN="/usr/local/bin/postgrest"

if [ ! -f "$PGREST_BIN" ]; then
  wget -q "https://github.com/PostgREST/postgrest/releases/download/$PGREST_VERSION/postgrest-$PGREST_VERSION-linux-static-x64.tar.xz" \
    -O /tmp/postgrest.tar.xz
  tar -xf /tmp/postgrest.tar.xz -C /tmp
  mv /tmp/postgrest "$PGREST_BIN"
  chmod +x "$PGREST_BIN"
fi

# Actualizar postgrest.conf con los valores reales
CONF_FILE="$(dirname "$0")/postgrest.conf"
sed -i "s/CAMBIAR_PASSWORD/$DB_PASSWORD/g" "$CONF_FILE"
sed -i "s/CAMBIAR_POR_SECRET_DE_32_CHARS_MINIMO/$JWT_SECRET/g" "$CONF_FILE"
cp "$CONF_FILE" /etc/postgrest.conf

echo "  PostgREST instalado en $PGREST_BIN"

# ── 5. Nginx ──────────────────────────────────────────────────────────────
echo ""
echo "[5/8] Configurando Nginx..."
apt-get install -y nginx

NGINX_CONF="$(dirname "$0")/nginx/specialcoffee.conf"
if [ -n "$DOMAIN" ]; then
  sed -i "s/TU_DOMINIO_O_IP/$DOMAIN/g" "$NGINX_CONF"
  sed -i "s/TU_DOMINIO/$DOMAIN/g" "$NGINX_CONF"
fi

cp "$NGINX_CONF" /etc/nginx/sites-available/specialcoffee
ln -sf /etc/nginx/sites-available/specialcoffee /etc/nginx/sites-enabled/specialcoffee
rm -f /etc/nginx/sites-enabled/default
nginx -t && systemctl reload nginx

# ── 6. Systemd — Auth service ─────────────────────────────────────────────
echo ""
echo "[6/8] Configurando servicio systemd para auth..."
AUTH_ABS="$(realpath "$(dirname "$0")/auth")"

cat > /etc/systemd/system/specialcoffee-auth.service <<SERVICE
[Unit]
Description=SpecialCoffee Auth Service
After=network.target postgresql.service

[Service]
Type=simple
WorkingDirectory=$AUTH_ABS
EnvironmentFile=$AUTH_ABS/.env
ExecStart=$AUTH_ABS/venv/bin/python main.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# ── 7. Systemd — PostgREST ────────────────────────────────────────────────
echo ""
echo "[7/8] Configurando servicio systemd para PostgREST..."
cat > /etc/systemd/system/specialcoffee-postgrest.service <<SERVICE
[Unit]
Description=SpecialCoffee PostgREST
After=network.target postgresql.service

[Service]
Type=simple
ExecStart=/usr/local/bin/postgrest /etc/postgrest.conf
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

# ── 8. Activar servicios ──────────────────────────────────────────────────
echo ""
echo "[8/8] Activando servicios..."
systemctl daemon-reload
systemctl enable specialcoffee-auth specialcoffee-postgrest
systemctl start specialcoffee-auth specialcoffee-postgrest

echo ""
echo "========================================"
echo "  Setup completado exitosamente"
echo "========================================"
echo ""
echo "  Servicios activos:"
echo "    Auth service: http://127.0.0.1:$AUTH_PORT"
echo "    PostgREST:    http://127.0.0.1:$POSTGREST_PORT"
echo "    Nginx:        https://$DOMAIN"
echo ""
echo "  Verificar estado:"
echo "    systemctl status specialcoffee-auth"
echo "    systemctl status specialcoffee-postgrest"
echo ""
echo "  Logs:"
echo "    journalctl -u specialcoffee-auth -f"
echo "    journalctl -u specialcoffee-postgrest -f"
echo ""
echo "  PENDIENTE: configurar SSL con certbot:"
echo "    apt-get install -y certbot python3-certbot-nginx"
echo "    certbot --nginx -d $DOMAIN"
echo ""
