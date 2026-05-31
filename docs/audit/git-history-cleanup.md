# Limpieza de historial git — Credenciales expuestas

**Contexto (hallazgo SEC-1):** `backend/postgrest.conf` y
`backend/postgrest_local.conf` fueron versionados con credenciales reales
antes de añadir `*.conf` al `.gitignore`. Las credenciales ya fueron rotadas
(2026-05-27). Esta guía elimina los archivos del historial completo.

---

## Requisitos previos

```bash
pip install git-filter-repo
```

---

## Archivos a purgar

| Archivo | Motivo |
|---------|--------|
| `backend/postgrest.conf` | Contenía `db-uri` con usuario/contraseña y `jwt-secret` |
| `backend/postgrest_local.conf` | Igual que el anterior (variante de desarrollo) |

---

## Comandos (ejecutar en orden)

```bash
# 1. Asegúrate de estar en la rama main y con working tree limpio
git checkout main
git status   # debe mostrar "nothing to commit"

# 2. Crea un backup de la rama antes de operar
git branch backup/pre-history-cleanup

# 3. Purga los archivos del historial completo
git filter-repo \
  --path backend/postgrest.conf --invert-paths \
  --path backend/postgrest_local.conf --invert-paths

# 4. Verifica que los archivos ya no aparecen en el historial
git log --all --full-history -- backend/postgrest.conf
git log --all --full-history -- backend/postgrest_local.conf
# Ambos deben devolver salida vacía

# 5. Fuerza la sincronización con el remoto
# ⚠️  COORDINAR CON EL EQUIPO: esto reescribe el historial público.
# Todos los colaboradores deberán hacer `git fetch --all` y resetear su rama local.
git remote add origin <URL_DEL_REMOTO>   # si se desconectó tras filter-repo
git push --force-with-lease origin main
```

---

## Post-limpieza: instrucciones para colaboradores

Cada persona con una copia del repo debe ejecutar:

```bash
git fetch --all
git checkout main
git reset --hard origin/main
# Borrar ramas locales antiguas si las hay
git remote prune origin
```

---

## Advertencias

- `git filter-repo` reescribe todos los commits afectados — los SHAs cambian.
  Los PRs abiertos que apunten a commits anteriores quedarán desincronizados.
- Si hay una pipeline de CI que cachea el repo por SHA, se debe invalidar.
- **No usar `git filter-branch`** — está deprecado y es significativamente más lento.
- El backup en `backup/pre-history-cleanup` se puede borrar una vez confirmada
  la sincronización de todo el equipo.

---

## Verificación final

```bash
# Confirmar que no quedan secretos en el historial
git log --all --full-history --diff-filter=A -- "*.conf" | head -20
# Confirmar tamaño del repo (debería reducirse ligeramente)
git count-objects -vH
```
