#!/usr/bin/env bash
# ==============================================================================
# Script: load_generator.sh
# Purpose: Runs load generator pods inside the cluster to trigger HPA scaling.
#          Traffic goes through the Service, so it is spread across all backend pods
#          (a local kubectl port-forward pins to one pod and is far too slow).
# Usage:   ./load_generator.sh [target-url] [load-pods] [workers-per-pod]
# ==============================================================================

set -euo pipefail

TARGET_URL="${1:-http://yatri-backend-service/}"
LOAD_PODS="${2:-10}"
WORKERS="${3:-20}"
NAME="load-generator"

echo "=================================================="
echo "      KUBERNETES HPA TRAFFIC LOAD GENERATOR       "
echo "=================================================="
echo "Target:  $TARGET_URL"
echo "Load:    $LOAD_PODS pods x $WORKERS workers = $((LOAD_PODS * WORKERS)) concurrent loops"
echo "Press Ctrl+C to stop and remove the load generators."
echo ""

trap 'echo; echo "Removing load generators..."; kubectl delete deployment "$NAME" --ignore-not-found' EXIT

kubectl delete deployment "$NAME" --ignore-not-found > /dev/null
kubectl create deployment "$NAME" --image=busybox:1.36 --replicas="$LOAD_PODS" -- \
    /bin/sh -c "for i in \$(seq $WORKERS); do (while true; do wget -q -O- $TARGET_URL > /dev/null 2>&1; done) & done; wait"

echo "Traffic load active! In another terminal, run: kubectl get hpa -w"
sleep infinity
