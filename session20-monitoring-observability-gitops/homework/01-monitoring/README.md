# Session 20, Task 1: Monitoring Demo

A complete monitoring stack on minikube that watches a real application, **podinfo** (a small Go web app that exposes Prometheus metrics, health endpoints and JSON logs). It covers metrics, logs, alerts, CPU utilisation, memory utilisation and application health. The alerts were triggered with real incidents.

All screenshots in [`screenshots/`](screenshots/) are real captures (Chrome for the UIs, a terminal window for CLI output).

## Architecture

```text
                       ┌──────────────── namespace: monitoring ────────────────┐
 podinfo pods ──/metrics──▶ Prometheus ──rules──▶ Alertmanager                   │
 (namespace shop)  ▲        ▲   ▲                                                 │
   │               │        │   └── kube-state-metrics (replicas, restarts, limits)│
   │   ServiceMonitor       └────── kubelet/cAdvisor (container CPU & memory)      │
   │                        └────── node-exporter (node CPU, memory, disk)          │
   └──stdout logs──▶ Promtail (DaemonSet) ──▶ Loki                                │
                                     Grafana ◀── Prometheus + Loki + Alertmanager │
                       └───────────────────────────────────────────────────────┘
```

| Component | How it's installed | Config |
|---|---|---|
| Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics, Prometheus Operator | Helm `prometheus-community/kube-prometheus-stack` 92.0.0 | [kube-prometheus-stack-values.yaml](kube-prometheus-stack-values.yaml) |
| Loki (single binary) | Helm `grafana/loki` | [loki-values.yaml](loki-values.yaml) |
| Promtail | Helm `grafana/promtail` | [promtail-values.yaml](promtail-values.yaml) |
| podinfo app + Service + **ServiceMonitor** | `kubectl apply` | [app/podinfo.yaml](app/podinfo.yaml) |
| Alert rules (**PrometheusRule**) | `kubectl apply` | [app/alert-rules.yaml](app/alert-rules.yaml) |
| Custom Grafana dashboard (ConfigMap picked up by the Grafana sidecar) | `kubectl apply` | [app/grafana-dashboard.yaml](app/grafana-dashboard.yaml) |
| Background traffic | `kubectl apply` | [app/traffic.yaml](app/traffic.yaml) |

```bash
helm upgrade --install monitoring prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f kube-prometheus-stack-values.yaml
helm upgrade --install loki grafana/loki -n monitoring -f loki-values.yaml
helm upgrade --install promtail grafana/promtail -n monitoring -f promtail-values.yaml
kubectl apply -f app/podinfo.yaml -f app/alert-rules.yaml -f app/traffic.yaml -f app/grafana-dashboard.yaml
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-alertmanager 9093:9093
```

---

## 1. Metrics

The ServiceMonitor makes the Prometheus Operator add podinfo's `/metrics` to the scrape config. Both replicas are **UP**:

![targets](screenshots/01-prometheus-targets.png)

Request rate by HTTP status, from podinfo's own `http_requests_total` counter:

![request rate](screenshots/04-prometheus-request-rate.png)

podinfo's raw `/metrics` and the health endpoints, from inside the cluster:

![health and metrics](screenshots/12-app-health-and-metrics.png)

## 2. CPU utilisation

`rate(container_cpu_usage_seconds_total[1m])` per Pod, from cAdvisor:

![cpu](screenshots/02-prometheus-cpu-query.png)

## 3. Memory utilisation

`container_memory_working_set_bytes` per Pod (this is what the OOM killer compares against the limit):

![memory](screenshots/03-prometheus-memory-query.png)

Node level, from node-exporter:

![node exporter](screenshots/08-grafana-node-exporter.png)

Namespace view from the built-in *Kubernetes / Compute Resources / Namespace (Pods)* dashboard, showing usage against requests and limits:

![namespace](screenshots/07-grafana-namespace-cpu-memory.png)

`kubectl top` (metrics-server) and logs from the CLI:

![kubectl top and logs](screenshots/11-kubectl-top-and-logs.png)

## 4. Application health

Health is measured in three independent ways:
- **Kubernetes probes:** `livenessProbe` on `/healthz` (restart if failing) and `readinessProbe` on `/readyz` (removed from the Service if failing).
- **Scrape health:** `up{job="podinfo"}`, so Prometheus can tell whether it reaches each instance.
- **Workload state:** `kube_deployment_status_replicas_available` from kube-state-metrics.

These make up the top row of the custom **podinfo – Application Overview** dashboard, together with RED metrics (rate, 5xx ratio, p95 latency), CPU and memory as a percentage of the limit, and logs:

![dashboard](screenshots/06-grafana-podinfo-dashboard.png)

## 5. Logs

Promtail tails every container's stdout and ships it to Loki with namespace/pod/container labels. podinfo's JSON logs in the dashboard's Loki panel:

![logs panel](screenshots/09-grafana-loki-logs-panel.png)

LogQL turns logs into metrics. Here, lines containing "error" per minute by container across the `shop` and `monitoring` namespaces:

![logql](screenshots/10-grafana-loki-logql-errors.png)

## 6. Alerts

[app/alert-rules.yaml](app/alert-rules.yaml) defines four alerts:

| Alert | Expression (simplified) | For | Severity |
|---|---|---|---|
| `PodinfoDown` | `sum(up{job="podinfo"}) == 0 or absent(...)` | 30s | critical |
| `PodinfoHighCPU` | CPU usage / CPU limit > 80% (per Pod) | 1m | warning |
| `PodinfoHighMemory` | memory working set / memory limit > 80% (per Pod) | 1m | warning |
| `PodinfoHighErrorRate` | 5xx requests / all requests > 5% | 1m | warning |

At rest, all four are **inactive**:

![rules ok](screenshots/05-prometheus-alert-rules-ok.png)

I then triggered each one with a real incident (manifests in [`app/`](app/)):

### Incident 1: error spike → `PodinfoHighErrorRate`

[app/incident-errors.yaml](app/incident-errors.yaml) runs a client that keeps calling `/status/500`. The alert went *pending* and then *firing* after 1 minute. Prometheus sends it to Alertmanager, which groups it and would route it to a receiver (Slack, e-mail, PagerDuty…):

![error firing](screenshots/13-alert-error-rate-firing.png)

![alertmanager errors](screenshots/14-alertmanager-error-rate.png)

![grafana errors](screenshots/15-grafana-during-errors.png)

### Incident 2: traffic spike → `PodinfoHighCPU`

[app/incident-spike.yaml](app/incident-spike.yaml) scaled to 20 clients calling `POST /token` (JWT signing is CPU-heavy). Both Pods reached ~165m of their 200m limit (≈83%):

![cpu firing](screenshots/16-alert-cpu-firing.png)

![grafana cpu](screenshots/17-grafana-during-cpu-spike.png)

### Incident 3: memory pressure → `PodinfoHighMemory` (and OOMKilled)

[app/incident-stress.yaml](app/incident-stress.yaml) starts podinfo with `--stress-memory=100`. The working set reached ~113Mi of 128Mi (≈88%). While ramping up, the containers briefly crossed the limit and were **OOMKilled** (exit code 137) and restarted. That is visible in `kubectl describe` (Last State) but not in the app's logs, because the kernel kills the process:

![memory firing](screenshots/18-alert-memory-firing.png)

![memory terminal](screenshots/19-memory-incident-terminal.png)

### Incident 4: application down → `PodinfoDown`

`kubectl scale deploy podinfo -n shop --replicas=0`. There are no targets left, `absent(up{job="podinfo"})` becomes true, and the **critical** alert fires after 30 seconds:

![down firing](screenshots/20-alert-down-firing.png)

![alertmanager down](screenshots/21-alertmanager-down.png)

![grafana down](screenshots/22-grafana-app-down.png)

### Recovery

`kubectl apply -f app/podinfo.yaml` restores the normal Deployment, and the alerts resolve:

![recovered](screenshots/23-recovered.png)

![resolved](screenshots/24-alerts-resolved.png)

---

## What I learned (including what went wrong)

- **My first CPU stress test broke the app instead of alerting.** Running podinfo with `--stress-cpu=1` (a full core) under a 200m CPU limit throttled the process so hard that `/healthz` couldn't answer within the probe timeout. The kubelet killed it (exit 137) and it went into CrashLoopBackOff, even after I raised the probe timeout to 5s. Lesson: CPU limits that are too tight plus strict liveness probes turn a slow app into a crashing app. Generating CPU load through real traffic worked better, and is also more realistic.
- **Memory limits are hard limits.** CPU over the limit gets *throttled*; memory over the limit gets *killed*. 95–100 MB of stress plus the app's own allocations under load went past 128Mi and caused OOMKills.
- **The monitoring stack has a cost too.** With Prometheus, Grafana, Loki, Argo CD and the stress test together, the minikube node (capped at 4.5 GB by its container) ran out of memory and the API server stopped responding. I raised the minikube container to ~6.6 GB and 6 CPUs (`docker update`), and everything recovered.
- Alert on **ratios against limits** and on **symptoms** (errors, availability), use `for:` to avoid flapping, and add `absent()` so "no data" also counts as down.
- Grafana and Argo CD anonymous access, and plain-text passwords in values files, are for this local lab only.
