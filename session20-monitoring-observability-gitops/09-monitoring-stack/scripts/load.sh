#!/usr/bin/env bash
# Generate traffic for the demo app.
# usage: scripts/load.sh [normal|errors|cpu|memory|all] [seconds]
set -euo pipefail
MODE="${1:-all}"; DURATION="${2:-60}"; URL="${APP_URL:-http://localhost:8000}"
end=$(( $(date +%s) + DURATION ))
hit() { curl -s -o /dev/null -w "%{http_code}\n" "$URL$1"; }
echo "mode=$MODE duration=${DURATION}s target=$URL"
case "$MODE" in
  memory) hit "/memory?mb=${MB:-200}"; echo "holding ${MB:-200} MB (release: curl $URL/memory/release)"; exit 0 ;;
esac
ok=0; err=0
while [ "$(date +%s)" -lt "$end" ]; do
  case "$MODE" in
    normal) codes=$(hit / ; hit /health) ;;
    errors) codes=$(hit / ; hit /error ; hit /error) ;;
    cpu)    codes=$(hit "/work?ms=400" & hit "/work?ms=400" & wait) ;;
    all)    codes=$(hit / ; hit /health ; hit "/work?ms=150" ; hit /error) ;;
    *) echo "unknown mode $MODE"; exit 1 ;;
  esac
  for c in $codes; do if [ "$c" -ge 500 ]; then err=$((err+1)); else ok=$((ok+1)); fi; done
  sleep 0.1
done
echo "done: ok=$ok errors=$err"
