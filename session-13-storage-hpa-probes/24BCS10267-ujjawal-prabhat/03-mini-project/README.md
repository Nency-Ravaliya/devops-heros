# Task 3 - Mini project: production-ready web app (PVC + HPA + probes)

**Ujjawal Prabhat - 24BCS10267 - Session 13 (Storage, HPA & Probes)**

This follows the course spec in `../../mini-project/README.md`. The manifests in this folder are the course's `namespace.yaml`, `pvc.yaml`, `deployment.yaml`, `service.yaml` and `hpa.yaml`, unchanged **except** that the namespace `production-webapp` is renamed to `s13-mini`, because the cluster is shared and I may only use my own namespaces. `hpa-challenge1-30pct.yaml` is the Bonus Challenge 1 variant (target 30%).

| Pillar | How it is implemented |
|---|---|
| State persistence | PVC `web-data` (500Mi, RWO, StorageClass `standard` = rancher local-path), mounted at `/data` |
| Elastic scaling | HPA `web-app-hpa`, 2-5 replicas, 50% average CPU. The pods request `cpu: 100m` with a `200m` limit |
| Health checks | startupProbe (`/`, 2s period, up to 30 failures = 60s to boot), readinessProbe (5s period, 2 failures), livenessProbe (5s period, 3 failures) |

In the spec diagram the StorageClass is `k8s.io/minikube-hostpath`. On kind, the default `standard` class uses `rancher.io/local-path`. The PVC sets no class, so it gets whichever class is the default.

---

## Step 5.1 - 5.4: deploy

```console
$ kubectl apply -f namespace.yaml
namespace/s13-mini created

$ kubectl apply -f pvc.yaml
persistentvolumeclaim/web-data created

$ kubectl get pvc -n s13-mini
NAME       STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
web-data   Pending                                      standard       <unset>                 0s

$ kubectl apply -f deployment.yaml
deployment.apps/web-app created

$ kubectl apply -f service.yaml
service/web-service created

$ kubectl get pods -n s13-mini
NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-9l89k   0/1     Pending   0          0s
web-app-d45775485-lhfsx   0/1     Pending   0          0s

$ kubectl get pods -n s13-mini -o wide        # after rollout finished
NAME                      READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
web-app-d45775485-9l89k   1/1     Running   0          12s   10.244.1.26   devops-heros-worker2   <none>           <none>
web-app-d45775485-lhfsx   1/1     Running   0          12s   10.244.1.25   devops-heros-worker2   <none>           <none>

$ kubectl get pvc -n s13-mini
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
web-data   Bound    pvc-b9327871-8cb7-43b8-bf6a-e8e669f30681   500Mi      RWO            standard       <unset>                 12s

$ kubectl get endpoints web-service -n s13-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME          ENDPOINTS                       AGE
web-service   10.244.1.25:80,10.244.1.26:80   12s

$ kubectl apply -f hpa.yaml
horizontalpodautoscaler.autoscaling/web-app-hpa created

$ kubectl get hpa -n s13-mini
NAME          REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   cpu: 1%/50%   2         5         2          45s
```

- The PVC is `Pending` at first because `standard` uses `WaitForFirstConsumer`. It became `Bound` as soon as the first Pod was scheduled.
- **Both pods landed on `devops-heros-worker2`.** A local-path PV is a directory on one node, so the PV has node affinity and every Pod that mounts it must run on that node. `ReadWriteOnce` means one *node*, not one Pod, so the two replicas can share the volume. On a multi-node production cluster you would use RWX storage, or a StatefulSet with one PVC per Pod.
- This also explains why the course uses `strategy: Recreate`. With a single-node RWO volume, a RollingUpdate whose new pod lands on another node would get stuck. Recreate stops the old pods first.

### Probes on a running pod

```console
$ kubectl describe pod -n s13-mini web-app-d45775485-9l89k | grep -E 'Liveness|Readiness|Startup|Requests|Limits|cpu|memory|/data|ClaimName'
    Limits:
      cpu:     200m
      memory:  128Mi
    Requests:
      cpu:        100m
      memory:     64Mi
    Liveness:     http-get http://:80/ delay=5s timeout=2s period=5s #success=1 #failure=3
    Readiness:    http-get http://:80/ delay=5s timeout=2s period=5s #success=1 #failure=2
    Startup:      http-get http://:80/ delay=0s timeout=1s period=2s #success=1 #failure=30
      /data from persistent-storage (rw)
    ClaimName:  web-data

$ kubectl get pod -n s13-mini web-app-d45775485-9l89k -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
PodReadyToStartContainers=True
Initialized=True
Ready=True
ContainersReady=True
PodScheduled=True
```

---

## Verification Task 1 - storage persistence

```console
$ POD_NAME=$(kubectl get pods -n s13-mini -l app=web-app -o jsonpath='{.items[0].metadata.name}'); echo $POD_NAME
web-app-d45775485-9l89k

$ kubectl exec -n s13-mini web-app-d45775485-9l89k -- sh -c 'echo "Student: Ujjawal Prabhat (24BCS10267)" > /data/student.txt'

$ kubectl exec -n s13-mini web-app-d45775485-9l89k -- cat /data/student.txt
Student: Ujjawal Prabhat (24BCS10267)

$ kubectl delete pod -n s13-mini web-app-d45775485-9l89k
pod "web-app-d45775485-9l89k" deleted from s13-mini namespace

$ kubectl get pods -n s13-mini
NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-lhfsx   1/1     Running   0          66s
web-app-d45775485-pm9pq   1/1     Running   0          9s

$ kubectl exec -n s13-mini web-app-d45775485-lhfsx -- cat /data/student.txt
Student: Ujjawal Prabhat (24BCS10267)

$ kubectl exec -n s13-mini web-app-d45775485-pm9pq -- cat /data/student.txt
Student: Ujjawal Prabhat (24BCS10267)
```

The pod I wrote from was deleted, and the replacement pod `pm9pq` reads the same file. Both replicas see it because they share the same PV. The file was still there at the very end of the session, after many more pod re-creations during the probe challenges (see below).

## Verification Task 2 - Service

Port 8080 is a common port on a shared machine, so I forwarded to local port 18013 instead:

```console
$ kubectl port-forward -n s13-mini svc/web-service 18013:80 &
$ curl -s http://localhost:18013 | head -8
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
```

## Verification Task 3 - HPA elastic scaling

### Run A - spec as written (target 50%)

```console
$ kubectl run load-generator -n s13-mini --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://web-service; done"
pod/load-generator created

$ kubectl get hpa -n s13-mini -w
NAME          REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   cpu: 1%/50%   2         5         2          72s
web-app-hpa   Deployment/web-app   cpu: 13%/50%   2         5         2          90s
web-app-hpa   Deployment/web-app   cpu: 40%/50%   2         5         2          105s
web-app-hpa   Deployment/web-app   cpu: 39%/50%   2         5         2          2m45s
web-app-hpa   Deployment/web-app   cpu: 40%/50%   2         5         2          3m15s
web-app-hpa   Deployment/web-app   cpu: 39%/50%   2         5         2          4m
...
web-app-hpa   Deployment/web-app   cpu: 38%/50%   2         5         2          7m45s
web-app-hpa   Deployment/web-app   cpu: 22%/50%   2         5         2          8m
web-app-hpa   Deployment/web-app   cpu: 1%/50%    2         5         2          8m15s
web-app-hpa   Deployment/web-app   cpu: 1%/50%    2         5         2          12m

----- snapshot 19:06:17 (under load, t+120s) -----
$ kubectl top pods -n s13-mini
NAME                      CPU(cores)   MEMORY(bytes)   
load-generator            795m         6Mi             
web-app-d45775485-lhfsx   40m          9Mi             
web-app-d45775485-pm9pq   39m          8Mi             
```

**Run A did not scale, and the spec's expected 110% did not happen on this cluster.** The single busybox `wget` loop used about 800m CPU itself but only produced about 40m of nginx work per pod, which is 40% of the 100m request. That stayed flat for 6 minutes. 40% < 50%, so the HPA correctly kept 2 replicas. The `describe` output confirms it saw valid metrics and made that decision:

```console
$ kubectl describe hpa web-app-hpa -n s13-mini
...
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  40% (40m) / 50%
Min replicas:                                          2
Max replicas:                                          5
Deployment pods:                                       2 current / 2 desired
Conditions:
  Type            Status  Reason              Message
  ----            ------  ------              -------
  AbleToScale     True    ReadyForNewScale    recommended size matches current size
  ScalingActive   True    ValidMetricFound    the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  False   DesiredWithinRange  the desired count is within the acceptable range
```

### Run B - Bonus Challenge 1: lower the target to 30%

The spec's Bonus Challenge 1 is exactly the right next step. Same load, lower threshold:

```console
$ diff hpa.yaml hpa-challenge1-30pct.yaml
19c19
<           averageUtilization: 50
---
>           averageUtilization: 30

$ kubectl apply -f hpa-challenge1-30pct.yaml
horizontalpodautoscaler.autoscaling/web-app-hpa configured

$ kubectl run load-generator -n s13-mini --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://web-service; done"
pod/load-generator created

$ kubectl get hpa -n s13-mini -w
NAME          REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   cpu: 1%/30%   2         5         2          24m
web-app-hpa   Deployment/web-app   cpu: 4%/30%   2         5         2          24m
web-app-hpa   Deployment/web-app   cpu: 35%/30%   2         5         2          24m
web-app-hpa   Deployment/web-app   cpu: 37%/30%   2         5         3          24m
web-app-hpa   Deployment/web-app   cpu: 31%/30%   2         5         3          25m
web-app-hpa   Deployment/web-app   cpu: 25%/30%   2         5         3          25m
web-app-hpa   Deployment/web-app   cpu: 24%/30%   2         5         3          26m
...
web-app-hpa   Deployment/web-app   cpu: 26%/30%   2         5         3          30m
web-app-hpa   Deployment/web-app   cpu: 7%/30%    2         5         3          31m
web-app-hpa   Deployment/web-app   cpu: 1%/30%    2         5         3          31m
web-app-hpa   Deployment/web-app   cpu: 1%/30%    2         5         3          35m
web-app-hpa   Deployment/web-app   cpu: 1%/30%    2         5         2          36m

----- snapshot 19:28:43 (under load, t+90s) -----
$ kubectl get hpa -n s13-mini
NAME          REFERENCE            TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   cpu: 25%/30%   2         5         3          25m
$ kubectl top pods -n s13-mini
NAME                      CPU(cores)   MEMORY(bytes)   
load-generator            717m         5Mi             
web-app-d45775485-g657v   25m          8Mi             
web-app-d45775485-lhfsx   25m          8Mi             
web-app-d45775485-pm9pq   25m          9Mi             
$ kubectl get pods -n s13-mini
NAME                      READY   STATUS    RESTARTS   AGE
load-generator            1/1     Running   0          90s
web-app-d45775485-g657v   1/1     Running   0          67s
web-app-d45775485-lhfsx   1/1     Running   0          25m
web-app-d45775485-pm9pq   1/1     Running   0          24m
```

With a 30% target, 37% utilization gave `ceil(2 * 37/30) = 3`, so the deployment **scaled 2 -> 3**. With 3 pods the same load spread to about 25% each, below 30%, so it stayed at 3. This answers the challenge's question ("how much faster does it scale out"): the threshold, not the traffic, decided whether the same load triggered scaling at all.

Stop the load and watch the scale-down:

```console
$ kubectl delete pod load-generator -n s13-mini
pod "load-generator" deleted from s13-mini namespace
```

```text
snapshot 19:34:15 (t+30s)    cpu: 7%/30%   REPLICAS 3
snapshot 19:34:45 (t+60s)    cpu: 1%/30%   REPLICAS 3
snapshot 19:36:46 (t+180s)   cpu: 1%/30%   REPLICAS 3
snapshot 19:38:46 (t+300s)   cpu: 1%/30%   REPLICAS 3
snapshot 19:39:16 (t+330s)   cpu: 1%/30%   REPLICAS 2      <- after the 5-minute stabilization window
snapshot 19:41:47 (t+480s)   cpu: 1%/30%   REPLICAS 2      (minReplicas)
```

```console
$ kubectl describe hpa web-app-hpa -n s13-mini
...
  ScalingLimited  True    TooFewReplicas    the desired replica count is less than the minimum replica count
Events:
  Type     Reason                        Age    From                       Message
  ----     ------                        ----   ----                       -------
  ...
  Normal   SuccessfulRescale             14m    horizontal-pod-autoscaler  New size: 3; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             2m55s  horizontal-pod-autoscaler  New size: 2; reason: All metrics below target
```

It went back to 2 about 5.5 minutes after the load stopped, and never below `minReplicas: 2`. At the end of the session I re-applied the spec's `hpa.yaml` (50%). In Task 2 (`../02-hpa`) I used three load generators against the course's `04-hpa` app and drove an HPA from 1 to 5 replicas.

---

## Probes - Bonus Challenges 2 and 3

### Challenge 2 - readiness gating (`readinessProbe.httpGet.path: /does-not-exist`)

```console
$ kubectl get endpoints web-service -n s13-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME          ENDPOINTS                       AGE
web-service   10.244.1.25:80,10.244.1.27:80   39m

$ kubectl patch deployment web-app -n s13-mini --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe/httpGet/path","value":"/does-not-exist"}]'
deployment.apps/web-app patched

$ kubectl get pods -n s13-mini
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5945bfc776-r8mw9   0/1     Running   0          40s
web-app-5945bfc776-zltlc   0/1     Running   0          40s

$ kubectl get endpoints web-service -n s13-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME          ENDPOINTS   AGE
web-service               40m

$ kubectl describe pod web-app-5945bfc776-r8mw9 -n s13-mini | grep -E 'Readiness|Ready:|Restart Count'
    Ready:          False
    Restart Count:  0
    Readiness:    http-get http://:80/does-not-exist delay=5s timeout=2s period=5s #success=1 #failure=2
  Warning  Unhealthy  1s (x7 over 31s)  kubelet            spec.containers{nginx}: Readiness probe failed: HTTP probe failed with statuscode: 404

$ kubectl logs web-app-5945bfc776-r8mw9 -n s13-mini --tail=3
10.244.1.1 - - [06/Oct/2026:11:43:16 +0000] "GET / HTTP/1.1" 200 615 "-" "kube-probe/1.37" "-"
2026/10/06 11:43:20 [error] 33#33: *15 open() "/usr/share/nginx/html/does-not-exist" failed (2: No such file or directory), client: 10.244.1.1, server: localhost, request: "GET /does-not-exist HTTP/1.1", host: "10.244.1.130:80"
10.244.1.1 - - [06/Oct/2026:11:43:20 +0000] "GET /does-not-exist HTTP/1.1" 404 153 "-" "kube-probe/1.37" "-"
```

As the spec predicts: the pods are `Running`, but `READY 0/1`, and the Service has **no endpoints**. A failing readiness probe removes the pod from load balancing and **never restarts it** (`Restart Count: 0`). The nginx log shows both probes at work: the startup and liveness probes on `/` get 200, and the readiness probe on `/does-not-exist` gets 404.

Restore:

```console
$ kubectl apply -f deployment.yaml
deployment.apps/web-app configured

$ kubectl get pods -n s13-mini
NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-kt2tg   1/1     Running   0          15s
web-app-d45775485-rgd9t   1/1     Running   0          15s

$ kubectl get endpoints web-service -n s13-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME          ENDPOINTS                         AGE
web-service   10.244.1.131:80,10.244.1.132:80   40m
```

### Challenge 3 - liveness restart loop (`livenessProbe.httpGet.path: /crash`)

```console
$ kubectl patch deployment web-app -n s13-mini --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/httpGet/path","value":"/crash"}]'
deployment.apps/web-app patched

$ kubectl get pods -n s13-mini -w     # watched for ~75s
NAME                      READY   STATUS    RESTARTS   AGE
web-app-85d86b65d-55qhq   1/1     Running   0          10s
web-app-85d86b65d-q8vmq   1/1     Running   0          10s
web-app-85d86b65d-55qhq   0/1     Running   1 (0s ago)   15s
web-app-85d86b65d-q8vmq   0/1     Running   1 (0s ago)   15s
...
web-app-85d86b65d-55qhq   1/1     Running   1 (8s ago)   23s
web-app-85d86b65d-q8vmq   1/1     Running   1 (8s ago)   23s
web-app-85d86b65d-q8vmq   0/1     Running   2 (0s ago)   30s
web-app-85d86b65d-55qhq   0/1     Running   2 (0s ago)   30s
...
web-app-85d86b65d-55qhq   1/1     Running   2 (9s ago)   39s
web-app-85d86b65d-q8vmq   1/1     Running   2 (9s ago)   39s
web-app-85d86b65d-q8vmq   0/1     Running   3 (0s ago)   45s
web-app-85d86b65d-55qhq   0/1     Running   3 (0s ago)   45s
...
web-app-85d86b65d-55qhq   1/1     Running   3 (8s ago)   53s
web-app-85d86b65d-q8vmq   1/1     Running   3 (8s ago)   53s
web-app-85d86b65d-q8vmq   0/1     CrashLoopBackOff   3 (1s ago)   61s
web-app-85d86b65d-55qhq   0/1     CrashLoopBackOff   3 (1s ago)   61s

$ kubectl describe pod web-app-85d86b65d-55qhq -n s13-mini | grep -E 'Liveness|Restart Count|Last State|Reason|Exit Code'
      Reason:       CrashLoopBackOff
    Last State:     Terminated
      Reason:       Completed
      Exit Code:    0
    Restart Count:  3
    Liveness:     http-get http://:80/crash delay=5s timeout=2s period=5s #success=1 #failure=3
  Type     Reason     Age                 From               Message
  Warning  Unhealthy  25s (x12 over 80s)  kubelet            spec.containers{nginx}: Liveness probe failed: HTTP probe failed with statuscode: 404

$ kubectl events -n s13-mini --for pod/web-app-85d86b65d-55qhq | tail -6
40s (x4 over 85s)    Normal    Pulled      Pod/web-app-85d86b65d-55qhq   Container image "nginx:1.27" already present on machine and can be accessed by the pod
40s (x4 over 85s)    Normal    Created     Pod/web-app-85d86b65d-55qhq   Container created
40s (x4 over 85s)    Normal    Started     Pod/web-app-85d86b65d-55qhq   Container started
25s (x12 over 80s)   Warning   Unhealthy   Pod/web-app-85d86b65d-55qhq   Liveness probe failed: HTTP probe failed with statuscode: 404
25s (x4 over 70s)    Normal    Killing     Pod/web-app-85d86b65d-55qhq   Container nginx failed liveness probe, will be restarted
22s (x3 over 25s)    Warning   BackOff     Pod/web-app-85d86b65d-55qhq   Back-off restarting failed container nginx in pod web-app-85d86b65d-55qhq_s13-mini(1f57f7c9-25af-42d9-b085-81430502ea24)

$ kubectl logs web-app-85d86b65d-55qhq -n s13-mini --previous | grep crash | tail -3
2026/10/06 11:44:31 [error] 34#34: *4 open() "/usr/share/nginx/html/crash" failed (2: No such file or directory), client: 10.244.1.1, server: localhost, request: "GET /crash HTTP/1.1", host: "10.244.1.134:80"
10.244.1.1 - - [06/Oct/2026:11:44:36 +0000] "GET /crash HTTP/1.1" 404 153 "-" "kube-probe/1.37" "-"
2026/10/06 11:44:36 [error] 38#38: *6 open() "/usr/share/nginx/html/crash" failed (2: No such file or directory), client: 10.244.1.1, server: localhost, request: "GET /crash HTTP/1.1", host: "10.244.1.134:80"
```

The RESTARTS count went up **every 15 seconds** (at AGE 15s, 30s and 45s), as the spec predicts: `initialDelaySeconds 5` + `failureThreshold 3` x `periodSeconds 5` = 15s. The kubelet kills the container (`Killing ... failed liveness probe`), and nginx exits cleanly on SIGTERM, which is why `Last State` is `Completed / Exit Code 0`. After a few restarts the kubelet adds back-off delays (`CrashLoopBackOff`). A wrong liveness probe can take down a perfectly healthy app, so liveness paths must point at a cheap endpoint that always succeeds while the process is healthy.

Restore everything and re-check the data:

```console
$ kubectl apply -f deployment.yaml
deployment.apps/web-app configured

$ kubectl get pods -n s13-mini
NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-56nln   1/1     Running   0          29s
web-app-d45775485-r4cgx   1/1     Running   0          29s

$ kubectl exec -n s13-mini $(kubectl get pods -n s13-mini -l app=web-app -o jsonpath='{.items[0].metadata.name}') -- cat /data/student.txt
Student: Ujjawal Prabhat (24BCS10267)

$ kubectl apply -f hpa.yaml
horizontalpodautoscaler.autoscaling/web-app-hpa configured

$ kubectl get hpa,deploy,svc,pvc -n s13-mini
NAME                                              REFERENCE            TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
horizontalpodautoscaler.autoscaling/web-app-hpa   Deployment/web-app   cpu: <unknown>/50%   2         5         2          42m

NAME                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web-app   2/2     2            2           42m

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web-service   ClusterIP   10.96.190.253   <none>        80/TCP    42m

NAME                             STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
persistentvolumeclaim/web-data   Bound    pvc-b9327871-8cb7-43b8-bf6a-e8e669f30681   500Mi      RWO            standard       <unset>                 42m
```

After all those pod re-creations, the PVC data is still there. `<unknown>/50%` here is the brief window just after the pods were replaced, before metrics-server has a sample for them (Troubleshooting Issue 2 in the spec).

## Probe reference

| Probe | Question | On failure | Seen here |
|---|---|---|---|
| startupProbe | Has the app finished starting? | Restart (other probes are disabled until it passes) | nginx starts in under 2s, so it passed at once |
| readinessProbe | Can it take traffic now? | Removed from Service endpoints, **no restart** | Challenge 2: endpoints empty, restarts 0 |
| livenessProbe | Is it still alive? | Container restarted | Challenge 3: restart every 15s, then CrashLoopBackOff |
