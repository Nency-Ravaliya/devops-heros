#!/bin/bash
#
# cleanup.sh — Tear down every resource created by run-demo.sh.
#   Uses --ignore-not-found so re-running is always safe (idempotent).
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> Deleting Ingress (yatri-ingress)..."
kubectl delete -f "${SCRIPT_DIR}/ingress.yaml" --ignore-not-found

echo "==> Deleting Frontend Deployment + Service (yatri-frontend)..."
kubectl delete -f "${SCRIPT_DIR}/frontend.yaml" --ignore-not-found

echo "==> Deleting Backend Deployment + Service (yatri-backend)..."
kubectl delete -f "${SCRIPT_DIR}/backend.yaml" --ignore-not-found

echo "==> Deleting Secret (yatri-db-secret)..."
kubectl delete -f "${SCRIPT_DIR}/secret.yaml" --ignore-not-found

echo "==> Deleting ConfigMap (yatri-app-config)..."
kubectl delete -f "${SCRIPT_DIR}/configmap.yaml" --ignore-not-found

echo ""
echo "==> Cleanup complete. Remaining app=yatri-app resources (should be empty):"
kubectl get configmap,secret,ingress,deploy,svc,pods -l app=yatri-app
