#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
docker compose up -d --build
minikube start
minikube image load --overwrite=true taskboard-backend:session21 taskboard-frontend:session21
kubectl rollout status deployment/ingress-nginx-controller -n ingress-nginx --timeout=180s
kubectl apply -f k8s/namespace.yaml
helm upgrade --install taskboard helm/taskboard -n taskboard -f helm/taskboard/values-local.yaml --wait --timeout 5m
kubectl apply -f monitoring/dashboard.yaml
