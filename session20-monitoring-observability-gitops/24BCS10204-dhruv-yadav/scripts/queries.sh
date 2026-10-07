#!/bin/bash
Q="$(dirname "$0")/q.sh"
echo "# Captured $(date -u '+%Y-%m-%dT%H:%M:%SZ') against kube-prometheus-stack"
echo "# (kubectl -n monitoring port-forward svc/kps-kube-prometheus-stack-prometheus 19090:9090)"
echo
echo '$ curl -s "http://localhost:19090/api/v1/targets?state=active" | jq -r <s20 targets: job pod scrapeUrl health>'
curl -s 'localhost:19090/api/v1/targets?state=active' | jq -r '.data.activeTargets[] | select(.labels.namespace=="s20") | [.labels.job, .labels.pod, .scrapeUrl, .health] | @tsv'
echo
bash "$Q" 'up{namespace="s20"}'
bash "$Q" 'rate(container_cpu_usage_seconds_total{namespace="s20"}[5m])'
bash "$Q" 'sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="s20", container="podinfo"}[5m]))'
bash "$Q" 'container_memory_working_set_bytes{namespace="s20", container="podinfo"}'
bash "$Q" 'http_requests_total{namespace="s20"}'
bash "$Q" 'sum by (status) (rate(http_request_duration_seconds_count{namespace="s20"}[5m]))'
bash "$Q" 'histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{namespace="s20"}[5m])))'
bash "$Q" 'kube_pod_status_ready{namespace="s20", condition="true"}'
bash "$Q" 'kube_deployment_status_replicas_available{namespace="s20"}'
