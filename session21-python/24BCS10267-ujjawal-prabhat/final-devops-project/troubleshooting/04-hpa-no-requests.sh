#!/usr/bin/env bash
# Issue 4: container without resource requests -> HPA shows <unknown> and cannot scale
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: remove resources (requests/limits) from the API container"
break_with "--set resources=null"
kubectl -n $NS rollout status deploy/stockpilot-api --timeout=120s >/dev/null
sleep 60

step "SYMPTOM"
run "kubectl -n $NS get hpa"

step "INVESTIGATE"
run "kubectl -n $NS describe hpa stockpilot-api | sed -n '/Conditions/,\$p' | cut -c1-220"
run "kubectl -n $NS get deploy stockpilot-api -o jsonpath='{.spec.template.spec.containers[0].resources}{\"\\n\"}'"
run "kubectl -n $NS top pods -l app.kubernetes.io/component=api"

step "ROOT CAUSE: HPA utilization = usage / request. With no cpu request the ratio is undefined, so the HPA reports <unknown> (metrics-server itself is fine - kubectl top works)."
echo

step "FIX"
fix_release
sleep 45

step "VERIFY"
run "kubectl -n $NS get deploy stockpilot-api -o jsonpath='{.spec.template.spec.containers[0].resources}{\"\\n\"}'"
run "kubectl -n $NS get hpa"
