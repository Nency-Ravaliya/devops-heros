#!/usr/bin/env bash
# Blue-green (02-blue-green). Usage: 04-blue-green.sh deploy|switch|rollback|cleanup
. "$(dirname "$0")/lib.sh"
EP="kubectl get endpointslices -l kubernetes.io/service-name=myapp-service -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]} {.targetRef.name}{\"\\n\"}{end}'"
case "$1" in
deploy)
  hr "Step 1: both environments up, Service -> BLUE"
  x "kubectl apply -f 02-blue-green/deployment-blue.yaml"
  x "kubectl apply -f 02-blue-green/deployment-green.yaml"
  x "kubectl rollout status deployment/app-blue; kubectl rollout status deployment/app-green"
  x "kubectl get pods -l app=myapp --show-labels"
  x "kubectl apply -f 02-blue-green/service-blue.yaml"
  sleep 5
  x "kubectl describe svc myapp-service | grep Selector"
  x "$EP"
  x "curl -s http://localhost:30020 | grep -oE 'BLUE ENVIRONMENT|GREEN ENVIRONMENT|Version: v[0-9]'"
  ;;
switch)
  hr "Step 4-5: flip the selector to GREEN"
  curl_loop http://localhost:30020 'BLUE ENVIRONMENT\|GREEN ENVIRONMENT' 20 0.3 > "$L/04-blue-green-curl.txt" &
  CURLPID=$!
  sleep 1
  x "kubectl apply -f 02-blue-green/service-green.yaml"
  wait $CURLPID
  x "kubectl describe svc myapp-service | grep Selector"
  x "$EP"
  x "curl -s http://localhost:30020 | grep -oE 'BLUE ENVIRONMENT|GREEN ENVIRONMENT|Version: v[0-9]'"
  x "cat '$L/04-blue-green-curl.txt' | uniq -c        # 20 requests 0.3s apart across the switch"
  x "kubectl get pods -l app=myapp --show-labels     # nothing was restarted, only routing changed"
  ;;
rollback)
  hr "Step 6: flip back to BLUE"
  x "kubectl apply -f 02-blue-green/service-blue.yaml"
  sleep 3
  x "curl -s http://localhost:30020 | grep -oE 'BLUE ENVIRONMENT|GREEN ENVIRONMENT'"
  x "$EP"
  ;;
cleanup)
  hr "Cleanup"
  x "kubectl delete -f 02-blue-green/service-blue.yaml"
  x "kubectl delete -f 02-blue-green/deployment-blue.yaml"
  x "kubectl delete -f 02-blue-green/deployment-green.yaml"
  ;;
esac
