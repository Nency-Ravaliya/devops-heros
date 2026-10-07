#!/usr/bin/env bash
# ==============================================================================
# Script: verify.sh
# Purpose: End-to-end verification of Mini Project (Storage, Probes, HPA)
# ==============================================================================

set -euo pipefail
NAMESPACE="production-webapp"

echo "=== 1. Deploying All Components ==="
kubectl apply -f namespace.yaml
kubectl apply -f pvc.yaml
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl apply -f hpa.yaml

echo "=== 2. Waiting for Pods to be Ready ==="
kubectl rollout status deployment/web-app -n "$NAMESPACE" --timeout=60s

echo "=== 3. Checking Resources ==="
kubectl get pvc -n "$NAMESPACE"
kubectl get pods -n "$NAMESPACE" -o wide
kubectl get svc -n "$NAMESPACE"
kubectl get hpa -n "$NAMESPACE"

echo "=== 4. Testing Storage Persistence ==="
POD_NAME=$(kubectl get pods -n "$NAMESPACE" -l app=web-app -o jsonpath='{.items[0].metadata.name}')
echo "Writing test file on $POD_NAME..."
kubectl exec -n "$NAMESPACE" "$POD_NAME" -- sh -c 'echo "Shivansh Singh - Storage Test" > /data/persistence-test.txt'

echo "Deleting pod $POD_NAME..."
kubectl delete pod "$POD_NAME" -n "$NAMESPACE"

echo "Waiting for replacement pod..."
sleep 10
NEW_POD=$(kubectl get pods -n "$NAMESPACE" -l app=web-app -o jsonpath='{.items[0].metadata.name}')
echo "Reading file from new pod $NEW_POD:"
kubectl exec -n "$NAMESPACE" "$NEW_POD" -- cat /data/persistence-test.txt

echo "=== All Mini Project Verifications Passed! ==="
