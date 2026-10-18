# Session 10: Kubernetes Pods, ReplicaSets and Deployments

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

| Task | Topic | Section |
|---|---|---|
| 1 | The 4 deployment strategies: Rolling Update, Blue-Green, Canary, Recreate | [Task 1](#task-1-deployment-strategies) |
| 2 | Pod lifecycle: 12 YAML files, each applied, inspected and explained | [Task 2](#task-2-pod-lifecycle) |

**Environment:** Minikube (Docker driver), Kubernetes v1.37.0, `kubectl` v1.37.0. All output is real, copied from the terminal. The manifests of Task 1 are mine (in the folders next to this file). The twelve Pod manifests of Task 2 are the exercise files from the course repository, applied unchanged.

> **Screenshots:** the homework asks to add a screenshot of each result to the README. Instead of pictures of a terminal, every result is included as real text output (the exact `kubectl` commands and their output), which carries the same evidence and can be searched and copied.

### Background

| Object | Role |
|---|---|
| **Pod** | Smallest deployable unit: one or more containers with a shared network and volumes. Not self-healing on its own. |
| **ReplicaSet** | Keeps a stated number of identical Pods running (recreates any that die). |
| **Deployment** | Manages ReplicaSets and gives **rolling updates, rollbacks and scaling**. Every new Pod template creates a new ReplicaSet. |

The strategies below all use the tiny `hashicorp/http-echo` image, which answers every request with a fixed text. That lets me **see which version answered** each request. `probe.sh` (in this folder) is a small helper that sends requests from a Pod inside the cluster, twice a second, and prints the answers (or `FAIL`).

---

## Task 1: Deployment strategies

First, a client Pod inside the cluster to send requests from:

_A busybox Pod used only to send test requests (wget) to the Services._

```console
$ kubectl run client --image=busybox:1.36 --restart=Never -- sleep 7200 && kubectl wait --for=condition=Ready pod/client --timeout=120s
pod/client created
pod/client condition met
```

### 1. Rolling Update

Replace Pods gradually: start new ones, wait until they are ready, stop old ones. The app stays up. The control knobs are in the manifest:

_`maxSurge: 1` allows one extra Pod during the update; `maxUnavailable: 0` means capacity never drops below the 4 wanted replicas._

```console
$ grep -B1 -A4 "strategy:" 01-rolling-update/deployment-v1.yaml; grep minReadySeconds 01-rolling-update/deployment-v1.yaml
      app: app-rolling
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1 # at most 1 extra Pod above the 4 wanted
      maxUnavailable: 0 # never fewer than 4 ready Pods
  minReadySeconds: 4 # slows the rollout a little so the steps are easy to observe
```

_**Create the Deployment** (version 1, 4 replicas) and its Service._

```console
$ kubectl apply -f 01-rolling-update/deployment-v1.yaml -f 01-rolling-update/service.yaml && kubectl rollout status deployment/app-rolling --timeout=180s
deployment.apps/app-rolling created
service/app-rolling created
Waiting for deployment "app-rolling" rollout to finish: 0 of 4 updated replicas are available...
Waiting for deployment "app-rolling" rollout to finish: 0 of 4 updated replicas are available...
Waiting for deployment "app-rolling" rollout to finish: 0 of 4 updated replicas are available...
Waiting for deployment "app-rolling" rollout to finish: 0 of 4 updated replicas are available...
Waiting for deployment "app-rolling" rollout to finish: 0 of 4 updated replicas are available...
deployment "app-rolling" successfully rolled out
```

_One Deployment, one ReplicaSet, four Pods labelled version=v1._

```console
$ kubectl get deployment,rs,pods -l app=app-rolling -L version
NAME                          READY   UP-TO-DATE   AVAILABLE   AGE   VERSION
deployment.apps/app-rolling   4/4     4            4           6s    

NAME                                     DESIRED   CURRENT   READY   AGE   VERSION
replicaset.apps/app-rolling-7d596f5f8b   4         4         4       6s    v1

NAME                               READY   STATUS    RESTARTS   AGE   VERSION
pod/app-rolling-7d596f5f8b-7hqms   1/1     Running   0          6s    v1
pod/app-rolling-7d596f5f8b-7vmxg   1/1     Running   0          6s    v1
pod/app-rolling-7d596f5f8b-w6n2n   1/1     Running   0          6s    v1
pod/app-rolling-7d596f5f8b-x9lkw   1/1     Running   0          6s    v1
```

_Twelve requests to the Service: every answer is version-1._

```console
$ kubectl exec -i client -- sh -s http://app-rolling 12 0 < probe.sh | sort | uniq -c
     12 version-1
```

_**Perform the update** (apply version 2) while the probe keeps sending requests. Both versions answered during the rollout, and there is **no FAIL line**: zero downtime._

```console
$ kubectl exec -i client -- sh -s http://app-rolling 70 < probe.sh > /tmp/probe-roll.txt & sleep 2; kubectl apply -f 01-rolling-update/deployment-v2.yaml; kubectl rollout status deployment/app-rolling --timeout=180s; wait; echo "answers received during the whole update:"; sort /tmp/probe-roll.txt | uniq -c
deployment.apps/app-rolling configured
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
deployment "app-rolling" successfully rolled out
answers received during the whole update:
     27 version-1
     43 version-2
```

_**Verify old and new Pods.** The old ReplicaSet is scaled to 0 (kept for rollback), the new one owns 4 Pods labelled version=v2._

```console
$ kubectl get rs,pods -l app=app-rolling -L version
NAME                                     DESIRED   CURRENT   READY   AGE   VERSION
replicaset.apps/app-rolling-7d596f5f8b   0         0         0       42s   v1
replicaset.apps/app-rolling-bd9468cd6    4         4         4       33s   v2

NAME                              READY   STATUS    RESTARTS   AGE   VERSION
pod/app-rolling-bd9468cd6-2lhmv   1/1     Running   0          33s   v2
pod/app-rolling-bd9468cd6-mnll4   1/1     Running   0          16s   v2
pod/app-rolling-bd9468cd6-p8bl2   1/1     Running   0          26s   v2
pod/app-rolling-bd9468cd6-rpvkc   1/1     Running   0          21s   v2
```

_Each template change is a revision._

```console
$ kubectl rollout history deployment/app-rolling
deployment.apps/app-rolling 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

_Rollback: the Deployment moves back to the previous ReplicaSet, and the answers are version-1 again._

```console
$ kubectl rollout undo deployment/app-rolling && kubectl rollout status deployment/app-rolling --timeout=180s && kubectl exec -i client -- sh -s http://app-rolling 8 0 < probe.sh | sort | uniq -c
Warning: resource deployments/app-rolling was previously managed with 'kubectl apply'. Rolling back will not update the kubectl.kubernetes.io/last-applied-configuration annotation, which may cause unexpected behavior on future 'kubectl apply' operations. Consider using 'kubectl apply' with your previous configuration file instead.
deployment.apps/app-rolling rolled back
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "app-rolling" rollout to finish: 1 old replicas are pending termination...
deployment "app-rolling" successfully rolled out
      8 version-1
```

_Cleanup._

```console
$ kubectl delete -f 01-rolling-update/deployment-v1.yaml -f 01-rolling-update/service.yaml
deployment.apps "app-rolling" deleted from default namespace
service "app-rolling" deleted from default namespace
```

### 2. Blue-Green Deployment

Run **two complete environments**: blue (live) and green (new). Traffic moves from one to the other in one step by changing the **Service selector**, and going back is just as fast.

_**Create the Blue version** and a Service whose selector points at `version: blue`._

```console
$ kubectl apply -f 02-blue-green/deployment-blue.yaml -f 02-blue-green/service.yaml && kubectl rollout status deployment/app-blue --timeout=180s
deployment.apps/app-blue created
service/app-bg created
Waiting for deployment "app-blue" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "app-blue" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "app-blue" rollout to finish: 2 of 3 updated replicas are available...
deployment "app-blue" successfully rolled out
```

_All traffic goes to BLUE._

```console
$ kubectl exec -i client -- sh -s http://app-bg 10 0 < probe.sh | sort | uniq -c
     10 BLUE (current version)
```

_**Create the Green version** next to blue. Six Pods run, but the Service still selects blue only._

```console
$ kubectl apply -f 02-blue-green/deployment-green.yaml && kubectl rollout status deployment/app-green --timeout=180s && kubectl get pods -l app=bg -L version
deployment.apps/app-green created
Waiting for deployment "app-green" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "app-green" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "app-green" rollout to finish: 2 of 3 updated replicas are available...
deployment "app-green" successfully rolled out
NAME                         READY   STATUS    RESTARTS   AGE   VERSION
app-blue-7cc7c95466-gl9z2    1/1     Running   0          4s    blue
app-blue-7cc7c95466-nwj5x    1/1     Running   0          4s    blue
app-blue-7cc7c95466-t5b55    1/1     Running   0          4s    blue
app-green-7b84495985-hw4g5   1/1     Running   0          2s    green
app-green-7b84495985-mvgdm   1/1     Running   0          2s    green
app-green-7b84495985-pt2cr   1/1     Running   0          2s    green
```

_Users still only see BLUE: green is deployed but receives no traffic, so it can be tested safely first._

```console
$ kubectl get svc app-bg -o jsonpath="selector={.spec.selector}{\"\\n\"}"; kubectl get endpoints app-bg; kubectl exec -i client -- sh -s http://app-bg 6 0 < probe.sh | sort | uniq -c
selector={"app":"bg","version":"blue"}
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME     ENDPOINTS                                               AGE
app-bg   10.244.0.108:5678,10.244.0.109:5678,10.244.0.110:5678   4s
      6 BLUE (current version)
```

_**Switch traffic**: one patch changes the Service selector from blue to green._

```console
$ kubectl patch service app-bg -p "{\"spec\":{\"selector\":{\"app\":\"bg\",\"version\":\"green\"}}}"
service/app-bg patched
```

_**Verify the active version**: every answer is now GREEN._

```console
$ kubectl get svc app-bg -o jsonpath="selector={.spec.selector}{\"\\n\"}"; kubectl exec -i client -- sh -s http://app-bg 10 0 < probe.sh | sort | uniq -c
selector={"app":"bg","version":"green"}
     10 GREEN (new version)
```

_Instant rollback: patch the selector back to blue and the old version is live again (it was never stopped)._

```console
$ kubectl patch service app-bg -p "{\"spec\":{\"selector\":{\"app\":\"bg\",\"version\":\"blue\"}}}" && kubectl exec -i client -- sh -s http://app-bg 6 0 < probe.sh | sort | uniq -c
service/app-bg patched
      6 BLUE (current version)
```

_Cleanup._

```console
$ kubectl delete -f 02-blue-green/deployment-blue.yaml -f 02-blue-green/deployment-green.yaml -f 02-blue-green/service.yaml
deployment.apps "app-blue" deleted from default namespace
deployment.apps "app-green" deleted from default namespace
service "app-bg" deleted from default namespace
```

### 3. Canary Deployment

Send a **small share of traffic** to the new version first. One Service selects both tracks, so the split follows the number of Pods behind each track.

_**Deploy the stable version** (4 replicas)._

```console
$ kubectl apply -f 03-canary/deployment-stable.yaml -f 03-canary/service.yaml && kubectl rollout status deployment/app-stable --timeout=180s
deployment.apps/app-stable created
service/app-canary created
Waiting for deployment "app-stable" rollout to finish: 0 of 4 updated replicas are available...
Waiting for deployment "app-stable" rollout to finish: 1 of 4 updated replicas are available...
Waiting for deployment "app-stable" rollout to finish: 2 of 4 updated replicas are available...
Waiting for deployment "app-stable" rollout to finish: 3 of 4 updated replicas are available...
deployment "app-stable" successfully rolled out
```

_**Deploy the canary version** (1 replica): 4 stable + 1 canary = 1 Pod in 5 is the canary, about 20%._

```console
$ kubectl apply -f 03-canary/deployment-canary.yaml && kubectl rollout status deployment/app-canary --timeout=180s && kubectl get pods -l app=canary-demo -L track
deployment.apps/app-canary created
Waiting for deployment "app-canary" rollout to finish: 0 of 1 updated replicas are available...
deployment "app-canary" successfully rolled out
NAME                          READY   STATUS    RESTARTS   AGE   TRACK
app-canary-88dbdf986-dgs8q    1/1     Running   0          1s    canary
app-stable-78748f65cb-cndpt   1/1     Running   0          3s    stable
app-stable-78748f65cb-h2rvb   1/1     Running   0          3s    stable
app-stable-78748f65cb-m54h9   1/1     Running   0          3s    stable
app-stable-78748f65cb-qw4qb   1/1     Running   0          3s    stable
```

_The Service has five endpoints: both versions are behind it._

```console
$ kubectl get endpoints app-canary
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME         ENDPOINTS                                                           AGE
app-canary   10.244.0.114:5678,10.244.0.115:5678,10.244.0.116:5678 + 2 more...   4s
```

_**Route a small percentage of traffic to the canary.** 50 requests: roughly one fifth are answered by CANARY (kube-proxy picks Pods randomly, so the exact count varies)._

```console
$ kubectl exec -i client -- sh -s http://app-canary 50 0 < probe.sh | sort | uniq -c
     12 CANARY
     38 STABLE
```

_Promote gradually: with 3 canary and 1 stable Pod, about 75% of the traffic goes to the new version._

```console
$ kubectl scale deployment/app-canary --replicas=3 && kubectl scale deployment/app-stable --replicas=1 && kubectl rollout status deployment/app-canary --timeout=180s && kubectl exec -i client -- sh -s http://app-canary 50 0 < probe.sh | sort | uniq -c
deployment.apps/app-canary scaled
deployment.apps/app-stable scaled
Waiting for deployment "app-canary" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "app-canary" rollout to finish: 2 of 3 updated replicas are available...
deployment "app-canary" successfully rolled out
     34 CANARY
     16 STABLE
```

_Cleanup. (If the canary had misbehaved, scaling it to 0 would instantly remove it from the Service.)_

```console
$ kubectl delete -f 03-canary/deployment-stable.yaml -f 03-canary/deployment-canary.yaml -f 03-canary/service.yaml
deployment.apps "app-stable" deleted from default namespace
deployment.apps "app-canary" deleted from default namespace
service "app-canary" deleted from default namespace
```

### 4. Recreate Deployment

Stop **all** old Pods first, then start the new ones. It is the simplest strategy and it causes **downtime**; it is used when two versions must never run at the same time (for example a breaking database migration).

_The strategy type is Recreate._

```console
$ grep -A1 "strategy:" 04-recreate/deployment-v1.yaml
  strategy:
    type: Recreate # stop ALL old Pods first, then start the new ones
```

_**Deploy the application** (version 1, 3 replicas)._

```console
$ kubectl apply -f 04-recreate/deployment-v1.yaml -f 04-recreate/service.yaml && kubectl rollout status deployment/app-recreate --timeout=180s && kubectl get pods -l app=app-recreate -L version
deployment.apps/app-recreate created
service/app-recreate created
Waiting for deployment "app-recreate" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "app-recreate" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "app-recreate" rollout to finish: 2 of 3 updated replicas are available...
deployment "app-recreate" successfully rolled out
NAME                           READY   STATUS    RESTARTS   AGE   VERSION
app-recreate-66d7f599d-fkn4x   1/1     Running   0          2s    v1
app-recreate-66d7f599d-mwptb   1/1     Running   0          2s    v1
app-recreate-66d7f599d-tnq75   1/1     Running   0          2s    v1
```

_**Update the application** (version 2) while watching the Pods. Read it top to bottom: all three old Pods go to Terminating **before** any new Pod is created (the new ones appear only after the old ones are gone)._

```console
$ timeout 45 kubectl get pods -l app=app-recreate -L version -w > /tmp/watch-recreate.txt 2>&1 & kubectl exec -i client -- sh -s http://app-recreate 70 < probe.sh > /tmp/probe-recreate.txt & sleep 3; kubectl apply -f 04-recreate/deployment-v2.yaml; kubectl rollout status deployment/app-recreate --timeout=180s; wait; echo "=== Pod changes in order (kubectl get pods -w) ==="; cat /tmp/watch-recreate.txt
deployment.apps/app-recreate configured
Waiting for deployment "app-recreate" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "app-recreate" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "app-recreate" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "app-recreate" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "app-recreate" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "app-recreate" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "app-recreate" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "app-recreate" rollout to finish: 2 of 3 updated replicas are available...
deployment "app-recreate" successfully rolled out
=== Pod changes in order (kubectl get pods -w) ===
NAME                           READY   STATUS    RESTARTS   AGE   VERSION
app-recreate-66d7f599d-fkn4x   1/1     Running   0          2s    v1
app-recreate-66d7f599d-mwptb   1/1     Running   0          2s    v1
app-recreate-66d7f599d-tnq75   1/1     Running   0          2s    v1
app-recreate-66d7f599d-tnq75   1/1     Terminating   0          5s    v1
app-recreate-66d7f599d-mwptb   1/1     Terminating   0          5s    v1
app-recreate-66d7f599d-fkn4x   1/1     Terminating   0          5s    v1
app-recreate-66d7f599d-fkn4x   1/1     Terminating   0          6s    v1
app-recreate-66d7f599d-mwptb   1/1     Terminating   0          6s    v1
app-recreate-66d7f599d-tnq75   1/1     Terminating   0          6s    v1
app-recreate-66d7f599d-mwptb   0/1     Error         0          6s    v1
app-recreate-66d7f599d-fkn4x   0/1     Error         0          6s    v1
app-recreate-66d7f599d-tnq75   0/1     Error         0          6s    v1
app-recreate-6674549bc8-67f5l   0/1     Pending       0          0s    v2
app-recreate-6674549bc8-cpl4j   0/1     Pending       0          0s    v2
app-recreate-6674549bc8-2rr79   0/1     Pending       0          0s    v2
app-recreate-6674549bc8-67f5l   0/1     Pending       0          0s    v2
app-recreate-6674549bc8-2rr79   0/1     Pending       0          0s    v2
app-recreate-6674549bc8-cpl4j   0/1     Pending       0          0s    v2
app-recreate-6674549bc8-67f5l   0/1     ContainerCreating   0          0s    v2
app-recreate-6674549bc8-2rr79   0/1     ContainerCreating   0          0s    v2
app-recreate-6674549bc8-cpl4j   0/1     ContainerCreating   0          0s    v2
app-recreate-66d7f599d-fkn4x    0/1     Error               0          7s    v1
app-recreate-66d7f599d-fkn4x    0/1     Error               0          7s    v1
app-recreate-66d7f599d-mwptb    0/1     Error               0          7s    v1
app-recreate-66d7f599d-mwptb    0/1     Error               0          7s    v1
app-recreate-66d7f599d-tnq75    0/1     Error               0          7s    v1
app-recreate-66d7f599d-tnq75    0/1     Error               0          7s    v1
app-recreate-6674549bc8-67f5l   0/1     ContainerCreating   0          1s    v2
app-recreate-6674549bc8-2rr79   0/1     ContainerCreating   0          1s    v2
app-recreate-6674549bc8-cpl4j   0/1     ContainerCreating   0          1s    v2
app-recreate-6674549bc8-67f5l   0/1     Running             0          1s    v2
app-recreate-6674549bc8-cpl4j   0/1     Running             0          1s    v2
app-recreate-6674549bc8-2rr79   0/1     Running             0          1s    v2
app-recreate-6674549bc8-cpl4j   1/1     Running             0          2s    v2
app-recreate-6674549bc8-67f5l   1/1     Running             0          2s    v2
app-recreate-6674549bc8-2rr79   1/1     Running             0          2s    v2
```

_Their `Error` status while stopping is cosmetic and unrelated to the strategy: what matters is the order, all old Pods are gone before any new Pod is created._

_What the client saw during the same update: version-1 answers, then **FAIL lines** (the window with no Pod at all), then version-2. That window is the downtime._

```console
$ sort /tmp/probe-recreate.txt | uniq -c
      2 FAIL
      7 version-1
     61 version-2
```

_The Deployment events confirm the order: the old ReplicaSet is scaled down to 0 first, then the new one is scaled up to 3._

```console
$ kubectl get events --sort-by=.lastTimestamp | grep app-recreate | grep -E "ScalingReplicaSet" | tail -n 6
10m         Normal    ScalingReplicaSet         deployment/app-recreate                     Scaled up replica set app-recreate-66d7f599d from 0 to 3
10m         Normal    ScalingReplicaSet         deployment/app-recreate                     Scaled down replica set app-recreate-66d7f599d from 3 to 0
9m59s       Normal    ScalingReplicaSet         deployment/app-recreate                     Scaled up replica set app-recreate-6674549bc8 from 0 to 3
48s         Normal    ScalingReplicaSet         deployment/app-recreate                     Scaled up replica set app-recreate-66d7f599d from 0 to 3
43s         Normal    ScalingReplicaSet         deployment/app-recreate                     Scaled down replica set app-recreate-66d7f599d from 3 to 0
42s         Normal    ScalingReplicaSet         deployment/app-recreate                     Scaled up replica set app-recreate-6674549bc8 from 0 to 3
```

_Cleanup (also the client Pod)._

```console
$ kubectl delete -f 04-recreate/deployment-v2.yaml -f 04-recreate/service.yaml; kubectl delete pod client --wait=false
deployment.apps "app-recreate" deleted from default namespace
service "app-recreate" deleted from default namespace
pod "client" deleted from default namespace
```

### Strategy comparison

| | Rolling | Blue-Green | Canary | Recreate |
|---|---|---|---|---|
| Downtime | none | none | none | **yes** |
| Extra capacity needed | small (`maxSurge`) | **double** | small | none |
| Rollback speed | fast (undo) | **instant** (selector) | instant (scale canary to 0) | slow (redeploy) |
| Risk exposure | gradual | all-at-once switch (after testing) | **only a small share** | everyone at once |
| Two versions live together | briefly | yes (one receives no traffic) | yes, on purpose | never |
| Best for | default for stateless apps | big releases, instant rollback | risky changes, real-traffic testing | breaking changes that cannot coexist |

---

## Task 2: Pod lifecycle

### Background

| Concept | Values / meaning |
|---|---|
| **Pod phase** | `Pending` (accepted, not running yet), `Running`, `Succeeded` (all containers exited 0), `Failed` (a container exited non-zero), `Unknown` |
| **Container state** | `Waiting` (with a reason such as ContainerCreating, ImagePullBackOff, CrashLoopBackOff), `Running`, `Terminated` (exit code, reason) |
| **Conditions** | `PodScheduled`, `Initialized`, `ContainersReady`, `Ready` |
| **restartPolicy** | `Always` (default), `OnFailure`, `Never` |
| **Probes** | `startupProbe` (is the app up yet?), `readinessProbe` (may it get traffic?), `livenessProbe` (is it alive, else restart) |

For every YAML file I do the same: **apply** it, **check the status**, **check the details** (`describe`), capture the output and explain what I saw.

_The twelve manifests (from the course repository)._

```console
$ ls pod-lifecycle
01-running.yaml
02-pending.yaml
03-succeeded.yaml
04-failed.yaml
05-crashloopbackoff.yaml
06-imagepullbackoff.yaml
07-readiness.yaml
08-liveness.yaml
09-startup.yaml
10-init-container.yaml
11-multi-container.yaml
12-termination.yaml
```

### 01: Running (the normal case)

_A plain nginx Pod._

```console
$ cat pod-lifecycle/01-running.yaml | grep -v "^#"
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-running
spec:
  containers:
    - name: nginx
      image: nginx:1.27
      ports:
        - containerPort: 80
```

_Apply, wait for Ready, check the status: 1/1 Running with a Pod IP and the node it landed on._

```console
$ kubectl apply -f pod-lifecycle/01-running.yaml && kubectl wait --for=condition=Ready pod/lifecycle-running --timeout=120s && kubectl get pod lifecycle-running -o wide
pod/lifecycle-running created
pod/lifecycle-running condition met
NAME                READY   STATUS    RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
lifecycle-running   1/1     Running   0          1s    10.244.0.127   minikube   <none>           <none>
```

_Details: phase Running, all four conditions True, and the events Scheduled, Pulled, Created, Started._

```console
$ kubectl describe pod lifecycle-running | awk "/^Status:/{print} /^Conditions:/{p=1} /^Volumes:/{p=0} p{print} /^Events:/{e=1} e{print}"
Status:           Running
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  2s    default-scheduler  Successfully assigned default/lifecycle-running to minikube
  Normal  Pulled     1s    kubelet            spec.containers{nginx}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    1s    kubelet            spec.containers{nginx}: Container created
  Normal  Started    1s    kubelet            spec.containers{nginx}: Container started
```

**What I observed:** the Pod went `Pending` -> `ContainerCreating` -> `Running`. The scheduler assigned a node (Scheduled), the kubelet pulled the image and started the container. `Ready=True` means it is allowed to receive traffic.

### 02: Pending (cannot be scheduled)

_The course file asks for 1 CPU and 9Gi of memory, hoping to be larger than the node._

```console
$ grep -A3 "resources:" pod-lifecycle/02-pending.yaml
      resources:
        requests:
          cpu: "1"
          memory: "9Gi"
```

_Applied as given, it did **not** stay Pending on my machine: it was scheduled and is Running._

```console
$ kubectl apply -f pod-lifecycle/02-pending.yaml && sleep 6 && kubectl get pod lifecycle-pending -o wide
pod/lifecycle-pending created
NAME                READY   STATUS    RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
lifecycle-pending   1/1     Running   0          6s    10.244.0.128   minikube   <none>           <none>
```

_The reason: my node reports about 11.3 GiB of allocatable memory (the Minikube node sees the memory of the Docker VM), so a 9Gi request fits. The file was written for a smaller node._

```console
$ kubectl get node minikube -o jsonpath="allocatable memory = {.status.allocatable.memory}  cpu = {.status.allocatable.cpu}{\"\\n\"}"
allocatable memory = 11853004Ki  cpu = 12
```

_To demonstrate the Pending phase on this machine I made a copy of the file with a request that cannot fit anywhere (64Gi)._

```console
$ cat pod-lifecycle/02-pending-64gi.yaml
# My variant of 02-pending.yaml: the request (64Gi) is bigger than any memory this node has
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-pending-64gi
spec:
  containers:
    - name: impossible-resource
      image: nginx:1.27
      resources:
        requests:
          cpu: "1"
          memory: "64Gi"
```

_Now the status stays **Pending** and the NODE column is empty: no node was chosen._

```console
$ kubectl apply -f pod-lifecycle/02-pending-64gi.yaml && sleep 6 && kubectl get pod lifecycle-pending-64gi -o wide
pod/lifecycle-pending-64gi created
NAME                     READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
lifecycle-pending-64gi   0/1     Pending   0          6s    <none>   <none>   <none>           <none>
```

_The scheduler says why: FailedScheduling, Insufficient memory._

```console
$ kubectl describe pod lifecycle-pending-64gi | awk "/^Status:/{print} /^Events:/{e=1} e{print}"
Status:           Pending
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  7s    default-scheduler  0/1 nodes are available: 1 Insufficient memory. preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
```

**What I observed:** `Pending` with no node. The cause is in the **Events** (`0/1 nodes are available: 1 Insufficient memory`). Fix: lower the request or add capacity. The unmodified course file (9Gi) ran fine because my node is large; the same file would be Pending on a node with less than 9 GiB free, so I kept it and added the 64Gi variant to show the real Pending behaviour.

### 03: Succeeded (a run-to-completion task)

_restartPolicy is Never; the task exits with 0 after about 5 seconds. The status column shows Completed and phase Succeeded._

```console
$ kubectl apply -f pod-lifecycle/03-succeeded.yaml && kubectl wait --for=jsonpath="{.status.phase}"=Succeeded pod/lifecycle-succeeded --timeout=90s && kubectl get pod lifecycle-succeeded
pod/lifecycle-succeeded created
pod/lifecycle-succeeded condition met
NAME                  READY   STATUS      RESTARTS   AGE
lifecycle-succeeded   0/1     Completed   0          8s
```

_The log and the terminated state: exit code 0, reason Completed._

```console
$ kubectl logs lifecycle-succeeded; kubectl get pod lifecycle-succeeded -o jsonpath="phase={.status.phase}  exitCode={.status.containerStatuses[0].state.terminated.exitCode}  reason={.status.containerStatuses[0].state.terminated.reason}{\"\\n\"}"
Task started
Task completed successfully
phase=Succeeded  exitCode=0  reason=Completed
```

**What I observed:** exit code 0 with `restartPolicy: Never` -> phase `Succeeded` (shown as `Completed`). The Pod object stays so its logs can be read. Jobs use this behaviour.

### 04: Failed (the task exits with an error)

_Same as 03 but it exits with 1: status Error, phase Failed._

```console
$ kubectl apply -f pod-lifecycle/04-failed.yaml && kubectl wait --for=jsonpath="{.status.phase}"=Failed pod/lifecycle-failed --timeout=90s && kubectl get pod lifecycle-failed
pod/lifecycle-failed created
pod/lifecycle-failed condition met
NAME               READY   STATUS   RESTARTS   AGE
lifecycle-failed   0/1     Error    0          9s
```

_The log shows "Task failed"; the terminated state has exit code 1, reason Error._

```console
$ kubectl logs lifecycle-failed; kubectl get pod lifecycle-failed -o jsonpath="phase={.status.phase}  exitCode={.status.containerStatuses[0].state.terminated.exitCode}  reason={.status.containerStatuses[0].state.terminated.reason}{\"\\n\"}"
Task started
Task failed
phase=Failed  exitCode=1  reason=Error
```

**What I observed:** a non-zero exit code with `restartPolicy: Never` -> phase `Failed`. No restart is attempted because the policy forbids it.

### 05: CrashLoopBackOff (the app keeps crashing)

_Apply it and, after the first crash, read the log of the previous (crashed) run: it shows what the app printed before dying._

```console
$ kubectl apply -f pod-lifecycle/05-crashloopbackoff.yaml && sleep 20 && kubectl logs lifecycle-crashloop --previous
pod/lifecycle-crashloop created
Application started
Application crashed
```

_restartPolicy defaults to Always, so Kubernetes restarts the crashing container again and again, waiting longer each time. About a minute later RESTARTS is greater than 0 and the status alternates between Error and CrashLoopBackOff._

```console
$ sleep 55 && kubectl get pod lifecycle-crashloop
NAME                  READY   STATUS   RESTARTS      AGE
lifecycle-crashloop   0/1     Error    3 (53s ago)   75s
```

_Details: Last State Terminated (exit code 1) and Back-off restarting failed container in the events._

```console
$ kubectl describe pod lifecycle-crashloop | awk "/^    State:/,/Ready:/{print} /^Events:/{e=1} e{print}"
    State:          Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Sun, 18 Oct 2026 19:15:45 +0530
      Finished:     Sun, 18 Oct 2026 19:15:48 +0530
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Sun, 18 Oct 2026 19:15:18 +0530
      Finished:     Sun, 18 Oct 2026 19:15:21 +0530
    Ready:          False
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  76s                default-scheduler  Successfully assigned default/lifecycle-crashloop to minikube
  Normal   Pulled     30s (x4 over 76s)  kubelet            spec.containers{crashing-app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal   Created    30s (x4 over 76s)  kubelet            spec.containers{crashing-app}: Container created
  Normal   Started    30s (x4 over 75s)  kubelet            spec.containers{crashing-app}: Container started
  Warning  BackOff    26s (x3 over 68s)  kubelet            spec.containers{crashing-app}: Back-off restarting failed container crashing-app in pod lifecycle-crashloop_default(dba84062-637b-4708-b7a0-4a49b18faa50)
```

**What I observed:** the cycle is *start, run 3 s, exit 1, wait (back-off 10 s, 20 s, 40 s ... up to 5 min), start again*. `CrashLoopBackOff` is a Waiting reason, not a phase; the Pod phase is still `Running`. Debug with `describe` and `logs --previous`.

### 06: ImagePullBackOff (image cannot be pulled)

_The image name does not exist: first ErrImagePull, then ImagePullBackOff (the back-off between retries)._

```console
$ kubectl apply -f pod-lifecycle/06-imagepullbackoff.yaml && sleep 25 && kubectl get pod lifecycle-image-error
pod/lifecycle-image-error created
NAME                    READY   STATUS             RESTARTS   AGE
lifecycle-image-error   0/1     ImagePullBackOff   0          25s
```

_The events show Failed to pull image ... and Back-off pulling image._

```console
$ kubectl describe pod lifecycle-image-error | awk "/^    State:/,/Ready:/{print} /^Events:/{e=1} e{print}"
    State:          Waiting
      Reason:       ImagePullBackOff
    Ready:          False
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  26s                default-scheduler  Successfully assigned default/lifecycle-image-error to minikube
  Normal   BackOff    23s                kubelet            spec.containers{broken-image}: Back-off pulling image "jakwehrgkaejw:kahsdfgkhj"
  Warning  Failed     23s                kubelet            spec.containers{broken-image}: Error: ImagePullBackOff
  Normal   Pulling    12s (x2 over 25s)  kubelet            spec.containers{broken-image}: Pulling image "jakwehrgkaejw:kahsdfgkhj"
  Warning  Failed     8s (x2 over 23s)   kubelet            spec.containers{broken-image}: Failed to pull image "jakwehrgkaejw:kahsdfgkhj": failed to pull and unpack image "docker.io/library/jakwehrgkaejw:kahsdfgkhj": failed to resolve reference "docker.io/library/jakwehrgkaejw:kahsdfgkhj": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  Warning  Failed     8s (x2 over 23s)   kubelet            spec.containers{broken-image}: Error: ErrImagePull
```

**What I observed:** the Pod is `Pending` (the container never started), the container is `Waiting` with reason `ErrImagePull`/`ImagePullBackOff`. Typical causes: wrong name or tag, private registry without credentials. Fix the image reference.

### 07: Readiness probe

_Kubernetes asks nginx for / every 5 s; only a success makes the Pod Ready._

```console
$ grep -A6 "readinessProbe" pod-lifecycle/07-readiness.yaml
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 5
```

_Right after start the Pod is Running but 0/1 (not ready yet, probe has not passed); about 10 seconds later it is 1/1._

```console
$ kubectl apply -f pod-lifecycle/07-readiness.yaml && sleep 2 && kubectl get pod lifecycle-readiness && sleep 12 && kubectl get pod lifecycle-readiness
pod/lifecycle-readiness created
NAME                  READY   STATUS    RESTARTS   AGE
lifecycle-readiness   0/1     Running   0          2s
NAME                  READY   STATUS    RESTARTS   AGE
lifecycle-readiness   1/1     Running   0          15s
```

_I break the app on purpose by deleting its home page. The probe now fails and the Pod turns 0/1 **without being restarted** (RESTARTS stays 0)._

```console
$ kubectl exec lifecycle-readiness -- rm /usr/share/nginx/html/index.html && sleep 12 && kubectl get pod lifecycle-readiness
NAME                  READY   STATUS    RESTARTS   AGE
lifecycle-readiness   0/1     Running   0          27s
```

_Ready=False and the event "Readiness probe failed"._

```console
$ kubectl describe pod lifecycle-readiness | awk "/^Conditions:/{p=1} /^Volumes:/{p=0} p{print} /^Events:/{e=1} e{print}" | grep -E "Ready|Type|Readiness"
  Type                        Status
  PodReadyToStartContainers   True 
  Ready                       False 
  ContainersReady             False 
  Type     Reason     Age               From               Message
  Warning  Unhealthy  2s (x4 over 12s)  kubelet            spec.containers{nginx}: Readiness probe failed: HTTP probe failed with statuscode: 403
```

_I put a page back: the probe passes and the Pod is Ready again._

```console
$ kubectl exec lifecycle-readiness -- sh -c "echo ok > /usr/share/nginx/html/index.html" && sleep 12 && kubectl get pod lifecycle-readiness
NAME                  READY   STATUS    RESTARTS   AGE
lifecycle-readiness   1/1     Running   0          40s
```

**What I observed:** readiness only controls **traffic**: a not-ready Pod is removed from Service endpoints but is neither restarted nor killed.

### 08: Liveness probe

_The app creates /tmp/healthy, deletes it after 20 s, and the liveness probe checks that the file exists._

```console
$ grep -A8 "command:" pod-lifecycle/08-liveness.yaml | head -n 12
      command: ["sh", "-c", "echo 'App started'; touch /tmp/healthy; sleep 20; rm /tmp/healthy; echo 'Health file removed'; sleep 300"]
      livenessProbe:
        exec:
          command: ["sh", "-c", "test -f /tmp/healthy"]
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 2
```

_First all is well. After the file is removed (at 20 s) the probe fails twice and Kubernetes kills the container; RESTARTS goes from 0 to 1. (The restart is not instant: the shell running as PID 1 ignores SIGTERM, so Kubernetes waits out the 30 s grace period before SIGKILL.)_

```console
$ kubectl apply -f pod-lifecycle/08-liveness.yaml && sleep 15 && kubectl get pod lifecycle-liveness && sleep 70 && kubectl get pod lifecycle-liveness
pod/lifecycle-liveness created
NAME                 READY   STATUS    RESTARTS   AGE
lifecycle-liveness   1/1     Running   0          15s
NAME                 READY   STATUS    RESTARTS      AGE
lifecycle-liveness   1/1     Running   1 (26s ago)   86s
```

_Events: Liveness probe failed, then Container app failed liveness probe, will be restarted._

```console
$ kubectl describe pod lifecycle-liveness | awk "/^Events:/{e=1} e{print}"
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  86s                default-scheduler  Successfully assigned default/lifecycle-liveness to minikube
  Normal   Killing    56s                kubelet            spec.containers{app}: Container app failed liveness probe, will be restarted
  Normal   Pulled     26s (x2 over 85s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal   Created    25s (x2 over 85s)  kubelet            spec.containers{app}: Container created
  Normal   Started    25s (x2 over 85s)  kubelet            spec.containers{app}: Container started
  Warning  Unhealthy  1s (x3 over 61s)   kubelet            spec.containers{app}: Liveness probe failed:
```

**What I observed:** liveness decides whether to **restart** a container that is running but stuck. Unlike readiness, a failure here kills the container (and the new one recreates `/tmp/healthy`, so the cycle repeats).

### 09: Startup probe

_A slow app gets up to 10 x 5 s = 50 s to start before liveness/readiness checks begin._

```console
$ grep -A5 "startupProbe" pod-lifecycle/09-startup.yaml
      startupProbe:
        exec:
          command: ["sh", "-c", "test -f /tmp/started"]
        periodSeconds: 5
        failureThreshold: 10
```

_During the first 30 s the app is still starting: Running but 0/1. After /tmp/started appears the startup probe passes and the Pod becomes 1/1._

```console
$ kubectl apply -f pod-lifecycle/09-startup.yaml && sleep 10 && kubectl get pod lifecycle-startup && sleep 32 && kubectl get pod lifecycle-startup
pod/lifecycle-startup created
NAME                READY   STATUS    RESTARTS   AGE
lifecycle-startup   0/1     Running   0          11s
NAME                READY   STATUS    RESTARTS   AGE
lifecycle-startup   1/1     Running   0          43s
```

_The app log, and the Startup probe failed events from the early checks._

```console
$ kubectl logs lifecycle-startup; kubectl describe pod lifecycle-startup | awk "/^Events:/{e=1} e{print}"
Application starting...
Application started
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  44s                default-scheduler  Successfully assigned default/lifecycle-startup to minikube
  Normal   Pulled     43s                kubelet            spec.containers{slow-app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal   Created    43s                kubelet            spec.containers{slow-app}: Container created
  Normal   Started    43s                kubelet            spec.containers{slow-app}: Container started
  Warning  Unhealthy  13s (x6 over 38s)  kubelet            spec.containers{slow-app}: Startup probe failed:
```

**What I observed:** the startup probe protects slow starters: until it succeeds, no other probe runs, so a slow-but-healthy app is not killed by a strict liveness probe.

### 10: Init container

_While the init container runs the status is Init:0/1: the main container has not started._

```console
$ kubectl apply -f pod-lifecycle/10-init-container.yaml && sleep 4 && kubectl get pod lifecycle-init
pod/lifecycle-init created
NAME             READY   STATUS     RESTARTS   AGE
lifecycle-init   0/1     Init:0/1   0          4s
```

_The init container log, then the status once it has completed: Running._

```console
$ kubectl logs lifecycle-init -c setup; sleep 12; kubectl get pod lifecycle-init
Init container running
NAME             READY   STATUS    RESTARTS   AGE
lifecycle-init   1/1     Running   0          17s
```

_The init container ended Terminated (Completed, exit 0); the events show it started first, then the app container._

```console
$ kubectl describe pod lifecycle-init | awk "/^Init Containers:/{p=1} /^Containers:/{p=0} p{print}" | head -n 14; kubectl describe pod lifecycle-init | awk "/^Events:/{e=1} e{print}"
Init Containers:
  setup:
    Container ID:  containerd://ca787be8fe5f19a1e80e5d6e6cf3f24eff75ef2bbf15bdc357aaecde1b30ba24
    Image:         busybox:1.36
    Image ID:      docker.io/library/busybox@sha256:73aaf090f3d85aa34ee199857f03fa3a95c8ede2ffd4cc2cdb5b94e566b11662
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      echo 'Init container running'; sleep 10; echo 'Init complete'
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  17s   default-scheduler  Successfully assigned default/lifecycle-init to minikube
  Normal  Pulled     16s   kubelet            spec.initContainers{setup}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal  Created    16s   kubelet            spec.initContainers{setup}: Container created
  Normal  Started    16s   kubelet            spec.initContainers{setup}: Container started
  Normal  Pulled     6s    kubelet            spec.containers{app}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    6s    kubelet            spec.containers{app}: Container created
  Normal  Started    6s    kubelet            spec.containers{app}: Container started
```

**What I observed:** init containers run **one after another, to completion, before** the app containers start (good for waiting on a dependency or preparing files). Pod phase stays `Pending` during init.

### 11: Multi-container Pod

_READY shows 2/2: both containers run in the same Pod._

```console
$ kubectl apply -f pod-lifecycle/11-multi-container.yaml && kubectl wait --for=condition=Ready pod/lifecycle-multi-container --timeout=120s && kubectl get pod lifecycle-multi-container
pod/lifecycle-multi-container created
pod/lifecycle-multi-container condition met
NAME                        READY   STATUS    RESTARTS   AGE
lifecycle-multi-container   2/2     Running   0          1s
```

_The sidecar log and the per-container status._

```console
$ kubectl logs lifecycle-multi-container -c sidecar --tail=3; kubectl get pod lifecycle-multi-container -o jsonpath="{range .status.containerStatuses[*]}{.name}{\"  ready=\"}{.ready}{\"  restarts=\"}{.restartCount}{\"\\n\"}{end}"
Sidecar is running
app  ready=true  restarts=0
sidecar  ready=true  restarts=0
```

_The sidecar reaches nginx on localhost: containers in a Pod share one network namespace (one IP)._

```console
$ kubectl exec lifecycle-multi-container -c sidecar -- wget -qO- localhost:80 | head -n 4
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

**What I observed:** all containers of a Pod are scheduled together, share the network (localhost) and can share volumes. The Pod is Ready only when **all** containers are ready. Typical use: app + log shipper / proxy sidecar.

### 12: Graceful termination

_The app traps SIGTERM; its grace period is 20 s._

```console
$ kubectl apply -f pod-lifecycle/12-termination.yaml && kubectl wait --for=condition=Ready pod/lifecycle-termination --timeout=120s && kubectl logs lifecycle-termination
pod/lifecycle-termination created
pod/lifecycle-termination condition met
Application running
```

_I delete the Pod while following its log. Status turns Terminating, the app receives SIGTERM, cleans up for 10 s and exits 0 on its own, before the 20 s limit (compare the two timestamps)._

```console
$ kubectl logs -f lifecycle-termination > /tmp/term-log.txt 2>&1 & sleep 1; date +%T; kubectl delete pod lifecycle-termination --wait=false; sleep 2; kubectl get pod lifecycle-termination; wait; date +%T; echo "--- log captured during deletion ---"; cat /tmp/term-log.txt
19:19:55
pod "lifecycle-termination" deleted from default namespace
NAME                    READY   STATUS        RESTARTS   AGE
lifecycle-termination   1/1     Terminating   0          4s
19:20:06
--- log captured during deletion ---
Application running
SIGTERM received; cleaning up...
Cleanup complete
```

_Afterwards the Pod is gone._

```console
$ kubectl get pod lifecycle-termination 2>&1
Error from server (NotFound): pods "lifecycle-termination" not found
```

**What I observed:** deleting a Pod sends **SIGTERM**, waits up to `terminationGracePeriodSeconds`, and only then sends **SIGKILL**. Apps should handle SIGTERM to finish requests cleanly. (Here the cleanup, 10 s, fits inside the 20 s grace period.)

### All the Pods side by side

_The states from this task in one table._

```console
$ kubectl get pods
NAME                        READY   STATUS             RESTARTS        AGE
lifecycle-crashloop         0/1     CrashLoopBackOff   5 (2m11s ago)   5m8s
lifecycle-failed            0/1     Error              0               5m18s
lifecycle-image-error       0/1     ImagePullBackOff   0               3m52s
lifecycle-init              1/1     Running            0               35s
lifecycle-liveness          1/1     Running            2 (45s ago)     2m45s
lifecycle-multi-container   2/2     Running            0               17s
lifecycle-pending           1/1     Running            0               5m41s
lifecycle-pending-64gi      0/1     Pending            0               5m34s
lifecycle-readiness         1/1     Running            0               3m26s
lifecycle-running           1/1     Running            0               5m44s
lifecycle-startup           1/1     Running            0               79s
lifecycle-succeeded         0/1     Completed          0               5m27s
```

_Cleanup (the number is how many Pods were deleted)._

```console
$ kubectl delete -f pod-lifecycle/ --ignore-not-found --wait=false 2>&1 | grep -c deleted
12
```

### Summary of the twelve cases

| # | File | What it shows | Pod phase | What `kubectl get pod` shows |
|---|---|---|---|---|
| 01 | running | normal start | Running | `1/1 Running` |
| 02 | pending | course file (9Gi) fits my 11 GiB node and runs; my 64Gi variant cannot be scheduled | Pending (64Gi variant) | `0/1 Pending` (no node) |
| 03 | succeeded | task exits 0, `restartPolicy: Never` | Succeeded | `Completed` |
| 04 | failed | task exits 1, `restartPolicy: Never` | Failed | `Error` |
| 05 | crashloopbackoff | app keeps crashing, `Always` restarts | Running | `CrashLoopBackOff` |
| 06 | imagepullbackoff | wrong image | Pending | `ErrImagePull` / `ImagePullBackOff` |
| 07 | readiness | probe gates traffic only | Running | `0/1` then `1/1` |
| 08 | liveness | failing probe restarts the container | Running | `RESTARTS` increases |
| 09 | startup | probe protects slow start | Running | `0/1` for 30 s, then `1/1` |
| 10 | init-container | init runs to completion first | Pending then Running | `Init:0/1` -> `Running` |
| 11 | multi-container | containers share network | Running | `2/2` |
| 12 | termination | SIGTERM then SIGKILL | Running -> gone | `Terminating` |

## What I learned

- A **Deployment** gives the Pod self-healing, scaling and four ways to ship a new version; the strategy is a trade-off between **downtime, cost and risk**.
- Rolling updates with `maxUnavailable: 0` and a readiness probe give zero downtime; Blue-Green switches by changing a Service selector; Canary shares traffic by Pod count; Recreate is simple but has a visible downtime window.
- `kubectl describe` **Events** explain almost every Pod problem (scheduling, image pulls, probes, back-offs).
- Readiness controls traffic, liveness controls restarts, startup protects slow starts; init containers prepare the ground; termination is SIGTERM first, SIGKILL after the grace period.
