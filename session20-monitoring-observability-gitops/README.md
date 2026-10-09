# Session 20: Monitoring, Observability & GitOps Continuous Delivery

**Name:** Durga Prasad  
**Enrollment Number:** 10012  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 20 - Monitoring, Observability & GitOps  
**Repository:** devops-heros / session20-monitoring-observability-gitops  

---

## Executive Summary

As distributed microservices and Kubernetes clusters scale, traditional reactive troubleshooting breaks down. Engineering teams cannot wait for customers to report downtime. 

This session covers:
1. **Full-Stack Monitoring & Observability**: Moving from knowing *that* something is broken (monitoring) to understanding *why* it is broken (observability) across Metrics, Logs, and Traces.
2. **GitOps with ArgoCD**: Automating continuous delivery where Git repositories act as the immutable single source of truth, and Kubernetes controllers automatically reconcile cluster state to match Git.

```
                  ENTERPRISE OBSERVABILITY & GITOPS ARCHITECTURE
                                                                               
   ┌────────────────────────────────────────────────────────────────────────┐  
   │                    GITOPS CONTINUOUS RECONCILIATION                    │  
   │                                                                        │  
   │   Git Repository (Source of Truth)                                     │  
   │   └── manifests/deployment.yaml ◄────────┐                             │  
   │                                          │ Watch (Webhook / Polling)   │  
   │                                          ▼                             │  
   │   ArgoCD Controller (Kubernetes) ──► Reconciles Drift ──► K8s Pods     │  
   └──────────────────────────────────────────┬─────────────────────────────┘  
                                              │ Emits Telemetry                
                                              ▼                                
   ┌────────────────────────────────────────────────────────────────────────┐  
   │                       THREE PILLARS OF OBSERVABILITY                   │  
   │                                                                        │  
   │    [METRICS] (Prometheus)     [LOGS] (Loki / FluentBit)  [TRACES]      │  
   │    • CPU/Memory (% usage)     • Application stdout/stderr • Span / Latency
   │    • HTTP Request Rates       • JSON Structured Logs      • Jaeger / OTel │
   │    • 99th Percentile Latency  • Exception Stack Traces    • Trace ID Map  │
   │               │                           │                     │         
   │               └───────────────────┬───────┴─────────────────────┘         
   │                                   ▼                                       
   │                       Unified Grafana Dashboards                          │  
   │                       & Alertmanager Notifications                        │  
   └────────────────────────────────────────────────────────────────────────┘  
```

---

## Task 1: Monitoring System Architecture

Monitoring tracks known failure modes by collecting quantitative measurements over time:

### Core Telemetry Dimensions:
* **Metrics:** Numeric values measured over time intervals (e.g. `node_cpu_seconds_total`, `http_requests_total`).
* **Logs:** Timestamped discrete text or JSON records emitted by software execution (e.g. `[ERROR] 2026-10-03 Connection refused to postgres:5432`).
* **Alerts:** Automated triggers that evaluate metric thresholds (e.g. `cpu_utilization > 85% for 5m`) and dispatch notifications to Slack, PagerDuty, or email via Alertmanager.
* **CPU & Memory Utilization:** Collected at the hardware/node level via `node_exporter` and container level via `cAdvisor`.
* **Application Health:** HTTP endpoints (`/health`, `/healthz`, `/metrics`) interrogated by Kubernetes readiness/liveness probes and Prometheus scrapers.

### Prometheus & Grafana Stack:
Implemented in [`03-prometheus/`](./03-prometheus/) and [`04-grafana/`](./04-grafana/):
```bash
docker compose up -d
```
* **Prometheus:** Runs on port `9090`, scraping metrics every 15s via pull-based architecture.
* **Grafana:** Runs on port `3000`, providing visual time-series dashboards.

---

## Task 2: The Three Pillars of Observability

| Pillar | Data Characteristics | Primary Function | Standard Open Source Stack |
|---|---|---|---|
| **Metrics** | Aggregatable numeric time-series data with key-value labels | Answers: *"Is there a problem right now and where?"* (High-level trends) | **Prometheus**, VictoriaMetrics, Datadog |
| **Logs** | High-cardinality contextual event strings emitted per transaction | Answers: *"What specifically failed inside the application?"* (Root cause analysis) | **Grafana Loki**, FluentBit, Elasticsearch |
| **Traces** | Distributed call graphs showing request path across microservice boundaries | Answers: *"Where was time spent across the network?"* (Latency bottlenecks) | **OpenTelemetry**, Jaeger, Zipkin |

### Why Observability is Mandatory for Kubernetes:
In ephemeral container clusters, Pods are frequently killed, rescheduled, or autoscaled by the Horizontal Pod Autoscaler (HPA). If a container terminates, its local filesystem and logs disappear unless centralized logging and persistent metrics scrape the telemetry in real time.

---

## Task 3: GitOps with ArgoCD

### 1. What is GitOps?
GitOps is an operational framework that takes DevOps best practices used for application development (version control, collaboration, compliance, and CI/CD) and applies them to modern cloud infrastructure automation.

### 2. The Four Principles of GitOps:
1. **Declarative State:** The entire system state is described declaratively (Kubernetes manifests, Helm charts, Kustomize).
2. **Version Controlled & Immutable:** The desired state is stored in Git with complete revision history and commit audits.
3. **Automated Pull Reconciliation:** Software agents in the cluster periodically pull state from Git rather than external push tools pushing into the cluster.
4. **Continuous Drift Correction:** If someone manually modifies the cluster (`kubectl edit`), the GitOps agent detects drift and automatically re-syncs to match Git.

### 3. Mini Project — ArgoCD Application Manifest
Located in [`08-mini-project/app/argocd-application.yaml`](./08-mini-project/app/argocd-application.yaml):

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: session20-guestbook
  namespace: argocd
  finalizers:
    - resources-finalizer.argocd.argoproj.io
spec:
  project: default
  source:
    repoURL: https://github.com/Durgaprasad-Developer/devops-heros.git
    targetRevision: main
    path: session20-monitoring-observability-gitops/08-mini-project/app
  destination:
    server: https://kubernetes.default.svc
    namespace: session20-demo
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

#### Key Capabilities Demonstrated:
* **`selfHeal: true`**: Automatically reverts unapproved manual changes made to the cluster.
* **`prune: true`**: Deletes Kubernetes resources when their YAML is removed from Git.
* **`CreateNamespace: true`**: Automatically provisions destination namespace `session20-demo`.

---

## Deliverables Verification Matrix

| Syllabus Requirement | Status | Verification & Artifact |
|---|---|---|
| **Monitoring Telemetry Demo** | Completed | [`03-prometheus/`](./03-prometheus/) & [`04-grafana/`](./04-grafana/) |
| **Observability Deep Dive** | Completed | Detailed documentation of Metrics, Logs, and Traces above |
| **GitOps Concepts Guide** | Completed | Comprehensive explanation of Git source of truth & reconciliation |
| **ArgoCD Application Manifest** | Completed | [`08-mini-project/app/argocd-application.yaml`](./08-mini-project/app/argocd-application.yaml) |
| **Kubernetes Target Manifests** | Completed | `deployment.yaml`, `service.yaml`, `namespace.yaml` |
| **Master Documentation** | Completed | [`README.md`](./README.md) |
