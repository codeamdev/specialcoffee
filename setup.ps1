# SpecialCoffee AI -- Setup inicial completo (Windows)
# Ejecutar desde PowerShell en la raiz del proyecto:
#   .\setup.ps1
#
# Si PowerShell bloquea la ejecucion, correr primero:
#   Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

$ErrorActionPreference = 'Stop'

function Step($msg)  { Write-Host "`n>> $msg" -ForegroundColor Cyan }
function Ok($msg)    { Write-Host "   [OK]   $msg" -ForegroundColor Green }
function Warn($msg)  { Write-Host "   [WARN] $msg" -ForegroundColor Yellow }
function Fail($msg)  { Write-Host "   [FAIL] $msg" -ForegroundColor Red }
function Info($msg)  { Write-Host "          $msg" -ForegroundColor Gray }

function Require($cmd, $hint) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        Fail "$cmd no encontrado."
        Info $hint
        exit 1
    }
}

# ---------------------------------------------------------------------------
# 1. Flutter
# ---------------------------------------------------------------------------

Step "Verificando Flutter SDK..."

Require "flutter" "Instalar desde: https://docs.flutter.dev/get-started/install/windows"

$flutterOut = flutter --version 2>&1
$flutterLine = ($flutterOut | Select-String "Flutter").ToString().Trim()
Ok $flutterLine

$dartOut = dart --version 2>&1
Ok $dartOut.ToString().Trim()

# ---------------------------------------------------------------------------
# 2. Dependencias
# ---------------------------------------------------------------------------

Step "Instalando dependencias (flutter pub get)..."

flutter pub get
if ($LASTEXITCODE -ne 0) { Fail "flutter pub get fallo."; exit 1 }
Ok "Dependencias instaladas."

# ---------------------------------------------------------------------------
# 3. Generacion de codigo
# ---------------------------------------------------------------------------

Step "Generando codigo (freezed, riverpod, drift, json_serializable)..."
Info "Primera ejecucion puede tardar 30-60 segundos..."

dart run build_runner build --delete-conflicting-outputs
if ($LASTEXITCODE -ne 0) { Fail "build_runner fallo."; exit 1 }
Ok "Generacion completada."

$generatedFiles = @(
    "lib\ai_engine\models\ai_context.freezed.dart",
    "lib\ai_engine\models\ai_rule.freezed.dart",
    "lib\core\di\providers.g.dart",
    "lib\presentation\providers\brew_provider.g.dart",
    "lib\presentation\providers\fermentation_provider.g.dart",
    "lib\presentation\providers\ai_engine_provider.g.dart"
)

$missingGenerated = $generatedFiles | Where-Object { -not (Test-Path $_) }
if ($missingGenerated.Count -gt 0) {
    Warn "Archivos generados faltantes:"
    $missingGenerated | ForEach-Object { Info $_ }
} else {
    Ok "Todos los archivos .g.dart / .freezed.dart verificados ($($generatedFiles.Count)/$($generatedFiles.Count))."
}

# ---------------------------------------------------------------------------
# 4. Firebase
# ---------------------------------------------------------------------------

Step "Verificando configuracion de Firebase..."

$hasGoogleServices = Test-Path "android\app\google-services.json"
$firebaseOptionsContent = Get-Content "lib\firebase_options.dart" -Raw -ErrorAction SilentlyContinue
$hasFirebaseOptions = $firebaseOptionsContent -and ($firebaseOptionsContent -notmatch "TU_PROJECT_ID")

if ($hasGoogleServices -and $hasFirebaseOptions) {
    Ok "Firebase configurado correctamente."
} else {
    Warn "Firebase NO configurado. La app no arrancara sin esto."
    Info ""
    Info "Pasos:"
    Info "  1. Instalar FlutterFire CLI:"
    Info "       dart pub global activate flutterfire_cli"
    Info ""
    Info "  2. Agregar pub cache al PATH (en esta sesion):"
    Info "       `$env:PATH += `";`$env:LOCALAPPDATA\Pub\Cache\bin`""
    Info ""
    Info "  3. Configurar (requiere proyecto en console.firebase.google.com):"
    Info "       flutterfire configure --project=TU_PROJECT_ID"
    Info ""
    if (-not $hasGoogleServices)  { Warn "Falta: android\app\google-services.json" }
    if (-not $hasFirebaseOptions) { Warn "lib\firebase_options.dart tiene valores placeholder." }
}

# ---------------------------------------------------------------------------
# 5. Fuentes
# ---------------------------------------------------------------------------

Step "Verificando fuentes tipograficas..."

$fontFiles = @(
    "assets\fonts\DMSerifDisplay-Regular.ttf",
    "assets\fonts\DMSerifDisplay-Italic.ttf",
    "assets\fonts\Inter-Regular.ttf",
    "assets\fonts\Inter-Medium.ttf",
    "assets\fonts\Inter-SemiBold.ttf",
    "assets\fonts\Inter-Bold.ttf",
    "assets\fonts\JetBrainsMono-Regular.ttf",
    "assets\fonts\JetBrainsMono-Medium.ttf"
)

$missingFonts = $fontFiles | Where-Object { -not (Test-Path $_) }

if ($missingFonts.Count -eq 0) {
    Ok "Todas las fuentes presentes ($($fontFiles.Count)/$($fontFiles.Count))."
} else {
    Warn "$($missingFonts.Count) de $($fontFiles.Count) fuentes faltantes."
    Info "Descargar de Google Fonts y copiar a assets\fonts\:"
    Info "  DM Serif Display : https://fonts.google.com/specimen/DM+Serif+Display"
    Info "  Inter            : https://fonts.google.com/specimen/Inter"
    Info "  JetBrains Mono   : https://fonts.google.com/specimen/JetBrains+Mono"
    Info ""
    Info "Solucion temporal: comentar el bloque 'fonts:' en pubspec.yaml"
}

# ---------------------------------------------------------------------------
# 6. Tests -- Capa 1: AI Engine
# ---------------------------------------------------------------------------

Step "Ejecutando tests del motor IA (Capa 1 - sin Firebase)..."

flutter test test\ai_engine\ --reporter compact
if ($LASTEXITCODE -ne 0) { Fail "Tests del AI Engine fallaron."; exit 1 }
Ok "AI Engine: todos los tests pasaron."

# ---------------------------------------------------------------------------
# 7. Tests -- Capa 2: Providers
# ---------------------------------------------------------------------------

Step "Ejecutando tests de providers (Capa 2 - sin Firebase)..."

flutter test test\presentation\providers\ --reporter compact
if ($LASTEXITCODE -ne 0) { Fail "Tests de providers fallaron."; exit 1 }
Ok "Providers: todos los tests pasaron."

# ---------------------------------------------------------------------------
# 8. Tests -- Capa 3: Widgets
# ---------------------------------------------------------------------------

Step "Ejecutando tests de widgets (Capa 3)..."

flutter test test\presentation\widgets\ --reporter compact
if ($LASTEXITCODE -ne 0) { Fail "Tests de widgets fallaron."; exit 1 }
Ok "Widgets: todos los tests pasaron."

# ---------------------------------------------------------------------------
# 9. Resumen
# ---------------------------------------------------------------------------

Write-Host ""
Write-Host "=================================================" -ForegroundColor DarkGray
Write-Host "  RESUMEN DE SETUP" -ForegroundColor White
Write-Host "=================================================" -ForegroundColor DarkGray

$summary = [ordered]@{
    "Flutter SDK"     = (Get-Command flutter -ErrorAction SilentlyContinue) -ne $null
    "Dependencias"    = $true
    "Codigo generado" = ($missingGenerated.Count -eq 0)
    "Firebase"        = ($hasGoogleServices -and $hasFirebaseOptions)
    "Fuentes"         = ($missingFonts.Count -eq 0)
    "Tests AI Engine" = $true
    "Tests Providers" = $true
    "Tests Widgets"   = $true
}

foreach ($item in $summary.GetEnumerator()) {
    if ($item.Value) {
        Write-Host ("  [OK]  " + $item.Key) -ForegroundColor Green
    } else {
        Write-Host ("  [--]  " + $item.Key) -ForegroundColor Yellow
    }
}

Write-Host "=================================================" -ForegroundColor DarkGray
Write-Host ""

$pendingFirebase = -not ($hasGoogleServices -and $hasFirebaseOptions)
$pendingFonts    = ($missingFonts.Count -gt 0)

if ($pendingFirebase -or $pendingFonts) {
    Write-Host "Pendientes antes de correr la app:" -ForegroundColor Yellow
    if ($pendingFirebase) {
        Write-Host "  -> Configurar Firebase (ver instrucciones arriba)" -ForegroundColor Yellow
    }
    if ($pendingFonts) {
        Write-Host "  -> Agregar fuentes a assets\fonts\" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "Cuando estes listo, corre la app con:" -ForegroundColor White
Write-Host "  flutter run" -ForegroundColor Cyan
Write-Host ""
