#!/usr/bin/env bash
# Smoke test a running instance of the API.
# usage: scripts/smoke_test.sh [base_url]
set -euo pipefail
BASE_URL="${1:-http://localhost:5000}"

echo "Smoke testing ${BASE_URL}"
for i in $(seq 1 15); do
  curl -fs "${BASE_URL}/health" >/dev/null && break
  if [ "${i}" -eq 15 ]; then echo "  App never became healthy."; exit 1; fi
  echo "  waiting for app... (${i})"; sleep 2
done

check() {
  local path="$1" expected="$2"
  local body
  body="$(curl -fs "${BASE_URL}${path}")"
  if echo "${body}" | grep -q "${expected}"; then
    echo "  PASS  GET ${path} -> ${body}"
  else
    echo "  FAIL  GET ${path} -> ${body} (expected '${expected}')"; exit 1
  fi
}

check /health            '"status":"ok"'
check "/calc/add?a=10&b=5"      '"result":15'
check "/calc/multiply?a=6&b=7"  '"result":42'
check /info              '"version"'
echo "Smoke test passed."
