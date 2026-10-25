#!/usr/bin/env bash
# Run the PromQL queries behind the Grafana panels against Prometheus (port-forwarded) and print the results.
# usage: kubectl -n monitoring port-forward svc/kube-prometheus-stack-prometheus 21090:9090 &  then  scripts/prom-queries.sh
set -uo pipefail
PROM="${PROM:-http://localhost:21090}"
q() {
  printf '\n# %s\n$ %s\n' "$1" "$2"
  curl -s --get "$PROM/api/v1/query" --data-urlencode "query=$2" | python3 -c '
import json, sys
hide = ("__name__", "instance", "endpoint", "service", "container", "namespace", "job")
d = json.load(sys.stdin)
for r in d["data"]["result"]:
    m = r["metric"]
    lbl = ",".join("%s=%s" % (k, v) for k, v in sorted(m.items()) if k not in hide)
    print("  %s => %s" % (lbl or m.get("__name__", ""), r["value"][1]))
if not d["data"]["result"]:
    print("  (no data)")
'
}
q "scrape target health"            'up{job="studytrack-backend"}'
q "requests per second by handler"  'sum by (handler) (rate(http_requests_total{job="studytrack-backend"}[1m]))'
q "requests per second by status"   'sum by (status) (rate(http_requests_total{job="studytrack-backend"}[1m]))'
q "p95 latency (s)"                 'histogram_quantile(0.95, sum(rate(http_request_duration_seconds_bucket{job="studytrack-backend"}[5m])) by (le))'
q "entries created, by subject"     'sum by (subject) (studytrack_entries_created_total)'
q "minutes logged"                  'sum(studytrack_minutes_logged_total)'
q "backend cpu (cores) per pod"     'sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="studytrack",container="backend"}[2m]))'
q "backend memory per pod (bytes)"  'sum by (pod) (container_memory_working_set_bytes{namespace="studytrack",container="backend"})'
q "hpa current replicas"            'kube_horizontalpodautoscaler_status_current_replicas{namespace="studytrack"}'
