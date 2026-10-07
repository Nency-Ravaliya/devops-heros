#!/usr/bin/env bash
# Session 20 end-to-end demo: monitoring, observability (metrics/logs/traces) and GitOps.
# Runs in GitHub Actions on a kind cluster (see .github/workflows/session20-observability-gitops.yml).
# Every command and its output is written to outputs/*.txt.
set +e
cd "$(dirname "$0")/.."
OUT=outputs
mkdir -p "$OUT"
cap() { echo "\$ $*"; bash -c "$*" 2>&1; echo; }
pf() { kubectl port-forward "$@" >/dev/null 2>&1 & echo $!; }          # background port-forward, prints PID
promq() { curl -s --get "http://localhost:9090/api/v1/query" --data-urlencode "query=$1" \
          | jq -r '.data.result[] | "\(.metric | del(.__name__) | to_entries | map("\(.key)=\(.value)") | join(",")) => \(.value[1])"'; }
export -f promq

############################################################ 1. MONITORING
{
echo '################ install kube-prometheus-stack (Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics) ################'
cap "helm repo add prometheus-community https://prometheus-community.github.io/helm-charts && helm repo update"
cap "helm install kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f monitoring/kps-values.yaml --wait --timeout 10m"
cap "kubectl get pods -n monitoring"
cap "kubectl get svc -n monitoring"
echo '################ deploy an instrumented app + ServiceMonitor + alert rules ################'
cap "kubectl apply -f monitoring/demo-app.yaml && kubectl apply -f monitoring/alerts.yaml"
cap "kubectl -n session20 rollout status deploy/demo-app --timeout=120s"
cap "kubectl get pods,svc,servicemonitor,prometheusrule -n session20"
APP=$(pf -n session20 svc/demo-app 8081:80); sleep 3
cap "curl -s localhost:8081/ ; curl -s localhost:8081/err >/dev/null; curl -s localhost:8081/metrics | grep -E '^# (HELP|TYPE) http_requests_total|^http_requests_total|^version'"
kill $APP 2>/dev/null
echo '################ generate traffic ################'
kubectl -n session20 run traffic --image=busybox:1.36 --restart=Never -- sh -c 'while true; do wget -qO- http://demo-app >/dev/null; wget -qO- http://demo-app/err >/dev/null 2>&1; sleep 0.05; done'
sleep 75
PROM=$(pf -n monitoring svc/kps-prometheus 9090:9090); sleep 4
# the operator needs a moment to turn the new ServiceMonitor/PrometheusRule into Prometheus config
for i in $(seq 1 40); do
  n=$(curl -s localhost:9090/api/v1/query --data-urlencode 'query=count(up{namespace="session20"} == 1)' | jq -r '.data.result[0].value[1] // 0')
  r=$(curl -s localhost:9090/api/v1/rules | jq '[.data.groups[] | select(.name=="demo-app.rules")] | length')
  [ "$n" = "2" ] && [ "$r" = "1" ] && break; sleep 6
done
sleep 30   # let rate() windows fill
echo '################ Prometheus: targets ################'
cap "curl -s localhost:9090/api/v1/targets | jq -r '.data.activeTargets[] | \"\(.labels.job) \(.labels.instance) health=\(.health)\"' | sort | uniq"
echo '################ Metrics: application health ################'
cap "promq 'up{namespace=\"session20\"}'"
cap "promq 'sum by (code) (rate(http_requests_total{namespace=\"session20\"}[1m]))'"
cap "promq 'kube_deployment_status_replicas_available{namespace=\"session20\"}'"
echo '################ Metrics: CPU utilization ################'
cap "promq 'sum by (pod) (rate(container_cpu_usage_seconds_total{namespace=\"session20\", container!=\"\"}[2m]))'"
cap "promq '100 * (1 - avg(rate(node_cpu_seconds_total{mode=\"idle\"}[2m])))'"
echo '################ Metrics: memory utilization ################'
cap "promq 'sum by (pod) (container_memory_working_set_bytes{namespace=\"session20\", container!=\"\"})'"
cap "promq '100 * (1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes)'"
echo '################ Alerts: rules loaded ################'
cap "curl -s localhost:9090/api/v1/rules | jq -r '.data.groups[] | select(.name==\"demo-app.rules\") | .rules[] | \"\(.name): \(.state) health=\(.health)\"'"
echo '################ Alerts: break something - scale demo-app to 1 replica ################'
cap "kubectl -n session20 scale deploy demo-app --replicas=1"
sleep 100
cap "curl -s localhost:9090/api/v1/alerts | jq -r '.data.alerts[] | select(.labels.namespace==\"session20\" or (.labels.alertname|startswith(\"DemoApp\"))) | \"\(.labels.alertname) state=\(.state) severity=\(.labels.severity) value=\(.value) since=\(.activeAt)\"'"
AM=$(pf -n monitoring svc/kps-alertmanager 9093:9093); sleep 3
cap "curl -s localhost:9093/api/v2/alerts | jq -r '.[] | select(.labels.alertname|startswith(\"DemoApp\")) | \"Alertmanager received: \(.labels.alertname) [\(.status.state)] \(.annotations.summary)\"'"
cap "kubectl -n session20 scale deploy demo-app --replicas=2 && kubectl -n session20 rollout status deploy/demo-app --timeout=60s"
} > "$OUT/01-monitoring.txt" 2>&1

############################################################ Grafana screenshots
GRAF=$(pf -n monitoring svc/kps-grafana 3000:80); sleep 5
{
cap "curl -s localhost:3000/api/health"
cap "curl -s -u admin:demo-only-not-secret localhost:3000/api/datasources | jq -r '.[] | \"\(.name) \(.type) \(.url)\"'"
cap "curl -s -u admin:demo-only-not-secret 'localhost:3000/api/search?type=dash-db' | jq -r '.[].title' | sort | head -40"
} > "$OUT/02-grafana.txt" 2>&1
shot() {  # shot <file> <title>  - screenshot a dashboard found by title
  uid=$(curl -s -u admin:demo-only-not-secret "localhost:3000/api/search?query=$(jq -rn --arg t "$2" '$t|@uri')" | jq -r '.[0].uid')
  google-chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size=1600,1000 \
    --virtual-time-budget=25000 --screenshot="$OUT/$1" \
    "http://localhost:3000/d/$uid/?orgId=1&kiosk&from=now-15m&to=now&refresh=&var-namespace=session20&var-datasource=prometheus" >/dev/null 2>&1
  echo "screenshot $1 <- dashboard '$2' (uid=$uid)" >> "$OUT/02-grafana.txt"
}
shot grafana-namespace-pods.png "Kubernetes / Compute Resources / Namespace (Pods)"
shot grafana-cluster.png "Kubernetes / Compute Resources / Cluster"
shot grafana-node-exporter.png "Node Exporter / Nodes"

############################################################ 2. OBSERVABILITY: logs + traces
{
echo '################ Logs pillar ################'
cap "kubectl -n session20 logs deploy/demo-app --tail=5"
cap "kubectl -n session20 logs traffic --tail=3"
cap "kubectl -n monitoring logs statefulset/prometheus-kps-prometheus -c prometheus --tail=5"
cap "kubectl get events -n session20 --sort-by=.lastTimestamp | tail -8"
echo '################ Traces pillar: Jaeger + HotROD (OpenTelemetry) ################'
cap "kubectl apply -f observability/tracing.yaml"
cap "kubectl -n tracing rollout status deploy/jaeger --timeout=180s && kubectl -n tracing rollout status deploy/hotrod --timeout=180s"
cap "kubectl get pods,svc -n tracing"
HOT=$(pf -n tracing svc/hotrod 8080:8080); JAE=$(pf -n tracing svc/jaeger 16686:16686); sleep 5
cap "for c in 123 392 731 567; do curl -s \"localhost:8080/dispatch?customer=\$c\" | jq -c '{Driver, ETA}'; done"
cap "kubectl -n tracing logs deploy/hotrod --tail=4 | cut -c1-220"
sleep 15
cap "curl -s localhost:16686/api/services | jq -r '.data[]' | sort"
cap "curl -s 'localhost:16686/api/traces?service=frontend&limit=1&lookback=1h' | jq -r '.data[0] | \"traceID=\(.traceID)  spans=\(.spans|length)  services=\([.processes[].serviceName]|unique|join(\",\"))\"'"
cap "curl -s 'localhost:16686/api/traces?service=frontend&limit=1&lookback=1h' | jq -r '.data[0] as \$t | \$t.spans | sort_by(.startTime) | .[] | \"\(\$t.processes[.processID].serviceName | .[0:10]) \(.operationName | .[0:40])  \(.duration/1000|floor)ms\"' | head -25"
google-chrome --headless=new --no-sandbox --disable-gpu --hide-scrollbars --window-size=1600,1000 --virtual-time-budget=20000 \
  --screenshot="$OUT/jaeger-trace.png" "http://localhost:16686/trace/$(curl -s 'localhost:16686/api/traces?service=frontend&limit=1&lookback=1h' | jq -r '.data[0].traceID')" >/dev/null 2>&1
echo "screenshot jaeger-trace.png"
} > "$OUT/03-observability.txt" 2>&1

############################################################ 3. GITOPS with Argo CD
{
echo '################ install Argo CD ################'
cap "kubectl create namespace argocd && kubectl apply -n argocd --server-side -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml | tail -3"
cap "kubectl -n argocd rollout status deploy/argocd-server --timeout=300s && kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s && kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s"
cap "kubectl get pods -n argocd"
echo '################ Git is the source of truth: create the Application ################'
cap "cat gitops/argocd-application.yaml"
cap "kubectl apply -f gitops/argocd-application.yaml"
timeout 240 bash -c 'until [ "$(kubectl -n argocd get application session20-app -o jsonpath="{.status.sync.status}/{.status.health.status}")" = "Synced/Healthy" ]; do sleep 5; done'
cap "kubectl -n argocd get application session20-app -o wide"
cap "kubectl -n argocd get application session20-app -o jsonpath='{.status.sync.revision}'; echo"
cap "kubectl get deploy,svc,pods -n session20-gitops"
echo '################ Continuous reconciliation: self-heal (manual drift is reverted) ################'
cap "kubectl -n session20-gitops scale deploy session20-gitops-app --replicas=5"
cap "kubectl -n session20-gitops get deploy session20-gitops-app"
sleep 25
cap "kubectl -n session20-gitops get deploy session20-gitops-app"
cap "kubectl -n session20-gitops delete svc session20-gitops-app"
sleep 25
cap "kubectl -n session20-gitops get svc"
cap "kubectl -n argocd get application session20-app -o jsonpath='{range .status.history[*]}{.id} {.revision} {.deployedAt}{\"\n\"}{end}'"
} > "$OUT/04-gitops.txt" 2>&1
echo "run-demo.sh part 1 finished"
