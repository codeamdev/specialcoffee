# start.ps1 — Levanta backend (Docker Compose) + app Flutter en un solo comando
# Uso:
#   .\start.ps1              # Windows desktop (default)
#   .\start.ps1 -d edge      # Chrome/Edge
#   .\start.ps1 -d windows   # Windows desktop explícito

param(
    [string]$d = "windows"
)

$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent $MyInvocation.MyCommand.Path
$BackendDir = Join-Path $Root "backend"

# ── 1. Backend ────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host ">>> Levantando backend..."
Push-Location $BackendDir
docker compose up -d --build
Pop-Location

# ── 2. Esperar a que nginx esté healthy ───────────────────────────────────────
Write-Host ""
Write-Host ">>> Esperando servicios..."

$MaxWait = 60
$Elapsed = 0
$Interval = 3

while ($Elapsed -lt $MaxWait) {
    $ps = & docker compose -f "$BackendDir/docker-compose.yml" ps 2>&1
    if ($ps -match "nginx.*\(healthy\)") { break }
    Start-Sleep $Interval
    $Elapsed += $Interval
}

Write-Host ""
& docker compose -f "$BackendDir/docker-compose.yml" ps
Write-Host ""

# ── 3. App Flutter ────────────────────────────────────────────────────────────
Write-Host ">>> Iniciando Flutter ($d)..."
Write-Host ""

Set-Location $Root
flutter run -d $d --dart-define=DEV_MODE=true
