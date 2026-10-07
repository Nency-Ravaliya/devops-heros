#!/usr/bin/env bash
# Smoke test StockPilot through the ingress-nginx controller of the kind cluster.
#   HOST=stockpilot.local BASE=http://localhost:8081 scripts/smoke-ingress.sh
set -euo pipefail
HOST="${HOST:-stockpilot.local}"
BASE="${BASE:-http://localhost:8081}"
c() { echo "\$ curl -s -H 'Host: $HOST' $*"; curl -s -H "Host: $HOST" "$@"; echo; echo; }

c "$BASE/health"
c "$BASE/ready"
c "$BASE/api/info"
c -X POST -H 'Content-Type: application/json' "$BASE/api/items" \
  -d '{"sku":"BOLT-M8","name":"M8 hex bolt","quantity":120,"reorder_level":50,"unit_price_paise":250}'
c -X POST -H 'Content-Type: application/json' "$BASE/api/items" \
  -d '{"sku":"BRG-6204","name":"6204 ball bearing","quantity":4,"reorder_level":10,"unit_price_paise":18000,"location":"WH2"}'
c -X POST -H 'Content-Type: application/json' "$BASE/api/items/1/adjust" -d '{"delta":-80,"reason":"order-1001"}'
c "$BASE/api/items/low-stock"
c "$BASE/api/summary"
c -o /dev/null -w '%{http_code} %{content_type}\n' "$BASE/"
echo "\$ curl -s -H 'Host: $HOST' $BASE/metrics | grep -E '^stockpilot_' | head -15"
curl -s -H "Host: $HOST" "$BASE/metrics" | grep -E '^stockpilot_' | head -15
