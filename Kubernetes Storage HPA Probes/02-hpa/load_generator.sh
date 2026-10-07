#!/usr/bin/env bash
# ==============================================================================
# Script: load_generator.sh
# Purpose: Spawns high-concurrency background curl requests to trigger HPA scaling
# ==============================================================================

set -euo pipefail

TARGET_URL="${1:-http://localhost:5000/healthz}"

echo "=================================================="
echo "      KUBERNETES HPA TRAFFIC LOAD GENERATOR       "
echo "=================================================="
echo "Pounding target endpoint: $TARGET_URL"
echo "Simulating traffic spike. Press Ctrl+C to stop."
echo ""

# Forward local port if needed
if ! curl -s -f "$TARGET_URL" > /dev/null 2>&1; then
    echo "Starting port-forward to yatri-backend deployment on port 5000..."
    kubectl port-forward svc/yatri-backend-service 5000:80 > /dev/null 2>&1 &
    PF_PID=$!
    trap 'kill $PF_PID 2>/dev/null || true' EXIT
    sleep 2
fi

# Run 10 parallel background workers firing requests in an infinite loop
for i in {1..10}; do
    while true; do
        curl -s "$TARGET_URL" > /dev/null || true
    done &
done

echo "Traffic load active! In another terminal, run: kubectl get hpa -w"
wait
