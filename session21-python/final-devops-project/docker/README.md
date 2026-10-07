# docker/ — local stack with Docker Compose

Runs the whole TaskBoard app (PostgreSQL 16 + FastAPI backend + React/nginx frontend) on one machine,
built from `../application/backend` and `../application/frontend`.

```bash
cd docker
docker compose build                 # -> taskboard-backend:1.0.0, taskboard-frontend:1.0.0
docker compose up -d --wait          # starts in order: postgres (healthy) -> backend (healthy) -> frontend
docker compose ps
curl localhost:8000/health           # {"status":"UP"}
curl localhost:8000/ready            # {"status":"READY"}  (checks the DB)
curl -X POST localhost:8000/api/tasks -H 'Content-Type: application/json' -d '{"title":"Ship it"}'
curl localhost:3000/api/tasks        # same API through the nginx reverse proxy
curl localhost:8000/api/tasks/stats
curl localhost:8000/metrics          # Prometheus metrics
open http://localhost:3000           # UI
docker compose down -v               # stop + delete the DB volume
```

| Service | Image | Port (host→container) | Healthcheck |
|---|---|---|---|
| postgres | `postgres:16-alpine` | 5432→5432 | `pg_isready` |
| backend | `taskboard-backend:${TAG:-1.0.0}` | 8000→8000 | `GET /ready` (DB reachable) |
| frontend | `taskboard-frontend:${TAG:-1.0.0}` | 3000→8080 | `GET /healthz` (nginx) |

* `depends_on: condition: service_healthy` — the backend only starts once Postgres accepts connections
  (it runs `alembic upgrade head` on start), and nginx only starts once the backend is ready
  (nginx resolves the `backend` upstream at startup).
* `TAG` / `GIT_SHA` env vars select the image tag and the `org.opencontainers.image.revision` label —
  CI runs `TAG=<commit-sha> docker compose build` and smoke-tests exactly this stack.
* `POSTGRES_PASSWORD` defaults to the local-dev value `taskboard`; override it in your shell or a `.env` file.

### Image hardening (see `application/*/Dockerfile`)

| | backend | frontend |
|---|---|---|
| Build | multi-stage: deps installed into `/opt/venv` in a builder stage | multi-stage: `npm ci` + `vite build` on `node:24-alpine` |
| Runtime base | `python:3.12.15-alpine3.24` + `apk upgrade` (Debian slim had 44 unfixed HIGH CVEs) | `nginxinc/nginx-unprivileged:1.30-alpine` + `apk upgrade` |
| User | uid **10001** (`appuser`), no shell | uid **101** (`nginx`), listens on **8080** (no root needed) |
| Extras | pip removed from the runtime, `exec uvicorn` as PID 1, `HEALTHCHECK` | security headers, gzip, immutable asset caching, `HEALTHCHECK` |
| Size | ~210 MB (was 339 MB on Debian slim) | ~93 MB |
