#!/usr/bin/env bash
# Start the whole stack locally and wait until the backend reports ready.
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose up --build -d
until curl -sf http://localhost:8000/ready >/dev/null; do sleep 2; done
echo "frontend: http://localhost:3000"
echo "backend:  http://localhost:8000/docs"
