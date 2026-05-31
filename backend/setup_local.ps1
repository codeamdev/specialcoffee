# =============================================================================
# SpecialCoffee AI - Setup local (Windows)
# Ejecutar una sola vez: .\backend\setup_local.ps1
# Requisitos: PostgreSQL instalado, Python 3.10+
# =============================================================================

$ErrorActionPreference = "Stop"
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# Leer contraseña de PostgreSQL desde .env (nunca hardcodear aquí)
$envFile = "$scriptDir\.env"
if (-not (Test-Path $envFile)) {
    Write-Error "No se encontró $envFile. Copiar .env.example a .env y rellenar los valores."
    exit 1
}
$envVars = Get-Content $envFile | Where-Object { $_ -match '^\s*[^#]' -and $_ -match '=' }
foreach ($line in $envVars) {
    $parts = $line -split '=', 2
    [System.Environment]::SetEnvironmentVariable($parts[0].Trim(), $parts[1].Trim())
}
$env:PGPASSWORD = [System.Environment]::GetEnvironmentVariable('POSTGRES_PASSWORD')
$pgUser         = [System.Environment]::GetEnvironmentVariable('POSTGRES_USER') ?? 'postgres'

if ([string]::IsNullOrEmpty($env:PGPASSWORD)) {
    Write-Error "POSTGRES_PASSWORD no está definida en .env"
    exit 1
}

Write-Host ""
Write-Host "==================================================="
Write-Host "  SpecialCoffee AI - Setup Local"
Write-Host "==================================================="

# ── 1. Crear base de datos ────────────────────────────────────────────────
Write-Host ""
Write-Host "[1/4] Configurando PostgreSQL..."

$dbExists = & psql -U $pgUser -tAc "SELECT 1 FROM pg_database WHERE datname='specialcoffee'" postgres 2>$null
if ($dbExists -ne "1") {
    Write-Host "  Creando base de datos specialcoffee..."
    & psql -U $pgUser -c "CREATE DATABASE specialcoffee;" postgres
} else {
    Write-Host "  Base de datos specialcoffee ya existe."
}

# Guardar SQL en archivo temporal para evitar conflicto con $$ de PostgreSQL
$rolesSqlPath = [System.IO.Path]::GetTempFileName()
@'
DO $$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') THEN
    CREATE ROLE anon NOLOGIN;
  END IF;
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') THEN
    CREATE ROLE authenticated NOLOGIN;
  END IF;
END
$$;
GRANT anon, authenticated TO postgres;
'@ | Out-File -FilePath $rolesSqlPath -Encoding utf8

Write-Host "  Creando roles anon y authenticated..."
& psql -U $pgUser -d specialcoffee -f $rolesSqlPath
Remove-Item $rolesSqlPath

Write-Host "  Aplicando schema SQL..."
& psql -U $pgUser -d specialcoffee -f "$scriptDir\schema.sql"

Write-Host "  Aplicando permisos a roles..."
& psql -U $pgUser -d specialcoffee -c "GRANT USAGE ON SCHEMA public TO anon, authenticated; GRANT SELECT ON ALL TABLES IN SCHEMA public TO anon; GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO authenticated; GRANT USAGE ON ALL SEQUENCES IN SCHEMA public TO authenticated;"

Write-Host "  PostgreSQL listo."

# ── 2. Python - dependencias del auth service ──────────────────────────────
Write-Host ""
Write-Host "[2/4] Instalando dependencias Python..."

$authDir = "$scriptDir\auth"
if (-not (Test-Path "$authDir\venv")) {
    Write-Host "  Creando entorno virtual con Python 3..."
    python3 -m venv "$authDir\venv"
}
& "$authDir\venv\Scripts\pip" install --quiet -r "$authDir\requirements.txt"

Write-Host "  Dependencias instaladas."

# ── 3. Verificar Docker (necesario para PostgREST) ─────────────────────────
Write-Host ""
Write-Host "[3/4] Verificando Docker..."

$dockerVersion = docker --version 2>$null
if ($dockerVersion) {
    Write-Host "  Docker disponible: $dockerVersion"
} else {
    Write-Host "  ADVERTENCIA: Docker no encontrado."
    Write-Host "  PostgREST requiere Docker en Windows."
    Write-Host "  Instalar desde: https://www.docker.com/products/docker-desktop"
}

# ── 4. Resumen ─────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "==================================================="
Write-Host "  Setup completado."
Write-Host "==================================================="
Write-Host ""
Write-Host "  Abre DOS terminales y ejecuta:"
Write-Host ""
Write-Host "  Terminal 1 - Auth (FastAPI):"
Write-Host "    cd backend\auth"
Write-Host "    .\venv\Scripts\uvicorn main:app --host 127.0.0.1 --port 8000 --reload"
Write-Host ""
Write-Host "  Terminal 2 - PostgREST:"
Write-Host "    .\backend\postgrest.exe .\backend\postgrest_local.conf"
Write-Host ""
Write-Host "  Verificar:"
Write-Host "    curl http://127.0.0.1:8000/health"
Write-Host "    curl http://127.0.0.1:3000/"
Write-Host ""
