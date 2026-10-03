#!/usr/bin/env bash
# ==============================================================================
# Script: triage_all.sh
# Purpose: Deploys all 5 broken pods for the Session 14 Triage Gauntlet
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================================="
echo "      KUBERNETES INCIDENT TRIAGE GAUNTLET         "
echo "=================================================="
echo "Deploying 5 intentionally broken production workloads..."
echo ""

kubectl apply -f "$SCRIPT_DIR/scenario-1-crashloop/broken.yaml"
kubectl apply -f "$SCRIPT_DIR/scenario-2-imagepull/broken.yaml"
kubectl apply -f "$SCRIPT_DIR/scenario-3-pending/broken.yaml"
kubectl apply -f "$SCRIPT_DIR/scenario-4-dns-failure/broken.yaml"
kubectl apply -f "$SCRIPT_DIR/scenario-5-oomkilled/broken.yaml"

echo ""
echo "Workloads deployed! Sleeping 5s to allow states to settle..."
sleep 5

echo ""
echo "=== CURRENT CLUSTER CARNAGE ==="
kubectl get pods -l tier=triage-gauntlet
echo ""
echo "=================================================="
echo "Your mission: Diagnose and fix each of the 5 pods!"
echo "Follow the diagnostic guide in README.md!"
echo "=================================================="
