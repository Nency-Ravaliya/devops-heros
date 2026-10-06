#!/usr/bin/env bash
# Issue 6: Ingress backend references a Service that does not exist -> 503
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: Ingress backend renamed to stockpilot-apii"
run "kubectl -n $NS patch ingress stockpilot --type=json -p \"\$(cat troubleshooting/patches/ingress-wrong-service.json)\""
sleep 8

step "SYMPTOM"
curl_ingress
run "kubectl -n $NS get pods,svc"

step "INVESTIGATE"
run "kubectl -n $NS describe ingress stockpilot | sed -n '/Rules:/,/Annotations/p'"
run "kubectl -n ingress-nginx logs deploy/ingress-nginx-controller --tail=300 | grep -E 'stockpilot-apii' | tail -2 | cut -c1-260"

step "ROOT CAUSE: ingress backend service name typo - the controller has no endpoints for it and returns 503."
echo

step "FIX: re-apply the chart; --force-conflicts because kubectl-patch now owns the field (see issue 5)"
run "helm upgrade $REL helm/stockpilot -n $NS -f helm/stockpilot/values-dev.yaml -f troubleshooting/values-trouble.yaml --force-conflicts --wait --timeout 5m | grep -E 'STATUS|REVISION'"
run "kubectl -n $NS get ingress stockpilot -o jsonpath='{.spec.rules[0].http.paths[0].backend.service.name}{\"\\n\"}'"
sleep 5

step "VERIFY"
curl_ingress
