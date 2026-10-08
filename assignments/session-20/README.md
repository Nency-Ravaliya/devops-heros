# Session 20: Monitoring, Observability & GitOps

## Overview
This directory contains the hands-on practice documentation, architectural analysis, GitOps declarative manifests, and cluster execution output screenshots for Session 20: Monitoring, Observability & GitOps.

---

## Task 1: Kubernetes Cluster & Application Monitoring

### Key Monitoring Concepts
- **Metrics**: Quantitative numeric data sampled over time representing resource usage (CPU %, Memory RSS, Network I/O, HTTP request rate, latency).
- **Logs**: Timestamped event records emitted by system components or containerized application processes (`stdout`/`stderr`).
- **Alerts**: Automated notifications triggered when monitored metrics breach predefined threshold rules (e.g. CPU > 85% for 5 minutes).
- **Resource Utilization**: Tracking node and container CPU/Memory consumption to prevent OOMKilled events and optimize resource requests/limits.
- **Application Health**: Monitoring container readiness and liveness endpoints (`/healthz`, `/metrics`).

### Monitoring Stack (Prometheus & Grafana)
- **Prometheus**: Time-series database that pulls metrics from Kubernetes nodes and pods using scrapers (`kube-state-metrics`, `node-exporter`).
- **Grafana**: Visualization platform rendering real-time dashboards for CPU, memory, network, and application SLA metrics.

### Terminal Screenshots:
- **Prometheus & Grafana Monitoring Dashboards**:
  ![Monitoring Output](./screenshots/01-monitoring.png)

---

## Task 2: The Three Pillars of Observability

```text
               ┌───────────────────────────┐
               │    OBSERVABILITY STACK    │
               └─────────────┬─────────────┘
                             │
       ┌─────────────────────┼─────────────────────┐
       │                     │                     │
       ▼                     ▼                     ▼
┌──────────────┐      ┌──────────────┐      ┌──────────────┐
│   METRICS    │      │     LOGS     │      │    TRACES    │
│ (Prometheus) │      │ (Grafana Loki│      │ (OpenTelemetry│
│              │      │ / Fluentd)   │      │   / Jaeger)  │
└──────────────┘      └──────────────┘      └──────────────┘
```

### The Three Pillars Explained:
1. **Metrics**: Aggregated quantitative state measurements over time. Shows *that* a system component is experiencing an issue.
2. **Logs**: Detailed discrete contextual records of specific execution events. Explains *what* failed during execution.
3. **Traces**: End-to-end request lifecycle tracking across distributed microservices. Identifies *where* bottlenecks or network latencies occur.

### Why Observability is Required:
Traditional monitoring tells you *when* a service is down. Observability allows engineers to infer the internal state of complex, distributed microservice architectures based on external telemetry signals, enabling rapid Root Cause Analysis (RCA).

### Common Observability Tooling in Kubernetes:
- **Metrics**: Prometheus, Thanos, VictoriaMetrics, Datadog
- **Logs**: Grafana Loki, Fluentd, Fluent Bit, Elasticsearch/Logstash/Kibana (ELK)
- **Traces**: OpenTelemetry, Jaeger, Zipkin, Tempo

### Observability Architecture Screenshot:
![Observability Architecture](./screenshots/02-observability.png)

---

## Task 3: GitOps Workflow & Continuous Reconciliation

### Core GitOps Principles:
1. **Declarative Configuration**: The entire target system state (deployments, services, ingress, HPA) is described declaratively in YAML stored in Git.
2. **Git as the Single Source of Truth**: Any state change must be initiated via Git commits and Pull Requests.
3. **Automated Pull-Based Synchronization**: A cluster-resident GitOps controller continuously compares actual live cluster state against the desired state stored in Git.
4. **Continuous Reconciliation & Self-Healing**: If live cluster state drifts (e.g., manual `kubectl delete`), the GitOps controller automatically reconciles and restores cluster state to match Git.

### GitOps Workflow Architecture:
```text
Developer ──► Git Commit ──► GitHub Repository
                                  │
                                  ▼ (Pull Poll / Webhook)
                           ArgoCD Controller
                                  │
                                  ▼ (Continuous Reconciliation)
                       Kubernetes Cluster State
```

### GitOps Project Manifests:
- **Namespace**: [`gitops/namespace.yaml`](./gitops/namespace.yaml)
- **Deployment**: [`gitops/deployment.yaml`](./gitops/deployment.yaml)
- **Service**: [`gitops/service.yaml`](./gitops/service.yaml)
- **ArgoCD Application CRD**: [`gitops/argocd-application.yaml`](./argocd-application.yaml)

### GitOps & ArgoCD Sync Verification:
![GitOps Reconciliation Output](./screenshots/03-gitops.png)
