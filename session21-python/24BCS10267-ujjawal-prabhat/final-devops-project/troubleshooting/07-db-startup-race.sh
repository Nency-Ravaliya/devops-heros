#!/usr/bin/env bash
# Issue 7 (found for real in an earlier version): backend pods crash-looped when PostgreSQL was
# not accepting connections yet. Re-check of the fix: start the backend while the database is down.
source "$(dirname "$0")/lib.sh"
baseline

step "BREAK: stop PostgreSQL, then restart every backend pod"
run "kubectl -n $NS scale deploy/stockpilot-postgres --replicas=0"
run "kubectl -n $NS delete pod -l app.kubernetes.io/component=backend --wait=false"
sleep 20

step "SYMPTOM / INVESTIGATE: backend pods wait in the init container instead of crash-looping"
run "kubectl -n $NS get pods"
POD=$(kubectl -n $NS get pods -l app.kubernetes.io/component=backend --field-selector=status.phase=Pending -o name | head -1)
run "kubectl -n $NS logs $POD -c migrate | tail -3 | cut -c1-160"
curl_ingress

step "ROOT CAUSE (original bug): schema creation ran inside the app start-up and raised on a refused connection, so the container exited. Now python -m app.migrate retries in an init container."

step "FIX: bring the database back"
run "kubectl -n $NS scale deploy/stockpilot-postgres --replicas=1"
run "kubectl -n $NS wait --for=condition=Ready pod --all --timeout=180s"
sleep 10

step "VERIFY: all Ready, 0 restarts, migration finished"
run "kubectl -n $NS get pods"
run "kubectl -n $NS logs $POD -c migrate | tail -2 | cut -c1-160"
curl_ingress
