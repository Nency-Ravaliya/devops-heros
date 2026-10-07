#!/bin/bash
#
# run-demo.sh — Deploy the full Session 12 multi-tier demo:
#   ConfigMap -> Secret -> Backend (Deploy+Svc) -> Frontend (Deploy+Svc) -> Ingress
#
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/5] Applying ConfigMap (yatri-app-config)..."
kubectl apply -f "${SCRIPT_DIR}/configmap.yaml"

echo "==> [2/5] Applying Secret (yatri-db-secret)..."
kubectl apply -f "${SCRIPT_DIR}/secret.yaml"

echo "==> [3/5] Applying Backend Deployment + Service (yatri-backend)..."
kubectl apply -f "${SCRIPT_DIR}/backend.yaml"

echo "==> [4/5] Applying Frontend Deployment + Service (yatri-frontend)..."
kubectl apply -f "${SCRIPT_DIR}/frontend.yaml"

echo "==> [5/5] Applying Ingress (yatri-ingress)..."
kubectl apply -f "${SCRIPT_DIR}/ingress.yaml"

echo "==> Waiting for deployments to become ready..."
kubectl rollout status deployment/yatri-backend
kubectl rollout status deployment/yatri-frontend

echo ""
echo "==> Full stack deployed. Current state (app=yatri-app):"
kubectl get configmap,secret,ingress,deploy,svc,pods -l app=yatri-app
