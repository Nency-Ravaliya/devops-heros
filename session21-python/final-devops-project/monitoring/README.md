# monitoring/ - Prometheus, Grafana, alerts, logs

```
monitoring/
├── prometheus-values.yaml            prometheus-community/prometheus: server only, 6h retention, scrape jobs + alert rules
├── grafana-values.yaml               grafana/grafana: Prometheus datasource, dashboard sidecar, anonymous Viewer (local only)
├── dashboards/taskboard-dashboard.json   "TaskBoard - Service Overview" (10 panels)
├── kustomization.yaml                configMapGenerator -> ConfigMap taskboard-grafana-dashboard (label grafana_dashboard=1)
├── traffic-generator.yaml            busybox pod: ~6 req/s incl. deliberate 404s
└── promql.sh                         tiny CLI: instant PromQL query -> one line per series
```

## Why not kube-prometheus-stack?

kube-prometheus-stack was tried first, with Alertmanager, the default rules and the default dashboards turned off. On the 2-vCPU, 2.9 GB node it still ran the operator, an admission-webhook job, node-exporter, kube-state-metrics, Prometheus and Grafana with three sidecars. Together those saturated the CPU: the API server returned `TLS handshake timeout` and kube-state-metrics was stuck in `ImagePullBackOff`. It was uninstalled and replaced with:

* **`prometheus-community/prometheus`:** a single pod (prometheus-server plus the config reloader) with Alertmanager, kube-state-metrics, node-exporter and Pushgateway all disabled.
* **`grafana/grafana`:** a single pod plus the dashboard sidecar.

The Helm chart still ships an optional **ServiceMonitor** and **PrometheusRule** (`serviceMonitor.enabled` and `prometheusRule.enabled`) for clusters that run the Prometheus Operator.

## How scraping works (annotations)

The backend pod template carries `prometheus.io/scrape: "true"`, `prometheus.io/port: "8000"` and `prometheus.io/path: /metrics`. The chart's default `kubernetes-pods` job finds the pod through Kubernetes service discovery and copies the pod labels onto the series, for example `app_kubernetes_io_component="backend"`.

A trimmed `cadvisor` job scrapes the kubelet's `/metrics/cadvisor` and keeps only these series, which feed the pod CPU and memory panels:

* `container_cpu_usage_seconds_total`
* `container_memory_working_set_bytes`
* `container_spec_memory_limit_bytes`

The backend metrics come from `prometheus-fastapi-instrumentator`:

* `http_requests_total{handler,method,status="2xx|4xx|5xx"}`
* `http_request_duration_seconds_bucket{handler,method,le}`

## Install

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm upgrade --install prometheus prometheus-community/prometheus -n monitoring --create-namespace -f monitoring/prometheus-values.yaml
helm upgrade --install grafana grafana/grafana -n monitoring -f monitoring/grafana-values.yaml
kubectl apply -k monitoring/                       # dashboard ConfigMap -> loaded by the sidecar
kubectl apply -f monitoring/traffic-generator.yaml # optional traffic
```

Access:

```bash
kubectl -n monitoring port-forward svc/prometheus-server 9090:80 &
kubectl -n monitoring port-forward svc/grafana 3000:80 &   # admin / taskboard-admin, or anonymous viewer
open http://localhost:3000/d/taskboard/taskboard-service-overview
```

## PromQL used (dashboard and screenshots 61-62)

| Panel | Query |
|-------|-------|
| Request rate | `sum by (method, handler) (rate(http_requests_total{namespace="taskboard", handler!="/metrics"}[1m]))` |
| Status classes | `sum by (status) (rate(http_requests_total{namespace="taskboard", handler!="/metrics"}[1m]))` |
| Error rate | `(sum(rate(http_requests_total{namespace="taskboard",status="5xx"}[5m])) or vector(0)) / clamp_min(sum(rate(http_requests_total{namespace="taskboard"}[5m])), 1e-9)` |
| Latency p50/p95/p99 | `histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket{namespace="taskboard"}[5m])))` |
| Pod CPU | `sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="taskboard", container!=""}[2m]))` |
| Pod memory | `sum by (pod) (container_memory_working_set_bytes{namespace="taskboard", container!=""})` |
| Backend pods up | `sum(up{job="kubernetes-pods", namespace="taskboard", app_kubernetes_io_component="backend"})` |

The `or vector(0)` matters. Without it, the error-rate query returns *no data* when there have been no 5xx responses yet, rather than `0`.

## Alerts (`serverFiles.alerting_rules.yml`)

| Alert | Fires when | Demo |
|-------|-----------|------|
| `TaskBoardBackendDown` (critical) | No backend pod has been scraped successfully for 1 minute | Backend scaled to 0: the alert went from inactive to **firing**, then cleared after scaling back (screenshot 63) |
| `TaskBoardHighErrorRate` (warning) | 5xx ratio above 5% for 1 minute | Postgres scaled to 0 while a client called the backend pod directly: the ratio reached **0.90** and the alert fired, then cleared once the DB was back (65, 66) |
| `TaskBoardHighLatencyP95` (warning) | p95 above 500 ms for 5 minutes | Not triggered |

Alertmanager is off to save memory. Firing alerts can be seen at `/api/v1/alerts` (Prometheus) and in Grafana.

## Logs

```bash
kubectl -n taskboard logs deploy/taskboard-backend --tail=20          # uvicorn access log (200/404/500)
kubectl -n taskboard logs deploy/taskboard-backend -c wait-for-db     # init container
kubectl -n taskboard logs deploy/taskboard-backend --previous         # after a restart
kubectl -n taskboard events --for pod/<pod>                           # probe failures, OOMKilled, ...
```

Loki was **not** installed because there was no memory left on the node. `kubectl logs` covers the demo.

## Screenshots

| File | Shows |
|------|-------|
| `60` | Releases, pods, and the dashboard ConfigMap picked up by the sidecar |
| `61` | Targets, request rate, latency and error ratio |
| `62` | Pod CPU and memory, loaded rules, logs |
| `63` | `TaskBoardBackendDown` firing and resolving |
| `64` | Grafana API: health, datasource, dashboard and its panels, a query through the datasource proxy |
| `65` | `TaskBoardHighErrorRate` firing during the DB outage |
| `66` | Grafana dashboard, rendered headless with Chrome during the 5xx incident |
