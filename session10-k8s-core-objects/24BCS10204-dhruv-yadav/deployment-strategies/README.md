# Task 1 - Deployment Strategies

**Student:** Dhruv Yadav | **Enrollment:** 24BCS10204 | **Session 10** - Pods, ReplicaSets & Deployments

- [x] Rolling update (maxSurge / maxUnavailable, image update, watched rollout, old vs new ReplicaSet)
- [x] Blue-green (two Deployments, Service selector switch, curl shows the version change)
- [x] Canary (9 stable + 1 canary behind one shared label, 50-request samples)
- [x] Recreate (`kubectl get pods -w` timeline: all old pods terminate before any new pod is created)

**Test app:** `hashicorp/http-echo` (multi-arch, so it runs on my arm64 kind nodes). It replies with whatever
`-text=` says, so every response shows its version. "v1" uses the image tag `hashicorp/http-echo:1.0` and
"v2" uses `hashicorp/http-echo:1.0.0`. Both tags point to the same binary (same digest). The tag change is
there so `kubectl get rs -o wide` shows an image change, and the `-text` change makes the version visible.

All Services are `ClusterIP`. I test them with a curl client pod ([`client-pod.yaml`](client-pod.yaml)) in namespace `s10`.

```
$ kubectl create ns s10
namespace/s10 created
$ kubectl apply -f client-pod.yaml
pod/client created
```

---

## 1. Rolling update - [`01-rolling-update/`](01-rolling-update)

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # at most 4 + 1 = 5 pods exist during the rollout
    maxUnavailable: 0  # never go below 4 ready pods
```

With 4 replicas the controller adds 1 new pod. When that pod passes its **readinessProbe**, it removes 1 old pod. It repeats this until all 4 pods are new.

### Deploy v1

```
$ kubectl apply -f deployment-v1.yaml -f service.yaml
deployment.apps/web-rolling created
service/web-rolling created

$ kubectl -n s10 rollout status deploy/web-rolling --timeout=120s
Waiting for deployment "web-rolling" rollout to finish: 0 of 4 updated replicas are available...
Waiting for deployment "web-rolling" rollout to finish: 1 of 4 updated replicas are available...
Waiting for deployment "web-rolling" rollout to finish: 2 of 4 updated replicas are available...
Waiting for deployment "web-rolling" rollout to finish: 3 of 4 updated replicas are available...
deployment "web-rolling" successfully rolled out

$ kubectl -n s10 get deploy,rs,pods -l app=web-rolling -o wide
NAME                                     DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                    SELECTOR
replicaset.apps/web-rolling-5b5979485b   4         4         4       5s    web          hashicorp/http-echo:1.0   app=web-rolling,pod-template-hash=5b5979485b

NAME                               READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
pod/web-rolling-5b5979485b-f9r4x   1/1     Running   0          5s    10.244.1.90   devops-heros-worker2   <none>           <none>
pod/web-rolling-5b5979485b-kl2kg   1/1     Running   0          5s    10.244.2.69   devops-heros-worker    <none>           <none>
pod/web-rolling-5b5979485b-rc8t9   1/1     Running   0          5s    10.244.2.68   devops-heros-worker    <none>           <none>
pod/web-rolling-5b5979485b-tdqx9   1/1     Running   0          5s    10.244.1.89   devops-heros-worker2   <none>           <none>

$ kubectl -n s10 exec client -- sh -c 'for i in 1 2 3 4 5; do curl -s web-rolling; done'
v1
v1
v1
v1
v1
```

### Update the image (v1 -> v2) and watch the rollout

[`deployment-v2.yaml`](01-rolling-update/deployment-v2.yaml) changes the image `http-echo:1.0 -> 1.0.0` and the text `v1 -> v2`.
While it ran I had three things recording: `kubectl get pods -w`, `kubectl get rs -w`, and a curl loop in the client pod (100 requests, one every 0.25 s).

```
$ kubectl apply -f deployment-v2.yaml
deployment.apps/web-rolling configured

$ kubectl -n s10 rollout status deploy/web-rolling --timeout=180s
Waiting for deployment "web-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 1 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 2 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 3 out of 4 new replicas have been updated...
Waiting for deployment "web-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web-rolling" rollout to finish: 1 old replicas are pending termination...
Waiting for deployment "web-rolling" rollout to finish: 1 old replicas are pending termination...
deployment "web-rolling" successfully rolled out
```

`kubectl -n s10 get rs -l app=web-rolling -w` (timestamps added). The new RS goes up by one and the old RS goes down by one, repeated 4 times:

```
19:28:55 NAME                     DESIRED   CURRENT   READY   AGE
19:28:55 web-rolling-5b5979485b   4         4         4       5s
19:28:57 web-rolling-6c88d89748   1         0         0       0s
19:28:57 web-rolling-6c88d89748   1         1         0       0s
19:29:01 web-rolling-6c88d89748   1         1         1       4s
19:29:01 web-rolling-5b5979485b   3         4         4       11s
19:29:01 web-rolling-6c88d89748   2         1         1       4s
19:29:01 web-rolling-5b5979485b   3         3         3       11s
19:29:01 web-rolling-6c88d89748   2         2         1       4s
19:29:05 web-rolling-6c88d89748   2         2         2       8s
19:29:05 web-rolling-5b5979485b   2         3         3       15s
19:29:05 web-rolling-6c88d89748   3         2         2       8s
19:29:05 web-rolling-5b5979485b   2         2         2       15s
19:29:05 web-rolling-6c88d89748   3         3         2       8s
19:29:08 web-rolling-6c88d89748   3         3         3       11s
19:29:08 web-rolling-5b5979485b   1         2         2       18s
19:29:08 web-rolling-6c88d89748   4         3         3       11s
19:29:08 web-rolling-5b5979485b   1         1         1       18s
19:29:08 web-rolling-6c88d89748   4         4         3       11s
19:29:11 web-rolling-6c88d89748   4         4         4       14s
19:29:11 web-rolling-5b5979485b   0         1         1       21s
19:29:11 web-rolling-5b5979485b   0         0         0       21s
...(duplicate status lines removed)
```

`kubectl -n s10 get pods -l app=web-rolling -w --output-watch-events` (excerpt). Each old pod moves to `Terminating` only after a new pod reaches `1/1`:

```
19:28:57 ADDED      web-rolling-6c88d89748-df8dj   0/1     Pending             0          0s
19:28:57 MODIFIED   web-rolling-6c88d89748-df8dj   0/1     ContainerCreating   0          0s
19:28:58 MODIFIED   web-rolling-6c88d89748-df8dj   0/1     Running             0          1s
19:29:01 MODIFIED   web-rolling-6c88d89748-df8dj   1/1     Running             0          4s
19:29:01 MODIFIED   web-rolling-5b5979485b-kl2kg   1/1     Terminating         0          11s
19:29:01 ADDED      web-rolling-6c88d89748-2cgqd   0/1     Pending             0          0s
19:29:02 MODIFIED   web-rolling-6c88d89748-2cgqd   0/1     Running             0          1s
19:29:05 MODIFIED   web-rolling-6c88d89748-2cgqd   1/1     Running             0          4s
19:29:05 MODIFIED   web-rolling-5b5979485b-tdqx9   1/1     Terminating         0          15s
19:29:05 ADDED      web-rolling-6c88d89748-dvx4x   0/1     Pending             0          0s
19:29:07 DELETED    web-rolling-5b5979485b-kl2kg   0/1     Error               0          17s
19:29:08 MODIFIED   web-rolling-6c88d89748-dvx4x   1/1     Running             0          3s
19:29:08 MODIFIED   web-rolling-5b5979485b-f9r4x   1/1     Terminating         0          18s
19:29:08 ADDED      web-rolling-6c88d89748-62s2l   0/1     Pending             0          0s
19:29:11 MODIFIED   web-rolling-6c88d89748-62s2l   1/1     Running             0          3s
19:29:11 MODIFIED   web-rolling-5b5979485b-rc8t9   1/1     Terminating         0          21s
19:29:17 DELETED    web-rolling-5b5979485b-rc8t9   0/1     Error               0          27s
```

(`Error` on the old pods means http-echo exits with a non-zero code on SIGTERM. The pods were still deleted normally.)

Traffic during the rollout: 100 requests and **0 failures**. v1 and v2 answers are mixed while both ReplicaSets serve:

```
$ awk '{print $2}' traffic.txt | sort | uniq -c
  43 v1
  57 v2

# middle of the rollout (client-pod clock is UTC):
11:29:01 v1 11:29:01 v1 11:29:01 v1 11:29:02 v1 11:29:02 v2 11:29:02 v1 11:29:02 v2 11:29:03 v2 11:29:03 v1 11:29:03 v1
11:29:03 v1 11:29:04 v1 11:29:04 v1 11:29:04 v2 11:29:04 v1 11:29:05 v2 11:29:05 v2 11:29:05 v2 11:29:05 v2 11:29:06 v2
11:29:06 v1 11:29:06 v1 11:29:06 v2 11:29:07 v1 11:29:07 v1 11:29:07 v1 11:29:07 v2 11:29:08 v1 11:29:08 v2 11:29:08 v2
11:29:08 v1 11:29:09 v2 11:29:09 v2 11:29:09 v2 11:29:10 v2 11:29:10 v2 11:29:10 v2
```

> **What I learned (real failure in my first attempt):** my first run had no `preStop` hook, and 1 of 60
> requests failed (`11:28:16 FAIL`, totals `1 FAIL / 51 v1 / 8 v2`). The old pod got SIGTERM and stopped
> **before** kube-proxy had removed its IP from the iptables rules, so one connection went to a dead pod.
> `maxUnavailable: 0` alone did not prevent this. I added `lifecycle.preStop.sleep: {seconds: 5}`, which keeps the old
> container serving while its endpoint is removed. The second run (shown above) had 0 failures.

### Old vs new ReplicaSet after the rollout

```
$ kubectl -n s10 get rs -l app=web-rolling -o wide
NAME                     DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                      SELECTOR
web-rolling-5b5979485b   0         0         0       33s   web          hashicorp/http-echo:1.0     app=web-rolling,pod-template-hash=5b5979485b
web-rolling-6c88d89748   4         4         4       26s   web          hashicorp/http-echo:1.0.0   app=web-rolling,pod-template-hash=6c88d89748

$ kubectl -n s10 get pods -l app=web-rolling -L version
NAME                           READY   STATUS    RESTARTS   AGE   VERSION
web-rolling-6c88d89748-2cgqd   1/1     Running   0          22s   v2
web-rolling-6c88d89748-62s2l   1/1     Running   0          15s   v2
web-rolling-6c88d89748-df8dj   1/1     Running   0          26s   v2
web-rolling-6c88d89748-dvx4x   1/1     Running   0          18s   v2

$ kubectl -n s10 describe deploy web-rolling | sed -n '/StrategyType/,/RollingUpdateStrategy/p;/^Events/,$p'
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  0 max unavailable, 1 max surge
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  33s   deployment-controller  Scaled up replica set web-rolling-5b5979485b from 0 to 4
  Normal  ScalingReplicaSet  26s   deployment-controller  Scaled up replica set web-rolling-6c88d89748 from 0 to 1
  Normal  ScalingReplicaSet  22s   deployment-controller  Scaled down replica set web-rolling-5b5979485b from 4 to 3
  Normal  ScalingReplicaSet  22s   deployment-controller  Scaled up replica set web-rolling-6c88d89748 from 1 to 2
  Normal  ScalingReplicaSet  18s   deployment-controller  Scaled down replica set web-rolling-5b5979485b from 3 to 2
  Normal  ScalingReplicaSet  18s   deployment-controller  Scaled up replica set web-rolling-6c88d89748 from 2 to 3
  Normal  ScalingReplicaSet  15s   deployment-controller  Scaled down replica set web-rolling-5b5979485b from 2 to 1
  Normal  ScalingReplicaSet  15s   deployment-controller  Scaled up replica set web-rolling-6c88d89748 from 3 to 4
  Normal  ScalingReplicaSet  12s   deployment-controller  Scaled down replica set web-rolling-5b5979485b from 1 to 0

$ kubectl -n s10 rollout history deploy/web-rolling
deployment.apps/web-rolling
REVISION  CHANGE-CAUSE
1         v1 - http-echo:1.0
2         v2 - http-echo:1.0.0 (image + text change)
```

The old ReplicaSet stays at `0` replicas. It is what `kubectl rollout undo` scales back up when you roll back.

---

## 2. Blue-green - [`02-blue-green/`](02-blue-green)

Two complete Deployments run side by side: `app-blue` (v1) and `app-green` (v2). They share `app: bg-app` and differ by
`slot: blue|green`. The Service selects `app=bg-app,slot=<colour>`, so changing **one selector field**
moves 100% of traffic in one step.

```
$ kubectl apply -f deployment-blue.yaml -f service.yaml
deployment.apps/app-blue created
service/bg-app created

$ kubectl -n s10 rollout status deploy/app-blue --timeout=120s
Waiting for deployment "app-blue" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "app-blue" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "app-blue" rollout to finish: 2 of 3 updated replicas are available...
deployment "app-blue" successfully rolled out

$ kubectl -n s10 exec client -- sh -c 'for i in 1 2 3 4 5; do curl -s bg-app; done'
v1 (BLUE)
v1 (BLUE)
v1 (BLUE)
v1 (BLUE)
v1 (BLUE)
```

Deploy green next to blue. Green gets no traffic yet:

```
$ kubectl apply -f deployment-green.yaml
deployment.apps/app-green created

$ kubectl -n s10 rollout status deploy/app-green --timeout=120s
Waiting for deployment "app-green" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "app-green" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "app-green" rollout to finish: 2 of 3 updated replicas are available...
deployment "app-green" successfully rolled out

$ kubectl -n s10 get deploy app-blue app-green -o wide
NAME        READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                      SELECTOR
app-blue    3/3     3            3           7s    web          hashicorp/http-echo:1.0     app=bg-app,slot=blue
app-green   3/3     3            3           2s    web          hashicorp/http-echo:1.0.0   app=bg-app,slot=green

$ kubectl -n s10 get pods -l app=bg-app -L slot,version
NAME                        READY   STATUS    RESTARTS   AGE   SLOT    VERSION
app-blue-f4668b997-mjq7h    1/1     Running   0          7s    blue    v1
app-blue-f4668b997-pcnmx    1/1     Running   0          7s    blue    v1
app-blue-f4668b997-pnwff    1/1     Running   0          7s    blue    v1
app-green-ddb44cb77-fstwd   1/1     Running   0          2s    green   v2
app-green-ddb44cb77-qcccn   1/1     Running   0          2s    green   v2
app-green-ddb44cb77-scdmh   1/1     Running   0          2s    green   v2

$ kubectl -n s10 get svc bg-app -o jsonpath='{.spec.selector}{"\n"}'
{"app":"bg-app","slot":"blue"}

$ kubectl -n s10 get endpointslices -l kubernetes.io/service-name=bg-app
NAME           ADDRESSTYPE   PORTS   ENDPOINTS                             AGE
bg-app-w4zsw   IPv4          5678    10.244.1.97,10.244.2.78,10.244.2.77   7s

$ kubectl -n s10 exec client -- sh -c 'for i in 1 2 3 4 5; do curl -s bg-app; done'
v1 (BLUE)
v1 (BLUE)
v1 (BLUE)
v1 (BLUE)
v1 (BLUE)

# smoke-test green directly by pod IP before it gets real traffic
$ kubectl -n s10 exec client -- curl -s 10.244.2.79:5678
v2 (GREEN)
```

**The switch:**

```
$ kubectl -n s10 patch svc bg-app -p '{"spec":{"selector":{"app":"bg-app","slot":"green"}}}'
service/bg-app patched

$ kubectl -n s10 get svc bg-app -o jsonpath='{.spec.selector}{"\n"}'
{"app":"bg-app","slot":"green"}

$ kubectl -n s10 get endpointslices -l kubernetes.io/service-name=bg-app
NAME           ADDRESSTYPE   PORTS   ENDPOINTS                             AGE
bg-app-w4zsw   IPv4          5678    10.244.1.98,10.244.2.79,10.244.1.99   10s

$ kubectl -n s10 exec client -- sh -c 'for i in 1 2 3 4 5; do curl -s bg-app; done'
v2 (GREEN)
v2 (GREEN)
v2 (GREEN)
v2 (GREEN)
v2 (GREEN)
```

The EndpointSlice now lists the 3 green pod IPs, and every response is `v2 (GREEN)`. **Instant rollback** is the same patch in reverse:

```
$ kubectl -n s10 patch svc bg-app -p '{"spec":{"selector":{"app":"bg-app","slot":"blue"}}}'
service/bg-app patched

$ kubectl -n s10 exec client -- sh -c 'for i in 1 2 3; do curl -s bg-app; done'
v1 (BLUE)
v1 (BLUE)
v1 (BLUE)

$ kubectl -n s10 patch svc bg-app -p '{"spec":{"selector":{"app":"bg-app","slot":"green"}}}'
service/bg-app patched

$ kubectl -n s10 exec client -- sh -c 'for i in 1 2 3; do curl -s bg-app; done'
v2 (GREEN)
v2 (GREEN)
v2 (GREEN)

# once green is confirmed good, retire blue
$ kubectl -n s10 scale deploy app-blue --replicas=0
deployment.apps/app-blue scaled
```

Trade-off: blue-green needs **2x the resources** during the switch, but the cut-over and the rollback both happen in one step.

---

## 3. Canary - [`03-canary/`](03-canary)

`app-stable` has 9 replicas (v1) and `app-canary` has 1 replica (v2). Both carry the **shared label** `app: canary-app`. The Service
selects only that label. kube-proxy picks a backend at random for each new connection, so the canary
gets about 1/10 of the requests.

```
$ kubectl apply -f deployment-stable.yaml -f deployment-canary.yaml -f service.yaml
deployment.apps/app-stable created
deployment.apps/app-canary created
service/canary-app created

$ kubectl -n s10 get deploy app-stable app-canary
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
app-stable   9/9     9            9           7s
app-canary   1/1     1            1           7s

$ kubectl -n s10 get pods -l app=canary-app -L track,version
NAME                          READY   STATUS    RESTARTS   AGE   TRACK    VERSION
app-canary-5d84bcdf7f-g5php   1/1     Running   0          7s    canary   v2
app-stable-669f8c97-4n2cc     1/1     Running   0          7s    stable   v1
app-stable-669f8c97-6rwbc     1/1     Running   0          7s    stable   v1
app-stable-669f8c97-8g5t2     1/1     Running   0          7s    stable   v1
app-stable-669f8c97-jff5z     1/1     Running   0          7s    stable   v1
app-stable-669f8c97-jzm49     1/1     Running   0          7s    stable   v1
app-stable-669f8c97-n4qnr     1/1     Running   0          7s    stable   v1
app-stable-669f8c97-rcqv9     1/1     Running   0          7s    stable   v1
app-stable-669f8c97-v8w8b     1/1     Running   0          7s    stable   v1
app-stable-669f8c97-x9n6b     1/1     Running   0          7s    stable   v1

$ kubectl -n s10 get svc canary-app -o jsonpath='{.spec.selector}{"\n"}'
{"app":"canary-app"}

$ kubectl -n s10 get endpointslices -l kubernetes.io/service-name=canary-app -o jsonpath='{range .items[*].endpoints[*]}{.addresses[0]}{"  "}{.targetRef.name}{"\n"}{end}'
10.244.2.81  app-stable-669f8c97-n4qnr
10.244.1.104  app-stable-669f8c97-x9n6b
10.244.1.102  app-stable-669f8c97-jff5z
10.244.1.103  app-stable-669f8c97-v8w8b
10.244.2.86  app-stable-669f8c97-rcqv9
10.244.1.105  app-stable-669f8c97-6rwbc
10.244.2.84  app-stable-669f8c97-4n2cc
10.244.2.82  app-stable-669f8c97-8g5t2
10.244.2.83  app-stable-669f8c97-jzm49
10.244.2.85  app-canary-5d84bcdf7f-g5php
```

Sampling 50 requests (twice), then 500 for a steadier number:

```
$ kubectl -n s10 exec client -- sh -c 'for i in $(seq 1 50); do curl -s canary-app; done' | sort | uniq -c
  42 v1-stable
   8 v2-canary

$ kubectl -n s10 exec client -- sh -c 'for i in $(seq 1 50); do curl -s canary-app; done' | sort | uniq -c
  46 v1-stable
   4 v2-canary

$ kubectl -n s10 exec client -- sh -c 'for i in $(seq 1 500); do curl -s canary-app; done' | sort | uniq -c
 455 v1-stable
  45 v2-canary
```

The two 50-request samples gave 16% and 8% canary. With only 50 requests, random selection moves the number around a lot.
With 500 requests it came out at **9%**, close to the expected 10% (1 of 10 pods).

Promoting the canary to 50% by changing replica counts:

```
$ kubectl -n s10 scale deploy app-stable --replicas=5
deployment.apps/app-stable scaled

$ kubectl -n s10 scale deploy app-canary --replicas=5
deployment.apps/app-canary scaled

$ kubectl -n s10 get deploy app-stable app-canary
NAME         READY   UP-TO-DATE   AVAILABLE   AGE
app-stable   5/5     5            5           22s
app-canary   5/5     5            5           22s

$ kubectl -n s10 exec client -- sh -c 'for i in $(seq 1 50); do curl -s canary-app; done' | sort | uniq -c
  26 v1-stable
  24 v2-canary
```

Limitation: with a plain Service the traffic split depends on the **pod ratio**. Getting exactly 1% would need 99+1 pods.
Ingress-nginx canary annotations, a service mesh (Istio/Linkerd) or Argo Rollouts can split traffic by weight.

---

## 4. Recreate - [`04-recreate/`](04-recreate)

```yaml
strategy:
  type: Recreate
```

v1 pods have a 5 s `preStop` sleep, so the `Terminating` phase is long enough to see in the watch output.

```
$ kubectl apply -f deployment-v1.yaml -f service.yaml
deployment.apps/web-recreate created
service/web-recreate created

$ kubectl -n s10 get pods -l app=web-recreate -L version
NAME                            READY   STATUS    RESTARTS   AGE   VERSION
web-recreate-794f65f64d-466s2   1/1     Running   0          6s    v1
web-recreate-794f65f64d-4skbp   1/1     Running   0          6s    v1
web-recreate-794f65f64d-hzjdc   1/1     Running   0          6s    v1

$ kubectl -n s10 get deploy web-recreate -o jsonpath='{.spec.strategy}{"\n"}'
{"type":"Recreate"}

$ kubectl apply -f deployment-v2.yaml
deployment.apps/web-recreate configured

$ kubectl -n s10 rollout status deploy/web-recreate --timeout=180s
Waiting for deployment "web-recreate" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "web-recreate" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "web-recreate" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "web-recreate" rollout to finish: 0 out of 3 new replicas have been updated...
Waiting for deployment "web-recreate" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "web-recreate" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "web-recreate" rollout to finish: 2 of 3 updated replicas are available...
deployment "web-recreate" successfully rolled out
```

**`kubectl -n s10 get pods -l app=web-recreate -w` timeline** (timestamps added, duplicate status lines removed):

```
19:31:29 NAME                            READY   STATUS    RESTARTS   AGE
19:31:29 web-recreate-794f65f64d-466s2   1/1     Running   0          6s
19:31:29 web-recreate-794f65f64d-4skbp   1/1     Running   0          6s
19:31:29 web-recreate-794f65f64d-hzjdc   1/1     Running   0          6s
19:31:32 web-recreate-794f65f64d-hzjdc   1/1     Terminating   0          9s      <- ALL 3 old pods
19:31:32 web-recreate-794f65f64d-4skbp   1/1     Terminating   0          9s      <- terminate at
19:31:32 web-recreate-794f65f64d-466s2   1/1     Terminating   0          9s      <- the same moment
19:31:37 web-recreate-794f65f64d-4skbp   0/1     Error         0          14s
19:31:37 web-recreate-794f65f64d-466s2   0/1     Error         0          14s
19:31:37 web-recreate-794f65f64d-hzjdc   0/1     Error         0          14s     <- all old containers dead
19:31:37 web-recreate-866cb6dcb8-78ssb   0/1     Pending       0          0s      <- only NOW are
19:31:37 web-recreate-866cb6dcb8-4cfdx   0/1     Pending       0          0s      <- new pods
19:31:37 web-recreate-866cb6dcb8-xrf7b   0/1     Pending       0          0s      <- created
19:31:37 web-recreate-866cb6dcb8-4cfdx   0/1     ContainerCreating   0          0s
19:31:37 web-recreate-866cb6dcb8-78ssb   0/1     ContainerCreating   0          0s
19:31:37 web-recreate-866cb6dcb8-xrf7b   0/1     ContainerCreating   0          0s
19:31:38 web-recreate-866cb6dcb8-4cfdx   0/1     Running             0          1s
19:31:38 web-recreate-866cb6dcb8-78ssb   0/1     Running             0          1s
19:31:38 web-recreate-866cb6dcb8-xrf7b   0/1     Running             0          1s
19:31:39 web-recreate-866cb6dcb8-xrf7b   1/1     Running             0          2s
19:31:39 web-recreate-866cb6dcb8-78ssb   1/1     Running             0          2s
19:31:39 web-recreate-866cb6dcb8-4cfdx   1/1     Running             0          2s
```

Traffic from the client during the update (60 requests, client clock is UTC). There is a gap where nothing answers:

```
$ awk '{$1=""; print}' traffic.txt | uniq -c
  28  v1
   5  FAIL (no endpoints)
  27  v2

...
11:31:36 v1
11:31:37 v1
11:31:37 FAIL (no endpoints)
11:31:38 FAIL (no endpoints)
11:31:38 FAIL (no endpoints)
11:31:39 FAIL (no endpoints)
11:31:39 FAIL (no endpoints)
11:31:39 v2
...
```

v1 kept answering during its `Terminating` window. When no ready endpoints exist, kube-proxy still sends traffic
to endpoints that are terminating but still serving. Once the old containers exited, nothing could answer
until the new pods passed readiness: **about 2 seconds of downtime**. In a real app with a slow start, this gap would be longer.

```
$ kubectl -n s10 get rs -l app=web-recreate -o wide
NAME                      DESIRED   CURRENT   READY   AGE   CONTAINERS   IMAGES                      SELECTOR
web-recreate-794f65f64d   0         0         0       24s   web          hashicorp/http-echo:1.0     app=web-recreate,pod-template-hash=794f65f64d
web-recreate-866cb6dcb8   3         3         3       10s   web          hashicorp/http-echo:1.0.0   app=web-recreate,pod-template-hash=866cb6dcb8

$ kubectl -n s10 describe deploy web-recreate | sed -n '/StrategyType/p;/^Events/,$p'
StrategyType:       Recreate
Events:
  Type    Reason             Age   From                   Message
  ----    ------             ----  ----                   -------
  Normal  ScalingReplicaSet  24s   deployment-controller  Scaled up replica set web-recreate-794f65f64d from 0 to 3
  Normal  ScalingReplicaSet  15s   deployment-controller  Scaled down replica set web-recreate-794f65f64d from 3 to 0
  Normal  ScalingReplicaSet  10s   deployment-controller  Scaled up replica set web-recreate-866cb6dcb8 from 0 to 3
```

The events show the difference from a rolling update: the old RS goes `3 -> 0` in **one** step, and only after that does the new RS go `0 -> 3`.

---

## Comparison

| Strategy | Downtime | Two versions live at once? | Extra resources | Rollback | Use when |
|---|---|---|---|---|---|
| Rolling update | None (with readiness + preStop) | Yes, briefly | +maxSurge pods | `rollout undo` (gradual) | Default for stateless apps |
| Blue-green | None | No, traffic switches in one step | 2x | Flip the selector back (instant) | Releases you must be able to undo instantly |
| Canary | None | Yes, on purpose (ratio) | +canary pods | Scale canary to 0 | Testing a risky change on a small share of users |
| Recreate | **Yes** (~2 s here) | Never | None | Redeploy the old version | Versions that cannot coexist (DB schema, singleton, RWO volume) |
