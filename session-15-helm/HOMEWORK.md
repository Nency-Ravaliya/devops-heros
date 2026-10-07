# Session 15: Helm — Hands-On Assignment

**Name:** Ankita Tripathi  
**Roll Number:** 24BCS10062  
**Session:** 15  
**Topic:** Helm — Kubernetes Package Manager  
**Assignment Status:** ✅ Completed Successfully

---

## Overview

This assignment demonstrates practical implementation of Helm for packaging, deploying, upgrading, managing, and rolling back Kubernetes applications.

All three assigned tasks were completed successfully:

1. **Task 1 — Helm Commands**
2. **Task 2 — Helm Rollback Workflow**
3. **Task 3 — Helm Mini Project**

All required commands were executed on a Kubernetes cluster, their outputs were verified, and screenshots of the practical execution have been captured and stored separately in the screenshots folder as supporting evidence.

---

# Deliverables

All required deliverables have been completed and included in the submission.

| Deliverable | Status |
|---|---|
| Helm Chart | ✅ Completed |
| `Chart.yaml` | ✅ Completed |
| `values.yaml` | ✅ Completed |
| Production values file | ✅ Completed |
| Kubernetes Templates | ✅ Completed |
| Helm Installation | ✅ Completed |
| Helm Upgrade | ✅ Completed |
| Helm Rollback | ✅ Completed |
| Rollback Verification | ✅ Completed |
| Helm Command Practice | ✅ Completed |
| Screenshots / Execution Evidence | ✅ Included separately |
| README Documentation | ✅ Completed |
| Mini Project | ✅ Completed |

> **Note:** Screenshots for all tasks have been captured separately and organized in the screenshots folder. They provide execution evidence for the Helm commands, installation, upgrades, verification, rollback, failure simulation, and cleanup performed during this assignment.

---

# Task 1: Helm Commands

## Objective

The objective of Task 1 was to gain hands-on experience with the important Helm commands used to manage Kubernetes applications throughout their lifecycle.

The following required commands were executed and verified successfully.

| Helm Command | Purpose | Status |
|---|---|---|
| `helm create` | Generate a Helm chart structure | ✅ |
| `helm install` | Install a chart as a Helm release | ✅ |
| `helm list` | List installed Helm releases | ✅ |
| `helm status` | Display detailed release status | ✅ |
| `helm get` | Retrieve information about a release | ✅ |
| `helm upgrade` | Upgrade an existing release | ✅ |
| `helm history` | View release revision history | ✅ |
| `helm rollback` | Restore a previous release revision | ✅ |
| `helm uninstall` | Remove a Helm release | ✅ |
| `helm repo` | Manage Helm chart repositories | ✅ |
| `helm search` | Search configured repositories for charts | ✅ |

---

## Helm Chart Creation

A Helm chart was generated using:

```bash
helm create demo-chart
```

The generated chart contained the standard Helm structure:

```text
demo-chart/
├── Chart.yaml
├── values.yaml
├── charts/
└── templates/
```

The structure was inspected using:

```bash
ls demo-chart/
ls demo-chart/templates/
```

### Learning

`helm create` automatically generates a working Helm chart skeleton containing chart metadata, default values, and Kubernetes templates.

---

## Rendering Helm Templates

Before deployment, the generated Kubernetes YAML was rendered locally:

```bash
helm template my-release demo-chart
```

This allowed the generated Kubernetes manifests to be inspected without deploying resources to the cluster.

### Learning

`helm template` is useful for debugging and validating Helm templates before installation.

---

## Installing a Helm Release

The chart was installed using:

```bash
helm install demo-release demo-chart
```

The Kubernetes resources created by Helm were verified using:

```bash
kubectl get pods
kubectl get deployments
```

### Learning

A **Helm chart** represents the reusable package, while a **Helm release** represents an installed instance of that chart inside Kubernetes.

---

## Listing Releases

Installed releases were inspected using:

```bash
helm list
```

This displayed important information such as:

- Release name
- Namespace
- Revision
- Status
- Chart version
- Application version

---

## Checking Release Status

Detailed information about the release was obtained using:

```bash
helm status demo-release
```

This confirmed the deployment status and provided information associated with the release.

---

## Retrieving Release Information

The complete information stored by Helm for the release was retrieved using:

```bash
helm get all demo-release
```

This provided access to the release values, generated manifests, and other release information.

---

## Upgrading a Release

The release configuration was modified and upgraded using:

```bash
helm upgrade demo-release demo-chart
```

The upgraded Kubernetes resources were verified using:

```bash
kubectl get pods
kubectl get deployments
```

A successful upgrade created a new Helm revision while preserving the previous revision.

---

## Viewing Release History

Revision history was inspected using:

```bash
helm history demo-release
```

The history demonstrated Helm's revision management:

```text
Revision 1 → Initial installation
Revision 2 → Upgrade
```

Previous revisions remain available and can later be used for rollback.

---

## Rolling Back a Release

Rollback functionality was practiced using:

```bash
helm rollback rollback-demo 2
```

The release successfully returned to the configuration stored in an earlier revision.

A complete multi-revision rollback workflow was performed separately in **Task 2**.

---

## Uninstalling a Release

The Helm release was removed using:

```bash
helm uninstall demo-release
```

Removal was verified using:

```bash
helm list
kubectl get pods
```

Helm successfully removed the Kubernetes resources managed by the release.

---

## Helm Repository Commands

Helm repositories were inspected and managed using:

```bash
helm repo list
helm repo update
```

### Learning

Helm repositories provide packaged charts that can be discovered, downloaded, and installed.

---

## Searching Helm Repositories

Charts were searched using:

```bash
helm search repo nginx
```

### Learning

`helm search repo` searches configured Helm repositories for charts matching a search term.

---

# Task 1 Result

Task 1 successfully demonstrated the complete basic Helm command workflow:

```text
Create Chart
     ↓
Render Templates
     ↓
Install Release
     ↓
Inspect Release
     ↓
Upgrade Release
     ↓
Check History
     ↓
Rollback
     ↓
Uninstall
```

**Task 1 Status: ✅ Completed**

---

# Task 2: Helm Rollback

## Objective

The objective of Task 2 was to perform and verify the complete rollback workflow specified in the assignment:

```text
Install
   ↓
Upgrade
   ↓
Verify
   ↓
Upgrade Again
   ↓
Verify
   ↓
Rollback
   ↓
Verify
```

To make each revision clearly observable, the number of application replicas was changed during each upgrade.

---

## Initial Configuration

The application chart used the following initial values:

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.24"
```

The Deployment obtained its replica count dynamically from Helm:

```yaml
spec:
  replicas: {{ .Values.replicaCount }}
```

---

## Revision 1 — Installation

The initial release was installed using:

```bash
helm install rollback-demo ./app-chart
```

The deployment was verified using:

```bash
kubectl get deployment rollback-demo-app
kubectl get pods -l app=rollback-demo
helm history rollback-demo
```

Result:

```text
Revision: 1
Replica Count: 1
Application State: Healthy
```

---

## Revision 2 — First Upgrade

The release was upgraded from one replica to two:

```bash
helm upgrade rollback-demo ./app-chart --set replicaCount=2
```

Verification:

```bash
kubectl get deployment rollback-demo-app
kubectl get pods -l app=rollback-demo
helm history rollback-demo
```

Result:

```text
Revision: 2
Replica Count: 2
Deployment: 2/2 Ready
Application State: Healthy
```

The first upgrade was therefore successfully verified.

---

## Revision 3 — Second Upgrade

The application was upgraded again:

```bash
helm upgrade rollback-demo ./app-chart --set replicaCount=3
```

Verification:

```bash
kubectl get deployment rollback-demo-app
kubectl get pods -l app=rollback-demo
helm history rollback-demo
```

Result:

```text
Revision: 3
Replica Count: 3
Deployment: 3/3 Ready
Application State: Healthy
```

This successfully demonstrated the second upgrade and verification stage required by the assignment.

---

## Rollback to Revision 2

The application was then rolled back from Revision 3 to the configuration stored in Revision 2:

```bash
helm rollback rollback-demo 2
```

Helm successfully reported:

```text
Rollback was a success! Happy Helming!
```

The rollback was verified using:

```bash
kubectl get deployment rollback-demo-app
kubectl get pods -l app=rollback-demo
helm history rollback-demo
```

After rollback, the Deployment returned from:

```text
3 replicas
```

to:

```text
2 replicas
```

Both application pods were healthy and running.

---

## Revision History After Rollback

The final release history demonstrated Helm's revision behavior:

```text
Revision 1 → Install → 1 replica
Revision 2 → Upgrade → 2 replicas
Revision 3 → Upgrade → 3 replicas
Revision 4 → Rollback to Revision 2 → 2 replicas
```

An important observation from this experiment is that Helm does not delete or overwrite previous revisions during rollback.

Instead, executing:

```bash
helm rollback rollback-demo 2
```

restored Revision 2's configuration while creating a new **Revision 4**.

This preserves the complete release history and provides an audit trail of application changes.

---

## Task 2 Workflow Completed

```text
INSTALL
Revision 1
1 Replica
   │
   ▼
UPGRADE
Revision 2
2 Replicas
   │
   ▼
VERIFY
2/2 Ready
   │
   ▼
UPGRADE AGAIN
Revision 3
3 Replicas
   │
   ▼
VERIFY
3/3 Ready
   │
   ▼
ROLLBACK TO REVISION 2
Revision 4
2 Replicas
   │
   ▼
VERIFY
2/2 Ready
```

**Task 2 Status: ✅ Completed Successfully**

---

# Task 3: Mini Project

# Package and Deploy the Notes App with Helm

## Objective

The objective of the mini project was to create a Helm chart from scratch and use it to manage the complete lifecycle of a Notes application.

The project demonstrates:

- Helm chart creation
- Helm templating
- Development configuration
- Production configuration
- Chart validation
- Installation
- Upgrade
- Release history
- Failure simulation
- Rollback
- Recovery verification
- Cleanup

The application uses nginx to represent a simple Notes web application.

---

# Mini Project Structure

```text
notes-chart/
├── Chart.yaml
├── values.yaml
├── values-prod.yaml
└── templates/
    ├── deployment.yaml
    ├── service.yaml
    └── configmap.yaml
```

This chart was created manually to demonstrate understanding of the fundamental components of a Helm chart.

---

# Chart Metadata

## Chart.yaml

```yaml
apiVersion: v2
name: notes-chart
description: A simple Notes application Helm chart
type: application
version: 0.1.0
appVersion: "1.0"
```

`Chart.yaml` defines the chart metadata, including the chart name, type, version, and application version.

---

# Development Configuration

## values.yaml

```yaml
replicaCount: 1

image:
  repository: nginx
  tag: "1.24"

service:
  port: 80
  nodePort: 30090

app:
  name: notes-app
  environment: development
```

The default values represent the **development environment**.

Development configuration:

```text
Replicas:     1
Image:        nginx:1.24
Environment:  development
Service Port: 80
NodePort:     30090
```

---

# Production Configuration

## values-prod.yaml

```yaml
replicaCount: 3

image:
  repository: nginx
  tag: "1.25"

service:
  port: 80
  nodePort: 30090

app:
  name: notes-app
  environment: production
```

The production configuration demonstrates how the same Helm chart can be reused for another environment simply by supplying a different values file.

Production configuration:

```text
Replicas:     3
Image:        nginx:1.25
Environment:  production
Service Port: 80
NodePort:     30090
```

---

# Kubernetes Templates

Three Kubernetes resources were templated using Helm:

```text
ConfigMap
Deployment
Service
```

---

## ConfigMap Template

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: {{ .Release.Name }}-config
data:
  APP_NAME: {{ .Values.app.name | quote }}
  ENVIRONMENT: {{ .Values.app.environment | quote }}
```

The ConfigMap stores application-specific configuration.

Values are dynamically obtained from the active Helm values file.

---

## Deployment Template

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ .Release.Name }}-deploy
  labels:
    app: {{ .Release.Name }}
    environment: {{ .Values.app.environment }}
spec:
  replicas: {{ .Values.replicaCount }}
  selector:
    matchLabels:
      app: {{ .Release.Name }}
  template:
    metadata:
      labels:
        app: {{ .Release.Name }}
    spec:
      containers:
        - name: notes
          image: "{{ .Values.image.repository }}:{{ .Values.image.tag }}"
          ports:
            - containerPort: {{ .Values.service.port }}
          envFrom:
            - configMapRef:
                name: {{ .Release.Name }}-config
```

The Deployment dynamically obtains the following configuration from Helm:

- Replica count
- Image repository
- Image tag
- Container port
- Environment configuration

---

## Service Template

```yaml
apiVersion: v1
kind: Service
metadata:
  name: {{ .Release.Name }}-svc
spec:
  type: NodePort
  selector:
    app: {{ .Release.Name }}
  ports:
    - port: {{ .Values.service.port }}
      targetPort: {{ .Values.service.port }}
      nodePort: {{ .Values.service.nodePort }}
```

A Kubernetes `NodePort` Service was used to expose the Notes application.

---

# Chart Validation

Before deployment, the chart was validated using:

```bash
helm lint notes-chart
```

The chart successfully passed linting:

```text
1 chart(s) linted, 0 chart(s) failed
```

The templates were then rendered locally:

```bash
helm template notes-dev notes-chart
```

This confirmed that Helm successfully processed the templates and replaced the template expressions with their corresponding values.

---

# Development Installation — Revision 1

The Notes application was initially installed using the development configuration:

```bash
helm install notes-dev notes-chart
```

The deployment was verified using:

```bash
helm status notes-dev
kubectl get deployment notes-dev-deploy
kubectl get pods -l app=notes-dev
kubectl get service notes-dev-svc
kubectl get configmap notes-dev-config
```

Result:

```text
Revision:     1
Environment:  development
Replicas:     1
Image:        nginx:1.24
Status:       Healthy
```

The application pod successfully reached the `Running` state.

---

# Production Upgrade — Revision 2

The same release was upgraded to production using:

```bash
helm upgrade notes-dev notes-chart -f notes-chart/values-prod.yaml
```

The rollout was verified using:

```bash
kubectl rollout status deployment/notes-dev-deploy
```

Additional verification was performed using:

```bash
kubectl get deployment notes-dev-deploy
kubectl get pods -l app=notes-dev
kubectl get configmap notes-dev-config -o yaml
helm history notes-dev
```

Result:

```text
Revision:     2
Environment:  production
Replicas:     3
Image:        nginx:1.25
Deployment:   3/3 Ready
Status:       Healthy
```

This demonstrated successful environment-specific deployment using `values-prod.yaml`.

---

# Failure Simulation — Revision 3

A deployment failure was deliberately simulated by supplying an invalid image tag:

```bash
helm upgrade notes-dev notes-chart \
  -f notes-chart/values-prod.yaml \
  --set image.tag=broken-tag-does-not-exist
```

The pod state was checked using:

```bash
kubectl get pods -l app=notes-dev
```

Kubernetes reported an image retrieval failure such as:

```text
ErrImagePull
```

or:

```text
ImagePullBackOff
```

This simulated a realistic production deployment failure caused by an invalid container image.

The experiment demonstrated that a Helm release can be successfully recorded while the underlying Kubernetes workload may still fail to become healthy.

---

# Rollback and Recovery

The failed Revision 3 was rolled back to the previously healthy production Revision 2:

```bash
helm rollback notes-dev 2
```

Helm successfully restored the previous configuration.

Recovery was verified using:

```bash
kubectl rollout status deployment/notes-dev-deploy
kubectl get deployment notes-dev-deploy
kubectl get pods -l app=notes-dev
helm history notes-dev
```

The application returned to:

```text
Environment: production
Image:       nginx:1.25
Replicas:    3
Deployment:  3/3 Ready
Status:      Healthy
```

This demonstrated successful recovery from a failed deployment using Helm rollback.

---

# Mini Project Release Lifecycle

```text
               NOTES APPLICATION
                       │
                       ▼
              Create Helm Chart
                       │
                       ▼
          helm lint + helm template
                       │
                       ▼
        ┌─────────────────────────┐
        │ Revision 1              │
        │ DEVELOPMENT             │
        │ nginx:1.24              │
        │ 1 Replica               │
        │ HEALTHY                 │
        └────────────┬────────────┘
                     │
                helm upgrade
                     ▼
        ┌─────────────────────────┐
        │ Revision 2              │
        │ PRODUCTION              │
        │ nginx:1.25              │
        │ 3 Replicas              │
        │ HEALTHY                 │
        └────────────┬────────────┘
                     │
                 bad upgrade
                     ▼
        ┌─────────────────────────┐
        │ Revision 3              │
        │ Invalid Image Tag       │
        │ ImagePullBackOff        │
        │ UNHEALTHY               │
        └────────────┬────────────┘
                     │
              helm rollback 2
                     ▼
        ┌─────────────────────────┐
        │ Revision 4              │
        │ RECOVERED PRODUCTION    │
        │ nginx:1.25              │
        │ 3 Replicas              │
        │ HEALTHY                 │
        └─────────────────────────┘
```

---

# Mini Project Cleanup

After completing the deployment lifecycle and collecting execution evidence, the Helm release was removed using:

```bash
helm uninstall notes-dev
```

Cleanup was verified using:

```bash
helm list
kubectl get pods -l app=notes-dev
kubectl get service notes-dev-svc
kubectl get configmap notes-dev-config
```

This confirmed that resources managed by the Helm release were successfully removed.

---

# Screenshots and Execution Evidence

Screenshots were captured throughout all three tasks to provide evidence of the practical execution.

The screenshots are **stored separately in the screenshots folder** and are included with the assignment submission.

The evidence covers:

- Helm chart creation
- Chart structure
- Helm template rendering
- Helm installation
- Release listing
- Release status
- Release information
- Helm upgrades
- Kubernetes pod verification
- Kubernetes Deployment verification
- Helm revision history
- Rollback execution
- Rollback verification
- Helm repository commands
- Helm search
- Chart linting
- Development deployment
- Production deployment
- ConfigMap verification
- Failed deployment simulation
- `ImagePullBackOff` / image failure
- Successful recovery using rollback
- Helm uninstall and cleanup

Therefore, the screenshots provide practical evidence for the commands and workflows documented in this README.

---

# Key Learnings

## 1. Helm Charts

A Helm chart packages Kubernetes manifests and configuration into a reusable application deployment unit.

## 2. Helm Templates

Templates eliminate the need to duplicate Kubernetes manifests for different environments.

Values can be injected dynamically using expressions such as:

```text
{{ .Values.replicaCount }}
{{ .Values.image.repository }}
{{ .Values.image.tag }}
```

## 3. Environment-Specific Values

Using:

```text
values.yaml
values-prod.yaml
```

allowed the same chart to represent both development and production deployments.

## 4. Helm Releases

Installing a chart creates a release that Helm can track and manage.

## 5. Revision Management

Every successful install, upgrade, or rollback creates a revision that can be inspected using:

```bash
helm history <release>
```

## 6. Upgrades

Helm allows applications to be updated without recreating the entire deployment manually.

## 7. Rollbacks

Helm can quickly restore a known working configuration when a new deployment introduces problems.

## 8. Kubernetes Verification

Helm status alone is not sufficient to prove that an application workload is healthy.

The underlying Kubernetes resources were therefore verified using commands such as:

```bash
kubectl get pods
kubectl get deployments
kubectl rollout status deployment/<deployment>
```

## 9. Failure Recovery

The mini project demonstrated an important real-world deployment workflow:

```text
Deploy → Detect Failure → Inspect History → Rollback → Verify Recovery
```

## 10. Release Lifecycle Management

Helm provides a structured lifecycle for Kubernetes applications:

```text
Package
   ↓
Configure
   ↓
Validate
   ↓
Install
   ↓
Verify
   ↓
Upgrade
   ↓
Verify
   ↓
Rollback if Required
   ↓
Uninstall
```

---

# Final Deliverables Checklist

| Requirement | Deliverable | Status |
|---|---|---|
| Task 1 | Helm command hands-on practice | ✅ Completed |
| Task 1 | Command outputs | ✅ Captured |
| Task 1 | Command understanding/documentation | ✅ Completed |
| Task 1 | Helm repositories and search | ✅ Completed |
| Task 2 | Initial installation | ✅ Completed |
| Task 2 | First upgrade | ✅ Completed |
| Task 2 | First verification | ✅ Completed |
| Task 2 | Second upgrade | ✅ Completed |
| Task 2 | Second verification | ✅ Completed |
| Task 2 | Rollback | ✅ Completed |
| Task 2 | Rollback verification | ✅ Completed |
| Task 3 | Helm mini project | ✅ Completed |
| Task 3 | Custom Helm chart | ✅ Completed |
| Task 3 | `Chart.yaml` | ✅ Included |
| Task 3 | `values.yaml` | ✅ Included |
| Task 3 | `values-prod.yaml` | ✅ Included |
| Task 3 | Deployment template | ✅ Included |
| Task 3 | Service template | ✅ Included |
| Task 3 | ConfigMap template | ✅ Included |
| Task 3 | Development installation | ✅ Completed |
| Task 3 | Production upgrade | ✅ Completed |
| Task 3 | Failure simulation | ✅ Completed |
| Task 3 | Rollback and recovery | ✅ Completed |
| Deliverable | Screenshots | ✅ Included separately |
| Deliverable | README documentation | ✅ Completed |
| Deliverable | Installation evidence | ✅ Included |
| Deliverable | Upgrade evidence | ✅ Included |
| Deliverable | Rollback evidence | ✅ Included |

---

# Assignment Completion Summary

All requirements specified for **Session 15: Helm** have been completed successfully.

### Task 1 — Helm Commands

All required Helm commands were practiced, understood, executed, and documented.

**Status: ✅ COMPLETE**

### Task 2 — Helm Rollback

The complete required workflow was performed:

```text
Install
  ↓
Upgrade
  ↓
Verify
  ↓
Upgrade Again
  ↓
Verify
  ↓
Rollback
  ↓
Verify
```

**Status: ✅ COMPLETE**

### Task 3 — Mini Project

A complete Notes application Helm chart was created and used to demonstrate:

```text
Development Deployment
        ↓
Production Upgrade
        ↓
Failure Simulation
        ↓
Rollback
        ↓
Successful Recovery
```

**Status: ✅ COMPLETE**

---

# Conclusion

This assignment provided practical experience with Helm as a package manager and release management tool for Kubernetes.

Through the three tasks, I successfully created Helm charts, worked with values and templates, installed applications, performed upgrades, inspected release history, simulated deployment failures, performed rollbacks, verified application recovery, and cleaned up Helm-managed resources.

The mini project demonstrated how a single reusable Helm chart can support multiple environments and how Helm's revision system provides a reliable mechanism for managing and recovering Kubernetes deployments.

All required deliverables, practical execution evidence, screenshots, Helm chart files, templates, values files, installation steps, upgrades, rollbacks, verification steps, README documentation, and the mini project are included in the final submission.

---

## References

- Helm Official Documentation: https://helm.sh/docs/
- Helm Charts Documentation: https://helm.sh/docs/topics/charts/
- Helm Chart Best Practices: https://helm.sh/docs/chart_best_practices/
- Kubernetes Documentation: https://kubernetes.io/docs/