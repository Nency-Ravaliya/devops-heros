#!/usr/bin/env bash
# Bootstrap the GitOps environment: secret out-of-band, then the Argo CD app.
set -uo pipefail
cd "$(dirname "$0")/.."
run() { echo "\$ $*"; "$@"; echo; }

run kubectl create namespace final-gitops
echo '$ kubectl -n final-gitops create secret generic stockpilot-db-prod --from-literal=DB_USER=stockpilot --from-literal=DB_PASSWORD="$(openssl rand -hex 16)"'
kubectl -n final-gitops create secret generic stockpilot-db-prod \
  --from-literal=DB_USER=stockpilot --from-literal=DB_PASSWORD="$(openssl rand -hex 16)"
echo
run kubectl apply -f gitops/application.yaml
for i in $(seq 1 40); do
  s=$(kubectl -n argocd get application final-stockpilot-24BCS10106 -o jsonpath='{.status.sync.status}/{.status.health.status}')
  [ "$s" = "Synced/Healthy" ] && break
  sleep 6
done
run kubectl -n argocd get application final-stockpilot-24BCS10106 -o wide
run kubectl -n argocd get application final-stockpilot-24BCS10106 -o jsonpath='{.status.sync.revision}{"\n"}{.status.summary.images}{"\n"}'
run kubectl get deploy,po,svc,ing,hpa,pvc,servicemonitor,prometheusrule -n final-gitops
run curl -s -H 'Host: stockpilot-gitops.local' localhost:8081/api/info
