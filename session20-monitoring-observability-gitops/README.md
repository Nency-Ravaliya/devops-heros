# Session 20 — Monitoring, Observability & GitOps

> **Learn how to monitor systems, observe their behaviour, and manage Kubernetes with GitOps**

---

## 📁 Folder Structure

```
session20-monitoring-observability-gitops/
├── 01-monitoring-vs-observability/   # Monitoring vs Observability concepts
├── 02-metrics-logs-traces/           # The three pillars of observability
├── 03-prometheus/                    # Prometheus metrics collection
├── 04-grafana/                       # Grafana dashboards
├── 05-introduction-to-gitops/        # GitOps fundamentals
├── 06-git-as-source-of-truth/        # Git as desired state
├── 07-argocd/                        # Argo CD setup & usage
└── 08-mini-project/                  # Full GitOps mini project (ArgoCD + K8s)
```

---

## Task 1 — Monitoring

### What is Monitoring?

Monitoring answers: **"Is the system healthy?"**

It tracks known signals and fires alerts when thresholds are breached.

```
CPU:        82%   ← metric
Memory:     70%   ← metric
Requests:   500/s ← metric
Errors:     20/s  ← metric  → ALERT if > 5%
Latency:    900ms ← metric  → ALERT if > 1s
```

### Metrics

**Metrics** are numerical measurements collected over time.

| Metric | Description | Alert Threshold |
|--------|-------------|-----------------|
| CPU utilization | % CPU used by pods/nodes | > 80% |
| Memory utilization | % memory used | > 85% |
| Request rate | Requests per second | Baseline ± 50% |
| Error rate | HTTP 5xx / total requests | > 1% |
| Response latency | p99 request duration | > 1 second |
| Pod restarts | Number of container restarts | > 3 in 5 min |

### Logs

**Logs** are timestamped event records from applications and infrastructure.

```bash
# View pod logs
kubectl logs deployment/session20-mini -n session20

# Follow logs in real-time
kubectl logs -f deployment/session20-mini -n session20

# View logs from all pods with label
kubectl logs -l app=session20-mini -n session20 --all-containers
```

**Example log output:**
```
2024-01-15T10:23:41Z INFO  Server started on port 8080
2024-01-15T10:23:45Z INFO  GET /health 200 OK (2ms)
2024-01-15T10:23:46Z INFO  GET /api/status 200 OK (5ms)
2024-01-15T10:24:10Z ERROR Database connection timeout after 5000ms
2024-01-15T10:24:10Z WARN  Retrying database connection (attempt 1/3)
```

### Alerts

Alerts notify when something goes wrong. Example Prometheus alert rules:

```yaml
groups:
  - name: kubernetes-alerts
    rules:
      - alert: HighCPUUsage
        expr: container_cpu_usage_seconds_total > 0.8
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High CPU usage on {{ $labels.pod }}"

      - alert: PodCrashLooping
        expr: rate(kube_pod_container_status_restarts_total[5m]) > 0
        for: 2m
        labels:
          severity: critical
        annotations:
          summary: "Pod {{ $labels.pod }} is crash looping"

      - alert: HighMemoryUsage
        expr: container_memory_usage_bytes / container_spec_memory_limit_bytes > 0.85
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "High memory usage on {{ $labels.pod }}"
```

### Prometheus + Grafana Demo

```bash
# Start Prometheus + Grafana with Docker Compose
cd 03-prometheus
docker-compose up -d

# Verify Prometheus is running
curl http://localhost:9090/-/healthy
# → Prometheus Server is Healthy.

# Access Prometheus UI
open http://localhost:9090

# Example PromQL queries
# CPU usage rate
rate(container_cpu_usage_seconds_total[5m])

# Memory usage
container_memory_usage_bytes{container!=""}

# HTTP request rate
rate(http_requests_total[5m])

# Error rate
rate(http_requests_total{status=~"5.."}[5m]) / rate(http_requests_total[5m])
```

**Grafana dashboard access:**
```bash
cd 04-grafana
docker-compose up -d

# Access Grafana
open http://localhost:3000
# Username: admin
# Password: admin
```

**Key Grafana panels configured:**
- CPU Utilization (gauge + time series)
- Memory Utilization (gauge + time series)
- Request Rate (time series)
- Error Rate (stat + alert)
- Pod Restart Count (table)
- Application Health (status panel)

---

## Task 2 — Observability

### The Three Pillars

```
┌──────────────────────────────────────────────────────┐
│                   OBSERVABILITY                       │
│                                                      │
│   ┌──────────┐   ┌──────────┐   ┌──────────────┐   │
│   │ METRICS  │   │  LOGS    │   │   TRACES     │   │
│   │          │   │          │   │              │   │
│   │ Numbers  │   │ Events   │   │  Journey     │   │
│   │ over time│   │ text     │   │  of request  │   │
│   └──────────┘   └──────────┘   └──────────────┘   │
│   Prometheus     Loki/ELK        Jaeger/Tempo        │
└──────────────────────────────────────────────────────┘
```

### Pillar 1 — Metrics

**What:** Numerical measurements sampled at regular intervals.

**Why:** Spot trends, set thresholds, trigger alerts.

**Example:**
```
timestamp=1705312800  cpu_percent=72.3
timestamp=1705312860  cpu_percent=78.1
timestamp=1705312920  cpu_percent=91.5  ← ALERT
```

**Tools:** Prometheus, Datadog, CloudWatch, InfluxDB

---

### Pillar 2 — Logs

**What:** Structured or unstructured text records of events.

**Why:** Debug specific errors, audit trails, understand what happened.

**Example (structured JSON log):**
```json
{
  "timestamp": "2024-01-15T10:24:10Z",
  "level": "ERROR",
  "service": "payment-service",
  "message": "Database connection timeout",
  "duration_ms": 5000,
  "trace_id": "abc123def456",
  "user_id": "u-789"
}
```

**Tools:** Loki, Elasticsearch + Kibana (ELK), Fluentd, Splunk

---

### Pillar 3 — Traces

**What:** End-to-end records of a single request as it flows through multiple services.

**Why:** Find exactly which service/database is causing latency in distributed systems.

**Example:**
```
Request: GET /checkout  Total: 2100ms

├── API Gateway          50ms
├── Auth Service        100ms
├── Cart Service        200ms
│   └── Redis Cache      10ms
├── Order Service       300ms
│   └── Postgres DB    1400ms  ← SLOW
└── Notification Svc     50ms
```

**Tools:** Jaeger, Tempo, Zipkin, AWS X-Ray

---

### Why Observability is Required

| Scenario | Without Observability | With Observability |
|---|---|---|
| App is slow | "Something is slow" | "DB query takes 1.4s on /checkout" |
| Intermittent errors | "Some users see errors" | "Error only when user_id has special chars" |
| High memory | "Memory alert fired" | "Memory leak in payment service after 1000 requests" |
| Microservices debugging | Check each service manually | Trace shows exact failure point |

### Common Observability Tools

| Tool | Category | Use Case |
|---|---|---|
| **Prometheus** | Metrics | Collect & query metrics |
| **Grafana** | Dashboards | Visualise metrics & logs |
| **Loki** | Logs | Log aggregation (Prometheus for logs) |
| **Jaeger** | Traces | Distributed tracing |
| **Tempo** | Traces | Grafana-native tracing backend |
| **OpenTelemetry** | All three | Vendor-neutral instrumentation |
| **Datadog** | All-in-one | Enterprise observability platform |
| **ELK Stack** | Logs | Elasticsearch + Logstash + Kibana |

### Kubernetes Observability

```bash
# Metrics — kubectl top
kubectl top nodes
kubectl top pods -n default
kubectl top pods --all-namespaces

# Logs — kubectl logs
kubectl logs <pod-name>
kubectl logs <pod-name> -c <container-name>
kubectl logs <pod-name> --previous   # crashed container logs

# Events — kubectl events
kubectl get events -n default --sort-by='.lastTimestamp'
kubectl describe pod <pod-name>     # includes events

# Resource health
kubectl get pods -A
kubectl get nodes
kubectl describe node <node-name>
```

---

## Task 3 — GitOps

### What is GitOps?

**GitOps** is an operational framework where **Git is the single source of truth** for the desired state of your infrastructure and applications.

```
Traditional:
  Developer → kubectl apply → Kubernetes

GitOps:
  Developer → git push → Git → ArgoCD → Kubernetes
```

### Git as the Source of Truth

Every change to infrastructure goes through Git:
- **Auditable** — full history of every change
- **Reversible** — `git revert` rolls back infrastructure
- **Reviewable** — Pull Requests for infrastructure changes
- **Automated** — no manual kubectl commands in production

```
Git Repo (Desired State)
   │
   │  ArgoCD watches repo every 3 minutes
   ▼
Kubernetes (Actual State)
   │
   │  If drift detected → auto-reconcile
   ▼
Matches Desired State ✅
```

### Declarative Configuration

Everything is defined as YAML files in Git:

```yaml
# deployment.yaml — desired state
apiVersion: apps/v1
kind: Deployment
metadata:
  name: session20-mini
  namespace: session20
spec:
  replicas: 2          # Git says: 2 replicas
  selector:
    matchLabels:
      app: session20-mini
  template:
    metadata:
      labels:
        app: session20-mini
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          ports:
            - containerPort: 80
```

### Continuous Reconciliation

ArgoCD continuously compares **desired state** (Git) with **actual state** (Kubernetes):

```
Every 3 minutes:
  Git says:       replicas=3
  K8s has:        replicas=1   ← drift detected!
  ArgoCD action:  scale to 3   ← reconcile
```

### GitOps Workflow

```
1. Developer changes replicas: 2 → 3 in deployment.yaml
2. git commit -m "Scale to 3 replicas"
3. git push origin main
4. ArgoCD detects change (webhook or polling)
5. ArgoCD syncs: kubectl apply -f deployment.yaml
6. Kubernetes scales deployment to 3 pods
7. ArgoCD status: Synced ✅  Healthy ✅
```

### GitOps Demo — Argo CD

```bash
# Install Argo CD
kubectl create namespace argocd
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# Wait for pods
kubectl get pods -n argocd -w

# Apply the application
kubectl apply -f 08-mini-project/app/argocd-application.yaml

# Check sync status
kubectl get applications -n argocd
```

**Output:**
```
NAME             SYNC STATUS   HEALTH STATUS
session20-mini   Synced        Healthy
```

```bash
# Check deployed resources
kubectl get all -n session20
```

**Output:**
```
NAME                                  READY   STATUS    RESTARTS   AGE
pod/session20-mini-7d9b8f6c5-xk2np    1/1     Running   0          2m
pod/session20-mini-7d9b8f6c5-pq8mt    1/1     Running   0          2m

NAME                     TYPE        CLUSTER-IP     PORT(S)   AGE
service/session20-mini   ClusterIP   10.96.45.123   80/TCP    2m

NAME                             READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/session20-mini   2/2     2            2           2m
```

### Self-Healing Demo

```bash
# Manually break the desired state
kubectl scale deployment session20-mini -n session20 --replicas=1

# Check immediately
kubectl get deployment session20-mini -n session20
# READY: 1/1  ← drifted from Git (replicas: 3)

# ArgoCD reconciles automatically
# Wait ~3 minutes...
kubectl get deployment session20-mini -n session20
# READY: 3/3  ← restored to Git desired state ✅
```

---

## 🔑 Key Concepts Summary

| Concept | One-line definition |
|---|---|
| **Monitoring** | Track known metrics, alert on thresholds |
| **Observability** | Understand *why* a system behaves as it does |
| **Metrics** | Numbers over time (CPU, memory, requests) |
| **Logs** | Timestamped event records |
| **Traces** | Full journey of a request across services |
| **Prometheus** | Pull-based metrics collection & storage |
| **Grafana** | Dashboard & visualisation layer |
| **GitOps** | Git as the single source of truth for infrastructure |
| **Argo CD** | GitOps controller — syncs Git state to Kubernetes |
| **Reconciliation** | Process of making actual state match desired state |
| **Self-healing** | Argo CD auto-reverts manual changes to match Git |

---

## 📚 Mini Project Summary

See [`08-mini-project/README.md`](08-mini-project/README.md) for the full step-by-step GitOps demo:

1. Create `kind` cluster
2. Install Argo CD
3. Push K8s manifests to Git
4. Apply `argocd-application.yaml`
5. Verify sync: `Synced ✅ Healthy ✅`
6. Scale replicas via Git push
7. Observe ArgoCD auto-sync
8. Demonstrate self-healing
