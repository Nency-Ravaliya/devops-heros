#!/usr/bin/env bash
# Shared helpers for the troubleshooting scenarios. Source from a scenario script.
set -uo pipefail
NS=final-trouble
REL=stockpilot
HOST=trouble.stockpilot.local
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART="$ROOT/helm/stockpilot"
BASE_VALUES=(-f "$CHART/values-dev.yaml" -f "$ROOT/troubleshooting/values-trouble.yaml")
cd "$ROOT"

# print the command like a terminal, then run it
run() { echo "\$ $*"; bash -c "$*" 2>&1; echo; }
step() { echo; echo "############ $* ############"; echo; }

baseline() {
  helm upgrade --install "$REL" "$CHART" -n "$NS" --create-namespace "${BASE_VALUES[@]}" \
    --wait --timeout 5m >/dev/null
}

# helm upgrade with extra --set flags, without waiting (broken releases never get ready)
break_with() {
  run "helm upgrade $REL helm/stockpilot -n $NS -f helm/stockpilot/values-dev.yaml -f troubleshooting/values-trouble.yaml $* | grep -E 'STATUS|REVISION'"
}

# the fix: re-apply the known-good values from Git
fix_release() {
  run "helm upgrade $REL helm/stockpilot -n $NS -f helm/stockpilot/values-dev.yaml -f troubleshooting/values-trouble.yaml --wait --timeout 5m | grep -E 'STATUS|REVISION'"
}

# per-endpoint readiness as seen by the Service (EndpointSlice conditions)
show_endpoints() {
  local jp='{range .items[*].endpoints[*]}{.targetRef.name}  {.addresses[0]}  ready={.conditions.ready}{"\n"}{end}'
  echo "\$ kubectl -n $NS get endpointslices -l kubernetes.io/service-name=stockpilot-api -o jsonpath='$jp'"
  kubectl -n "$NS" get endpointslices -l kubernetes.io/service-name=stockpilot-api -o jsonpath="$jp"
  echo
}

curl_ingress() {
  run "curl -s -o /dev/null -w 'HTTP %{http_code}\n' -H 'Host: $HOST' localhost:8081/ready"
}
