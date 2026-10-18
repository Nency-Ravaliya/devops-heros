# monitoring/

| Folder / file | Purpose |
|---|---|
| [`local/`](local) | Prometheus + Grafana in Docker that scrape the running Compose stack (`backend:8000/metrics`): scrape config, alert rules and a provisioned dashboard. This is what was run and screenshotted for this submission. |
| [`prometheus-values.yaml`](prometheus-values.yaml), [`grafana-values.yaml`](grafana-values.yaml), [`grafana-dashboard.yaml`](grafana-dashboard.yaml) | values for the `kube-prometheus-stack` Helm chart and the dashboard ConfigMap, for a full in-cluster installation (installed by `scripts/install-cluster-addons.sh`, together with the chart's `ServiceMonitor`) |

The backend exposes Prometheus metrics at `/metrics` through `prometheus-fastapi-instrumentator`: request counts per endpoint and status class, latency histograms, and process CPU and memory. Health is exposed at `/health` (liveness) and `/ready` (readiness, checks the database).

Start the local stack:

```bash
cd ../docker && docker compose -p stockpilot-final up -d --build     # the application
cd ../monitoring/local && docker compose -p stockpilot-mon up -d     # Prometheus :9091, Grafana :3001
```
