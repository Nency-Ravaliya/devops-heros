#!/usr/bin/env bash
# ==============================================================================
# Script: load-generator.sh
# Purpose: Generate high-concurrency requests to trigger HPA scaling
# ==============================================================================

set -euo pipefail

TARGET_SVC="${1:-http://hpa-demo-service}"

echo "=================================================="
echo "    KUBERNETES HPA LOAD GENERATOR - SESSION 13   "
echo "=================================================="
echo "Targeting service: $TARGET_SVC"
echo "Spawning concurrent load generator Pod..."

kubectl run -i --tty load-generator \
  --image=busybox:1.36 \
  --restart=Never \
  --rm \
  -- /bin/sh -c "while true; do wget -q -O- $TARGET_SVC; done"
