# Session 15: Helm Package Manager

**Author:** Shivansh Singh  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 15  
**Status:** Completed  

---

## 1. Executive Summary & Overview

Kubernetes configuration manifests deployed across multiple environments (Dev, Staging, Prod) quickly suffer from configuration drift and code duplication. **Helm** serves as the package manager for Kubernetes, enabling parameterized templating, centralized value management, atomic release versioning, and instant rollback capabilities.

```text
                                  [ Helm CLI ]
                                       │
                    ┌──────────────────┴──────────────────┐
                    ▼                                     ▼
          [ Chart Templates ]                   [ Values Files ]
       (Go template YAML logic)              (Default & Env Overrides)
                    │                                     │
                    └──────────────────┬──────────────────┘
                                       │
                                       ▼ (helm install / upgrade)
                            [ Rendered Kubernetes YAML ]
                                       │
                                       ▼
                       [ Kubernetes API Server & Cluster ]
                                       │
                                       ▼
                         [ Release State as K8s Secret ]
```

---

## 2. Deliverables Checklist

| Deliverable | Location | Description | Status |
| :--- | :--- | :--- | :---: |
| **Helm Commands Guide** | `01-what-is-helm/README.md` | In-depth command guide with captured outputs covering all 11 required commands. | Completed |
| **Rollback Workflow** | `08-rollback/README.md` | Complete 7-step lifecycle: Install $\to$ Upgrade $\to$ Verify $\to$ Upgrade (Broken) $\to$ Verify $\to$ Rollback $\to$ Verify. | Completed |
| **Helm Chart Package** | `mini-project/notes-chart/` | Production-ready Notes app chart with templates, metadata, and variables. | Completed |
| **Values Configuration** | `mini-project/notes-chart/values*.yaml` | Multi-environment configurations (`values.yaml` and `values-prod.yaml`). | Completed |
| **Templates Suite** | `mini-project/notes-chart/templates/` | Go templates for `Deployment`, `Service`, and `ConfigMap` with dynamic release naming. | Completed |
| **Mini-Project Solution** | `mini-project/README.md` | Turnkey walkthrough with linting, templating, deployment, upgrade, and testing. | Completed |
| **Screenshots Directory** | `screenshots/` | Screenshot and terminal artifact storage. | Completed |

---

## 3. Task 1: Essential Helm Commands Reference

Detailed command logs and terminal outputs are documented in [01-what-is-helm/README.md](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-15-helm/01-what-is-helm/README.md).

```bash
# 1. Chart Creation
helm create my-chart

# 2. Chart Validation & Local Rendering
helm lint ./my-chart
helm template my-release ./my-chart

# 3. Installation
helm install notes-dev ./my-chart --set replicaCount=2

# 4. Release Listing & Status
helm list -A
helm status notes-dev

# 5. Manifest & Values Inspection
helm get values notes-dev
helm get manifest notes-dev

# 6. Upgrade & Revision History
helm upgrade notes-dev ./my-chart --set replicaCount=3
helm history notes-dev

# 7. Rollback & Teardown
helm rollback notes-dev 1
helm uninstall notes-dev

# 8. Repository Management & Search
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm search repo nginx
helm search hub redis
```

---

## 4. Task 2: Helm Complete Rollback Lifecycle

The full 7-stage rollback workflow is documented in [08-rollback/README.md](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-15-helm/08-rollback/README.md).

```text
[ 1. Install (Rev 1) ] ──> [ 2. Upgrade (Rev 2) ] ──> [ 3. Verify Rev 2 ]
                                                             │
                                                             ▼
[ 7. Verify Rev 4 ] <──── [ 6. Rollback to Rev 2 ] <── [ 4. Upgrade Broken (Rev 3) ]
                                                             │
                                                             ▼
                                                    [ 5. Verify Rev 3 Failure ]
```

### Execution Log Summary:
1. **Install (`Rev 1`)**: `helm install rollback-demo ./app-chart --set replicaCount=1`
2. **Upgrade (`Rev 2`)**: `helm upgrade rollback-demo ./app-chart --set replicaCount=2 --set image.tag="1.25"`
3. **Verify (`Rev 2`)**: Verified 2 running pods; `helm history` reports Revision 2 `deployed`.
4. **Upgrade Broken (`Rev 3`)**: `helm upgrade rollback-demo ./app-chart --set image.tag="doesnotexist-tag"`
5. **Verify Failure**: New pods enter `ImagePullBackOff` while old pods attempt termination.
6. **Rollback**: `helm rollback rollback-demo 2` executed in under 2 seconds.
7. **Verify Recovery**: Kubernetes restores healthy `nginx:1.25` pods with 2 replicas; `helm history` creates Revision 4 (`Rollback to 2`).

---

## 5. Task 3: Mini Project - Notes App Helm Packaging

Full details and instructions in [mini-project/README.md](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-15-helm/mini-project/README.md).

### Architecture & Structure:
```text
mini-project/notes-chart/
├── Chart.yaml              # Chart metadata (v0.1.0, appVersion: 1.0)
├── values.yaml             # Dev defaults (1 replica, nginx:1.24, env: development)
├── values-prod.yaml        # Prod overrides (3 replicas, nginx:1.25, env: production)
└── templates/
    ├── configmap.yaml      # Dynamic ConfigMap injecting APP_NAME and ENVIRONMENT
    ├── deployment.yaml     # Parametric Deployment with envFrom configMapRef
    └── service.yaml        # NodePort service exposed on port 30090
```

### Verification Highlights:
- **Linting**: `helm lint notes-chart` $\to$ `1 chart(s) linted, 0 chart(s) failed`.
- **Local Rendering**: `helm template notes-dev notes-chart` correctly parameterized all `{{ .Release.Name }}` labels.
- **Development Deployment**:
  ```bash
  $ helm install notes-dev notes-chart
  $ kubectl get pods -l app=notes-dev
  NAME                            READY   STATUS    RESTARTS   AGE
  notes-dev-deploy-74b88bf9c-6x2  1/1     Running   0          30s
  ```
- **Production Upgrade**:
  ```bash
  $ helm upgrade notes-dev notes-chart -f notes-chart/values-prod.yaml
  $ kubectl get pods -l app=notes-dev
  NAME                            READY   STATUS    RESTARTS   AGE
  notes-dev-deploy-5cb68d8ff-98x  1/1     Running   0          15s
  notes-dev-deploy-5cb68d8ff-l2k  1/1     Running   0          15s
  notes-dev-deploy-5cb68d8ff-w7m  1/1     Running   0          15s
  ```
- **Live ConfigMap Verification**:
  ```bash
  $ kubectl get configmap notes-dev-config -o yaml
  data:
    APP_NAME: notes-app
    ENVIRONMENT: production
  ```

---

## 6. Production Best Practices & Interview Essentials

1. **Atomic Deployments**: Always run production upgrades with `--atomic --timeout 120s`. If health checks or readiness probes fail, Helm automatically rolls back without human delay.
2. **Values Auditing in Git**: Avoid ad-hoc `--set` arguments in CI/CD pipelines. Maintain dedicated `values-<env>.yaml` files in version control for full auditability.
3. **Release Secrets Storage**: In Helm 3, release history is persisted as `sh.helm.release.v1.<release>.v<revision>` Kubernetes Secrets in the target namespace.
