#!/usr/bin/env bash
# Issue 6: Ingress /api backend references a Service that does not exist -> 503
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: Ingress /api backend renamed to stockpilot-backendd"
run "kubectl -n $NS patch ingress stockpilot --type=json -p \"\$(cat troubleshooting/patches/ingress-wrong-service.json)\""
sleep 8

step "SYMPTOM"
curl_ingress
run "curl -s -o /dev/null -w 'HTTP %{http_code}\\n' -H 'Host: $HOST' localhost:8081/"
run "kubectl -n $NS get pods,svc"

step "INVESTIGATE"
run "kubectl -n $NS describe ingress stockpilot | sed -n '/Rules:/,/Annotations/p'"
run "kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=300 | grep -E 'stockpilot-backendd' | tail -1 | cut -c1-260"

step "ROOT CAUSE: typo in the /api backend Service name: the controller has no endpoints for it and returns 503 (the / path still works)."

step "FIX: re-apply the chart with --force-conflicts (kubectl-patch owns the field, see issue 5)"
fix_release --force-conflicts
run "kubectl -n $NS get ingress stockpilot -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}{\"\\n\"}'"
sleep 5

step "VERIFY"
curl_ingress
