#!/usr/bin/env bash
# Generates API traffic so the request metrics and the HPA have something to show.
# Usage: monitoring/load-test.sh <base-url> [seconds] [parallel]
#   monitoring/load-test.sh http://localhost:8080 60 8      (port-forward / ingress)
set -euo pipefail
BASE_URL="${1:?base url, e.g. http://localhost:8080}"
DURATION="${2:-60}"
PARALLEL="${3:-8}"
HOST_HEADER="${HOST_HEADER:-}"

hit() {
  local end=$((SECONDS + DURATION))
  while [ "$SECONDS" -lt "$end" ]; do
    curl -s -o /dev/null ${HOST_HEADER:+-H "Host: $HOST_HEADER"} "$BASE_URL/api/tasks/stats" || true
    curl -s -o /dev/null ${HOST_HEADER:+-H "Host: $HOST_HEADER"} "$BASE_URL/api/tasks" || true
  done
}

echo "load: $PARALLEL workers x ${DURATION}s against $BASE_URL"
for _ in $(seq 1 "$PARALLEL"); do hit & done
wait
echo "load finished"
