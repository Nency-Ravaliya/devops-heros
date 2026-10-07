#!/usr/bin/env bash
# Recreate (04-recreate). Usage: 06-recreate.sh deploy|update|rollback|cleanup
. "$(dirname "$0")/lib.sh"
case "$1" in
deploy)
  hr "Step 1: v1 on NodePort 30040"
  x "kubectl apply -f 04-recreate/deployment-v1.yaml"
  x "kubectl apply -f 04-recreate/service.yaml"
  x "kubectl rollout status deployment/app-recreate"
  sleep 5
  x "kubectl get pods -l app=app-recreate"
  x "kubectl get deployment app-recreate -o jsonpath='strategy={.spec.strategy.type}{\"\\n\"}'"
  x "curl -s http://localhost:30040 | grep -o 'VERSION: [^<]*'"
  ;;
update)
  hr "Step 2-3: apply v2 and watch the outage window"
  watch_start "$L/06-recreate-watch.txt" -l app=app-recreate
  curl_loop http://localhost:30040 'VERSION: [^<]*' 60 0.5 > "$L/06-recreate-curl.txt" &
  CURLPID=$!
  x "kubectl apply -f 04-recreate/deployment-v2.yaml"
  x "sleep 2; kubectl get pods -l app=app-recreate            # all v1 pods Terminating together, no v2 yet"
  x "kubectl rollout status deployment/app-recreate"
  wait $CURLPID
  watch_stop
  x "curl -s http://localhost:30040 | grep -o 'VERSION: [^<]*'"
  hr "what the curl loop saw (60 requests, 0.5s apart)"
  x "cat '$L/06-recreate-curl.txt' | uniq -c"
  hr "pod watch during the update"
  x "cat '$L/06-recreate-watch.txt'"
  ;;
rollback)
  hr "Step 5: rollback (also a full stop/start with Recreate)"
  x "kubectl rollout undo deployment/app-recreate"
  x "kubectl rollout status deployment/app-recreate"
  x "curl -s http://localhost:30040 | grep -o 'VERSION: [^<]*'"
  ;;
cleanup)
  hr "Cleanup"
  x "kubectl delete -f 04-recreate/service.yaml"
  x "kubectl delete -f 04-recreate/deployment-v2.yaml"
  ;;
esac
