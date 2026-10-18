#!/usr/bin/env bash
# One-time setup of the cluster add-ons StockPilot relies on, after `terraform apply`:
#   - Metrics Server        (the HPA reads CPU usage from it)
#   - ingress-nginx         (the Ingress controller; creates an AWS load balancer)
#   - kube-prometheus-stack (Prometheus + Grafana, see monitoring/)
#
#   aws eks update-kubeconfig --region ap-south-1 --name stockpilot-eks
#   scripts/install-cluster-addons.sh
set -euo pipefail

cd "$(dirname "$0")/.."

helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

echo "==> Metrics Server"
helm upgrade --install metrics-server metrics-server/metrics-server \
  --namespace kube-system --wait

echo "==> ingress-nginx"
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx --create-namespace --wait

echo "==> gp3 StorageClass for the PostgreSQL volume"
kubectl apply -f k8s/storageclass-gp3.yaml

echo "==> kube-prometheus-stack (Prometheus + Grafana)"
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace \
  -f monitoring/prometheus-values.yaml \
  -f monitoring/grafana-values.yaml \
  --wait --timeout 10m

echo "==> Grafana dashboard for StockPilot"
kubectl apply -f monitoring/grafana-dashboard.yaml

echo
echo "Done. The Ingress address (a load balancer hostname) appears here after a minute:"
echo "  kubectl get svc -n ingress-nginx ingress-nginx-controller"
