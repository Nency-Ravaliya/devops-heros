#!/usr/bin/env bash
# Hammer the backend through the Ingress so the HPA has something to react to.
# usage: scripts/load-test.sh [seconds] [parallel-workers] [url]
set -euo pipefail
DURATION="${1:-180}"
WORKERS="${2:-12}"
URL="${3:-http://localhost/api/entries/summary}"
HOST_HEADER="${HOST_HEADER:-studytrack.local}"

echo "load-test: ${WORKERS} workers x ${DURATION}s against ${URL} (Host: ${HOST_HEADER})"
end=$((SECONDS + DURATION))
for _ in $(seq 1 "$WORKERS"); do
  (
    while [ $SECONDS -lt $end ]; do
      curl -s -o /dev/null -H "Host: ${HOST_HEADER}" "$URL" || true
    done
  ) &
done
wait
echo "load-test: done"
