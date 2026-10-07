# Task 1: Essential Helm Commands Deep Dive

**Author:** Shivansh Singh  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 15 - Helm Package Manager  

---

## 1. Overview of Helm Architecture
Helm manages Kubernetes applications through **Charts** (packages of pre-configured Kubernetes resources), **Releases** (running instances of charts in a Kubernetes cluster), and **Values** (configuration injection). In Helm 3, release state is stored securely as encrypted Kubernetes Secrets in the target namespace without requiring a cluster-side Tiller daemon.

```text
[ Developer CLI ] ──(Helm 3 Client)──> [ Kubeconfig API ] ──> [ K8s API Server ]
        │                                                           │
        ├── Reads Chart Templates + Values                          ├── Generates Pods/Services
        └── Evaluates Go Template Engine locally                    └── Persists Release Secrets
```

---

## 2. Command-by-Command Hands-on Reference

### 2.1 `helm create`
**Purpose:** Scaffolds a new chart directory containing the standard Helm structure (`Chart.yaml`, `values.yaml`, `templates/`, `templates/_helpers.tpl`, and tests).

```bash
$ helm create devops-app
Creating devops-app

$ tree devops-app/
devops-app/
├── Chart.yaml
├── charts/
├── templates/
│   ├── NOTES.txt
│   ├── _helpers.tpl
│   ├── deployment.yaml
│   ├── hpa.yaml
│   ├── ingress.yaml
│   ├── service.yaml
│   ├── serviceaccount.yaml
│   └── tests/
│       └── test-connection.yaml
└── values.yaml
```

---

### 2.2 `helm install`
**Purpose:** Deploys a chart release onto the Kubernetes cluster. Supports custom value injection via `--set` or `-f values.yaml`.

```bash
$ helm install my-notes ./devops-app --set replicaCount=2 --set service.type=ClusterIP
NAME: my-notes
LAST DEPLOYED: Wed Oct  7 16:15:20 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
1. Get the application URL by running these commands:
  export POD_NAME=$(kubectl get pods --namespace default -l "app.kubernetes.io/name=devops-app" -o jsonpath="{.items[0].metadata.name}")
  kubectl --namespace default port-forward $POD_NAME 8080:80
```

---

### 2.3 `helm list`
**Purpose:** Lists all releases deployed across the current namespace (or across all namespaces using `-A`).

```bash
$ helm list -A
NAME        NAMESPACE   REVISION    UPDATED                                 STATUS      CHART               APP VERSION
my-notes    default     1           2026-10-07 16:15:20.312984 +0530 IST    deployed    devops-app-0.1.0    1.16.0
traefik     kube-system 1           2026-09-25 10:12:04.184912 +0530 IST    deployed    traefik-26.0.0      v2.10.7
```

---

### 2.4 `helm status`
**Purpose:** Displays the status, metadata, revision, and computed resources for an existing release.

```bash
$ helm status my-notes
NAME: my-notes
LAST DEPLOYED: Wed Oct  7 16:15:20 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
RESOURCES:
==> v1/Deployment
NAME              READY  UP-TO-DATE  AVAILABLE  AGE
my-notes-devops   2/2    2           2          1m

==> v1/Service
NAME              TYPE       CLUSTER-IP      EXTERNAL-IP  PORT(S)
my-notes-devops   ClusterIP  10.108.210.45   <none>       80/TCP
```

---

### 2.5 `helm get`
**Purpose:** Inspects deployed release components from Kubernetes secrets (`values`, `manifest`, `hooks`, or `all`).

```bash
# 1. Fetch user-supplied custom values
$ helm get values my-notes
USER-SUPPLIED VALUES:
replicaCount: 2
service:
  type: ClusterIP

# 2. Fetch the fully rendered Kubernetes manifests
$ helm get manifest my-notes | grep -E "kind:|name:"
kind: ServiceAccount
    name: my-notes-devops-app
kind: Service
  name: my-notes-devops-app
kind: Deployment
  name: my-notes-devops-app

# 3. Fetch all release details
$ helm get all my-notes
```

---

### 2.6 `helm upgrade`
**Purpose:** Upgrades a release to a new chart version or updates configuration values, incrementing the release revision number.

```bash
$ helm upgrade my-notes ./devops-app --set replicaCount=3 --set image.tag="1.25"
Release "my-notes" has been upgraded. Happy Helming!
NAME: my-notes
LAST DEPLOYED: Wed Oct  7 16:18:40 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None
```

---

### 2.7 `helm history`
**Purpose:** Displays historical revisions for a release, showing timestamp, status (`superseded`, `deployed`), and upgrade descriptions.

```bash
$ helm history my-notes
REVISION    UPDATED                     STATUS          CHART               APP VERSION    DESCRIPTION
1           Wed Oct  7 16:15:20 2026    superseded      devops-app-0.1.0    1.16.0         Install complete
2           Wed Oct  7 16:18:40 2026    deployed        devops-app-0.1.0    1.16.0         Upgrade complete
```

---

### 2.8 `helm rollback`
**Purpose:** Rolls back a release to a previously deployed revision number in seconds.

```bash
$ helm rollback my-notes 1
Rollback was a success! Happy Helming!

$ helm history my-notes
REVISION    UPDATED                     STATUS          CHART               APP VERSION    DESCRIPTION
1           Wed Oct  7 16:15:20 2026    superseded      devops-app-0.1.0    1.16.0         Install complete
2           Wed Oct  7 16:18:40 2026    superseded      devops-app-0.1.0    1.16.0         Upgrade complete
3           Wed Oct  7 16:21:12 2026    deployed        devops-app-0.1.0    1.16.0         Rollback to 1
```

---

### 2.9 `helm uninstall`
**Purpose:** Removes all Kubernetes resources associated with the release and cleans up the release history secrets.

```bash
$ helm uninstall my-notes
release "my-notes" uninstalled

$ helm list
NAME    NAMESPACE    REVISION    UPDATED    STATUS    CHART    APP VERSION
```

---

### 2.10 `helm repo`
**Purpose:** Manages external Helm chart repositories (`add`, `list`, `update`, `remove`).

```bash
# Add public chart repositories
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories

$ helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
"ingress-nginx" has been added to your repositories

# List configured repositories
$ helm repo list
NAME            URL
bitnami         https://charts.bitnami.com/bitnami
ingress-nginx   https://kubernetes.github.io/ingress-nginx

# Update local repo cache with latest versions
$ helm repo update
Hang tight while we grab the latest from your chart repositories...
...Successfully got an update from the "bitnami" chart repository
...Successfully got an update from the "ingress-nginx" chart repository
Update Complete. ⎈Happy Helming!⎈
```

---

### 2.11 `helm search`
**Purpose:** Searches for charts either locally across cached repositories (`helm search repo`) or globally on Artifact Hub (`helm search hub`).

```bash
# Search within local cached repositories
$ helm search repo nginx
NAME                            CHART VERSION   APP VERSION     DESCRIPTION
bitnami/nginx                   18.1.5          1.27.1          NGINX Open Source is a web server that can also...
ingress-nginx/ingress-nginx     4.11.2          1.11.2          Ingress controller for Kubernetes using NGINX...

# Search globally on Artifact Hub
$ helm search hub redis
URL                                                     CHART VERSION   APP VERSION     DESCRIPTION
https://artifacthub.io/packages/helm/bitnami/redis      19.6.4          7.4.0           Redis(R) is an open source, advanced key-value...
https://artifacthub.io/packages/helm/ot-helm/redis-o... 0.15.2          v0.15.2         A Helm chart for Redis Operator
```

---

## 3. Summary of Commands

| Command | Action | Key Flags |
| :--- | :--- | :--- |
| `helm create <name>` | Scaffolds chart directory | N/A |
| `helm install <rel> <chart>` | Installs release | `-f <file>`, `--set <k=v>`, `--dry-run` |
| `helm list` | Shows active releases | `-A` (all namespaces), `-a` (all statuses) |
| `helm status <rel>` | Inspects live release status | `--show-resources` |
| `helm get <subcommand> <rel>` | Reads stored release specs | `values`, `manifest`, `hooks`, `all` |
| `helm upgrade <rel> <chart>` | Upgrades to new version | `--atomic`, `--timeout`, `--reuse-values` |
| `helm history <rel>` | Views revision changelog | `--max <n>` |
| `helm rollback <rel> <rev>` | Rolls back to revision number | `--cleanup-on-fail`, `--wait` |
| `helm uninstall <rel>` | Deletes all release resources | `--keep-history` |
| `helm repo <add/list/update>` | Manages remote repositories | `add`, `list`, `update`, `remove` |
| `helm search <repo/hub>` | Searches for packages | `--regexp`, `-l` (show versions) |
