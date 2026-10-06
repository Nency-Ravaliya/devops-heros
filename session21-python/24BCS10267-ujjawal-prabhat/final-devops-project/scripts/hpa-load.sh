#!/usr/bin/env bash
# Generate load against the StockPilot service from inside the cluster and
# watch the HPA react. Usage: NS=final DURATION=150 scripts/hpa-load.sh
set -uo pipefail
NS="${NS:-final}"
DURATION="${DURATION:-150}"
SVC="http://stockpilot-api.${NS}.svc.cluster.local"

echo "\$ kubectl -n $NS get hpa"
kubectl -n "$NS" get hpa
echo
echo "\$ kubectl -n $NS run load-gen --image=busybox:1.37 --restart=Never -- sh -c '<8 parallel wget loops against $SVC/api/summary and /api/items>'"
kubectl -n "$NS" run load-gen --image=busybox:1.37 --restart=Never --labels=app=load-gen -- sh -c \
  "for i in 1 2 3 4 5 6 7 8; do (while true; do wget -q -O /dev/null $SVC/api/summary; wget -q -O /dev/null $SVC/api/items; done) & done; sleep $DURATION"
echo
end=$(( $(date +%s) + DURATION + 20 ))
while [ "$(date +%s)" -lt "$end" ]; do
  echo "--- $(date +%H:%M:%S)"
  kubectl -n "$NS" get hpa --no-headers
  kubectl -n "$NS" top pods -l app.kubernetes.io/component=api --no-headers 2>/dev/null || true
  sleep 15
done
echo
echo "\$ kubectl -n $NS describe hpa | sed -n '/Events/,\$p'"
kubectl -n "$NS" describe hpa | sed -n '/Events/,$p'
echo
echo "\$ kubectl -n $NS get deploy stockpilot-api"
kubectl -n "$NS" get deploy stockpilot-api
kubectl -n "$NS" delete pod load-gen --wait=false >/dev/null
