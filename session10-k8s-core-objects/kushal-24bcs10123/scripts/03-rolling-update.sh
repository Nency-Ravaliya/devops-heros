#!/usr/bin/env bash
# Rolling update (01-rolling-update). Usage: 03-rolling-update.sh deploy|update|rollback|cleanup
. "$(dirname "$0")/lib.sh"
case "$1" in
deploy)
  hr "Step 1-2: deploy v1 and reach it on NodePort 30010"
  x "kubectl apply -f 01-rolling-update/deployment-v1.yaml"
  x "kubectl apply -f 01-rolling-update/service.yaml"
  x "kubectl rollout status deployment/app-rolling"
  x "kubectl get pods -l app=app-rolling --show-labels"
  x "kubectl get svc app-rolling-service"
  x "curl -s http://localhost:30010 | grep -o 'VERSION: v[0-9]'"
  x "kubectl get deployment app-rolling -o jsonpath='strategy={.spec.strategy.type} maxSurge={.spec.strategy.rollingUpdate.maxSurge} maxUnavailable={.spec.strategy.rollingUpdate.maxUnavailable}{\"\\n\"}'"
  ;;
update)
  hr "Step 3-5: roll to v2 while curling continuously"
  watch_start "$L/03-rolling-watch.txt" -l app=app-rolling
  curl_loop http://localhost:30010 'VERSION: v[0-9]' 80 0.5 > "$L/03-rolling-curl.txt" &
  CURLPID=$!
  x "kubectl apply -f 01-rolling-update/deployment-v2.yaml"
  x "sleep 4; kubectl get pods -l app=app-rolling            # mid-rollout: 4 desired + 1 surge = 5 pods"
  x "kubectl rollout status deployment/app-rolling"
  wait $CURLPID
  watch_stop
  x "kubectl get pods -l app=app-rolling --show-labels"
  x "curl -s http://localhost:30010 | grep -o 'VERSION: v[0-9]'"
  hr "what the curl loop saw during the rollout (80 requests, 0.5s apart)"
  x "cat '$L/03-rolling-curl.txt' | uniq -c"
  x "sort '$L/03-rolling-curl.txt' | uniq -c"
  hr "pod watch during the rollout"
  x "cat '$L/03-rolling-watch.txt'"
  x "kubectl rollout history deployment/app-rolling"
  x "kubectl get rs -l app=app-rolling"
  ;;
rollback)
  hr "Step 7: rollback"
  x "kubectl rollout undo deployment/app-rolling"
  x "kubectl rollout status deployment/app-rolling"
  x "kubectl get pods -l app=app-rolling --show-labels"
  x "curl -s http://localhost:30010 | grep -o 'VERSION: v[0-9]'"
  x "kubectl rollout history deployment/app-rolling"
  ;;
cleanup)
  hr "Cleanup"
  x "kubectl delete -f 01-rolling-update/service.yaml"
  x "kubectl delete -f 01-rolling-update/deployment-v1.yaml"
  ;;
esac
