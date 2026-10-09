#!/usr/bin/env bash
# run-demo.sh — Full deployment script for Session 12 demo
# Usage: bash run-demo.sh
set -euo pipefail

DEMO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "[INFO] Step 1: Enabling NGINX Ingress Controller on Minikube..."
minikube addons enable ingress
echo "[INFO] Waiting 30 seconds for Ingress Controller pods to become Ready..."
sleep 30
kubectl wait --namespace ingress-nginx \
  --for=condition=ready pod \
  --selector=app.kubernetes.io/component=controller \
  --timeout=120s
echo "[INFO] Ingress Controller is Ready."

echo ""
echo "[INFO] Step 2: Applying ConfigMap (plain-text configuration)..."
kubectl apply -f "${DEMO_DIR}/configmap.yaml"
kubectl get configmap yatri-app-config

echo ""
echo "[INFO] Step 3: Applying Secret (sensitive database credentials)..."
kubectl apply -f "${DEMO_DIR}/secret.yaml"
kubectl get secret yatri-db-secret

echo ""
echo "[INFO] Step 4: Deploying Frontend (Nginx) + ClusterIP Service..."
kubectl apply -f "${DEMO_DIR}/frontend.yaml"

echo ""
echo "[INFO] Step 5: Deploying Backend (Python HTTP server) + ClusterIP Service..."
kubectl apply -f "${DEMO_DIR}/backend.yaml"

echo ""
echo "[INFO] Step 6: Waiting for all pods to reach Running state..."
kubectl rollout status deployment/yatri-frontend --timeout=90s
kubectl rollout status deployment/yatri-backend  --timeout=90s

echo ""
echo "[INFO] Step 7: Applying Ingress routing rules..."
kubectl apply -f "${DEMO_DIR}/ingress.yaml"

echo ""
echo "[INFO] Step 8: Summary of deployed resources..."
kubectl get configmap yatri-app-config
kubectl get secret    yatri-db-secret
kubectl get pods      -l app=yatri-frontend
kubectl get pods      -l app=yatri-backend
kubectl get svc       yatri-frontend-service yatri-backend-service
kubectl get ingress   yatri-ingress

echo ""
echo "[INFO] Step 9: Adding yatri.local to /etc/hosts (requires sudo)..."
MINIKUBE_IP=$(minikube ip)
echo "[INFO] Minikube IP detected: ${MINIKUBE_IP}"

if grep -q "yatri.local" /etc/hosts; then
  echo "[INFO] yatri.local already exists in /etc/hosts. Skipping."
else
  echo "${MINIKUBE_IP}  yatri.local" | sudo tee -a /etc/hosts
  echo "[INFO] Added: ${MINIKUBE_IP}  yatri.local"
fi

echo ""
echo "[INFO] ============================================================"
echo "[INFO] Demo is READY. Test with the following commands:"
echo ""
echo "  Test FRONTEND (path: /):"
echo "    curl http://yatri.local"
echo "    OR open http://yatri.local in your browser"
echo ""
echo "  Test BACKEND API (path: /api/) -- shows ConfigMap + Secret values:"
echo "    curl http://yatri.local/api/"
echo ""
echo "  Verify environment variable injection inside backend pod:"
echo "    kubectl exec -it deploy/yatri-backend -- env | grep -E 'ENVIRONMENT|LOG_LEVEL|POSTGRES'"
echo ""
echo "  Decode Secret password:"
echo "    kubectl get secret yatri-db-secret -o jsonpath='{.data.POSTGRES_PASSWORD}' | base64 --decode"
echo "[INFO] ============================================================"
