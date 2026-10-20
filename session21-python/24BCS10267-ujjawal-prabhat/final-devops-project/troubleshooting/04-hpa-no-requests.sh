#!/usr/bin/env bash
# Issue 4: backend without resource requests -> HPA shows <unknown> and cannot scale
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: remove resources (requests/limits) from the backend containers"
break_with "--set backend.resources=null"
kubectl -n $NS rollout status deploy/stockpilot-backend --timeout=120s >/dev/null
sleep 60

step "SYMPTOM"
run "kubectl -n $NS get hpa"

step "INVESTIGATE"
run "kubectl -n $NS describe hpa stockpilot-backend | sed -n '/Conditions/,\$p' | cut -c1-220"
run "kubectl -n $NS get deploy stockpilot-backend -o jsonpath='{.spec.template.spec.containers[0].resources}{\"\\n\"}'"
run "kubectl -n $NS top pods -l app.kubernetes.io/component=backend"

step "ROOT CAUSE: utilization = usage / request. With no CPU request the ratio is undefined, so the HPA reports <unknown> (metrics-server works: kubectl top answers)."

step "FIX"
fix_release
sleep 45

step "VERIFY"
run "kubectl -n $NS get deploy stockpilot-backend -o jsonpath='{.spec.template.spec.containers[0].resources}{\"\\n\"}'"
run "kubectl -n $NS get hpa"
