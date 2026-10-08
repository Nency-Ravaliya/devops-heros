# Session 20, Task 2: Observability

## Monitoring vs observability

- **Monitoring** answers questions you already knew to ask: *Is the service up? Is CPU above 80%? Is the error rate above 5%?* You define the checks, dashboards and alert thresholds in advance.
- **Observability** is how well you can understand *why* a system behaves the way it does from the data it emits, including failures you didn't predict. It needs rich telemetry that can be sliced by any dimension (pod, version, endpoint, user, region…).

Monitoring is something you *do*; observability is a *property* of the system. You need both: monitoring tells you something is wrong, observability lets you find out what and why.

## Why observability is required

Modern systems are distributed: dozens of microservices, Pods that come and go, autoscaling, retries, queues and third-party APIs. One user request can touch ten services, so "the server is up" says very little. Observability is needed to:

- **Detect** problems before users report them (alerts on symptoms such as latency and errors).
- **Debug** unknown failures quickly: go from "checkout is slow" to "the inventory call from pod X on version Y waits 2s on the database". This lowers MTTD (mean time to detect) and MTTR (mean time to resolve).
- **Measure SLOs and error budgets**, e.g. 99.9% of requests under 300ms.
- **Plan capacity** and right-size resources (requests/limits, HPA targets).
- **Verify deployments**: did the new version raise errors or latency?
- **Run post-mortems** with facts instead of guesses.

## The three pillars

| | Metrics | Logs | Traces |
|---|---|---|---|
| **What** | Numeric measurements over time, aggregated | Timestamped, discrete event records | The path of one request across services, as a tree of timed *spans* |
| **Example** | `http_requests_total{status="500"}`, CPU 82% of limit | `{"level":"error","msg":"db timeout","order_id":42}` | `checkout 820ms → payment 30ms → inventory 760ms → db 740ms` |
| **Answers** | *Is something wrong, and how much?* Trends, alerting | *What exactly happened?* Detail and context of an event | *Where in the call chain is the time or error?* |
| **Cost** | Cheap: fixed size per time series | Expensive at volume | Medium; usually sampled |
| **Watch out for** | High-cardinality labels (user IDs) explode storage | Unstructured text is hard to query; use JSON | Needs context propagation (trace ID) through every hop |
| **Typical tools** | Prometheus, Thanos/Mimir, Datadog, CloudWatch Metrics | Loki, Elasticsearch/OpenSearch (ELK/EFK), Fluentd/Fluent Bit, Promtail/Alloy, CloudWatch Logs | Jaeger, Grafana Tempo, Zipkin, AWS X-Ray, Datadog APM |

### Metrics
Four common metric types (Prometheus): **counter** (only goes up: requests, errors), **gauge** (up and down: memory, queue length), **histogram** (buckets: request duration → p95/p99), **summary**. Two well-known ways to choose what to measure:
- **RED** for services: **R**ate, **E**rrors, **D**uration.
- **USE** for resources: **U**tilisation, **S**aturation, **E**rrors.

In my [monitoring demo](../01-monitoring/README.md), podinfo exposes `http_requests_total` and `http_request_duration_seconds_bucket` (RED), and cAdvisor/kube-state-metrics provide CPU and memory against limits (USE).

### Logs
Logs carry the detail that metrics aggregate away. Good practice: write **structured (JSON) logs to stdout**, include a request/trace ID, use levels consistently, never log secrets. In Kubernetes, a node agent (Promtail, Fluent Bit, Alloy) tails `/var/log/pods/*`, adds labels (namespace, pod, container) and ships to a backend. In the demo, Promtail ships every Pod's logs to Loki, where LogQL queries such as `{namespace="shop", container="podinfo"}` or `count_over_time({namespace="shop"} |~ "error" [1m])` turn logs into graphs.

### Traces
A **trace** is one request's journey. Each step is a **span** with a start time, duration, service name and attributes, and spans link parent → child. The trace ID travels between services in HTTP headers (W3C `traceparent`). Traces are the fastest way to find *which* service in a chain causes latency or errors. **OpenTelemetry** (OTel) is the vendor-neutral standard: SDKs instrument the app, and the OTel Collector receives, processes and exports metrics, logs and traces to any backend.

### Connecting the pillars
The real power is in moving between them: an **alert** on a metric (error rate > 5%) → the **dashboard** shows when it started and on which pods → **logs** for those pods in that time window show the exception → the **trace ID** in the log line opens the trace that shows the failing downstream call. Grafana does this by linking Prometheus, Loki and Tempo (*exemplars* and *derived fields*).

## Common tools

| Category | Open source | Managed / commercial |
|---|---|---|
| Metrics | Prometheus, Thanos, Cortex/Mimir, VictoriaMetrics | Amazon Managed Prometheus, CloudWatch, Datadog, New Relic |
| Logs | Loki, ELK/EFK (Elasticsearch/OpenSearch + Logstash/Fluentd + Kibana), Fluent Bit | CloudWatch Logs, Splunk, Datadog Logs |
| Traces | Jaeger, Tempo, Zipkin | AWS X-Ray, Honeycomb, Datadog APM |
| Visualisation | Grafana, Kibana | Grafana Cloud, Datadog |
| Alerting | Alertmanager, Grafana Alerting | PagerDuty, Opsgenie |
| Collection standard | OpenTelemetry (SDKs + Collector) | (supported by all major vendors) |

## Kubernetes observability

What to observe at each layer, and where the data comes from:

| Layer | Signals | Source |
|---|---|---|
| Cluster / nodes | CPU, memory, disk, network, node conditions | **node-exporter**, kubelet |
| Containers | CPU/memory usage vs requests/limits, throttling, OOM kills, restarts | **cAdvisor** (in the kubelet), `kubectl top` via **metrics-server** |
| Kubernetes objects | desired vs available replicas, Pod phase, restarts, HPA state, PVC status | **kube-state-metrics** |
| Control plane | API server latency and errors, etcd, scheduler | component `/metrics` endpoints |
| Applications | RED metrics, business metrics | app `/metrics` + **ServiceMonitor/PodMonitor** |
| Logs | container stdout/stderr | Promtail / Fluent Bit / Alloy → Loki / Elasticsearch |
| Events | scheduling failures, probe failures, pulls, kills | `kubectl get events` (short-lived, ~1h); export with an event exporter |
| Traces | request flow between services | OpenTelemetry SDK + Collector → Tempo/Jaeger; service meshes can also emit spans |
| Health | liveness, readiness and startup probes | kubelet; reflected in Pod status and endpoints |

The standard stack is **kube-prometheus-stack** (Prometheus Operator, Prometheus, Alertmanager, Grafana with ready-made dashboards, node-exporter, kube-state-metrics), plus **Loki** for logs and **Tempo** for traces. This is what I deployed in Task 1.

Things I saw in practice while doing the monitoring demo:
- **Liveness probes and CPU limits interact.** When podinfo burned a full CPU core under a 200m limit, the throttled HTTP server couldn't answer `/healthz` within the probe timeout, so the kubelet killed it (exit 137) and the Pod went into CrashLoopBackOff. The metrics showed restarts, but only the events and probe settings explained why.
- **OOMKilled shows up in kube-state-metrics** (`kube_pod_container_status_last_terminated_reason`) and in `kubectl describe pod` (Last State: OOMKilled, exit 137), not in the app's own logs, because the kernel kills the process.
- Alerts should be based on **symptoms relative to limits** (CPU/memory as % of limit, error *ratio*) rather than absolute numbers, so they keep working when resources change.
