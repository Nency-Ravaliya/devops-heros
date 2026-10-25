#!/usr/bin/env bash
# 02-metrics-servicemonitor: the METRICS pillar. My own app exposing /metrics, scraped by the in-cluster Prometheus
# through a ServiceMonitor; CPU / memory / request-rate PromQL; readiness+liveness as "application health".
. "$(dirname "$0")/lib.sh"
kubectl create namespace "$NS" --dry-run=client -o yaml | kubectl apply -f - >/dev/null
M="$ME/01-monitoring"
x "helm -n $MON list"
x "kubectl -n $MON get prometheus,alertmanager,servicemonitor | head -20"
hr "Deploy the app (Deployment + Service + probes)"
x "sed -n '1,45p' $M/metrics-app.yaml"
x "kubectl apply -f $M/metrics-app.yaml"
x "kubectl -n $NS rollout status deployment/s20-metrics-app --timeout=180s"
x "kubectl -n $NS get pods,svc,endpointslices -l app=s20-metrics-app"
pf "$NS" s20-metrics-app 19080:8000
x "for i in 1 2 3; do curl -s http://localhost:19080/; done; curl -s http://localhost:19080/health; curl -s http://localhost:19080/doesnotexist"
x "curl -s http://localhost:19080/metrics"
x "kubectl -n $NS logs deployment/s20-metrics-app --tail=4        # structured JSON access logs = the logs pillar from the same app"
pf_stop
hr "Application health: readiness and liveness probes"
x "kubectl -n $NS get deploy s20-metrics-app -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}{\"\\n\"}{.spec.template.spec.containers[0].livenessProbe}{\"\\n\"}'"
x "kubectl -n $NS get pod -l app=s20-metrics-app -o jsonpath='{range .items[*]}{.metadata.name}  ready={.status.containerStatuses[0].ready}  restarts={.status.containerStatuses[0].restartCount}{\"\\n\"}{end}'"
hr "Tell Prometheus to scrape it: ServiceMonitor"
x "cat $M/servicemonitor.yaml"
x "kubectl apply -f $M/servicemonitor.yaml"
pf "$MON" kube-prometheus-stack-prometheus 19090:9090
echo "  waiting for the operator to reload Prometheus and for the first scrapes..."
for _ in $(seq 1 40); do curl -s http://localhost:19090/api/v1/targets | grep -q 's20-metrics-app' && break; sleep 5; done
x "curl -s http://localhost:19090/api/v1/targets | python3 -c 'import sys,json; [print(t[\"labels\"][\"job\"], t[\"scrapeUrl\"], t[\"health\"]) for t in json.load(sys.stdin)[\"data\"][\"activeTargets\"] if \"s20\" in t[\"labels\"][\"job\"]]'"
x "curl -s 'http://localhost:19090/api/v1/status/config' | grep -o 'job_name: serviceMonitor/s20-monitoring/s20-metrics-app/0'"
# generate some traffic so the counters move
pf2() { kubectl -n "$NS" port-forward svc/s20-metrics-app 19080:8000 >/dev/null 2>&1 & PF2=$!; sleep 2; }
pf2; for _ in $(seq 1 120); do curl -s -o /dev/null http://localhost:19080/; done; for _ in $(seq 1 10); do curl -s -o /dev/null http://localhost:19080/health; done; sleep 35
hr "PromQL: metrics from the app"
x "echo 'up{job=\"s20-metrics-app\"}'; promql 'up{job=\"s20-metrics-app\"}'"
x "echo 'http_requests_total{job=\"s20-metrics-app\"}'; promql 'http_requests_total{job=\"s20-metrics-app\"}'"
x "echo 'sum by (path)(rate(http_requests_total{job=\"s20-metrics-app\"}[1m]))'; promql 'sum by (path)(rate(http_requests_total{job=\"s20-metrics-app\"}[1m]))'"
x "echo 'app_uptime_seconds'; promql 'app_uptime_seconds'"
hr "PromQL: CPU and memory utilization (from cAdvisor via the kubelet, no app code needed)"
x "echo 'sum by (pod)(rate(container_cpu_usage_seconds_total{namespace=\"$NS\",container=\"app\"}[2m]))'; promql 'sum by (pod)(rate(container_cpu_usage_seconds_total{namespace=\"$NS\",container=\"app\"}[2m]))'"
x "echo 'container_memory_working_set_bytes{namespace=\"$NS\",container=\"app\"}'; promql 'container_memory_working_set_bytes{namespace=\"$NS\",container=\"app\"}'"
x "echo 'kube_pod_container_resource_limits{namespace=\"$NS\",resource=\"cpu\"}'; promql 'kube_pod_container_resource_limits{namespace=\"$NS\",resource=\"cpu\"}'"
x "echo 'kube_pod_container_status_ready{namespace=\"$NS\"}'; promql 'kube_pod_container_status_ready{namespace=\"$NS\"}'"
x "kubectl top pods -n $NS --containers"
node "$ME/scripts/shot.mjs" "http://localhost:19090/graph?g0.expr=sum%20by%20(path)%20(rate(http_requests_total%7Bjob%3D%22s20-metrics-app%22%7D%5B1m%5D))&g0.tab=0&g0.range_input=15m" "$ME/screenshots/02-prometheus-requests-rate.png" '' 5000
node "$ME/scripts/shot.mjs" "http://localhost:19090/targets?search=s20" "$ME/screenshots/02-prometheus-targets.png" '' 5000
kill $PF2 2>/dev/null; pf_stop
