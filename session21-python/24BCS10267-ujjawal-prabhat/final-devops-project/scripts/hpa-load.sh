#!/usr/bin/env bash
# Load the backend Service from inside the cluster and watch the HPA react.
#   NS=final DURATION=150 scripts/hpa-load.sh
set -uo pipefail
NS="${NS:-final}"
DURATION="${DURATION:-150}"
SVC="http://stockpilot-backend.${NS}.svc.cluster.local"

echo "\$ kubectl -n $NS get hpa"
kubectl -n "$NS" get hpa
echo
echo "\$ kubectl -n $NS run load-gen --image=busybox:1.37 --restart=Never -- sh -c '<8 parallel wget loops against $SVC/api/summary and /api/items for ${DURATION}s>'"
kubectl -n "$NS" run load-gen --image=busybox:1.37 --restart=Never -- sh -c \
  "for i in 1 2 3 4 5 6 7 8; do (while true; do wget -q -O /dev/null $SVC/api/summary; wget -q -O /dev/null $SVC/api/items; done) & done; sleep $DURATION"
echo
end=$(( $(date +%s) + DURATION + 60 ))
while [ "$(date +%s)" -lt "$end" ]; do
  echo "--- $(date +%H:%M:%S)"
  kubectl -n "$NS" get hpa --no-headers
  sleep 15
done
echo
echo "\$ kubectl -n $NS describe hpa stockpilot-backend | grep SuccessfulRescale"
kubectl -n "$NS" describe hpa stockpilot-backend | grep SuccessfulRescale
kubectl -n "$NS" delete pod load-gen --wait=false >/dev/null
