# Observability

Prepared by: Yash Gaikwad (Roll no. 24BCS10100)
Session: 20 - Monitoring, Observability and GitOps

These are my theory notes on observability. The hands-on demos (installing the monitoring stack and building dashboards) are done separately; here I keep the concepts, the Kubernetes-specific pieces, and reusable commands and snippets.

---

## What is observability

Observability is the ability to understand what is happening **inside** a system by looking at the data it emits from the **outside**. If a service misbehaves, I should be able to ask new questions of the data and find the cause without shipping new code first.

It is built from three kinds of telemetry, usually called the three pillars.

### Pillar 1: Metrics

- Numeric measurements sampled over time (a time series): CPU %, requests per second, queue length, error count.
- Cheap to store and fast to query, so they are the best fit for **dashboards and alerting**.
- Answer: "Is something wrong, and how bad is it?"
- Example: `http_requests_total{service="orders", status="500"}`.

### Pillar 2: Logs

- Timestamped records of discrete events, either free text or (better) structured JSON.
- Rich in detail (stack traces, user ids, request ids), but high volume and more expensive to store and search.
- Answer: "What exactly happened in this event?"
- Example: `{"level":"error","msg":"db timeout","order_id":"A-1042","trace_id":"4bf9..."}`.

### Pillar 3: Traces

- A trace follows **one request** as it travels through many services. It is made of **spans** (one per operation, with start time, duration and parent), tied together by a **trace id**.
- Answer: "Where in the call chain did the time go, or which service failed?"
- Very useful in microservices, where one user click can touch ten services.

How they work together: an alert fires from a **metric** (error rate up), I jump to a **trace** to find the slow/failing service, then read that service's **logs** for the root cause. Putting a shared `trace_id` into logs and linking dashboards to traces is what makes this smooth.

---

## Monitoring vs observability

| | Monitoring | Observability |
|---|---|---|
| Question | "Is it working?" | "Why is it not working?" |
| Approach | watch predefined metrics and thresholds | explore telemetry with arbitrary questions |
| Handles | known failure modes (**known-unknowns**) | new, unexpected failures (**unknown-unknowns**) |
| Output | dashboards, alerts | context to debug: correlated metrics, logs, traces |
| Relationship | a **part of** observability | the broader property of the system |

Monitoring tells me something is broken; observability helps me find out why.

---

## Why observability is required

- **Unknown-unknowns**: in distributed systems, many failures cannot be predicted, so pre-written checks are not enough.
- **Microservices and Kubernetes**: pods are short-lived, requests cross many services, and logs disappear with the pod unless they are shipped out. Without traces and central logs, debugging is guesswork.
- **Faster recovery**: it reduces **MTTD** (mean time to detect) and **MTTR** (mean time to recover/resolve).
- **Reliability targets** (SRE view):
  - **SLI** (service level indicator): a measurement, for example the percentage of requests that succeed under 300 ms.
  - **SLO** (service level objective): the target for an SLI, for example 99.9% over 30 days.
  - **Error budget**: `1 - SLO`. For 99.9% over 30 days that is 0.1% of 43,200 minutes, about 43 minutes of allowed failure. If the budget is spent, releases slow down and reliability work takes priority.
  - **SLA**: the contractual promise to customers, usually looser than the internal SLO.
- Capacity planning, cost control, security/audit trails and release confidence (compare before and after a deploy) also depend on it.

---

## Common tools per pillar

| Area | Tools | Notes |
|---|---|---|
| Metrics | **Prometheus**, VictoriaMetrics, Thanos / Mimir (long-term storage) | Prometheus is pull-based: it scrapes `/metrics` endpoints |
| Dashboards | **Grafana** | queries many data sources in one UI |
| Alerting | **Alertmanager**, Grafana Alerting | groups, deduplicates, routes to Slack, email, PagerDuty |
| Logs | **Loki**, **ELK** (Elasticsearch, Logstash, Kibana), **EFK** (Fluentd instead of Logstash), OpenSearch | Loki indexes only labels, so it is cheaper than full-text indexing |
| Log shippers | **Fluent Bit**, Fluentd, Grafana Alloy, Filebeat | run as a DaemonSet on every node; Promtail is deprecated in favour of Alloy |
| Traces | **Jaeger**, **Tempo**, Zipkin | store and visualise spans |
| Instrumentation | **OpenTelemetry** (API, SDKs, Collector, OTLP protocol) | vendor-neutral standard for metrics, logs and traces |
| All-in-one SaaS | Datadog, New Relic, Dynatrace, Splunk, AWS CloudWatch + X-Ray | commercial, less setup, ongoing cost |

A common open-source stack is the **Grafana stack**: Prometheus (metrics) + Loki (logs) + Tempo (traces) + Grafana (UI), fed by OpenTelemetry or Fluent Bit.

---

## Kubernetes observability

Kubernetes does not give long-term metrics by itself; several components cooperate.

| Component | What it does |
|---|---|
| **metrics-server** | collects current CPU/memory from kubelets; powers `kubectl top` and the HPA. Keeps no history |
| **kube-state-metrics** | turns object state into metrics (deployment replicas desired vs available, pod phase, restarts) |
| **node-exporter** | host-level metrics per node (CPU, memory, disk, network) |
| **cAdvisor** | built into the kubelet; per-container CPU, memory, filesystem and network usage (`container_*` metrics) |
| **Prometheus Operator** | manages Prometheus/Alertmanager through CRDs: `ServiceMonitor`, `PodMonitor`, `PrometheusRule` |
| **kube-prometheus-stack** | Helm chart bundling Prometheus Operator, Prometheus, Alertmanager, Grafana, node-exporter, kube-state-metrics and default dashboards/alerts |

### Built-in kubectl tools

```bash
kubectl top nodes                         # needs metrics-server
kubectl top pods -A --sort-by=memory
kubectl logs deploy/myapp -f              # stream logs
kubectl logs mypod --previous             # logs of the crashed container
kubectl logs -l app=myapp --all-containers --tail=100
kubectl get events -A --sort-by=.lastTimestamp
kubectl describe pod mypod                # events, probe failures, OOMKilled reason
```

### Installing kube-prometheus-stack

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring --create-namespace

kubectl -n monitoring get pods
kubectl -n monitoring port-forward svc/monitoring-grafana 3000:80
kubectl -n monitoring port-forward svc/monitoring-kube-prometheus-prometheus 9090:9090
kubectl -n monitoring get secret monitoring-grafana -o jsonpath="{.data.admin-password}" | base64 -d
```

(The service names above follow from naming the Helm release `monitoring`.)

To scrape my own app, expose a `/metrics` endpoint and add a ServiceMonitor:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: myapp
  namespace: demo
  labels:
    release: monitoring        # chart's Prometheus selects monitors by this label
spec:
  selector:
    matchLabels:
      app: myapp
  endpoints:
    - port: http               # name of the Service port
      path: /metrics
      interval: 15s
```

### What to measure: golden signals, RED and USE

**Four golden signals** (Google SRE book), for any user-facing service:

1. **Latency**: time to serve requests (track successful and failed separately).
2. **Traffic**: demand on the system, e.g. requests per second.
3. **Errors**: rate of failed requests.
4. **Saturation**: how "full" the service is (CPU, memory, queue depth).

**RED method**, for **services / request-driven** workloads: **R**ate, **E**rrors, **D**uration.

**USE method**, for **resources** (CPU, memory, disk, network): **U**tilization, **S**aturation, **E**rrors.

Quick mapping I use: RED for each microservice dashboard, USE for node and pod resource dashboards, golden signals as the overall checklist.

---

## Monitoring basics from the course

### Metrics

Numeric time series scraped or pushed into a store like Prometheus. Types: **counter** (only goes up, e.g. total requests), **gauge** (up and down, e.g. memory), **histogram** (distribution in buckets, e.g. latency). Use `rate()` on counters.

### Logs

Write structured logs to stdout/stderr in containers (Kubernetes captures them). A shipper such as Fluent Bit forwards them to Loki or Elasticsearch so they outlive the pod.

### Alerts

An alert is a rule on a metric that notifies a human when something needs action. Good alerts are **actionable, symptom-based** (users are hurting) and use a `for:` duration to avoid flapping. Prometheus evaluates the rules, Alertmanager groups, silences and routes them.

### CPU utilization

How much of the available compute is in use. High sustained CPU means saturation and slow responses; Kubernetes compares usage to **requests/limits** (CPU throttling happens at the limit).

### Memory utilization

How much memory is in use. Unlike CPU, hitting the **memory limit** kills the container (`OOMKilled`). Watch the *working set*, not just total usage.

### Application health

- **Liveness probe**: "is the process stuck?" On failure kubelet restarts the container.
- **Readiness probe**: "can it take traffic?" On failure the pod is removed from Service endpoints, but not restarted.
- **Startup probe**: gives slow-starting apps time before the other probes begin.
- Apps usually expose `/healthz` (liveness) and `/ready` (readiness).

```yaml
containers:
  - name: myapp
    image: myapp:1.0
    ports:
      - containerPort: 8080
    readinessProbe:
      httpGet: { path: /ready, port: 8080 }
      initialDelaySeconds: 5
      periodSeconds: 10
    livenessProbe:
      httpGet: { path: /healthz, port: 8080 }
      initialDelaySeconds: 15
      periodSeconds: 20
      failureThreshold: 3
```

### Example PromQL queries

The `http_*` metrics assume the app is instrumented with common Prometheus client names; adjust names and labels to the real exporter.

```promql
# CPU used per pod (in cores)
sum by (pod) (rate(container_cpu_usage_seconds_total{namespace="demo", container!=""}[5m]))

# Node CPU utilization %
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)

# Memory working set per pod (bytes)
sum by (pod) (container_memory_working_set_bytes{namespace="demo", container!=""})

# Node memory utilization %
(1 - node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes) * 100

# Memory used as a fraction of the container limit
sum by (namespace, pod, container) (container_memory_working_set_bytes{container!=""})
  / on (namespace, pod, container)
sum by (namespace, pod, container) (kube_pod_container_resource_limits{resource="memory"})

# Request rate per service (RED: Rate)
sum by (service) (rate(http_requests_total[5m]))

# Error ratio (RED: Errors), share of 5xx responses
sum(rate(http_requests_total{status=~"5.."}[5m])) / sum(rate(http_requests_total[5m]))

# 95th percentile latency (RED: Duration)
histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# Container restarts in the last hour
increase(kube_pod_container_status_restarts_total[1h])
```

### Example Prometheus alert rules

Plain Prometheus rule file:

```yaml
groups:
  - name: app-alerts
    rules:
      - alert: HighErrorRatio
        expr: |
          sum(rate(http_requests_total{status=~"5.."}[5m]))
            / sum(rate(http_requests_total[5m])) > 0.05
        for: 10m
        labels:
          severity: critical
        annotations:
          summary: "More than 5% of requests are failing"
          description: "5xx ratio has been above 5% for 10 minutes."

      - alert: PodCrashLooping
        expr: increase(kube_pod_container_status_restarts_total[15m]) > 3
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "{{ $labels.namespace }}/{{ $labels.pod }} is restarting repeatedly"
```

With the Prometheus Operator the same rules go inside a `PrometheusRule` object:

```yaml
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: app-alerts
  namespace: monitoring
  labels:
    release: monitoring        # lets the chart's Prometheus discover it
spec:
  groups:
    - name: app-alerts
      rules:
        - alert: HighNodeCPU
          expr: 100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100) > 85
          for: 10m
          labels:
            severity: warning
          annotations:
            summary: "Node {{ $labels.instance }} CPU above 85%"
```

Prometheus only evaluates these rules; **Alertmanager** then groups, silences and routes the firing alerts to receivers such as Slack, email or PagerDuty.

---

## Interview quick points

- Three pillars: **metrics** (what/how much), **logs** (what happened), **traces** (where in the request path).
- Monitoring = known-unknowns with predefined checks; observability = ability to debug unknown-unknowns.
- Prometheus **pulls** (scrapes) metrics; Pushgateway exists only for short-lived batch jobs.
- Counter vs gauge vs histogram; always use `rate()` or `increase()` on counters.
- Loki indexes labels only, ELK indexes full text; Fluent Bit is a lightweight log forwarder, Fluentd is heavier and more plugin-rich.
- OpenTelemetry is a vendor-neutral standard for instrumentation and the Collector; Jaeger/Tempo store traces.
- metrics-server is for `kubectl top` and HPA only, with no history; Prometheus is for history and alerting.
- kube-state-metrics = object state; node-exporter = host metrics; cAdvisor = container metrics (in kubelet).
- Golden signals: latency, traffic, errors, saturation. RED for services, USE for resources.
- Error budget = 1 - SLO; 99.9% over 30 days is about 43 minutes.
- Liveness restarts a container; readiness removes it from Service endpoints; startup protects slow starters.
- `OOMKilled` means the memory limit was exceeded; CPU over the limit is throttled, not killed.
- Alert on symptoms (user impact), use `for:` to cut noise, and make every alert actionable.
