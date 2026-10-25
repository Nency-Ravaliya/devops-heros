# Observability – the three pillars, in my own words

**Name:** Kushal Talati  
**Enrollment No:** 24BCS10123

Everything below is backed by the demo in [`../README.md`](../README.md): the metrics come from my `s20-metrics-app` scraped by Prometheus, the logs from `kubectl logs` on the same pods, and the alerts from a `PrometheusRule`.

## Monitoring vs observability

*Monitoring* is asking questions I already know to ask: "is the pod up?", "is CPU above 80 %?". I pick the metric, I pick the threshold, I get a page when it is crossed. That is what the `S20AppDown` and `S20HighCPU` alerts in this homework are.

*Observability* is the property of a system that lets me answer questions I did **not** plan for, from the data it already emits. When a user says "the app was slow at 14:03", I should be able to go from a graph (metrics) to the exact requests (logs) to the exact slow step inside one request (traces) without deploying new code. Monitoring is a subset of observability: good observability makes it possible to write good monitors after the fact.

## The three pillars

| Pillar | What it is | Shape of the data | In this homework |
|---|---|---|---|
| **Metrics** | Numbers sampled over time | time series: name + labels + (timestamp, value) | `http_requests_total{path="/"} 312`, `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes` in Prometheus |
| **Logs** | Discrete events, one line each | text or JSON lines with a timestamp | `kubectl logs deployment/s20-metrics-app` prints one JSON line per request; the course's busybox demo prints `Request received` every 10 s |
| **Traces** | The journey of one request across services | a tree of spans (service, operation, start, duration, parent) | not demoed – my app is a single process, so a trace would have exactly one span. Jaeger/Tempo + OpenTelemetry would be the tools |

**Metrics** are cheap and aggregatable – one counter can describe millions of requests – which is why alerting and dashboards are built on them. Their weakness is cardinality: a label like `user_id` would create a series per user and kill Prometheus. I only used `path` as a label for that reason.

**Logs** carry the detail metrics drop (which request, which client, what error message). They are expensive to store at scale and hard to aggregate, so the usual pattern is: metric tells me *that* something is wrong, log tells me *what*. Writing them as JSON (as my app does) makes them filterable in Loki / Elasticsearch instead of grep.

**Traces** answer "where did the time go" when a request crosses several services. Each hop records a span with the same trace id; a tool like Jaeger draws the waterfall. They need instrumentation in every service, so they are the pillar most teams add last.

## Why observability is required

* Kubernetes moves things. Pods get rescheduled, IPs change, replicas come and go. `ssh` into "the server" is not an option, so the system has to export its state.
* Microservices make failures distributed. One slow database call shows up as five services "being slow"; without traces that is a guessing game.
* Alerts need data to exist *before* the incident. Prometheus had 15 minutes of CPU history when `S20HighCPU` fired, so I could see the exact minute the load started.
* Capacity and cost: `kubectl top`, `container_memory_working_set_bytes` and `kube_pod_container_resource_limits` together tell me whether my requests/limits are right. Mine were 100m / 500m CPU and the burn test hit the 500m ceiling – visible in the graph as a flat line.

## Common tools

| Need | Tools | Note |
|---|---|---|
| Metrics store + query | **Prometheus**, Thanos / Mimir / VictoriaMetrics (long-term, HA) | pull model: Prometheus scrapes `/metrics` |
| Dashboards | **Grafana** | reads Prometheus (and Loki, Tempo, …) |
| Alert routing | **Alertmanager** | dedup, group, silence, send to Slack / PagerDuty |
| Logs | **Loki** (+ Promtail / Alloy), ELK / EFK (Elasticsearch + Logstash or Fluentd + Kibana), Fluent Bit | Loki indexes only labels, cheaper than Elasticsearch |
| Traces | **Jaeger**, **Tempo**, Zipkin | all accept OpenTelemetry data |
| Instrumentation standard | **OpenTelemetry** (OTel) | one SDK / one collector for metrics, logs and traces |
| Pod-level quick view | **metrics-server** → `kubectl top` | short-lived, no history – not a replacement for Prometheus |

## Kubernetes observability – how the pieces fit on this cluster

```text
             kube-prometheus-stack (helm, namespace monitoring)
             ┌────────────────────────────────────────────────────────────┐
 kubelet ──► │ node-exporter      (node CPU / mem / disk)                 │
 (cAdvisor)─►│ kube-state-metrics (desired vs actual: replicas, phases)   │
             │ Prometheus Operator ──reads──► ServiceMonitor / PrometheusRule (CRDs, any namespace)
 my app ────►│ Prometheus  ◄── scrapes /metrics every 15 s                │──► Alertmanager ──► (Slack/mail)
 /metrics    │ Grafana     ◄── PromQL                                     │
             └────────────────────────────────────────────────────────────┘
 my app stdout ──► kubelet writes /var/log/pods/… ──► kubectl logs   (a log agent such as Promtail would ship this to Loki)
```

* **cAdvisor** inside the kubelet gives container CPU and memory for every pod with zero app changes – `container_cpu_usage_seconds_total`, `container_memory_working_set_bytes`.
* **kube-state-metrics** turns Kubernetes objects into metrics – `kube_pod_container_status_ready`, `kube_deployment_status_replicas`. That is how a "deployment has fewer ready replicas than desired" alert is written.
* **Probes are health, not metrics**: `readinessProbe` decides if the pod receives traffic, `livenessProbe` restarts it. Prometheus still sees the result through `kube_pod_container_status_ready` and through `up` (a pod that is not ready is removed from the Service's endpoints, so the scrape target disappears – exactly what made `S20AppDown` fire when I scaled to zero).
* **The Operator pattern** means I never edit `prometheus.yml`. I create a `ServiceMonitor` next to my app and the operator rewrites the config and reloads Prometheus. Same for alert rules via `PrometheusRule`.

## What I would add next

1. Ship the JSON logs to Loki so a Grafana panel can show CPU (Prometheus) and the matching request lines (Loki) side by side for the same minute.
2. Add OpenTelemetry to the app and send spans to Tempo – only worth it once there is a second service to call.
3. Route Alertmanager to a real receiver (Slack webhook) instead of only reading `/api/v2/alerts`.
