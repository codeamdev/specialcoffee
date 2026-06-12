"""
SpecialCoffee AI — Auth Service
Endpoints: POST /auth/register  POST /auth/login  POST /auth/refresh  GET /auth/me
JWT compatible con PostgREST: claim 'sub' = user_id, claim 'role' = 'authenticated'
"""

import os
from contextlib import asynccontextmanager
from datetime import datetime, timedelta, timezone
from typing import Optional

import bcrypt
import asyncpg
from dotenv import load_dotenv
from fastapi import Depends, FastAPI, HTTPException, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from jose import JWTError, jwt
from pydantic import BaseModel, EmailStr

load_dotenv()

# ── Configuración ──────────────────────────────────────────────────────────

DATABASE_URL             = os.getenv("DATABASE_URL")
JWT_SECRET               = os.getenv("JWT_SECRET")
JWT_ALGORITHM            = os.getenv("JWT_ALGORITHM", "HS256")
ACCESS_EXPIRE_MINUTES    = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES", "60"))
REFRESH_EXPIRE_DAYS      = int(os.getenv("REFRESH_TOKEN_EXPIRE_DAYS", "30"))

if not DATABASE_URL:
    raise ValueError("DATABASE_URL no está configurada")
if not JWT_SECRET:
    raise ValueError("JWT_SECRET no está configurada")

def _hash_password(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt()).decode()

def _verify_password(password: str, hashed: str) -> bool:
    return bcrypt.checkpw(password.encode(), hashed.encode())

bearer = HTTPBearer()

# ── Pool de conexiones ─────────────────────────────────────────────────────

_pool: Optional[asyncpg.Pool] = None

async def get_pool() -> asyncpg.Pool:
    global _pool
    if _pool is None:
        _pool = await asyncpg.create_pool(DATABASE_URL, min_size=2, max_size=10)
    return _pool

@asynccontextmanager
async def lifespan(app: FastAPI):
    await get_pool()
    yield
    if _pool:
        await _pool.close()

app = FastAPI(title="SpecialCoffee Auth", version="1.0.0", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    # Dominio de producción. En desarrollo local, el cliente Flutter corre
    # en la misma máquina que el servidor — no hay solicitudes cross-origin.
    allow_origins=["https://specialcoffee.app"],
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"],
    allow_headers=["Authorization", "Content-Type", "Accept", "Origin"],
    allow_credentials=False,   # la app usa Bearer token en header, no cookies
    expose_headers=["Content-Range"],
    max_age=600,
)

# ── Modelos Pydantic ───────────────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: EmailStr
    password: str
    display_name: str
    role: str = "farmer"
    region: str = ""
    country: str = "CO"
    language: str = "es"

class LoginRequest(BaseModel):
    email: EmailStr
    password: str

class RefreshRequest(BaseModel):
    refresh_token: str

class TokenResponse(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user_id: str
    email: str
    display_name: str
    role: str

class UserResponse(BaseModel):
    user_id: str
    email: str
    display_name: str
    role: str
    region: str
    country: str
    language: str

# ── Utilidades JWT ─────────────────────────────────────────────────────────

def _make_access_token(
    user_id: str,
    email: str,
    role: str,
    display_name: str = "",
    region: str = "",
    country: str = "CO",
    language: str = "es",
) -> str:
    exp = datetime.now(timezone.utc) + timedelta(minutes=ACCESS_EXPIRE_MINUTES)
    return jwt.encode(
        {
            "sub": user_id,
            "email": email,
            "display_name": display_name,
            "app_role": role,
            "region": region,
            "country": country,
            "language": language,
            "role": "authenticated",  # rol PostgreSQL que PostgREST usa
            "exp": exp,
            "type": "access",
        },
        JWT_SECRET,
        algorithm=JWT_ALGORITHM,
    )

def _make_refresh_token(user_id: str) -> str:
    exp = datetime.now(timezone.utc) + timedelta(days=REFRESH_EXPIRE_DAYS)
    return jwt.encode(
        {"sub": user_id, "exp": exp, "type": "refresh"},
        JWT_SECRET,
        algorithm=JWT_ALGORITHM,
    )

def _decode_token(token: str) -> dict:
    try:
        return jwt.decode(token, JWT_SECRET, algorithms=[JWT_ALGORITHM])
    except JWTError:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Token inválido o expirado",
        )

async def _current_user_id(
    credentials: HTTPAuthorizationCredentials = Depends(bearer),
) -> str:
    payload = _decode_token(credentials.credentials)
    if payload.get("type") != "access":
        raise HTTPException(status_code=401, detail="Se requiere access token")
    return payload["sub"]

# ── Endpoints ──────────────────────────────────────────────────────────────

@app.post("/auth/register", response_model=TokenResponse, status_code=201)
async def register(body: RegisterRequest):
    if len(body.password) < 8:
        raise HTTPException(400, "La contraseña debe tener al menos 8 caracteres")
    if body.role not in ("farmer", "processor", "barista", "entrepreneur",
                         "producer", "coffee_master", "brand_manager", "producer_integral"):
        raise HTTPException(400, "Rol inválido")

    pool = await get_pool()
    async with pool.acquire() as conn:
        exists = await conn.fetchval(
            "SELECT id FROM users WHERE email = $1", body.email
        )
        if exists:
            raise HTTPException(400, "El email ya está registrado")

        try:
            password_hash = _hash_password(body.password)
            user_id = await conn.fetchval(
                """
                INSERT INTO users (email, display_name, password_hash, role, region, country, language)
                VALUES ($1, $2, $3, $4, $5, $6, $7)
                RETURNING id
                """,
                body.email, body.display_name, password_hash,
                body.role, body.region, body.country, body.language,
            )
        except asyncpg.UniqueViolationError:
            raise HTTPException(400, "El email ya está registrado")
        except asyncpg.NotNullViolationError as e:
            raise HTTPException(422, f"Campo requerido: {e}")

        await conn.execute(
            "INSERT INTO ai_user_profiles (user_id) VALUES ($1) ON CONFLICT DO NOTHING",
            user_id,
        )

    return TokenResponse(
        access_token=_make_access_token(
            user_id, body.email, body.role, body.display_name,
            body.region, body.country, body.language,
        ),
        refresh_token=_make_refresh_token(user_id),
        user_id=user_id,
        email=body.email,
        display_name=body.display_name,
        role=body.role,
    )


@app.post("/auth/login", response_model=TokenResponse)
async def login(body: LoginRequest):
    pool = await get_pool()

    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """SELECT id, email, display_name, password_hash, role,
                      region, country, language
               FROM users WHERE email = $1 AND is_active = TRUE""",
            body.email,
        )
        if not row or not _verify_password(body.password, row["password_hash"]):
            raise HTTPException(status_code=401, detail="Credenciales incorrectas")

        await conn.execute(
            "UPDATE users SET last_active_at = NOW() WHERE id = $1", row["id"]
        )

    return TokenResponse(
        access_token=_make_access_token(
            row["id"], row["email"], row["role"], row["display_name"],
            row["region"], row["country"], row["language"],
        ),
        refresh_token=_make_refresh_token(row["id"]),
        user_id=row["id"],
        email=row["email"],
        display_name=row["display_name"],
        role=row["role"],
    )


@app.post("/auth/refresh", response_model=TokenResponse)
async def refresh(body: RefreshRequest):
    payload = _decode_token(body.refresh_token)
    if payload.get("type") != "refresh":
        raise HTTPException(400, "Se requiere refresh token")

    user_id = payload["sub"]
    pool = await get_pool()

    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            """SELECT id, email, display_name, role, region, country, language
               FROM users WHERE id = $1 AND is_active = TRUE""",
            user_id,
        )

    if not row:
        raise HTTPException(401, "Usuario no encontrado")

    return TokenResponse(
        access_token=_make_access_token(
            row["id"], row["email"], row["role"], row["display_name"],
            row["region"], row["country"], row["language"],
        ),
        refresh_token=_make_refresh_token(row["id"]),
        user_id=row["id"],
        email=row["email"],
        display_name=row["display_name"],
        role=row["role"],
    )


@app.get("/auth/me", response_model=UserResponse)
async def me(user_id: str = Depends(_current_user_id)):
    pool = await get_pool()

    async with pool.acquire() as conn:
        row = await conn.fetchrow(
            "SELECT id, email, display_name, role, region, country, language FROM users WHERE id = $1",
            user_id,
        )

    if not row:
        raise HTTPException(404, "Usuario no encontrado")

    return UserResponse(
        user_id=row["id"],
        email=row["email"],
        display_name=row["display_name"],
        role=row["role"],
        region=row["region"],
        country=row["country"],
        language=row["language"],
    )


@app.get("/health")
async def health():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("AUTH_PORT", "8000"))
    uvicorn.run("main:app", host="0.0.0.0", port=port, reload=False)
