# Camino A — Setup Android y verificación en dispositivo

> Archivo vivo: se actualiza a medida que se descubren bugs o requisitos en testing de Windows/Android.
> Última actualización: 2026-05-25

---

## 1. Instalación del toolchain

- [ ] Descargar e instalar **Android Studio** (https://developer.android.com/studio)
- [ ] Ejecutar el wizard de primer lanzamiento — instala automáticamente:
  - SDK Platform 34
  - Android SDK Build-Tools 34
  - Android Emulator
  - Android SDK Platform-Tools
- [ ] Aceptar licencias: `flutter doctor --android-licenses`
- [ ] Verificar: `flutter doctor` — Android toolchain en verde
- [ ] Verificar: `flutter devices` — muestra emulador o dispositivo físico Android

## 2. Crear emulador (AVD)

- [ ] Android Studio › Device Manager › Create Virtual Device
  - Recommended: **Pixel 6**, API 34 (Android 14)
  - Secondary: API 21 (Android 5) — para validar minSdk límite inferior
- [ ] Arrancar emulador: `flutter emulators --launch <emulator_id>`
- [ ] Confirmar que `flutter devices` lo lista

## 3. Configuración ya hecha (no repetir)

- [x] `android/app/build.gradle.kts` — `applicationId = "com.specialcoffee.app"`, `minSdk = 21`
- [x] `AndroidManifest.xml` — permisos: `RECEIVE_BOOT_COMPLETED`, `VIBRATE`, `POST_NOTIFICATIONS`
- [x] `AndroidManifest.xml` — receivers: `ScheduledNotificationReceiver`, `ScheduledNotificationBootReceiver`
- [x] `MainActivity.kt` — paquete movido a `com.specialcoffee.app`
- [ ] **D-11**: Decidir `applicationId` definitivo antes de publicar en Play Store
      (verificar disponibilidad de dominio `specialcoffee.com` y ausencia de colisión de marca)

## 4. Primera compilación Android

- [ ] `flutter build apk --debug` — sin errores de compilación
- [ ] Verificar que todos los plugins (Drift, flutter_local_notifications, path_provider, riverpod) resuelven sus bindings Android nativos
- [ ] `flutter install` en emulador — instala el APK de debug

## 5. Tests de runtime — flujo completo (D-1)

### 5a. Instalación limpia (onCreate path — Drift v6 fresh)
- [ ] Desinstalar la app si existe, instalar de nuevo
- [ ] Abrir la app — sin crash en inicialización
- [ ] Verificar que el schema v6 se crea correctamente (11 tablas, incluye `local_lots`)
- [ ] Navegar a Lots — lista vacía sin error
- [ ] Crear un lote — debe persistir localmente y aparecer en la lista

### 5b. Flujo no-natural completo (6 pasos)
- [ ] Crear un lote con proceso "Lavado"
- [ ] **Cosecha**: registrar pase con Brix, color, peso — verificar reglas AI (BRIX-OPTIMAL, etc.)
- [ ] **Clasificación**: ingresar flotación y aprovechamiento — verificar recomendación y botón "Ir al despulpado"
- [ ] **Despulpado**: verificar DelayCard con tiempo transcurrido, registrar kg
- [ ] **Fermentación**: registrar sesión — verificar que se programa notificación
- [ ] **Secado**: registrar sesión con humedad — verificar alerta si humedad fuera de rango
- [ ] **Catación**: llenar formulario SCA, registrar — verificar score y recomendación IA
- [ ] Stepper en lot_detail: verificar que los 6 pasos muestran done/active/next correctamente

### 5c. Flujo natural completo (4 pasos)
- [ ] Crear un lote con proceso "Natural"
- [ ] **Cosecha** → **Clasificación** → **Secado** → **Catación**
- [ ] Verificar que DepulpingScreen no aparece en el stepper para proceso natural
- [ ] Verificar que ClassificationScreen muestra "Ir al secado" (no "Ir al despulpado") para natural

### 5d. Notificaciones (requiere esperar o mockar tiempo)
- [ ] Registrar sesión de fermentación
- [ ] Verificar que se programa una notificación (`zonedSchedule` con `inexactAllowWhileIdle`)
- [ ] Cerrar la app completamente
- [ ] Esperar a que llegue la notificación (o usar un intervalo corto de prueba)
- [ ] Verificar que la notificación aparece con el mensaje correcto

### 5e. Comportamiento offline
- [ ] Desactivar la red (modo avión)
- [ ] Realizar flujo completo — todo debe funcionar sin errores de red
- [ ] Verificar que no hay crashes por timeout de Supabase/PostgREST

## 6. Test de migración encadenada (D-4 — mitigado, pendiente verificación)

> D-4: Las migraciones v1→v6 son aditivas (solo CREATE TABLE). El onUpgrade
> encadenado aún no ha sido ejecutado en dispositivo real con base pre-existente.

- [ ] Obtener o compilar el APK del estado Sprint 1 (schemaVersion=1 — commits anteriores a b3c1633)
- [ ] Instalar Sprint 1 APK en emulador
- [ ] Crear datos: un lote con sesión de fermentación
- [ ] Instalar el APK actual (schemaVersion=6) sobre el anterior — sin desinstalar
- [ ] Verificar que el lote y la sesión de fermentación del Sprint 1 siguen intactos
- [ ] Verificar que los pasos nuevos del stepper (clasificación, despulpado, catación) aparecen como "next/pending" (sin datos)
- [ ] Verificar que la tabla `local_lots` se crea vacía (migración v6)
- [ ] Si cualquier migración falla: revisar el bloque onUpgrade en `app_database.dart`

## 7. Bugs encontrados en testing Windows (actualizar aquí)

> Esta sección se llena durante el Camino B (Windows desktop).
> Cada bug encontrado en Windows es candidato a reproducirse en Android también.

### GAP-01 — LotRepository era 100% PostgREST: sin backend, el flujo completo era inalcanzable ✅ CERRADO
- **Impacto original**: bloqueaba D-1 completo. No se podía llegar a la pantalla de detalle de un lote sin PostgREST corriendo — `getLots()` y `getLotById()` eran PostgREST-only
- **Raíz**: `PostgRESTLotRepository` era la única implementación. La tabla `Lots` existía en Drift desde v1 pero nunca se escribía ni leía localmente
- **Fix aplicado (schemaVersion 6)**:
  1. Nueva tabla `local_lots` (14 campos, soft-delete vía `deleted_at`) — CREATE TABLE aditivo, D-4 no se reabre
  2. `LotDao` + `LotLocalRepository` — implementan `LotRepository` sobre Drift
  3. `lotRepositoryProvider`: switch `ApiConfig.devBypass` → `LotLocalRepository` (local) o `PostgRESTLotRepository` (prod)
  4. Con `devBypass = true` el modo es **100% local** — PostgREST no se ejerce en ningún módulo hasta el ítem #14
- **Deuda generada**: D-12 — dos tablas para Lot (`local_lots` + `lots`) que el ítem #14 debe reconciliar
- **Estado**: devBypass cubre el flujo completo sin red. D-1 desbloqueado.

### BUG-01 — Hard crash cuando AuthNotifier.login() recibe error de red/400 ✅ CERRADO
- **Reproducir**: `devBypass = false`, lanzar app, intentar login con backend caído o con credenciales inválidas
- **Síntoma**: `⛔ [Riverpod] FAILED: authProvider` → `Lost connection to device` (crash del proceso)
- **Causa raíz real**: `appRouterProvider` era `@riverpod` (auto-dispose) + `ref.watch(authProvider)`.
  Cuando `authProvider` cambiaba de `AsyncLoading → AsyncError`, el provider recreaba el GoRouter.
  Durante la transición, errores de providers en vuelo escapaban al zone raíz sin listener → proceso muere.
- **Diagnóstico descartado**: sweep completo de `.value!`, `.requireValue`, `.when()` — todos los handlers de error están correctamente en su lugar. El patrón sospechado no existía.
- **Fix aplicado (commit BUG-01/02)**:
  1. `app_router.dart`: `@Riverpod(keepAlive: true)` + `_RouterNotifier extends ChangeNotifier` con `ref.listen`. GoRouter se crea UNA sola vez. El redirect usa `ref.read(authProvider)` en tiempo de ejecución, no una closure capturada.
  2. `main.dart`: `PlatformDispatcher.instance.onError = (e, s) { debugPrint(...); return true; }` — captura cualquier excepción async que escape el zone Flutter.

### BUG-02 — Hard crash cuando userLotsProvider recibe error de red (PostgREST no disponible) ✅ CERRADO
- **Reproducir**: `devBypass = true`, lanzar app (auto-login dev), navegar a Lots o Dashboard que carga lotes
- **Síntoma**: `⛔ [Riverpod] FAILED: userLotsProvider` → `Lost connection to device`
- **Causa raíz real**: misma que BUG-01. `authProvider` se resuelve casi instantáneamente con devBypass.
  `appRouterProvider` recreaba el GoRouter → `DashboardScreen` se desmontaba brevemente durante la transición
  → `userLotsProvider` (auto-dispose) perdía su último watcher → Riverpod lo dispose
  → el DioException de `getLots()` en vuelo escapaba al zone sin receptor → proceso muere.
- **Fix aplicado**: mismo par de fixes que BUG-01 (GoRouter keepAlive + PlatformDispatcher).

## 8. Deudas relacionadas con Android

| ID  | Estado  | Descripción |
|-----|---------|-------------|
| D-1 | 🔴 abierta | Verificación en dispositivo Android — este documento completo |
| D-4 | 🟡 mitigado | Migración v1→v6 en dispositivo con base existente — ver sección 6 |
| D-11 | ⚪ pendiente | Decidir applicationId definitivo antes de Play Store |
| D-12 | ⚪ pendiente | Reconciliar modelo de dos tablas para Lot (`local_lots` vs `lots`) en ítem #14 — definir fuente de verdad y mecanismo de sync |
