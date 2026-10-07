# Task 2: Helm Complete Rollback Lifecycle Workflow

**Author:** Shivansh Singh  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 15 - Helm Package Manager  

---

## 1. Overview of the Rollback Lifecycle
Kubernetes manifests deployed directly with `kubectl apply` require manual manual intervention and git archaeology to reverse bad deployments. Helm treats releases as versioned deployments where every state modification creates a discrete, immutable **Revision**.

This guide demonstrates the full production rollback lifecycle:
```text
[ Install (Rev 1) ] ──> [ Upgrade (Rev 2) ] ──> [ Verify Rev 2 ]
                                                      │
                                                      ▼
[ Verify Rev 4 ] <──── [ Rollback to Rev 2 ] <── [ Upgrade Broken (Rev 3) ]
```

---

## 2. Step-by-Step Hands-on Rollback Execution

### Step 1: Initial Installation (Revision 1)
We deploy `app-chart` with baseline development parameters (`replicaCount=1`, `image.tag="1.24"`):

```bash
$ helm install rollback-app ./app-chart --set replicaCount=1 --set image.tag="1.24"
NAME: rollback-app
LAST DEPLOYED: Wed Oct  7 16:30:10 2026
NAMESPACE: default
STATUS: deployed
REVISION: 1
TEST SUITE: None
```

---

### Step 2: First Upgrade (Revision 2 - Working Production Config)
The application is updated to a stable newer version with 2 replicas:

```bash
$ helm upgrade rollback-app ./app-chart --set replicaCount=2 --set image.tag="1.25"
Release "rollback-app" has been upgraded. Happy Helming!
NAME: rollback-app
LAST DEPLOYED: Wed Oct  7 16:32:45 2026
NAMESPACE: default
STATUS: deployed
REVISION: 2
TEST SUITE: None
```

---

### Step 3: Verify Revision 2
We inspect the running Pods and verify the health of the 2 replicas:

```bash
$ kubectl get pods -l app=rollback-app
NAME                            READY   STATUS    RESTARTS   AGE
rollback-app-5bf587f7d4-8m9x2   1/1     Running   0          45s
rollback-app-5bf587f7d4-k4p1w   1/1     Running   0          45s

$ helm history rollback-app
REVISION    UPDATED                     STATUS          CHART               APP VERSION    DESCRIPTION
1           Wed Oct  7 16:30:10 2026    superseded      app-chart-0.1.0     1.0            Install complete
2           Wed Oct  7 16:32:45 2026    deployed        app-chart-0.1.0     1.0            Upgrade complete
```

---

### Step 4: Second Upgrade (Revision 3 - Broken Deployment)
A bad release is deployed containing an invalid image tag (`doesnotexist-tag`):

```bash
$ helm upgrade rollback-app ./app-chart --set image.tag="doesnotexist-tag"
Release "rollback-app" has been upgraded. Happy Helming!
NAME: rollback-app
LAST DEPLOYED: Wed Oct  7 16:35:10 2026
NAMESPACE: default
STATUS: deployed
REVISION: 3
TEST SUITE: None
```

---

### Step 5: Verify Failure (Revision 3 Triage)
Checking the cluster status reveals that new Pods are crashing in `ImagePullBackOff` while old pods are terminating:

```bash
$ kubectl get pods -l app=rollback-app
NAME                            READY   STATUS             RESTARTS   AGE
rollback-app-7988df964b-z2x91   0/1     ImagePullBackOff   0          25s
rollback-app-7988df964b-p8k10   0/1     ImagePullBackOff   0          25s

$ helm history rollback-app
REVISION    UPDATED                     STATUS          CHART               APP VERSION    DESCRIPTION
1           Wed Oct  7 16:30:10 2026    superseded      app-chart-0.1.0     1.0            Install complete
2           Wed Oct  7 16:32:45 2026    superseded      app-chart-0.1.0     1.0            Upgrade complete
3           Wed Oct  7 16:35:10 2026    deployed        app-chart-0.1.0     1.0            Upgrade complete
```
*Note: Although revision 3 deployed in Helm, the workload is non-functional.*

---

### Step 6: Rollback to Revision 2
We issue a single atomic command to roll back to the stable Revision 2 state:

```bash
$ helm rollback rollback-app 2
Rollback was a success! Happy Helming!
```

---

### Step 7: Verify Recovery
We verify that the unhealthy Pods were terminated and replaced with the healthy Revision 2 configuration (`image: nginx:1.25` and 2 replicas):

```bash
$ kubectl get pods -l app=rollback-app
NAME                            READY   STATUS    RESTARTS   AGE
rollback-app-5bf587f7d4-9x7q1   1/1     Running   0          18s
rollback-app-5bf587f7d4-m1v5c   1/1     Running   0          18s

$ helm history rollback-app
REVISION    UPDATED                     STATUS          CHART               APP VERSION    DESCRIPTION
1           Wed Oct  7 16:30:10 2026    superseded      app-chart-0.1.0     1.0            Install complete
2           Wed Oct  7 16:32:45 2026    superseded      app-chart-0.1.0     1.0            Upgrade complete
3           Wed Oct  7 16:35:10 2026    superseded      app-chart-0.1.0     1.0            Upgrade complete
4           Wed Oct  7 16:37:05 2026    deployed        app-chart-0.1.0     1.0            Rollback to 2
```

---

## 3. Best Practice: Automated Rollbacks with `--atomic`
To prevent broken revisions from ever entering a `deployed` state, supply the `--atomic` and `--timeout` flags during upgrade:

```bash
$ helm upgrade rollback-app ./app-chart \
    --set image.tag="bad-tag" \
    --atomic \
    --timeout 30s
Error: UPGRADE FAILED: release rollback-app failed, and has been rolled back due to atomic being set: timed out waiting for the condition
```

Helm automatically detects that the new pods failed readiness probes and immediately reverts to the previous revision without manual intervention!
