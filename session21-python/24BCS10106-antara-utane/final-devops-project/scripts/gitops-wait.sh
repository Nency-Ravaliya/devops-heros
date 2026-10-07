#!/usr/bin/env bash
# Wait until the Argo CD app is Synced+Healthy at the expected git revision.
#   scripts/gitops-wait.sh <expected-sha>
set -uo pipefail
APP=final-stockpilot-24BCS10106
WANT="${1:-}"
kubectl -n argocd annotate application "$APP" argocd.argoproj.io/refresh=normal --overwrite >/dev/null
for i in $(seq 1 60); do
  rev=$(kubectl -n argocd get application "$APP" -o jsonpath='{.status.sync.revision}')
  st=$(kubectl -n argocd get application "$APP" -o jsonpath='{.status.sync.status}/{.status.health.status}')
  if [ "$st" = "Synced/Healthy" ] && { [ -z "$WANT" ] || [ "$rev" = "$WANT" ]; }; then break; fi
  sleep 5
done
echo "\$ kubectl -n argocd get application $APP -o wide"
kubectl -n argocd get application "$APP" -o wide
echo
echo "\$ kubectl -n argocd get application $APP -o jsonpath='{.status.operationState.phase} {.status.operationState.message}'"
kubectl -n argocd get application "$APP" -o jsonpath='{.status.operationState.phase} {.status.operationState.message}{"\n"}'
echo
echo "\$ kubectl -n argocd get application $APP -o jsonpath='{.status.summary.images}'"
kubectl -n argocd get application "$APP" -o jsonpath='{.status.summary.images}{"\n"}'
echo
