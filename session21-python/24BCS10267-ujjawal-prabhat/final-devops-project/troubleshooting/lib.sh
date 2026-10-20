#!/usr/bin/env bash
# Shared helpers for the troubleshooting scenarios. Source from a scenario script.
set -uo pipefail
NS=final-trouble
REL=stockpilot
HOST=trouble.stockpilot.local
cd "$(dirname "${BASH_SOURCE[0]}")/.."

# print the command like a terminal, then run it
run() { echo "\$ $*"; bash -c "$*" 2>&1; echo; }
step() { echo; echo "############ $* ############"; echo; }

# helm upgrade of the lab release with the known-good values from Git plus extra flags
HELM_UP="helm upgrade --install $REL helm/stockpilot -n $NS -f helm/stockpilot/values-dev.yaml -f troubleshooting/values-trouble.yaml"
helm_up() { run "$HELM_UP $* | grep -E 'STATUS|REVISION|Error'"; }

baseline() { bash -c "$HELM_UP --create-namespace --wait --timeout 5m" >/dev/null; }
break_with() { helm_up "$@"; }                    # no --wait: a broken release never gets ready
fix_release() { helm_up --wait --timeout 5m "$@"; }

# per-endpoint readiness as seen by the Service (EndpointSlice conditions)
show_endpoints() {
  local jp='{range .items[*].endpoints[*]}{.targetRef.name}  {.addresses[0]}  ready={.conditions.ready}{"\n"}{end}'
  echo "\$ kubectl -n $NS get endpointslices -l kubernetes.io/service-name=stockpilot-backend -o jsonpath='$jp'"
  kubectl -n "$NS" get endpointslices -l kubernetes.io/service-name=stockpilot-backend -o jsonpath="$jp"
  echo
}

curl_ingress() {
  run "curl -s -o /dev/null -w 'HTTP %{http_code}\n' -H 'Host: $HOST' localhost:8081/api/summary"
}
