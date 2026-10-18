#!/usr/bin/env bash
# Generates CPU load on the backend so the Horizontal Pod Autoscaler scales it up.
#
#   scripts/load-test.sh [namespace] [workers] [seconds]
#   scripts/load-test.sh stockpilot 30 240
#
# Needs kubectl pointing at the cluster and Metrics Server installed.
# In a second terminal you can also watch:  kubectl get hpa,pods -n stockpilot -w
set -euo pipefail

NAMESPACE="${1:-stockpilot}"
WORKERS="${2:-30}"
DURATION="${3:-240}"
SERVICE="${SERVICE:-stockpilot-backend}"
PORT="${PORT:-8000}"
POD="load-generator"

cleanup() {
  echo
  echo "Stopping the load generator..."
  kubectl delete pod "$POD" -n "$NAMESPACE" --ignore-not-found --wait=false >/dev/null
}
trap cleanup EXIT INT TERM

echo "Starting $WORKERS workers against http://$SERVICE:$PORT/api/items for ${DURATION}s"
kubectl delete pod "$POD" -n "$NAMESPACE" --ignore-not-found >/dev/null

# each worker is a tight request loop; they all run inside one small busybox pod
cat <<YAML | kubectl apply -n "$NAMESPACE" -f - >/dev/null
apiVersion: v1
kind: Pod
metadata:
  name: $POD
spec:
  restartPolicy: Never
  securityContext:
    runAsNonRoot: true
    runAsUser: 65534
    seccompProfile:
      type: RuntimeDefault
  containers:
    - name: load
      image: busybox:1.37
      command:
        - sh
        - -c
        - |
          for i in \$(seq 1 $WORKERS); do
            ( while true; do wget -q -O /dev/null http://$SERVICE:$PORT/api/items; done ) &
          done
          wait
      resources:
        limits:
          cpu: "2"
          memory: 128Mi
      securityContext:
        allowPrivilegeEscalation: false
        capabilities:
          drop: [ALL]
YAML

kubectl wait --for=condition=Ready "pod/$POD" -n "$NAMESPACE" --timeout=120s >/dev/null

end=$((SECONDS + DURATION))
while [ "$SECONDS" -lt "$end" ]; do
  echo "--- $(date +%H:%M:%S)"
  kubectl get hpa -n "$NAMESPACE" --no-headers
  kubectl get pods -n "$NAMESPACE" -l app.kubernetes.io/component=backend --no-headers | awk '{print "   " $1, $2, $3}'
  sleep 15
done

echo "Load finished. The HPA scales back down after its 2 minute stabilisation window."
