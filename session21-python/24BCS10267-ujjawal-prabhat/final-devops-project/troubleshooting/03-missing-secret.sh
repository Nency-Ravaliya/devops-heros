#!/usr/bin/env bash
# Issue 3: workloads reference a Secret that does not exist -> CreateContainerConfigError
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: typo in database.existingSecret"
break_with "--set database.existingSecret=stockpilot-db-prd"
sleep 25

step "SYMPTOM"
run "kubectl -n $NS get pods"
curl_ingress

step "INVESTIGATE"
run "kubectl -n $NS get events --sort-by=.lastTimestamp | grep -E 'not found' | tail -3 | cut -c1-200"
run "kubectl -n $NS get secret -l app.kubernetes.io/instance=$REL"
run "kubectl -n $NS get deploy stockpilot-backend -o jsonpath='{.spec.template.spec.containers[0].envFrom}{\"\\n\"}'"

step "ROOT CAUSE"
cat <<'TXT'
envFrom.secretRef / secretKeyRef point at "stockpilot-db-prd", which does not exist, so the kubelet
cannot build the container environment (CreateContainerConfigError). It cascades:
  1. existingSecret is set, so the chart stops rendering its own Secret and Helm deletes "stockpilot-db".
  2. the postgres Deployment changed too (Recreate strategy): the old DB pod is killed, the new one cannot start.
  3. the running backend pods lose the database, /ready returns 503, they leave the Service: /api fails.
TXT

step "FIX: correct the value (or create the Secret before referencing it)"
fix_release
run "kubectl -n $NS rollout status deploy/stockpilot-postgres --timeout=120s"
sleep 15

step "VERIFY"
run "kubectl -n $NS get pods"
run "kubectl -n $NS get secret -l app.kubernetes.io/instance=$REL"
curl_ingress
