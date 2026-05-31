# INFORME DE AUDITORÍA — SpecialCoffee AI
**Fecha:** 2026-05-27 · **Base:** commit `ef82a51` · **Auditores:** Arquitecto senior, Ing. Seguridad, DBA, DevOps/SRE, QA

---

## Resumen ejecutivo

El proyecto está bien estructurado y sigue Clean Architecture con coherencia. El motor de reglas on-device, los DAOs Drift y los providers Riverpod son de calidad sólida. Sin embargo, **no está listo para producción** por tres razones bloqueantes: (1) credenciales de base de datos y JWT hardcodeadas en archivos versionados en git, (2) CORS abierto a `*` en toda la capa de red y sin rate limiting en auth, y (3) dos pantallas del módulo Brewing son stubs vacíos que rompen el flujo anunciado. Adicionalmente, los errores críticos de base de datos y AI se silencian en producción sin notificar al usuario. El resto de hallazgos son deuda técnica gestionable.

---

## Hallazgos — CRÍTICO

### SEC-1 · Credenciales en el repositorio git
**Rol:** Ing. Seguridad  
**Archivos:** `backend/postgrest.conf` (línea 8, 25), `backend/postgrest_local.conf` (línea 4, 9)  
**Problema:** Ambos archivos están **trackeados en git** (`git ls-files` los devuelve) y contienen credenciales literales:
```
db-uri = "postgres://postgrest_auth:sc_pgrst_2025@localhost:5432/specialcoffee"
jwt-secret = "specialcoffee_dev_local_secret_2025_ok"
```
El `.gitignore` cubre `.env` y `.env.*` pero **no cubre `*.conf`**. Los archivos `.env` (backend y auth) NO están trackeados — eso está correcto.  
**Riesgo:** Cualquier persona con acceso al repo obtiene credenciales de BD y puede forjar JWT válidos para cualquier `user_id`.  
**Solución:** Añadir `*.conf` a `.gitignore` (o entradas específicas), eliminar los archivos del historial con `git filter-repo`, regenerar las credenciales.

---

### SEC-2 · JWT_SECRET débil y predecible
**Rol:** Ing. Seguridad  
**Archivos:** `backend/postgrest.conf:25`, `backend/.env:5`, `backend/auth/.env:2`  
**Problema:** El secret es `specialcoffee_dev_local_secret_2025_ok` — texto legible, predecible, ~38 chars pero sin entropía real.  
**Riesgo:** Un atacante puede forjar tokens JWT firmados válidos para cualquier `sub` (user_id), escalando a cualquier cuenta de la plataforma.  
**Solución:**
```bash
openssl rand -base64 48   # ≥ 32 bytes de entropía real
```
Actualizar en todos los archivos `.env` y regenerar tokens activos.

---

### SEC-3 · CORS abierto a `*` en producción
**Rol:** Ing. Seguridad  
**Archivos:** `backend/nginx/nginx.conf` (líneas 12, 24), `backend/auth/main.py` (bloque CORSMiddleware)  
**Problema:** `Access-Control-Allow-Origin: *` en ambas capas (Nginx y FastAPI). El config de nginx para producción (`backend/nginx/specialcoffee.conf`) también tiene `*`.  
**Riesgo:** Cualquier web maliciosa puede hacer requests autenticadas en nombre del usuario (CSRF via CORS). Especialmente crítico con tokens en memoria.  
**Solución:** Restringir al dominio real:
```nginx
add_header Access-Control-Allow-Origin 'https://tu-dominio.com' always;
```
En FastAPI:
```python
allow_origins=["https://tu-dominio.com"]
```

---

### SEC-4 · Sin rate limiting en endpoints de autenticación
**Rol:** Ing. Seguridad  
**Archivo:** `backend/auth/main.py`, `backend/nginx/nginx.conf`  
**Problema:** Los endpoints `/auth/login` y `/auth/register` no tienen rate limiting en ninguna capa (ni FastAPI ni Nginx). No hay throttling, no hay bloqueo por IP, no hay CAPTCHA.  
**Riesgo:** Ataques de fuerza bruta y credential stuffing sin fricción. Un script puede probar millones de contraseñas.  
**Solución mínima en Nginx:**
```nginx
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/m;
limit_req zone=auth burst=10 nodelay;
```

---

### FUNC-1 · BrewDiagnosisScreen y BrewRecipeScreen son stubs vacíos
**Rol:** Arquitecto senior / QA  
**Archivos:** `lib/presentation/screens/brewing/brew_diagnosis_screen.dart` (17 líneas), `lib/presentation/screens/brewing/brew_recipe_screen.dart` (19 líneas)  
**Problema:** Ambas pantallas son placeholders con un `Center(child: Text(...))`. Están registradas en el router y accesibles desde la UI, pero no implementan ninguna funcionalidad.
```dart
// brew_diagnosis_screen.dart — contenido completo de la pantalla
body: const Center(
  child: Text('Diagnóstico post-extracción', style: AppTextStyles.displaySmall),
),
```
**Riesgo:** El flujo de Brewing — anunciado como funcionalidad central — está roto para el usuario final. `BrewScreen` genera la receta y navega a `brew/recipe`, que muestra un texto vacío.  
**Solución:** Implementar MVP mínimo: mostrar los parámetros de la receta generada en `BrewRecipeScreen`, y al menos los campos de diagnóstico (TDS, rendimiento, notas) en `BrewDiagnosisScreen`.

---

### QUAL-1 · Errores críticos silenciados en providers de producción
**Rol:** Arquitecto senior / QA  
**Archivos:** `lib/presentation/providers/drying_provider.dart` (líneas 128, 156, 206, 222), `lib/presentation/providers/fermentation_provider.dart` (líneas 93, 116, 192, 214), `lib/presentation/providers/harvest_provider.dart` (líneas 92, 134, 199, 248)  
**Problema:** 34 ocurrencias de `catch (_) {}` en providers críticos sin logging ni feedback al usuario. Los más graves:

```dart
// drying_provider.dart — fallo de IA silenciado
try {
  final recs = await engine.recommend(aiContext);
} catch (_) {
  state = state.copyWith(isAnalyzing: false); // Usuario ve "sin recomendaciones"
}

// drying_provider.dart — fallo de persistencia silenciado
try {
  await repo.createSession(...);
} catch (_) {
  // Los datos del usuario NO se guardaron — él no lo sabe
}
```
**Riesgo:** Un usuario registra lecturas de secado, la BD local falla silenciosamente, y cree que sus datos están guardados cuando no lo están. En fermentación, un fallo de AI presenta "sin alertas" en lugar de un error.  
**Solución:** Mínimo: propagar el error al estado del notifier para que la UI lo muestre. Ideal: logging estructurado + `state.copyWith(error: e.toString())`.

---

## Hallazgos — ALTO

### SEC-5 · Security headers ausentes en Nginx
**Rol:** Ing. Seguridad / DevOps  
**Archivo:** `backend/nginx/nginx.conf`, `backend/nginx/specialcoffee.conf`  
**Problema:** Faltan headers estándar de seguridad web en ambas configuraciones.  
**Solución — añadir al bloque `server`:**
```nginx
add_header X-Content-Type-Options  "nosniff"         always;
add_header X-Frame-Options          "DENY"            always;
add_header Referrer-Policy          "no-referrer"     always;
add_header Permissions-Policy       "geolocation=()"  always;
server_tokens off;
```
Para producción (HTTPS): añadir `Strict-Transport-Security "max-age=31536000; includeSubDomains"`.

---

### SEC-6 · setup_local.ps1 expone contraseña en variable de entorno
**Rol:** Ing. Seguridad / DevOps  
**Archivo:** `backend/setup_local.ps1` (línea ~9)  
**Problema:** `$env:PGPASSWORD = "posgres"` establece la contraseña en una variable de entorno del proceso, visible en `ps` / Task Manager y en logs de CI si el script se ejecuta en pipelines.  
**Solución:** Usar `.pgpass` file o pasar `-W` para prompt interactivo. Para scripts automatizados: leer de `.env` con `Get-Content`.

---

### SEC-7 · Sin validación de fortaleza de contraseña en registro
**Rol:** Ing. Seguridad  
**Archivo:** `backend/auth/main.py` — endpoint `POST /auth/register`  
**Problema:** No hay validación de longitud mínima, complejidad ni listas de contraseñas prohibidas.  
**Riesgo:** Usuarios pueden registrarse con contraseña `"1"`.  
**Solución mínima:**
```python
if len(body.password) < 8:
    raise HTTPException(400, "La contraseña debe tener al menos 8 caracteres")
```

---

### DB-1 · Índice faltante en `drying_sessions` (PostgreSQL)
**Rol:** DBA  
**Archivo:** `backend/schema.sql` — tabla `drying_sessions` (~línea 321)  
**Problema:** Todas las tablas de sesiones tienen índice por `lot_id` excepto `drying_sessions`. La consulta más frecuente (`WHERE lot_id = $1 ORDER BY started_at DESC LIMIT 1`) hace full scan.  
**Solución:**
```sql
CREATE INDEX idx_drying_sessions_lot ON drying_sessions(lot_id, started_at DESC);
```

---

### TEST-1 · Sin tests para DryingProvider (259 líneas de código crítico)
**Rol:** QA  
**Archivo:** `lib/presentation/providers/drying_provider.dart`  
**Problema:** El provider de secado —que incluye creación de sesión, múltiples lecturas, integración con AI, notificaciones push y persistencia— no tiene ningún test. Es el módulo con más líneas de código de producción y más `catch (_)` silenciados.  
**Riesgo:** Regresiones en el flujo crítico de secado no se detectan hasta producción.  
**Solución:** Crear `test/presentation/providers/drying_provider_test.dart` siguiendo el patrón establecido en `fermentation_provider_test.dart`.

---

### DEVOPS-1 · _local = true hardcodeado — no hay separación dev/prod en código
**Rol:** DevOps / Arquitecto  
**Archivo:** `lib/core/config/api_config.dart` (línea 3)  
**Problema:** `static const bool _local = true` está hardcodeado. Para producción hay que editar el archivo fuente. No hay mecanismo de build flavors ni `--dart-define`.  
**Riesgo:** Un build de producción con `_local = true` apunta a `127.0.0.1:8000` — la app falla silenciosamente en todos los requests de red.  
**Solución recomendada:**
```dart
static const bool _local = bool.fromEnvironment('DEV_MODE', defaultValue: false);
// flutter run --dart-define=DEV_MODE=true
// flutter build apk --dart-define=DEV_MODE=false
```

---

## Hallazgos — MEDIO

### DB-2 · `db-schema-cache-ttl = 0` en producción
**Rol:** DBA / DevOps  
**Archivo:** `backend/postgrest.conf:28`, `docker-compose.yml` (variable `PGRST_DB_SCHEMA_CACHE_TTL: "0"`)  
**Problema:** TTL 0 significa que PostgREST re-introspecciona el schema en cada request en producción.  
**Riesgo:** Latencia añadida y carga extra en PostgreSQL bajo carga real.  
**Solución:** Cambiar a `300` (5 minutos) en producción.

---

### DB-3 · `sync_queue` sin GRANT definido
**Rol:** DBA  
**Archivo:** `backend/schema.sql` (~línea 671)  
**Problema:** La tabla `sync_queue` existe en el schema pero no tiene GRANT para `authenticated`. Cuando se implemente la sincronización, fallará con `permission denied`.  
**Solución:** Añadir GRANTs o documentar explícitamente que la tabla es solo para uso futuro.

---

### ARCH-1 · Logout no invalida providers cacheados que dependen de userId
**Rol:** Arquitecto senior  
**Archivo:** `lib/core/di/providers.dart`  
**Problema:** Los providers de repositorios son `keepAlive: true` y capturan `currentUserIdProvider` en su construcción. Si el usuario hace logout y otro inicia sesión, los repos retienen el `userId` del usuario anterior hasta que el proceso se reinicie.  
**Riesgo:** Fuga de datos entre sesiones en dispositivos compartidos.  
**Solución:** En el handler de logout, invalidar los providers de repositorios: `ref.invalidate(fermentationLocalRepoProvider)`, etc. O usar `ref.watch` en lugar de `ref.read` para que se reconstruyan automáticamente.

---

### ARCH-2 · Variedades hardcodeadas en LotCreateScreen
**Rol:** Arquitecto senior  
**Archivo:** `lib/presentation/screens/lot/lot_create_screen.dart`  
**Problema:** Las 7 variedades de café (Geisha, Colombia, Castillo, etc.) están hardcodeadas como `static const` en la pantalla. El backend tiene una tabla `coffee_varieties_catalog` con esta información.  
**Riesgo:** Añadir una variedad requiere una actualización de la app. No hay consistencia con el catálogo del servidor.  
**Solución:** Cargar desde `coffee_varieties_catalog` vía PostgREST o, si offline-first es requerido, seedear localmente desde la tabla Drift.

---

### ARCH-3 · ConflictResolver puede suprimir alerta de mayor criticidad
**Rol:** Arquitecto senior  
**Archivo:** `lib/ai_engine/core/conflict_resolver.dart` (línea 18-26)  
**Problema:** El resolver deduplica por `action`, conservando la regla de mayor `confidenceBase`. Si dos reglas disparan para la misma acción con niveles de alerta distintos (e.g., `critical` con confidence 0.75 vs `warning` con confidence 0.95), la alerta crítica se descarta.

```dart
if (existing == null || rule.outcome.confidenceBase > existing.outcome.confidenceBase) {
  byAction[rule.outcome.action] = rule;  // ← sobrescribe sin verificar alertLevel
}
```
**Riesgo:** Con el conjunto de reglas actual, esto no ocurre (las reglas están bien diseñadas y usan `supersedes` explícito). Es un riesgo latente para futuras reglas.  
**Solución recomendada:** Al comparar rules con misma action, priorizar `alertLevel` sobre `confidenceBase`:
```dart
if (existing == null || _alertPriority(rule) > _alertPriority(existing)) {
  byAction[rule.outcome.action] = rule;
}
```

---

### QUAL-2 · custom_lint y riverpod_lint deshabilitados
**Rol:** Arquitecto senior / QA  
**Archivo:** `pubspec.yaml` (comentario en dev_dependencies)  
**Problema:** Ambos linters están comentados por incompatibilidad de `analyzer ^8` vs `^9`. Se pierde la validación estática de patrones Riverpod (providers no consumidos, `ref.read` en build, etc.).  
**Riesgo:** Errores de uso de Riverpod llegan a producción sin detección en CI.  
**Solución:** Monitorear `riverpod_lint` — en su versión 3.x hay versiones compatibles con analyzer 8. Intentar con `riverpod_lint: ^3.0.0` y `analyzer: ^8.4.1`.

---

### DEVOPS-2 · Docker sin health checks ni límites de recursos
**Rol:** DevOps / SRE  
**Archivo:** `backend/docker-compose.yml`  
**Problema:** Ningún servicio tiene `healthcheck`, `mem_limit` ni `cpus` definidos. Nginx no espera que PostgREST esté healthy, solo que el contenedor haya iniciado.  
**Solución mínima:**
```yaml
auth:
  healthcheck:
    test: ["CMD", "curl", "-f", "http://localhost:8000/health"]
    interval: 30s
    timeout: 5s
    retries: 3
  mem_limit: 256m
```

---

## Mejoras sugeridas (no bloqueantes)

| ID | Descripción | Área |
|----|-------------|------|
| MEJ-1 | Patrón `Result<T, E>` en lugar de exceptions — mejor manejo en UI | Arquitectura |
| MEJ-2 | i18n / intl — soporte multiidioma (estructura importada pero no usada) | UX |
| MEJ-3 | Implementar sync_queue offline → PostgREST para fase final | Persistencia |
| MEJ-4 | Tests de widget para LotDetailScreen y FermentationScreen | QA |
| MEJ-5 | Benchmark real del RuleEngine (promete `< 5ms`, sin prueba adjunta) | Performance |
| MEJ-6 | Soft delete en todas las entidades, no solo Lot | Dominio |
| MEJ-7 | Validar rule_id únicos en AllRules al cargar (assert en debug) | Motor de reglas |
| MEJ-8 | `client_max_body_size 1M` en nginx.conf de desarrollo | DevOps |
| MEJ-9 | `PGRST_LOG_LEVEL: "warn"` en docker-compose (evitar logs con datos en info) | DevOps |
| MEJ-10 | Agregar `.env.example` al repo como plantilla con placeholders | DevOps |

---

## Checklist — Listo para producción

### Bloqueantes (deben pasar antes del release)

- [ ] **SEC-1** Eliminar `postgrest.conf` y `postgrest_local.conf` del historial git + rotar credenciales
- [ ] **SEC-2** Regenerar JWT_SECRET con ≥32 bytes de entropía (`openssl rand -base64 48`)
- [ ] **SEC-3** Configurar CORS con dominio específico en Nginx y FastAPI (eliminar `*`)
- [ ] **SEC-4** Implementar rate limiting en `/auth/login` y `/auth/register`
- [ ] **FUNC-1** Implementar MVP de `BrewRecipeScreen` y `BrewDiagnosisScreen`
- [ ] **QUAL-1** Propagar errores al estado del notifier en los `catch (_)` de providers críticos (drying, fermentation, harvest)
- [ ] **SEC-5** Añadir security headers en Nginx (X-Content-Type-Options, X-Frame-Options, etc.)
- [ ] **DEVOPS-1** Separar configuración dev/prod con `--dart-define` o build flavors
- [ ] **TEST-1** Crear `test/presentation/providers/drying_provider_test.dart`

### Importantes (antes de escala real)

- [ ] **SEC-6** Refactorizar `setup_local.ps1` para no exponer contraseña en variable de entorno
- [ ] **SEC-7** Validar fortaleza mínima de contraseña en `/auth/register`
- [ ] **DB-1** Añadir `CREATE INDEX idx_drying_sessions_lot ON drying_sessions(lot_id, started_at DESC)`
- [ ] **ARCH-1** Invalidar providers de repositorios en logout
- [ ] **DB-2** Cambiar `db-schema-cache-ttl` a `300` en producción

### Deuda técnica (gestionar en backlog)

- [ ] **ARCH-2** Cargar variedades dinámicamente desde catálogo
- [ ] **ARCH-3** Mejorar ConflictResolver para priorizar alertLevel sobre confidence
- [ ] **QUAL-2** Re-habilitar custom_lint + riverpod_lint cuando los analyzers converjan
- [ ] **DEVOPS-2** Añadir health checks y límites de recursos en docker-compose
- [ ] **DB-3** Definir GRANTs para `sync_queue` antes de implementar sync

---

*Informe generado en modo solo-lectura. Ningún archivo fue modificado. Pendiente aprobación del usuario para iniciar Fase 2.*
