#!/usr/bin/env bash
# ==============================================================================
# GitOps Continuous Reconciliation & Drift Correction Demo Script
# ==============================================================================
set -e

echo "=================================================================="
echo "          GITOPS DRIFT DETECTION & CONTINUOUS RECONCILIATION     "
echo "=================================================================="
echo ""
echo "1. Current Git State (Source of Truth):"
echo "   File: session20-monitoring-observability-gitops/gitops-demo/k8s/deployment.yaml"
echo "   Desired Replicas: 2"
echo ""

echo "2. Current Live Cluster State:"
kubectl get deployment gitops-webapp -n gitops-prod -o custom-columns=NAME:.metadata.name,DESIRED_REPLICAS:.spec.replicas,READY_REPLICAS:.status.readyReplicas || echo "Deployment not yet applied"
echo ""

echo "3. Simulating Configuration Drift (Unauthorized manual edit via kubectl):"
echo "   Command: kubectl scale deployment gitops-webapp -n gitops-prod --replicas=5"
echo ""

echo "4. Argo CD Drift Detection & Continuous Reconciliation:"
echo "   [STATUS] Sync Status: OutOfSync"
echo "   [ACTION] Argo CD self-healing policy triggered."
echo "   [ACTION] Live cluster state (5 replicas) conflicts with Git source of truth (2 replicas)."
echo "   [RESULT] Reconciling live cluster back to Git desired state (2 replicas)..."
echo ""

echo "5. Post-Reconciliation Cluster Verification:"
echo "   [STATUS] Synced & Healthy (Replicas restored to 2)"
echo "=================================================================="
