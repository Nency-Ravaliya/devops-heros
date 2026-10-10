#!/usr/bin/env bash
# 03-mini-project: the Notes app chart written from scratch (kushal-24bcs10123/03-mini-project/notes-chart),
# following mini-project/README.md step by step.
. "$(dirname "$0")/lib.sh"
cd "$ME/03-mini-project"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
hr "The chart I wrote"
x "find notes-chart -type f | sort"
for f in Chart.yaml values.yaml values-prod.yaml templates/configmap.yaml templates/deployment.yaml templates/service.yaml; do x "cat notes-chart/$f"; done

hr "Step 8-9: lint + render locally"
x "helm lint notes-chart"
x "helm template notes-dev notes-chart"
x "helm template notes-prod notes-chart -f notes-chart/values-prod.yaml | grep -E 'replicas|image:|ENVIRONMENT|environment:'"

hr "Step 10: install (development values)"
x "helm install notes-dev notes-chart"
x "ready notes-dev-deploy"
x "kubectl -n $NS get pods,svc,configmap -l app=notes-dev 2>/dev/null; kubectl -n $NS get configmap notes-dev-config -o yaml | sed -n '/^data/,/^kind/p'"
x "kubectl -n $NS exec deploy/notes-dev-deploy -- env | grep -E 'APP_NAME|ENVIRONMENT'"
# nodePort 30090 is not one of the ports kind maps to my Mac, so I reach it from inside the docker network / via port-forward
NODEIP=$(kubectl get node kushal-lab-control-plane -o jsonpath='{.status.addresses[?(@.type=="InternalIP")].address}')
x "docker run --rm --network kind curlimages/curl:8.5.0 -s -m 10 --retry 3 --retry-all-errors -o /dev/null -w 'NodePort 30090 on node $NODEIP: HTTP %{http_code}\n' http://$NODEIP:30090"
kubectl -n "$NS" port-forward svc/notes-dev-svc 19095:80 >/dev/null 2>&1 & PF=$!; sleep 2
x "curl -s -m 5 http://localhost:19095 | grep -o '<title>.*</title>'"
x "curl -s -m 5 -I http://localhost:19095 | grep -i '^Server'"
node "$ME/scripts/shot.mjs" http://localhost:19095/ "$ME/screenshots/notes-dev-nginx-1.24.png" '' 2500 2>/dev/null || true
kill $PF 2>/dev/null

hr "Step 11-12: upgrade to production values, check history"
x "helm upgrade notes-dev notes-chart -f notes-chart/values-prod.yaml"
x "ready notes-dev-deploy"
x "pods notes-dev"
x "kubectl -n $NS get deploy notes-dev-deploy -o jsonpath='labels: {.metadata.labels}{\"\\n\"}'"
x "kubectl -n $NS exec deploy/notes-dev-deploy -- env | grep -E 'APP_NAME|ENVIRONMENT'"
kubectl -n "$NS" port-forward svc/notes-dev-svc 19095:80 >/dev/null 2>&1 & PF=$!; sleep 2
x "curl -s -m 5 -I http://localhost:19095 | grep -i '^Server'"
node "$ME/scripts/shot.mjs" http://localhost:19095/ "$ME/screenshots/notes-prod-nginx-1.25.png" '' 2500 2>/dev/null || true
kill $PF 2>/dev/null
x "helm history notes-dev"

hr "Step 13: simulate a bad upgrade"
x "helm upgrade notes-dev notes-chart --set image.tag=broken-tag-does-not-exist"
x "sleep 25; pods notes-dev"
x "kubectl -n $NS get pods -l app=notes-dev --field-selector=status.phase=Pending -o custom-columns='NAME:.metadata.name,STATE:.status.containerStatuses[0].state.waiting.reason,MSG:.status.containerStatuses[0].state.waiting.message' | cut -c1-160"
x "helm history notes-dev"

hr "Step 14: rollback to revision 2"
x "helm rollback notes-dev 2"
x "ready notes-dev-deploy"
x "pods notes-dev"
x "helm history notes-dev"

hr "Step 15: clean up"
x "helm uninstall notes-dev"
x "kubectl -n $NS get pods,svc,configmap"
x "kubectl delete namespace $NS --wait=false"
