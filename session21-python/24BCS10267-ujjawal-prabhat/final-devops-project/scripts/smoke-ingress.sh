#!/usr/bin/env bash
# Smoke test through ingress-nginx (kind host port 8081): / -> frontend, /api -> backend.
#   HOST=stockpilot.local scripts/smoke-ingress.sh
set -euo pipefail
HOST="${HOST:-stockpilot.local}"
c() { echo "\$ curl -s -H 'Host: $HOST' $*"; curl -s -H "Host: $HOST" "$@"; echo; echo; }

c -o /dev/null -w '%{http_code} %{content_type}\n' localhost:8081/
c localhost:8081/api/info
c -X POST -H 'Content-Type: application/json' localhost:8081/api/items -d '{"sku":"SMOKE-1","name":"smoke test item","quantity":3}'
ID=$(curl -s -H "Host: $HOST" localhost:8081/api/items | python3 -c 'import json,sys; print([i["id"] for i in json.load(sys.stdin) if i["sku"]=="SMOKE-1"][0])')
c -X PUT -H 'Content-Type: application/json' "localhost:8081/api/items/$ID" -d '{"quantity":30}'
c localhost:8081/api/items
c -X DELETE -o /dev/null -w '%{http_code}\n' "localhost:8081/api/items/$ID"
c localhost:8081/api/summary
