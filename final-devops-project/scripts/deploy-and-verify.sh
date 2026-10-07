#!/usr/bin/env bash
# GitOps deployment (Argo CD + Helm) and end-to-end verification of the final project.
# Needs: TAG (image tag), the image tarball image.tar.gz, kubeconfig for the Terraform-created cluster.
set +e
cd "$(dirname "$0")/.."
OUT=outputs; mkdir -p $OUT
IMAGE="ghcr.io/tejasvarshney/final-notes-api:$TAG"
cap() { echo "\$ $*"; bash -c "$*" 2>&1; echo; }
pf() { kubectl port-forward "$@" >/dev/null 2>&1 & echo $!; }
promq() { curl -s --get localhost:9090/api/v1/query --data-urlencode "query=$1" \
  | jq -r '.data.result[] | "\(.metric | del(.__name__) | to_entries | map("\(.key)=\(.value)") | join(",")) => \(.value[1])"'; }
export -f promq
api() { curl -s -H "Host: notes.local" "http://localhost$1" "${@:2}"; }    # through the ingress (kind maps :80)
export -f api

######################################## GitOps deploy
{
echo "################ load the image built + scanned by the pipeline into the cluster ################"
cap "docker load -i ../image.tar.gz 2>/dev/null || docker load -i image.tar.gz"
cap "kind load docker-image $IMAGE --name final-devops"
echo "################ the Secret is created by the pipeline - never committed to Git ################"
cap "kubectl create namespace notes"
cap "kubectl -n notes create secret generic notes-redis-auth --from-literal=password=\$(openssl rand -hex 16)"
cap "kubectl -n notes get secret notes-redis-auth"
echo "################ GitOps: commit the new image tag to the environment branch ################"
# use a separate worktree so the main checkout (and the outputs commit) stays on main
WT=$(mktemp -d); git fetch -q origin
git worktree add -q --detach "$WT" HEAD
sed -i "s/^  tag: .*/  tag: \"$TAG\"/" "$WT/final-devops-project/gitops/notes-values.yaml"
git -C "$WT" -c user.name="github-actions[bot]" -c user.email="41898282+github-actions[bot]@users.noreply.github.com" commit -q -m "GitOps: deploy notes-api $TAG" -- final-devops-project/gitops/notes-values.yaml
git -C "$WT" push -q -f origin HEAD:refs/heads/final-gitops
GITOPS_REV=$(git -C "$WT" rev-parse HEAD)
cap "git -C $WT log --oneline -1 && git -C $WT show --format= HEAD"
git worktree remove --force "$WT"
echo "################ Argo CD Application (Helm chart + values from Git) ################"
cap "cat gitops/argocd-application.yaml"
cap "kubectl apply -f gitops/argocd-application.yaml"
for i in $(seq 1 60); do
  s=$(kubectl -n argocd get application notes-api -o jsonpath='{.status.sync.status}/{.status.health.status}')
  [ "$s" = "Synced/Healthy" ] && break; sleep 5
done
cap "kubectl -n argocd get applications -o wide"
cap "kubectl -n argocd get application notes-api -o jsonpath='revision={.status.sync.revisions}{\"\n\"}'"
echo "(expected GitOps commit: $GITOPS_REV)"; echo
cap "kubectl -n notes get all,ingress,hpa,pvc,configmap,secret,servicemonitor"
} > $OUT/20-gitops-deploy.txt 2>&1

######################################## verification
{
echo "################ through the Ingress (http://notes.local on the cluster's port 80) ################"
cap "api / | jq ."
cap "api /health"
cap "api /ready"
cap "api /api/notes -X POST -H 'Content-Type: application/json' -d '{\"text\":\"Final project deployed by Argo CD\"}' | jq ."
cap "api /api/notes -X POST -H 'Content-Type: application/json' -d '{\"text\":\"Notes survive Redis restarts\"}' | jq ."
cap "api /api/notes | jq -r '.[].text'"
echo "################ storage: delete the Redis Pod, the PVC keeps the data ################"
cap "kubectl -n notes get pvc"
cap "kubectl -n notes delete pod notes-redis-0 && kubectl -n notes wait --for=condition=Ready pod/notes-redis-0 --timeout=120s"
sleep 10
cap "api /api/notes | jq -r '.[].text'"
echo "################ ConfigMap + Secret inside the container ################"
cap "kubectl -n notes exec deploy/notes-api -- sh -c 'echo APP_ENV=\$APP_ENV; echo WELCOME_MESSAGE=\$WELCOME_MESSAGE; echo REDIS_HOST=\$REDIS_HOST; echo REDIS_PASSWORD length=\${#REDIS_PASSWORD}'"
echo "################ probes ################"
cap "kubectl -n notes describe deploy notes-api | grep -E 'Liveness|Readiness|Startup|Limits|Requests' -A0"
echo "################ HPA: generate CPU load on /api/burn ################"
cap "kubectl -n notes get hpa"
kubectl -n notes create deployment load --image=busybox:1.36 --replicas=3 -- sh -c 'while true; do wget -qO- "http://notes-api/api/burn?n=400000" >/dev/null; done'
for i in 1 2 3 4; do sleep 45; echo "======== t+$((i*45))s under load ========"; cap "kubectl -n notes get hpa notes-api"; done
cap "kubectl -n notes top pods"
cap "kubectl -n notes get pods -l app=notes-api"
cap "kubectl -n notes describe hpa notes-api | sed -n '/Events:/,\$p'"
kubectl -n notes delete deployment load --now >/dev/null
echo "################ GitOps self-heal: manual change is reverted by Argo CD ################"
cap "kubectl -n notes patch configmap notes-config --type merge -p '{\"data\":{\"WELCOME_MESSAGE\":\"hacked by hand\"}}'"
sleep 30
cap "kubectl -n notes get configmap notes-config -o jsonpath='{.data.WELCOME_MESSAGE}'; echo"
} > $OUT/21-verify.txt 2>&1

######################################## monitoring
kubectl apply -f monitoring/alerts.yaml >/dev/null 2>&1
PROM=$(pf -n monitoring svc/kps-prometheus 9090:9090); GRAF=$(pf -n monitoring svc/kps-grafana 3000:80); sleep 5
for i in $(seq 1 20); do api /api/notes >/dev/null; api /missing >/dev/null; done
for i in $(seq 1 30); do   # wait until the operator has loaded the PrometheusRule
  [ "$(curl -s localhost:9090/api/v1/rules | jq '[.data.groups[] | select(.name=="notes-api.rules")] | length')" = "1" ] && break; sleep 6
done
sleep 20
{
cap "curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | select(.labels.namespace==\"notes\") | \"\(.labels.job) \(.labels.instance) health=\(.health)\"'"
cap "promq 'sum by (endpoint, status) (rate(notes_http_requests_total{namespace=\"notes\"}[2m]))'"
cap "promq 'histogram_quantile(0.95, sum by (le) (rate(notes_http_request_duration_seconds_bucket{namespace=\"notes\"}[5m])))'"
cap "promq 'notes_created_total'"
cap "promq 'sum by (pod) (rate(container_cpu_usage_seconds_total{namespace=\"notes\", container!=\"\"}[2m]))'"
cap "promq 'sum by (pod) (container_memory_working_set_bytes{namespace=\"notes\", container!=\"\"})'"
cap "curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[] | select(.name==\"notes-api.rules\") | .rules[] | \"\(.name): \(.state) health=\(.health)\"'"
cap "kubectl -n notes logs deploy/notes-api --tail=6"
} > $OUT/22-monitoring.txt 2>&1
uid=$(curl -s -u admin:demo-only-not-secret "localhost:3000/api/search?query=Namespace%20(Pods)" | jq -r '.[0].uid')
google-chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size=1600,1000 --virtual-time-budget=25000 \
  --screenshot="$OUT/grafana-notes-namespace.png" "http://localhost:3000/d/$uid/?orgId=1&kiosk&from=now-15m&to=now&var-namespace=notes&var-datasource=prometheus" >/dev/null 2>&1
kill $PROM $GRAF 2>/dev/null
echo "deploy-and-verify.sh finished"
