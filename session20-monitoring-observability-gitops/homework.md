# Session 20: Monitoring, Observability & GitOps

**Name:** Ankita Tripathi  
**Roll Number:** 24bcs10062  
**Repository:** [devops-heros](https://github.com/vvsleepy/devops-heros)  
**Project directory:** `session20-monitoring-observability-gitops/`  
**Environment:** macOS, Docker Desktop Kubernetes, `kubectl`, Git, GitHub, Argo CD

---

## 1. Assignment Overview

This session explores how cloud-native applications are monitored, how observability helps diagnose failures, and how GitOps makes Kubernetes deployments repeatable and auditable.

| Task | Objective | Deliverable |
|---|---|---|
| Task 1 — Monitoring | Explore metrics, logs, alerts, CPU, memory, and application health | Monitoring demonstration and evidence |
| Task 2 — Observability | Explain metrics, logs, traces, tools, and Kubernetes observability | Observability documentation |
| Task 3 — GitOps | Use Git as the source of truth and reconcile Kubernetes resources through Argo CD | Working GitOps demonstration and evidence |

**Submission contents:** project manifests, task-specific documentation, screenshots in `ss/`, and this README.

## 2. Project Organization

The repository's Session 20 directory is organized by topic:

```text
session20-monitoring-observability-gitops/
├── 04-grafana/
├── 05-introduction-to-gitops/
│   ├── app/
│   └── README.md
├── 06-git-as-source-of-truth/
│   ├── gitops-repo/
│   │   └── app/
│   │       ├── deployment.yaml
│   │       └── service.yaml
│   └── README.md
├── 07-argocd/
│   ├── app/
│   │   ├── argocd-application.yaml
│   │   ├── deployment.yaml
│   │   └── service.yaml
│   └── README.md
├── 08-mini-project/
│   ├── app/
│   └── README.md
├── evidence/
│   └── task2/
└── ss/
    └── (screenshots captured during the exercises)
```

> The tree highlights the files and folders used or observed during the session; it is not intended as an exhaustive listing of every file in the repository. Screenshots are maintained separately in `ss/` and are not embedded in this document.

---

# Task 1 — Monitoring

## 3. What Is Monitoring?

Monitoring is the continuous collection and examination of system and application signals to determine whether a service is available, healthy, and operating within expected limits. It answers questions such as:

- Is the application running and responding?
- Is CPU or memory usage unusually high?
- Are containers restarting or failing health checks?
- Are errors increasing?
- Should an operator be alerted?

### 3.1 Metrics

Metrics are numeric measurements collected over time. Examples include CPU utilization, memory consumption, request throughput, request latency, error rates, and Kubernetes pod counts. Metrics make trends, capacity issues, and threshold violations visible.

**Examples:** CPU at 75%, memory use at 400 MiB, five HTTP errors per minute, or three ready replicas.

### 3.2 Logs

Logs are timestamped records of events produced by applications, containers, and infrastructure. They explain *what happened*, including startup messages, failed requests, exceptions, and authentication errors.

Common Kubernetes commands:

```bash
kubectl --context docker-desktop get pods -A
kubectl --context docker-desktop logs -n session20 deployment/session20-gitops-app
kubectl --context docker-desktop describe pod <pod-name> -n session20
```

### 3.3 Alerts

Alerts notify operators when a defined condition is met, such as CPU usage remaining above a threshold, a service becoming unavailable, or a pod repeatedly restarting. Useful alerts include a meaningful threshold, evaluation duration, severity, and a clear response action.

**Illustrative alert conditions:**

- CPU utilization above 80% for five minutes.
- Memory approaching a container's limit.
- Application readiness dropping below the required replica count.
- A sustained increase in HTTP 5xx responses.

These are examples of alert rules, **not claims that each rule was deployed or fired during this session**.

### 3.4 CPU Utilization

CPU utilization shows the processing resources consumed by a workload. High sustained usage may cause slow response times and indicate a need for optimization or horizontal scaling.

```bash
kubectl --context docker-desktop top nodes
kubectl --context docker-desktop top pods -A
```

`kubectl top` requires a working Metrics Server. If metrics are unavailable, verify Metrics Server before treating missing output as zero usage.

### 3.5 Memory Utilization

Memory utilization measures RAM used by containers and nodes. Memory pressure can lead to eviction or out-of-memory termination. Kubernetes resource requests help schedule workloads; limits define maximum permitted consumption.

```bash
kubectl --context docker-desktop top pods -n session20
kubectl --context docker-desktop describe nodes
```

### 3.6 Application Health

Application health includes availability, readiness, liveness, restart behavior, and the ability to serve traffic. Kubernetes distinguishes:

- **Liveness:** whether a container should be restarted.
- **Readiness:** whether a container should receive traffic.
- **Startup:** whether an application has finished initializing.

Useful checks:

```bash
kubectl --context docker-desktop get deployments,pods,services -n session20
kubectl --context docker-desktop get events -n session20 --sort-by=.lastTimestamp
kubectl --context docker-desktop describe deployment session20-gitops-app -n session20
```

### 3.7 Monitoring Demonstration

The monitoring portion of the assignment covers inspecting workload state, resource utilization, logs, and health indicators. The Session 20 project also includes a `04-grafana/` section for monitoring/visualization material.

The GitOps workload provides a **verified application-health example**: the final Kubernetes check showed `3/3` ready Deployment replicas and three running pods with zero restarts. This confirms readiness at the time of the check, not long-term availability or a configured alerting pipeline.

**Evidence:** See the monitoring screenshots saved in `ss/`. CPU/memory graphs and fired alerts should be considered demonstrated only where their corresponding screenshots or configuration are present.

---

# Task 2 — Observability

## 4. What Is Observability?

Observability is the ability to understand the internal behavior of a system from the signals it emits. Monitoring identifies known problems; observability helps investigate both expected and unexpected behavior, especially across distributed services.

For example, monitoring may show that request latency increased. Observability helps determine whether the cause was CPU saturation, a slow database query, a failing downstream service, or network delay.

## 5. The Three Pillars of Observability

| Pillar | Meaning | Main Question | Typical Data |
|---|---|---|---|
| **Metrics** | Aggregated numeric measurements over time | How much? How often? | CPU, memory, request rate, latency, error count |
| **Logs** | Timestamped event records | What happened? | Application messages, errors, container output |
| **Traces** | End-to-end records of requests across components | Where was time spent? | Trace IDs, spans, service dependencies, duration |

### 5.1 Metrics

Metrics are efficient for dashboards, historical trends, capacity planning, and alerts. For example, a sudden increase in CPU usage may coincide with a spike in traffic.

**Common tools:** Prometheus, Grafana, Kubernetes Metrics Server, cloud monitoring platforms.

### 5.2 Logs

Logs preserve contextual details that metrics usually omit. Structured logs may contain severity, timestamps, request IDs, component names, and error details. Centralized logging makes it possible to search logs across many pods.

**Common tools:** Fluent Bit, Loki, Elasticsearch, OpenSearch, Kibana, Grafana.

### 5.3 Traces

A distributed trace follows a request as it moves through services. Each unit of work is represented by a **span**; spans are correlated using a **trace ID**. Tracing helps identify slow dependencies and pinpoint failures in microservice architectures.

Example:

```text
Client request
    |
    v
API Gateway (span)
    |
    v
Application Service (span)
    |
    v
Database Query (span)
```

**Common tools:** OpenTelemetry, Jaeger, Zipkin, Grafana Tempo.

> This is a conceptual tracing example; it does not assert that a distributed tracing backend was deployed in the exercise.

## 6. Why Observability Is Required

Observability supports:

1. **Faster incident diagnosis:** identify the component responsible for a failure.
2. **Performance analysis:** locate slow endpoints and resource bottlenecks.
3. **Reliability:** detect regressions and understand recurring failures.
4. **Capacity planning:** track workload trends and anticipate scaling needs.
5. **Distributed debugging:** correlate behavior across services and infrastructure.
6. **Better operations:** validate deployments, upgrades, and recovery.

## 7. Common Observability Tools

| Tool | Primary Use |
|---|---|
| Prometheus | Metrics scraping, storage, and alert-rule evaluation |
| Grafana | Dashboards and visualization across multiple data sources |
| Alertmanager | Routing and grouping Prometheus alerts |
| Loki | Log aggregation and querying |
| Fluent Bit | Collection and forwarding of logs |
| OpenTelemetry | Instrumentation and collection of telemetry |
| Jaeger / Tempo | Distributed trace storage and exploration |
| Kubernetes Metrics Server | Resource metrics used by `kubectl top` and autoscaling |

## 8. Kubernetes Observability

Kubernetes observability combines signals from the cluster, nodes, pods, containers, applications, and networking.

```text
Kubernetes cluster
    |
    +-- Metrics ------> Prometheus / Metrics Server --> Grafana
    |
    +-- Logs ---------> Log collector ---------------> Log backend
    |
    +-- Traces -------> OpenTelemetry ---------------> Trace backend
    |
    +-- Health -------> Kubernetes API / probes / events
```

Useful investigation commands:

```bash
kubectl --context docker-desktop get nodes
kubectl --context docker-desktop get pods -A
kubectl --context docker-desktop get events -A --sort-by=.lastTimestamp
kubectl --context docker-desktop top nodes
kubectl --context docker-desktop top pods -A
kubectl --context docker-desktop logs -n session20 deployment/session20-gitops-app
kubectl --context docker-desktop describe deployment session20-gitops-app -n session20
```

**Key distinction:** A pod being `Running` does not by itself prove that the application is serving requests correctly; readiness probes, service-level metrics, logs, and end-to-end checks add confidence.

**Task 2 documentation/evidence:** `evidence/task2/` and the relevant Session 20 README files; screenshots are stored separately in `ss/`.

---

# Task 3 — GitOps

## 9. What Is GitOps?

GitOps is an operational approach in which the desired state of an application or infrastructure is defined declaratively in Git. A controller compares the live environment with Git and continuously works to reconcile differences.

In this assignment:

- **GitHub** stores the desired Kubernetes manifests.
- **Argo CD** observes the Git repository and the cluster.
- **Kubernetes** runs the application described by those manifests.
- **Automated sync** applies approved Git changes to the cluster.
- **Self-healing** corrects manual drift away from the Git-defined state.

## 10. Core GitOps Principles

### 10.1 Git as the Source of Truth

The repository contains the authoritative Deployment and Service definitions. Changes are committed and pushed to Git instead of relying on undocumented manual cluster edits.

**Repository:** `https://github.com/vvsleepy/devops-heros.git`  
**Branch:** `main`  
**Application manifest path:**

```text
session20-monitoring-observability-gitops/06-git-as-source-of-truth/gitops-repo/app
```

### 10.2 Declarative Configuration

Declarative YAML describes *what should exist*, rather than the sequence of imperative commands needed to create it.

The application Deployment uses `nginx:1.27-alpine`. The initial configuration requested **2 replicas**; the GitOps exercise updated it to **3 replicas**.

Relevant files:

```text
06-git-as-source-of-truth/gitops-repo/app/deployment.yaml
06-git-as-source-of-truth/gitops-repo/app/service.yaml
07-argocd/app/argocd-application.yaml
```

### 10.3 Continuous Reconciliation

Argo CD repeatedly compares the live Kubernetes state with the desired Git state. If a tracked resource differs, Argo CD can synchronize it. With automated self-healing enabled, it can also undo manual changes made directly in the cluster.

### 10.4 GitOps Workflow

```text
Developer edits Kubernetes YAML
              |
              v
       Git commit + push
              |
              v
        GitHub main branch
              |
              v
       Argo CD detects change
              |
              v
     Compare desired vs live
              |
              v
       Automatic sync to K8s
              |
              v
     Deployment reaches 3/3
              |
              v
    Continuous drift detection
```

## 11. Environment and Application Details

| Component | Configuration |
|---|---|
| Local Kubernetes cluster | Docker Desktop (`docker-desktop` context) |
| Git repository | `vvsleepy/devops-heros` |
| Git branch | `main` |
| Argo CD namespace | `argocd` |
| Argo CD Application | `session20-app` |
| Application namespace | `session20` |
| Kubernetes Deployment | `session20-gitops-app` |
| Kubernetes Service | `session20-gitops-app` |
| Container image | `nginx:1.27-alpine` |
| Final desired replicas | `3` |
| Final observed health | `Synced`, `Healthy`, Deployment `3/3` |

## 12. Argo CD Application Configuration

The Application manifest is stored at:

```text
session20-monitoring-observability-gitops/07-argocd/app/argocd-application.yaml
```

The working configuration is equivalent to:

```yaml
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: session20-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/vvsleepy/devops-heros.git
    targetRevision: main
    path: session20-monitoring-observability-gitops/06-git-as-source-of-truth/gitops-repo/app
  destination:
    server: https://kubernetes.default.svc
    namespace: session20
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
```

**Configuration explanation:**

- `targetRevision: main` tracks the main branch.
- `source.path` identifies the folder containing Kubernetes YAML.
- `automated` enables synchronization without manually applying every Git change.
- `prune: true` permits deletion of managed resources removed from Git.
- `selfHeal: true` enables correction of live-state drift.
- `CreateNamespace=true` allows Argo CD to create the destination namespace if necessary.

## 13. Deployment and Verification Workflow

### Step 1 — Check the Kubernetes Cluster

```bash
kubectl config get-contexts
kubectl --context docker-desktop get nodes
kubectl --context docker-desktop get namespace argocd
kubectl --context docker-desktop get pods -n argocd
```

Argo CD was installed in the `argocd` namespace, and its components were brought into a running state before the application was deployed.

### Step 2 — Apply the Argo CD Application

From the `devops-heros` repository root:

```bash
kubectl --context docker-desktop apply -f \
  session20-monitoring-observability-gitops/07-argocd/app/argocd-application.yaml
```

### Step 3 — Check Synchronization and Workload Health

```bash
kubectl --context docker-desktop get applications -n argocd
kubectl --context docker-desktop get deployments,pods,services -n session20
```

The initial GitOps Deployment ran with two desired replicas.

### Step 4 — Update Desired State in Git

The tracked Deployment manifest was edited from:

```yaml
replicas: 2
```

to:

```yaml
replicas: 3
```

The change was committed and pushed:

```bash
git add session20-monitoring-observability-gitops/06-git-as-source-of-truth/gitops-repo/app/deployment.yaml
git commit -m "feat: scale GitOps application from 2 to 3 replicas"
git push origin main
```

**Git revision:** `68c1465` (`68c1465446aa92d75b2dfcdd28e74fbf156688ac`).

The Kubernetes Deployment was **not manually scaled or applied** for this Git-driven update; Argo CD performed the synchronization.

### Step 5 — Refresh Argo CD's Git Comparison

Argo CD initially continued displaying the previous revision, `4beda07`, despite the new commit being present on GitHub. A normal refresh did not immediately update the revision. A hard refresh invalidated cached manifest data and caused Argo CD to recognize the new commit:

```bash
kubectl --context docker-desktop annotate \
  application session20-app -n argocd \
  argocd.argoproj.io/refresh=hard --overwrite
```

**Important:** This refresh requested a new comparison; it was not a manual synchronization of the Kubernetes Deployment. Argo CD's automated sync policy then applied the Git change.

Verification:

```bash
kubectl --context docker-desktop get application session20-app \
  -n argocd \
  -o jsonpath='{.status.sync.revision}{"\n"}'

kubectl --context docker-desktop get deployments,pods -n session20
```

**Observed result:** the revision changed to `68c1465...` and the Deployment reached **3/3 ready replicas**, with three running pods.

## 14. Self-Healing Demonstration

To prove that Git remained the source of truth, the live Deployment was deliberately changed without editing the repository.

### Step 1 — Introduce Configuration Drift

```bash
kubectl --context docker-desktop scale \
  deployment/session20-gitops-app \
  --replicas=1 -n session20
```

This changed the live desired replica count to one while Git continued to specify three.

### Step 2 — Watch Argo CD Restore the Git State

```bash
kubectl --context docker-desktop get deployment \
  session20-gitops-app -n session20 -w
```

**Observed progression:**

```text
READY   UP-TO-DATE   AVAILABLE
1/1     1            1
1/3     1            1
2/3     3            1
3/3     3            3
```

Argo CD detected the drift and restored the Deployment to three replicas automatically. No Git commit or manual corrective `kubectl scale --replicas=3` was needed.

### Step 3 — Confirm Final Health

```bash
kubectl --context docker-desktop get applications -n argocd
kubectl --context docker-desktop get deployments,pods -n session20
```

**Final verified status:**

```text
NAME            SYNC STATUS   HEALTH STATUS
session20-app   Synced        Healthy

NAME                                   READY   UP-TO-DATE   AVAILABLE
deployment.apps/session20-gitops-app   3/3     3            3
```

Three application pods were `Running` and showed zero restarts in the final verification.

## 15. Troubleshooting and Resolutions

The exercise involved real troubleshooting, which was an important part of the hands-on work.

| Issue | Cause / Investigation | Resolution |
|---|---|---|
| Argo CD components initially experienced API/Redis timeouts | Cluster and service connectivity needed verification | Checked Kubernetes API, Redis, and DNS connectivity; restarted the affected Argo CD controller |
| Argo CD repository checkout failed | Tracked Python `.venv` symlinks in other parts of the monorepo pointed outside the repository | Excluded virtual environments from Git and removed the problematic tracked files from the index |
| Argo CD reported that the application path did not exist | The Application used `06-git-as-source-of-truth/gitops-repo/app`, omitting the Session 20 directory prefix | Updated `spec.source.path` to the full path under `session20-monitoring-observability-gitops/` |
| Argo CD remained on old Git revision `4beda07` | A stale comparison/cache was observed | Requested a hard refresh; Argo CD fetched revision `68c1465` and synchronized the change |
| Need to prove drift recovery | A successful sync alone does not prove self-healing | Manually scaled to one replica and watched Argo CD restore three |

These steps reinforced that successful GitOps depends on correct repository paths, valid repository contents, healthy controllers, and observable reconciliation.

## 16. GitOps Results

| Test | Expected | Observed | Result |
|---|---|---|---|
| Application creation | Argo CD recognizes the Application | `session20-app` present | PASS |
| Initial deployment | Application runs from Git manifests | Deployment ready with 2 replicas | PASS |
| Git-driven scaling | Commit changes desired replicas to 3 | Revision `68c1465` deployed; `3/3` ready | PASS |
| Self-healing | Manual change to 1 replica is corrected | Restored to `3/3` | PASS |
| Final sync | Live resources match Git | `Synced` | PASS |
| Final health | Workload healthy | `Healthy`, 3 running pods, 0 restarts | PASS |

---

## Evidence and Verification

To demonstrate the successful completion of Session 20, supporting evidence has been organized into two directories: `evidence/` and `ss/`.

### Evidence Directory

The `evidence/` directory contains supporting files and command outputs collected during the practical implementation and verification of the assignments.

These files provide additional documentation of the Kubernetes environment, deployed resources, and GitOps workflow.

Evidence includes the verification outputs collected during the hands-on tasks, such as Kubernetes deployment details and application status checks.

### Screenshots Directory

The `ss/` directory contains screenshots captured during the practical demonstrations.

Screenshots document the monitoring and GitOps activities performed, including relevant Kubernetes commands, deployment verification, Argo CD synchronization, Git-driven scaling, and self-healing.

### GitOps Verification Results

The following GitOps operations were successfully verified:

| Verification | Result |
|---|---|
| Argo CD Application | Successfully configured |
| GitHub repository integration | Successful |
| GitOps synchronization | Successful |
| Application health | Synced and Healthy |
| Git-driven scaling | 2 to 3 replicas |
| Manual scaling test | Reduced to 1 replica |
| Automatic self-healing | Restored to 3 replicas |
| Final deployment status | 3/3 replicas available |
| Kubernetes pods | 3 Running |

All supporting evidence and screenshots are maintained separately in their respective directories rather than embedded directly in this README.

This organization keeps the documentation readable while allowing reviewers to inspect the implementation and verification results independently.

## 18. Key Learnings

1. **Monitoring** makes resource usage, failures, and application health measurable.
2. **Metrics, logs, and traces** provide complementary perspectives on system behavior.
3. **Kubernetes observability** requires looking beyond pod status to resource usage, events, logs, and service behavior.
4. **GitOps** replaces undocumented manual deployments with version-controlled desired state.
5. **Argo CD** reconciles Kubernetes resources with Git and can recover from configuration drift.
6. **Troubleshooting** repository paths, controller connectivity, and Git cache behavior is an essential operational skill.
7. **Evidence-based verification** matters: `Synced`, `Healthy`, ready replicas, and self-healing output demonstrate concrete results.

## 19. Conclusion

Session 20 covered monitoring concepts and demonstrations, observability theory and Kubernetes tooling, and a working GitOps deployment using GitHub, Argo CD, and Docker Desktop Kubernetes.

The strongest verified practical outcome was the GitOps exercise: the application was deployed from Git, automatically updated from **2 to 3 replicas**, and automatically restored to **3 replicas** after a manual change to **1 replica**. The final observed state was **Argo CD `Synced` / `Healthy`, with 3/3 ready Deployment replicas**.

The session demonstrates how monitoring and observability help operators understand system behavior, while GitOps helps keep deployed systems aligned with a reviewed, version-controlled desired state.

---

**Submitted by:** Ankita Tripathi  
**Roll Number:** 24bcs10062  
**Repository:** https://github.com/vvsleepy/devops-heros
