#!/usr/bin/env bash
# Issue 3: workload references a Secret that does not exist -> CreateContainerConfigError
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: point the release at a non-existent secret (typo in database.existingSecret)"
break_with "--set database.existingSecret=stockpilot-db-prd"
sleep 25

step "SYMPTOM"
run "kubectl -n $NS get pods"
curl_ingress

step "INVESTIGATE"
run "kubectl -n $NS get events --sort-by=.lastTimestamp | grep -E 'not found|Killing' | tail -4 | cut -c1-200"
run "kubectl -n $NS get secret -l app.kubernetes.io/instance=$REL"
run "kubectl -n $NS get deploy stockpilot-api -o jsonpath='{.spec.template.spec.containers[0].envFrom}{\"\\n\"}'"
run "kubectl -n $NS logs deploy/stockpilot-api --tail=50 | grep -m1 'readiness check failed' | cut -c1-200"

step "ROOT CAUSE"
cat <<'EOF'
envFrom.secretRef / secretKeyRef point at "stockpilot-db-prd", which does not exist -> kubelet cannot
build the container environment -> CreateContainerConfigError. It cascades:
  1. existingSecret set => the chart stops rendering its own Secret => Helm deletes "stockpilot-db".
  2. the postgres Deployment also changed (Recreate strategy) => old DB pod killed, new one cannot start.
  3. the old API pods lose their database => /ready returns 503 => they leave the Service => ingress 503.
EOF
echo

step "FIX: correct the value (or create the secret out-of-band before referencing it)"
fix_release
run "kubectl -n $NS rollout status deploy/stockpilot-postgres --timeout=120s"
sleep 15

step "VERIFY"
run "kubectl -n $NS get pods"
run "kubectl -n $NS get secret -l app.kubernetes.io/instance=$REL"
curl_ingress
