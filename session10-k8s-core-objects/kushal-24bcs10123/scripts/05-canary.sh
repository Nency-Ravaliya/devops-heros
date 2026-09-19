#!/usr/bin/env bash
# Canary (03-canary). Usage: 05-canary.sh deploy|canary|increase|promote|rollback|cleanup
. "$(dirname "$0")/lib.sh"
hits() { echo "--- $1 requests:"; curl_loop http://localhost:30030 'STABLE v1\|CANARY v2' "$1" 0.1 | sort | uniq -c; }
case "$1" in
deploy)
  hr "Step 1-3: stable v1 only (9 pods)"
  x "kubectl apply -f 03-canary/deployment-stable.yaml"
  x "kubectl rollout status deployment/app-stable"
  x "kubectl apply -f 03-canary/service.yaml"
  sleep 5
  x "kubectl get svc myapp-canary-service -o jsonpath='selector={.spec.selector}{\"\\n\"}'"
  x "hits 20"
  ;;
canary)
  hr "Step 4-5: add 1 canary pod = 10% of endpoints"
  x "kubectl apply -f 03-canary/deployment-canary.yaml"
  x "kubectl rollout status deployment/app-canary"
  x "kubectl get pods -l app=myapp-canary -L track,version"
  x "kubectl get endpointslices -l kubernetes.io/service-name=myapp-canary-service -o jsonpath='{range .items[*]}{.endpoints[*].addresses[0]}{\"\\n\"}{end}' | wc -w"
  x "hits 100"
  ;;
increase)
  hr "Step 6: 30% canary (3 canary + 7 stable)"
  x "kubectl scale deployment app-canary --replicas=3"
  x "kubectl scale deployment app-stable --replicas=7"
  x "kubectl rollout status deployment/app-canary; kubectl rollout status deployment/app-stable"
  x "kubectl get deploy app-stable app-canary"
  x "hits 100"
  ;;
promote)
  hr "Step 7A: promote canary to 100%"
  x "kubectl scale deployment app-canary --replicas=9"
  x "kubectl scale deployment app-stable --replicas=0"
  x "kubectl rollout status deployment/app-canary"
  x "kubectl get deploy app-stable app-canary"
  x "hits 20"
  ;;
rollback)
  hr "Step 7B (shown for completeness): instant rollback is just the reverse scale"
  x "kubectl scale deployment app-stable --replicas=9 && kubectl scale deployment app-canary --replicas=0"
  x "kubectl rollout status deployment/app-stable"
  x "hits 20"
  ;;
cleanup)
  hr "Cleanup"
  x "kubectl delete -f 03-canary/service.yaml"
  x "kubectl delete -f 03-canary/deployment-canary.yaml"
  x "kubectl delete -f 03-canary/deployment-stable.yaml"
  ;;
esac
