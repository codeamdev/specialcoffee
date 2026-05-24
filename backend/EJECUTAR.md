# SpecialCoffee AI — Ejecución local del backend

## Requisitos previos

- PostgreSQL corriendo en Windows (usuario `postgres`, contraseña `posgres`)
- Docker Desktop activo
- Python 3.10+ (solo para setup inicial de la BD)

---

## Paso 1 — Setup de base de datos (solo la primera vez)

```powershell
cd C:\Users\Administrador\Documents\specialcoffee
.\backend\setup_local.ps1
```

Qué hace:
- Crea la base de datos `specialcoffee`
- Crea los roles `anon` y `authenticated` (requeridos por PostgREST)
- Aplica el schema SQL completo (18 tablas + datos semilla)
- Verifica que Docker esté disponible

---

## Paso 2 — Levantar el backend completo

```powershell
cd backend
docker compose up
```

Levanta en paralelo:
- **Auth service** (FastAPI) → `http://127.0.0.1:8000`
- **PostgREST** → `http://127.0.0.1:3000`

La primera vez descarga la imagen de PostgREST (~20 MB) y construye la imagen del auth service.

Para correr en segundo plano:
```powershell
docker compose up -d
```

Para detener:
```powershell
docker compose down
```

---

## Paso 3 — Verificar que todo responde

```powershell
curl http://127.0.0.1:8000/health
# Esperado: {"status":"ok"}

curl http://127.0.0.1:3000/
# Esperado: JSON con las tablas disponibles
```

---

## Paso 4 — Correr la app Flutter

```powershell
# En otra terminal, desde la raíz del proyecto
flutter run -d edge
```

o en escritorio Windows:

```powershell
flutter run -d windows
```

---

## Endpoints del Auth service

| Método | URL | Descripción |
|--------|-----|-------------|
| POST | `http://127.0.0.1:8000/auth/register` | Crear cuenta |
| POST | `http://127.0.0.1:8000/auth/login` | Iniciar sesión |
| POST | `http://127.0.0.1:8000/auth/refresh` | Renovar token |
| GET  | `http://127.0.0.1:8000/auth/me` | Usuario actual |
| GET  | `http://127.0.0.1:8000/health` | Estado del servicio |
| GET  | `http://127.0.0.1:8000/docs` | Swagger UI interactivo |

## Endpoints de PostgREST

| URL | Tabla |
|-----|-------|
| `http://127.0.0.1:3000/lots` | Lotes |
| `http://127.0.0.1:3000/fermentation_sessions` | Sesiones de fermentación |
| `http://127.0.0.1:3000/fermentation_readings` | Lecturas de fermentación |
| `http://127.0.0.1:3000/brew_sessions` | Sesiones de preparación |
| `http://127.0.0.1:3000/ai_recommendations` | Recomendaciones IA |
| `http://127.0.0.1:3000/coffee_varieties_catalog` | Catálogo de variedades |

---

## Configuración

| Archivo | Propósito |
|---------|-----------|
| `backend/.env` | Variables compartidas (DB, JWT_SECRET) — leído por Docker Compose |
| `backend/auth/.env` | Igual que el anterior, para ejecutar auth sin Docker |

> El `JWT_SECRET` debe ser **idéntico** en ambos archivos.

---

## Estructura de archivos

```
backend/
├── docker-compose.yml     ← orquesta auth + postgrest
├── .env                   ← credenciales compartidas (Docker Compose)
├── postgrest_local.conf   ← config PostgREST (sin Docker)
├── schema.sql             ← schema completo de PostgreSQL
├── setup_local.ps1        ← setup inicial de la BD
├── setup.sh               ← setup para el servidor Linux
└── auth/
    ├── Dockerfile
    ├── main.py
    ├── requirements.txt
    └── .env               ← credenciales para correr sin Docker
```

---

## Pasar a producción

1. Cambiar `_local = true` → `_local = false` en `lib/core/config/api_config.dart`
2. Reemplazar `TU_DOMINIO` con la IP o dominio real del servidor Linux
3. En el servidor: `bash backend/setup.sh`
