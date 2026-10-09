# Session 20: Monitoring, Observability & GitOps

This document provides a comprehensive guide, architecture diagrams, and commands for the Monitoring, Observability, and GitOps tasks.

---

## Task 1: Monitoring

### 1. Concepts & Demonstration Metrics
* **Metrics:** Numerical values sampled over time (CPU %, Memory RSS bytes, HTTP request rate, error counts).
* **Logs:** Timestamped discrete strings recording application and infrastructure events.
* **Alerts:** Automated rules notifying on-call engineers via Slack, PagerDuty, or Webhooks when thresholds are breached.
* **CPU & Memory Utilization:** Tracked via `container_cpu_usage_seconds_total` and `container_memory_working_set_bytes`.
* **Application Health:** Readiness/Liveness probe states and HTTP status code rates (`rate(http_requests_total[5m])`).

### 2. Hands-on Execution Commands
```bash
# 1. Deploy Prometheus & Grafana stack
cd 04-grafana
docker compose up -d

# 2. Verify running containers
docker ps --filter "name=grafana" --filter "name=prometheus"

# 3. Access Dashboards:
#    - Prometheus: http://localhost:9090
#    - Grafana: http://localhost:3000 (admin / admin)
```

---

## Task 2: Observability (The Three Pillars)

Observability is the degree to which you can infer the internal states of a system based solely on knowledge of its external outputs.

```text
                     +----------------------------+
                     |   THE THREE PILLARS OF     |
                     |       OBSERVABILITY        |
                     +--------------+-------------+
                                    |
          +-------------------------+-------------------------+
          |                         |                         |
          v                         v                         v
   [ METRICS ]                  [ LOGS ]                  [ TRACES ]
 "Is it failing?"           "Why is it failing?"      "Where is it failing?"
 Aggregable Numbers         Timestamped Events        Request Context Path
 (Prometheus, Datadog)      (Loki, ELK, Fluentd)      (Jaeger, OpenTelemetry)
```

### Why Observability is Required:
In microservices architectures, a single user transaction may hop across 15 different services. If a request times out, traditional server monitoring cannot pinpoint which specific database call, API hop, or lock caused the latency.

### Kubernetes Observability Architecture:
* **Node Metrics:** `node-exporter` queries the host OS kernel and hardware.
* **Container Metrics:** `cAdvisor` built directly into the `kubelet` tracks CPU, memory, and disk per container.
* **Cluster State:** `kube-state-metrics` converts Kubernetes API objects (deployments, pods, nodes) into Prometheus metrics.

---

## Task 3: GitOps with Argo CD

### 1. Core Principles of GitOps
1. **Declarative Descriptions:** The entire desired state of the system is stored declaratively (Kubernetes YAML, Kustomize, Helm).
2. **Git as Single Source of Truth:** Changes are made exclusively via Git pull requests, providing auditability and version control.
3. **Automated Continuous Reconciliation:** Software agents continuously compare desired Git state with actual cluster state.
4. **Self-Healing & Drift Detection:** Manual changes made directly in the cluster are detected and automatically overwritten by the Git source of truth.

### 2. GitOps Workflow

```text
[ Developer ] ---> Git Commit/PR ---> [ Git Repository (Source of Truth) ]
                                                        │
                                                        │ (Watches for Commits)
                                                        ▼
                                                [ Argo CD Controller ]
                                                        │
                                          ┌─────────────┴─────────────┐
                                          │ Continuous Reconciliation │
                                          ▼                           ▼
                                [ Desired State (Git) ] == [ Live State (Cluster) ]
```

### 3. Argo CD Hands-on Commands
Directory: [`07-argocd/`](file:///home/akshanshsinha/DevOps/devops-heros/session20-monitoring-observability-gitops/07-argocd)

```bash
# 1. Install Argo CD inside Kubernetes
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 2. Retrieve initial admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d; echo

# 3. Port-forward Argo CD API server
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 4. Deploy GitOps Application manifest
kubectl apply -f 07-argocd/application.yaml

# 5. Verify sync status
kubectl get applications -n argocd
```

---

## Deliverables & Screenshot Evidence

* **Screenshot 1: Prometheus Metrics Graph / Targets**  
  <!-- Add screenshot: ![Prometheus Targets](screenshots/prometheus-targets.png) -->

* **Screenshot 2: Grafana Dashboard (CPU & Memory)**  
  <!-- Add screenshot: ![Grafana Dashboard](screenshots/grafana-dashboard.png) -->

* **Screenshot 3: Argo CD UI Showing Healthy & Synced Application**  
  <!-- Add screenshot: ![ArgoCD Sync](screenshots/argocd-sync.png) -->
