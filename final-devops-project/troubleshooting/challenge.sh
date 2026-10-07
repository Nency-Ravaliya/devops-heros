#!/usr/bin/env bash
# Final troubleshooting challenge: deploy a copy of the app with 5 intentional faults
# (troubleshooting/broken/), then identify -> investigate -> root cause -> fix -> verify each one,
# using the correct manifests from kubernetes/.
set +e
cd "$(dirname "$0")/.."
OUT=outputs; mkdir -p $OUT
NS=notes-staging
IMAGE="ghcr.io/tejasvarshney/final-notes-api:$TAG"
cap() { echo "\$ $*"; bash -c "$*" 2>&1; echo; }
api() { curl -s -m 5 -H "Host: notes-staging.local" "http://localhost$1" "${@:2}"; }
export -f api
render() { sed "s#IMAGE_PLACEHOLDER_TYPO#${IMAGE}x#; s#IMAGE_PLACEHOLDER#${IMAGE}#" "$1"; }   # typo = extra "x" in the tag

kubectl create namespace $NS >/dev/null
kubectl -n $NS create secret generic notes-redis-auth --from-literal=password="$(openssl rand -hex 16)" >/dev/null
for f in troubleshooting/broken/*.yaml; do render "$f" | kubectl -n $NS apply -f - >/dev/null; done
sleep 60
{ echo "\$ kubectl -n $NS get hpa notes-api"; kubectl -n $NS get hpa notes-api; echo
  echo "\$ kubectl -n $NS describe hpa notes-api | grep -iE 'missing request|FailedGetResourceMetric|unable' | head -3"
  kubectl -n $NS describe hpa notes-api | grep -iE 'missing request|FailedGetResourceMetric|unable' | head -3; echo; } > /tmp/hpa-broken.txt 2>&1

{
echo "############################ THE REPORT: \"notes-staging.local is down\" ############################"
cap "api / ; echo \"HTTP \$(curl -s -o /dev/null -w '%{http_code}' -H 'Host: notes-staging.local' http://localhost/)\""
cap "kubectl -n $NS get pods,svc,ingress,hpa"

echo "############################ ISSUE 1: ImagePullBackOff ############################"
cap "kubectl -n $NS get pods -l app=notes-api"
cap "kubectl -n $NS describe pod -l app=notes-api | grep -E 'Image:|Failed|BackOff' | sort -u | head -5"
echo "# ROOT CAUSE: image tag has a typo (extra 'x') - that tag was never built or pushed"
echo "# FIX: use the image the pipeline built ($IMAGE)"
cap "kubectl -n $NS set image deploy/notes-api api=$IMAGE"
sleep 30
cap "kubectl -n $NS get pods -l app=notes-api"

echo "############################ ISSUE 2: CreateContainerConfigError ############################"
cap "kubectl -n $NS describe pod -l app=notes-api | grep -E 'Error:|Warning' | sort -u | head -4"
cap "kubectl -n $NS get secret notes-redis-auth -o jsonpath='{.data}' | jq 'keys'"
echo "# ROOT CAUSE: Deployment reads key 'redis-password' but the Secret's key is 'password'"
cap "diff <(sed 's#IMAGE_PLACEHOLDER_TYPO#IMG#' troubleshooting/broken/deployment.yaml) <(sed 's#IMAGE_PLACEHOLDER#IMG#' kubernetes/deployment.yaml)"
echo "# FIX: apply the corrected Deployment (also adds resource requests - see issue 4)"
cap "sed 's#IMAGE_PLACEHOLDER#$IMAGE#' kubernetes/deployment.yaml | kubectl -n $NS apply -f -"
sleep 40
cap "kubectl -n $NS get pods -l app=notes-api"

echo "############################ ISSUE 3: Pods Running but never Ready ############################"
cap "kubectl -n $NS describe pod -l app=notes-api | grep -E 'Readiness probe failed' | sort -u | head -2"
POD=$(kubectl -n $NS get pod -l app=notes-api -o jsonpath='{.items[0].metadata.name}')
cap "kubectl -n $NS exec $POD -- python -c \"import urllib.request as u; print(u.urlopen('http://127.0.0.1:8000/health').read().decode())\""
cap "kubectl -n $NS exec $POD -- python -c \"import urllib.request as u, urllib.error as e
try: u.urlopen('http://127.0.0.1:8000/ready')
except e.HTTPError as x: print(x.code, x.read().decode())\""
cap "kubectl -n $NS get endpoints notes-api"
cap "kubectl -n $NS get configmap notes-config -o jsonpath='{.data.REDIS_HOST}'; echo; kubectl -n $NS get svc"
echo "# ROOT CAUSE: REDIS_HOST=redis, but the Redis Service is named notes-redis -> name does not resolve -> /ready 503 -> no endpoints"
cap "kubectl -n $NS apply -f kubernetes/configmap.yaml && kubectl -n $NS rollout restart deploy/notes-api && kubectl -n $NS rollout status deploy/notes-api --timeout=120s"
cap "kubectl -n $NS get endpoints notes-api"

echo "############################ ISSUE 4: HPA shows <unknown> ############################"
echo "(captured from the broken Deployment before the fix in issue 2 removed it:)"
cat /tmp/hpa-broken.txt 2>/dev/null
cap "kubectl -n $NS get hpa notes-api"
cap "kubectl -n $NS describe hpa notes-api | grep -E 'Metrics|resource cpu|Conditions' -A2 | head -12"
echo "# ROOT CAUSE (broken manifest): no resources.requests.cpu -> HPA cannot compute utilization (% of request)"
echo "# FIX: requests added in kubernetes/deployment.yaml (applied in issue 2)"

echo "############################ ISSUE 5: Ingress returns 503 ############################"
cap "echo HTTP \$(curl -s -o /dev/null -w '%{http_code}' -H 'Host: notes-staging.local' http://localhost/)"
cap "kubectl -n $NS describe ingress notes-api | sed -n '/Rules:/,/Annotations:/p'"
cap "kubectl -n $NS get svc notes-api -o jsonpath='{.spec.ports}'; echo"
echo "# ROOT CAUSE: Ingress backend port 8000, but the Service port is 80 (8000 is the targetPort)"
cap "kubectl -n $NS apply -f kubernetes/ingress.yaml"
sleep 10

echo "############################ VERIFY: everything fixed ############################"
cap "kubectl -n $NS get pods,svc,ingress,hpa"
cap "api / | jq ."
cap "api /api/notes -X POST -H 'Content-Type: application/json' -d '{\"text\":\"staging fixed\"}' | jq -c ."
cap "api /api/notes | jq -c '[.[].text]'"
} > $OUT/30-troubleshooting.txt 2>&1
kubectl delete namespace $NS --wait=false >/dev/null 2>&1
echo "challenge.sh finished"
