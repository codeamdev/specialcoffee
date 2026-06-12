# Android Release Checklist — SpecialCoffee AI

## Variables requeridas antes del build

| Variable | Dónde configurar | Estado |
|----------|-----------------|--------|
| `ONESIGNAL_APP_ID` | Dashboard OneSignal → App Settings | ⬜ pendiente |
| `ONESIGNAL_REST_API_KEY` | Dashboard OneSignal → App Settings → Keys & IDs | ⬜ pendiente |
| `weather_config.dart` | `lib/core/config/weather_config.dart` (gitignored) | ⬜ confirmar que existe |
| `google-services.json` | `android/app/google-services.json` (gitignored) | ⬜ confirmar que existe |
| `firebase_options.dart` | `lib/firebase_options.dart` (gitignored) | ⬜ confirmar que existe |

---

## Pasos previos al build

### 1. Configurar variables de entorno del backend

Crear o actualizar `backend/.env` con los valores reales:

```env
ONESIGNAL_APP_ID=tu_app_id_del_dashboard
ONESIGNAL_REST_API_KEY=tu_rest_api_key_del_dashboard
```

Verificar que `backend/docker-compose.yml` lee `${ONESIGNAL_APP_ID}` y `${ONESIGNAL_REST_API_KEY}` (no valores hardcodeados).

### 2. Correr migraciones en PostgreSQL de producción

```bash
# Ejecutar en orden si la BD de producción no las tiene aún
psql -U postgres -d specialcoffee -f backend/artifacts/0001_idx_drying_sessions_lot.sql
psql -U postgres -d specialcoffee -f backend/artifacts/0002_grant_sync_queue.sql
psql -U postgres -d specialcoffee -f backend/artifacts/0003_onesignal_player_id.sql
psql -U postgres -d specialcoffee -f backend/artifacts/0004_fcm_token.sql
```

### 3. Verificar archivos gitignored en la máquina de build

```powershell
Test-Path lib\core\config\weather_config.dart   # debe ser True
Test-Path lib\firebase_options.dart              # debe ser True
Test-Path android\app\google-services.json       # debe ser True
Test-Path lib\core\config\gemini_config.dart     # debe ser True (si Gemini está activo)
```

### 4. Conectar dispositivo Android con USB debugging

```bash
flutter devices   # verificar que el dispositivo aparece
adb devices       # verificar que ADB lo reconoce
```

---

## Comando de build

```powershell
# APK de debug con todas las variables
flutter build apk `
  --dart-define=DEV_MODE=false `
  --dart-define=ONESIGNAL_APP_ID=tu_app_id_aqui

# AAB para Play Store
flutter build appbundle `
  --dart-define=DEV_MODE=false `
  --dart-define=ONESIGNAL_APP_ID=tu_app_id_aqui
```

## Instalación en dispositivo conectado

```powershell
flutter install
# O directamente:
adb install build\app\outputs\flutter-apk\app-release.apk
```

---

## Checklist de prueba post-instalación

1. ⬜ Abrir la app → pantalla de login aparece sin errores
2. ⬜ Registrar usuario nuevo → recibir JWT válido, navegar al dashboard
3. ⬜ Login con usuario existente → JWT válido, dashboard
4. ⬜ Verificar en dashboard OneSignal que aparece un nuevo suscriptor
5. ⬜ Registrar una lectura de pH = 3.2 en una sesión de fermentación activa
6. ⬜ Esperar ≤ 60 segundos → verificar que llega push notification al dispositivo
7. ⬜ Tap en la notificación → app navega al lote correcto (deep-link)
8. ⬜ Logout → OneSignal.logout() se llama; el dispositivo deja de recibir notificaciones

---

## Troubleshooting

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| Push no llega | `ONESIGNAL_APP_ID` vacío o incorrecto | Verificar dart-define y dashboard |
| `player_id` null en logs | Permisos de notificación denegados | Ir a Ajustes → Notificaciones y habilitarlas |
| Deep-link no navega | `lot_id` ausente en el payload | Verificar que `dispatch_pending_alerts` incluye `lot_id` en los datos |
| Build falla con Firebase | `google-services.json` ausente | Copiar desde Firebase Console |
| Backend no envía push | `ONESIGNAL_REST_API_KEY` incorrecto en `.env` | Verificar clave en dashboard OneSignal |
