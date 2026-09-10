#!/usr/bin/env bash
# cleanup.sh — Tear down all demo resources for Session 12
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[INFO] Deleting Ingress..."
kubectl delete -f "${DEMO_DIR}/ingress.yaml"   --ignore-not-found=true

echo "[INFO] Deleting Backend Deployment and Service..."
kubectl delete -f "${DEMO_DIR}/backend.yaml"   --ignore-not-found=true

echo "[INFO] Deleting Frontend Deployment and Service..."
kubectl delete -f "${DEMO_DIR}/frontend.yaml"  --ignore-not-found=true

echo "[INFO] Deleting Secret..."
kubectl delete -f "${DEMO_DIR}/secret.yaml"    --ignore-not-found=true

echo "[INFO] Deleting ConfigMap..."
kubectl delete -f "${DEMO_DIR}/configmap.yaml" --ignore-not-found=true

echo "[INFO] All demo resources removed."
