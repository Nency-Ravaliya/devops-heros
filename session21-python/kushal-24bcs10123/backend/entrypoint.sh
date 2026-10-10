#!/bin/sh
# Run the Alembic migrations, then start the API. In Kubernetes this runs in every
# replica; `alembic upgrade head` is idempotent so the second pod is a no-op.
# The migration is retried for up to ~60s so a backend pod that starts a few seconds
# before PostgreSQL does not crash-loop while the database is still coming up.
set -e
attempt=1
until alembic upgrade head; do
  if [ "$attempt" -ge 12 ]; then
    echo "[entrypoint] database still unreachable after $attempt attempts, giving up" >&2
    exit 1
  fi
  echo "[entrypoint] migration failed (attempt $attempt), database probably not ready yet - retrying in 5s"
  attempt=$((attempt + 1))
  sleep 5
done
echo "[entrypoint] migrations applied, starting uvicorn"
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --workers "${UVICORN_WORKERS:-1}"
