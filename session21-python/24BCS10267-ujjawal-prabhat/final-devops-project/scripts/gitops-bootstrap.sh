#!/usr/bin/env bash
# Bootstrap the GitOps environment: DB Secret created outside Git, then the Argo CD app.
set -uo pipefail
cd "$(dirname "$0")/.."
run() { echo "\$ $*"; "$@"; echo; }

run kubectl create namespace final-gitops
echo '$ kubectl -n final-gitops create secret generic stockpilot-db-gitops --from-literal=DB_USER=stockpilot --from-literal=DB_PASSWORD="$(openssl rand -hex 16)"'
kubectl -n final-gitops create secret generic stockpilot-db-gitops \
  --from-literal=DB_USER=stockpilot --from-literal=DB_PASSWORD="$(openssl rand -hex 16)"
echo
run kubectl apply -f gitops/application.yaml
