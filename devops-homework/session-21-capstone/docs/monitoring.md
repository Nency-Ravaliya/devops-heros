# Monitoring and autoscaling

Install the monitoring stack **before** enabling `monitoring.enabled` in the application chart; otherwise the ServiceMonitor custom resource does not exist. Follow section 3 of [the deployment guide](deployment.md) to install the stack and dashboard.

The backend exports `queuedesk_http_requests_total{method,route,status}` and `queuedesk_http_request_duration_seconds_bucket`. Route labels use templates, such as `/api/tickets/{ticket_id}`, to avoid creating a time series for every ticket. Health/readiness and metrics requests are excluded from application request metrics.

## Verify scraping

```bash
kubectl get servicemonitor -n queuedesk
kubectl port-forward -n queuedesk svc/queuedesk-backend 8000:8000
curl http://localhost:8000/api/tickets
curl http://localhost:8000/metrics
```

In another terminal:

```bash
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
```

Open http://localhost:9090/targets and find `queuedesk/queuedesk`; both backend targets should be **UP**. The ServiceMonitor selects backend **Service labels**, and its endpoint references the named Service port `http`. Its `release: monitoring` label matches the Prometheus selector; the configured namespace selector permits discovery across namespaces.

Useful queries:

```promql
sum by (route) (rate(queuedesk_http_requests_total[2m]))
histogram_quantile(0.95, sum by (le) (rate(queuedesk_http_request_duration_seconds_bucket[5m])))
up{namespace="queuedesk",service="queuedesk-backend"}
```

## Grafana

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3001:80
kubectl get secret monitoring-grafana -n monitoring -o jsonpath='{.data.admin-password}' | base64 --decode
```

Open http://localhost:3001, sign in as `admin` using the generated Secret password, and open **QueueDesk · Application overview**. Do not include the password in evidence. The ConfigMap has `grafana_dashboard: "1"`, so the Grafana dashboard sidecar provisions it. The dashboard uses the stack's default Prometheus datasource UID `prometheus`.

Panels show request rate, p95 latency, server error rate, backend CPU, HPA desired replicas, and scrape availability. The dashboard is provisioned from `monitoring/dashboard-configmap.yaml`. After the first traffic, allow at least two scrapes before expecting rate panels to populate.

```bash
kubectl run queuedesk-load -n queuedesk --restart=Never --image=busybox:1.37 -- \
  sh -c 'i=0; while [ "$i" -lt 600 ]; do wget -q -O /dev/null http://queuedesk-backend:8000/api/tickets; i=$((i+1)); done'
```

This temporary Pod sends 600 read-only requests. Once it finishes, remove it with `kubectl delete pod queuedesk-load -n queuedesk`. The error-rate panel can legitimately be zero.

## HPA

```bash
kubectl top pods -n queuedesk
kubectl get hpa -n queuedesk --watch
```

HPA reads CPU through Metrics Server (an EKS add-on), independently of Prometheus. The backend requests 100m CPU per Pod; the target is 65% of that request and the replica range is 2–6. `unknown` utilization usually indicates a missing/unready Metrics Server or unavailable kubelet metrics. Prometheus being healthy does not fix HPA metrics.

A lightweight CRUD workload might not saturate CPU. Generate bounded traffic and inspect measured utilization; do not claim a scale-up unless the replica count actually changes. HPA does not add worker nodes; sufficient node capacity must exist. Scaling down waits for the configured stabilization window.
