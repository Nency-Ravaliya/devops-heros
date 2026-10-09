#!/usr/bin/env bash
set -euo pipefail
URL="${URL:-http://labtrack.local/api/health}"
for i in $(seq 1 500); do curl -s "$URL" >/dev/null || true; done
echo "Load test completed"
