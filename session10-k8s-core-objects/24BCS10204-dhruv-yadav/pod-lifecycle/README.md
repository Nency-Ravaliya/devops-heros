# Task 2 - Pod Lifecycle

**Student:** Dhruv Yadav | **Enrollment:** 24BCS10204 | **Session 10** - Pods, ReplicaSets & Deployments

- [x] Applied every manifest from the course folder [`../../pod-lifecycle/`](../../pod-lifecycle) (01-12) into namespace `s10`
- [x] For each: `kubectl get pod`, phase, `kubectl describe pod` (trimmed), logs where useful, and an explanation
- [x] Extra: [`13-lifecycle-hooks.yaml`](13-lifecycle-hooks.yaml) showing `postStart` / `preStop` hooks

## Background

**Pod phase** (`.status.phase`) has 5 values: `Pending`, `Running`, `Succeeded`, `Failed`, `Unknown`.
Names like `CrashLoopBackOff`, `ImagePullBackOff`, `Init:0/1` and `Completed` are **container states and reasons** that `kubectl get` shows in
the STATUS column. They are not phases. **Pod conditions** (`PodScheduled`, `PodReadyToStartContainers`, `Initialized`, `ContainersReady`, `Ready`)
show how far the pod has progressed.

```
create -> Pending --(scheduled, images pulled, init done)--> Running --(all containers exit 0)--> Succeeded
                                                              \--(a container exits non-0, restartPolicy Never)--> Failed
```

All 11 manifests were applied at once:

```
$ for f in 01-running.yaml 02-pending.yaml 03-succeeded.yaml 04-failed.yaml 05-crashloopbackoff.yaml 06-imagepullbackoff.yaml 07-readiness.yaml 08-liveness.yaml 09-startup.yaml 10-init-container.yaml 11-multi-container.yaml; do kubectl apply -n s10 -f $f; done
pod/lifecycle-running created
pod/lifecycle-pending created
pod/lifecycle-succeeded created
pod/lifecycle-failed created
pod/lifecycle-crashloop created
pod/lifecycle-image-error created
pod/lifecycle-readiness created
pod/lifecycle-liveness created
pod/lifecycle-startup created
pod/lifecycle-init created
pod/lifecycle-multi-container created

######## T+3s
$ kubectl -n s10 get pods -l '!app' -o wide
NAME                        READY   STATUS              RESTARTS   AGE     IP             NODE                   NOMINATED NODE   READINESS GATES
client                      1/1     Running             0          5m28s   10.244.2.59    devops-heros-worker    <none>           <none>
lifecycle-crashloop         1/1     Running             0          4s      10.244.1.116   devops-heros-worker2   <none>           <none>
lifecycle-failed            1/1     Running             0          4s      10.244.2.96    devops-heros-worker    <none>           <none>
lifecycle-image-error       0/1     ContainerCreating   0          4s      <none>         devops-heros-worker    <none>           <none>
lifecycle-init              0/1     Init:0/1            0          3s      10.244.2.99    devops-heros-worker    <none>           <none>
lifecycle-liveness          1/1     Running             0          3s      10.244.2.98    devops-heros-worker    <none>           <none>
lifecycle-multi-container   2/2     Running             0          3s      10.244.1.119   devops-heros-worker2   <none>           <none>
lifecycle-pending           0/1     Pending             0          4s      <none>         <none>                 <none>           <none>
lifecycle-readiness         0/1     Running             0          4s      10.244.1.117   devops-heros-worker2   <none>           <none>
lifecycle-running           1/1     Running             0          4s      10.244.2.95    devops-heros-worker    <none>           <none>
lifecycle-startup           0/1     Running             0          3s      10.244.1.118   devops-heros-worker2   <none>           <none>
lifecycle-succeeded         1/1     Running             0          4s      10.244.1.115   devops-heros-worker2   <none>           <none>

######## T+15s
$ kubectl -n s10 get pods -l '!app'
NAME                        READY   STATUS             RESTARTS      AGE
client                      1/1     Running            0             5m40s
lifecycle-crashloop         0/1     Error              1 (12s ago)   16s
lifecycle-failed            0/1     Error              0             16s
lifecycle-image-error       0/1     ImagePullBackOff   0             16s
lifecycle-init              1/1     Running            0             15s
lifecycle-liveness          1/1     Running            0             15s
lifecycle-multi-container   2/2     Running            0             15s
lifecycle-pending           0/1     Pending            0             16s
lifecycle-readiness         1/1     Running            0             16s
lifecycle-running           1/1     Running            0             16s
lifecycle-startup           0/1     Running            0             15s
lifecycle-succeeded         0/1     Completed          0             16s

######## T+50s
$ kubectl -n s10 get pods -l '!app'
NAME                        READY   STATUS             RESTARTS      AGE
client                      1/1     Running            0             6m15s
lifecycle-crashloop         0/1     Error              2 (43s ago)   51s
lifecycle-failed            0/1     Error              0             51s
lifecycle-image-error       0/1     ImagePullBackOff   0             51s
lifecycle-init              1/1     Running            0             50s
lifecycle-liveness          1/1     Running            0             50s
lifecycle-multi-container   2/2     Running            0             50s
lifecycle-pending           0/1     Pending            0             51s
lifecycle-readiness         1/1     Running            0             51s
lifecycle-running           1/1     Running            0             51s
lifecycle-startup           1/1     Running            0             50s
lifecycle-succeeded         0/1     Completed          0             51s

######## T+90s
$ kubectl -n s10 get pods -l '!app'
NAME                        READY   STATUS             RESTARTS      AGE
client                      1/1     Running            0             6m55s
lifecycle-crashloop         0/1     Error              3 (66s ago)   91s
lifecycle-failed            0/1     Error              0             91s
lifecycle-image-error       0/1     ImagePullBackOff   0             91s
lifecycle-init              1/1     Running            0             90s
lifecycle-liveness          1/1     Running            1 (30s ago)   90s
lifecycle-multi-container   2/2     Running            0             90s
lifecycle-pending           0/1     Pending            0             91s
lifecycle-readiness         1/1     Running            0             91s
lifecycle-running           1/1     Running            0             91s
lifecycle-startup           1/1     Running            0             90s
lifecycle-succeeded         0/1     Completed          0             91s
```

*In the `get` outputs, `-l '!app'` hides my deployment-strategy pods. `client` is my curl pod from Task 1.*

Describe output below is **trimmed** (`...` replaces volumes, QoS, tolerations, IPs and image IDs). The remaining lines are unedited.
Watch lines come from `kubectl -n s10 get pods -w`, with host-clock timestamps added and repeated identical lines removed.

---

## 01. Running - `01-running.yaml`

```yaml
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

**Watch timeline:**

```
19:32:43 lifecycle-running   0/1     Pending   0          0s
19:32:43 lifecycle-running   0/1     ContainerCreating   0          0s
19:32:44 lifecycle-running           1/1     Running             0          1s
```

```
$ kubectl -n s10 get pod lifecycle-running -o wide
NAME                READY   STATUS    RESTARTS   AGE    IP            NODE                  NOMINATED NODE   READINESS GATES
lifecycle-running   1/1     Running   0          108s   10.244.2.95   devops-heros-worker   <none>           <none>

$ kubectl -n s10 get pod lifecycle-running -o jsonpath='{.status.phase}{"\n"}'
Running

$ kubectl -n s10 describe pod lifecycle-running
Name:             lifecycle-running
Namespace:        s10
...
Node:             devops-heros-worker/172.18.0.4
...
Status:           Running
...
Containers:
  nginx:
    Image:          nginx:1.27
    State:          Running
      Started:      Tue, 06 Oct 2026 19:32:44 +0800
    Ready:          True
    Restart Count:  0
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  108s  default-scheduler  Successfully assigned s10/lifecycle-running to devops-heros-worker
  Normal  Pulled     107s  kubelet            spec.containers{nginx}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    107s  kubelet            spec.containers{nginx}: Container created
  Normal  Started    107s  kubelet            spec.containers{nginx}: Container started
```

```
$ kubectl -n s10 get pod lifecycle-running -o jsonpath='{range .status.conditions[*]}{.type}={.status}{"\n"}{end}'
PodReadyToStartContainers=True
Initialized=True
Ready=True
ContainersReady=True
PodScheduled=True

$ kubectl -n s10 exec lifecycle-running -- curl -s -o /dev/null -w '%{http_code}\n' localhost:80
200
```

**Observed:** nginx starts and keeps running. Phase **Running**, and all five conditions are `True`: `PodScheduled` (a node was chosen), `PodReadyToStartContainers` (sandbox and network ready), `Initialized` (no init containers left), `ContainersReady` and `Ready` (no probe is defined, so a running container counts as ready).

---

## 02. Pending (unschedulable) - `02-pending.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-pending
spec:
  containers:
    - name: impossible-resource
      image: nginx:1.27
      resources:
        requests:
          cpu: "1"
          memory: "9Gi"
```

**Watch timeline:**

```
19:32:43 lifecycle-pending   0/1     Pending             0          0s
```

```
$ kubectl -n s10 get pod lifecycle-pending -o wide
NAME                READY   STATUS    RESTARTS   AGE    IP       NODE     NOMINATED NODE   READINESS GATES
lifecycle-pending   0/1     Pending   0          108s   <none>   <none>   <none>           <none>

$ kubectl -n s10 get pod lifecycle-pending -o jsonpath='{.status.phase}{"\n"}'
Pending

$ kubectl -n s10 describe pod lifecycle-pending
Name:             lifecycle-pending
Namespace:        s10
...
Node:             <none>
...
Status:           Pending
...
Containers:
  impossible-resource:
    Image:      nginx:1.27
    Requests:
      cpu:        1
      memory:     9Gi
Conditions:
  Type           Status
  PodScheduled   False 
...
Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  25s (x19 over 108s)  default-scheduler  0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient memory. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.
```

**Observed:** The pod requests `memory: 9Gi`, but each kind node only has about 7.7Gi allocatable (`8124516Ki`). The scheduler cannot place it, so `Node: <none>`, phase **Pending**, condition `PodScheduled=False`, and a repeating `FailedScheduling` event: "2 Insufficient memory" (the workers) and "1 node(s) had untolerated taint(s)" (the control-plane). The pod stays Pending until the request is lowered or a bigger node joins.

---

## 03. Succeeded - `03-succeeded.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-succeeded
spec:
  restartPolicy: Never
  containers:
    - name: task
      image: busybox:1.36
      command: ["sh", "-c", "echo 'Task started'; sleep 5; echo 'Task completed successfully'; exit 0"]
```

**Watch timeline:**

```
19:32:43 lifecycle-succeeded   0/1     Pending             0          0s
19:32:43 lifecycle-succeeded   0/1     ContainerCreating   0          0s
19:32:44 lifecycle-succeeded         1/1     Running             0          1s
19:32:50 lifecycle-succeeded         0/1     Completed           0            7s
```

```
$ kubectl -n s10 get pod lifecycle-succeeded -o wide
NAME                  READY   STATUS      RESTARTS   AGE    IP             NODE                   NOMINATED NODE   READINESS GATES
lifecycle-succeeded   0/1     Completed   0          108s   10.244.1.115   devops-heros-worker2   <none>           <none>

$ kubectl -n s10 get pod lifecycle-succeeded -o jsonpath='{.status.phase}{"\n"}'
Succeeded

$ kubectl -n s10 describe pod lifecycle-succeeded
Name:             lifecycle-succeeded
Namespace:        s10
...
Node:             devops-heros-worker2/172.18.0.2
...
Status:           Succeeded
...
Containers:
  task:
    Image:         busybox:1.36
    Command:
      sh
      -c
      echo 'Task started'; sleep 5; echo 'Task completed successfully'; exit 0
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Tue, 06 Oct 2026 19:32:44 +0800
      Finished:     Tue, 06 Oct 2026 19:32:49 +0800
    Ready:          False
    Restart Count:  0
Conditions:
  Type                        Status
  PodReadyToStartContainers   False 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  108s  default-scheduler  Successfully assigned s10/lifecycle-succeeded to devops-heros-worker2
  Normal  Pulled     107s  kubelet            spec.containers{task}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal  Created    107s  kubelet            spec.containers{task}: Container created
  Normal  Started    107s  kubelet            spec.containers{task}: Container started
```

```
$ kubectl -n s10 logs lifecycle-succeeded
Task started
Task completed successfully
```

**Observed:** `restartPolicy: Never` and the command exits `0` after 5 s. The container is `Terminated / Completed / Exit Code 0`, and the pod phase is **Succeeded** (`kubectl get` shows `Completed`). `Ready=False` is expected: a finished pod does not serve traffic.

---

## 04. Failed - `04-failed.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-failed
spec:
  restartPolicy: Never
  containers:
    - name: task
      image: busybox:1.36
      command: ["sh", "-c", "echo 'Task started'; sleep 5; echo 'Task failed'; exit 1"]
```

**Watch timeline:**

```
19:32:43 lifecycle-failed      0/1     Pending             0          0s
19:32:43 lifecycle-failed      0/1     ContainerCreating   0          0s
19:32:45 lifecycle-failed            1/1     Running             0          2s
19:32:50 lifecycle-failed            0/1     Error               0            7s
```

```
$ kubectl -n s10 get pod lifecycle-failed -o wide
NAME               READY   STATUS   RESTARTS   AGE    IP            NODE                  NOMINATED NODE   READINESS GATES
lifecycle-failed   0/1     Error    0          108s   10.244.2.96   devops-heros-worker   <none>           <none>

$ kubectl -n s10 get pod lifecycle-failed -o jsonpath='{.status.phase}{"\n"}'
Failed

$ kubectl -n s10 describe pod lifecycle-failed
Name:             lifecycle-failed
Namespace:        s10
...
Node:             devops-heros-worker/172.18.0.4
...
Status:           Failed
...
Containers:
  task:
    Image:         busybox:1.36
    Command:
      sh
      -c
      echo 'Task started'; sleep 5; echo 'Task failed'; exit 1
    State:          Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Tue, 06 Oct 2026 19:32:44 +0800
      Finished:     Tue, 06 Oct 2026 19:32:49 +0800
    Ready:          False
    Restart Count:  0
Conditions:
  Type                        Status
  PodReadyToStartContainers   False 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  108s  default-scheduler  Successfully assigned s10/lifecycle-failed to devops-heros-worker
  Normal  Pulled     107s  kubelet            spec.containers{task}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal  Created    107s  kubelet            spec.containers{task}: Container created
  Normal  Started    107s  kubelet            spec.containers{task}: Container started
```

```
$ kubectl -n s10 logs lifecycle-failed
Task started
Task failed
```

**Observed:** Same as above, but the command exits `1`. With `restartPolicy: Never` the kubelet does not restart it, so the container is `Terminated / Error / Exit Code 1` and the pod phase is **Failed** (`kubectl get` shows `Error`).

---

## 05. CrashLoopBackOff - `05-crashloopbackoff.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-crashloop
spec:
  containers:
    - name: crashing-app
      image: busybox:1.36
      command: ["sh", "-c", "echo 'Application started'; sleep 3; echo 'Application crashed'; exit 1"]
```

**Watch timeline:**

```
19:32:43 lifecycle-crashloop   0/1     Pending             0          0s
19:32:43 lifecycle-crashloop   0/1     ContainerCreating   0          0s
19:32:44 lifecycle-crashloop         1/1     Running             0          1s
19:32:48 lifecycle-crashloop         0/1     Error               0          5s
19:32:48 lifecycle-crashloop         1/1     Running             1 (1s ago)   5s
19:32:52 lifecycle-crashloop         0/1     Error               1 (5s ago)   9s
19:33:05 lifecycle-crashloop         0/1     CrashLoopBackOff    1 (14s ago)   22s
19:33:05 lifecycle-crashloop         1/1     Running             2 (14s ago)   22s
19:33:09 lifecycle-crashloop         0/1     Error               2 (18s ago)   26s
19:33:38 lifecycle-crashloop         0/1     CrashLoopBackOff    2 (30s ago)   55s
19:33:38 lifecycle-crashloop         1/1     Running             3 (30s ago)   55s
19:33:41 lifecycle-crashloop         0/1     Error               3 (33s ago)   58s
```

```
$ kubectl -n s10 get pod lifecycle-crashloop -o wide
NAME                  READY   STATUS   RESTARTS      AGE    IP             NODE                   NOMINATED NODE   READINESS GATES
lifecycle-crashloop   0/1     Error    3 (83s ago)   108s   10.244.1.116   devops-heros-worker2   <none>           <none>

$ kubectl -n s10 get pod lifecycle-crashloop -o jsonpath='{.status.phase}{"\n"}'
Running

$ kubectl -n s10 describe pod lifecycle-crashloop
Name:             lifecycle-crashloop
Namespace:        s10
...
Node:             devops-heros-worker2/172.18.0.2
...
Status:           Running
...
Containers:
  crashing-app:
    Image:         busybox:1.36
    Command:
      sh
      -c
      echo 'Application started'; sleep 3; echo 'Application crashed'; exit 1
    State:          Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Tue, 06 Oct 2026 19:33:38 +0800
      Finished:     Tue, 06 Oct 2026 19:33:41 +0800
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Tue, 06 Oct 2026 19:33:05 +0800
      Finished:     Tue, 06 Oct 2026 19:33:08 +0800
    Ready:          False
    Restart Count:  3
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
...
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  109s                default-scheduler  Successfully assigned s10/lifecycle-crashloop to devops-heros-worker2
  Normal   Pulled     54s (x4 over 108s)  kubelet            spec.containers{crashing-app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal   Created    54s (x4 over 108s)  kubelet            spec.containers{crashing-app}: Container created
  Normal   Started    54s (x4 over 108s)  kubelet            spec.containers{crashing-app}: Container started
  Warning  BackOff    51s (x3 over 100s)  kubelet            spec.containers{crashing-app}: Back-off restarting failed container crashing-app in pod lifecycle-crashloop_s10(b3c76438-95d5-4efd-b3b1-81d1cf3171d7)
```

```
$ kubectl -n s10 logs lifecycle-crashloop
Application started
Application crashed

$ kubectl -n s10 get pod lifecycle-crashloop
NAME                  READY   STATUS             RESTARTS        AGE
lifecycle-crashloop   0/1     CrashLoopBackOff   6 (2m26s ago)   8m39s
```

**Observed:** The container exits `1` every 3 s, and the default `restartPolicy: Always` restarts it each time. The kubelet waits longer between restarts (10 s, 20 s, 40 s, ... up to 5 min). During that wait the pod shows **CrashLoopBackOff** (see the watch timeline). The pod **phase stays `Running`**, because CrashLoopBackOff is a *container waiting reason*, not a phase. In the short snapshots right after a crash, STATUS showed `Error` (last termination reason). After 6 restarts the back-off is long, and the final `get` shows `CrashLoopBackOff` with `6 (2m26s ago)`. The `Warning BackOff ... Back-off restarting failed container` event confirms it. Debug with `kubectl logs` (plus `--previous`) and look at `Last State` / exit code.

---

## 06. ErrImagePull / ImagePullBackOff - `06-imagepullbackoff.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-image-error
spec:
  containers:
    - name: broken-image
      image: jakwehrgkaejw:kahsdfgkhj
```

**Watch timeline:**

```
19:32:43 lifecycle-image-error   0/1     Pending             0          0s
19:32:43 lifecycle-image-error   0/1     ContainerCreating   0          0s
19:32:47 lifecycle-image-error       0/1     ErrImagePull        0          4s
19:32:59 lifecycle-image-error       0/1     ImagePullBackOff    0            16s
19:33:15 lifecycle-image-error       0/1     ErrImagePull        0             32s
19:33:29 lifecycle-image-error       0/1     ImagePullBackOff    0             46s
19:33:47 lifecycle-image-error       0/1     ErrImagePull        0             64s
19:34:01 lifecycle-image-error       0/1     ImagePullBackOff    0             78s
```

```
$ kubectl -n s10 get pod lifecycle-image-error -o wide
NAME                    READY   STATUS         RESTARTS   AGE    IP            NODE                  NOMINATED NODE   READINESS GATES
lifecycle-image-error   0/1     ErrImagePull   0          109s   10.244.2.97   devops-heros-worker   <none>           <none>

$ kubectl -n s10 get pod lifecycle-image-error -o jsonpath='{.status.phase}{"\n"}'
Pending

$ kubectl -n s10 describe pod lifecycle-image-error
Name:             lifecycle-image-error
Namespace:        s10
...
Node:             devops-heros-worker/172.18.0.4
...
Status:           Pending
...
Containers:
  broken-image:
    Image:          jakwehrgkaejw:kahsdfgkhj
    State:          Waiting
      Reason:       ErrImagePull
    Ready:          False
    Restart Count:  0
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
...
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  109s                default-scheduler  Successfully assigned s10/lifecycle-image-error to devops-heros-worker
  Normal   Pulling    17s (x4 over 108s)  kubelet            spec.containers{broken-image}: Pulling image "jakwehrgkaejw:kahsdfgkhj"
  Warning  Failed     14s (x4 over 105s)  kubelet            spec.containers{broken-image}: Failed to pull image "jakwehrgkaejw:kahsdfgkhj": failed to pull and unpack image "docker.io/library/jakwehrgkaejw:kahsdfgkhj": failed to resolve reference "docker.io/library/jakwehrgkaejw:kahsdfgkhj": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  Warning  Failed     14s (x4 over 105s)  kubelet            spec.containers{broken-image}: Error: ErrImagePull
  Normal   BackOff    1s (x5 over 105s)   kubelet            spec.containers{broken-image}: Back-off pulling image "jakwehrgkaejw:kahsdfgkhj"
  Warning  Failed     1s (x5 over 105s)   kubelet            spec.containers{broken-image}: Error: ImagePullBackOff
```

**Observed:** The image `jakwehrgkaejw:kahsdfgkhj` does not exist. The pod is scheduled, then the kubelet fails to pull (`ErrImagePull`) and retries with back-off (`ImagePullBackOff`). The container is `Waiting`, and the pod **phase is Pending**, because a pod stays Pending until all its containers have been created.

---

## 07. Readiness probe - `07-readiness.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-readiness
spec:
  containers:
    - name: nginx
      image: nginx:1.27
      readinessProbe:
        httpGet:
          path: /
          port: 80
        initialDelaySeconds: 5
        periodSeconds: 5
```

**Watch timeline:**

```
19:32:44 lifecycle-readiness     0/1     Pending             0          0s
19:32:44 lifecycle-readiness     0/1     ContainerCreating   0          1s
19:32:45 lifecycle-readiness         0/1     Running             0          2s
19:32:50 lifecycle-readiness         1/1     Running             0            7s
```

```
$ kubectl -n s10 get pod lifecycle-readiness -o wide
NAME                  READY   STATUS    RESTARTS   AGE    IP             NODE                   NOMINATED NODE   READINESS GATES
lifecycle-readiness   1/1     Running   0          109s   10.244.1.117   devops-heros-worker2   <none>           <none>

$ kubectl -n s10 get pod lifecycle-readiness -o jsonpath='{.status.phase}{"\n"}'
Running

$ kubectl -n s10 describe pod lifecycle-readiness
Name:             lifecycle-readiness
Namespace:        s10
...
Node:             devops-heros-worker2/172.18.0.2
...
Status:           Running
...
Containers:
  nginx:
    Image:          nginx:1.27
    State:          Running
      Started:      Tue, 06 Oct 2026 19:32:45 +0800
    Ready:          True
    Restart Count:  0
    Readiness:      http-get http://:80/ delay=5s timeout=1s period=5s #success=1 #failure=3
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  109s  default-scheduler  Successfully assigned s10/lifecycle-readiness to devops-heros-worker2
  Normal  Pulled     108s  kubelet            spec.containers{nginx}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    108s  kubelet            spec.containers{nginx}: Container created
  Normal  Started    107s  kubelet            spec.containers{nginx}: Container started
```

**Observed:** The container is `Running` at once but `0/1` (not Ready) until the first readiness probe succeeds (`initialDelaySeconds: 5`). Then `Ready=True` and the pod would be added to Service endpoints. A failing readiness probe never restarts the container. It only removes the pod from load balancing.

---

## 08. Liveness probe - `08-liveness.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-liveness
spec:
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "echo 'App started'; touch /tmp/healthy; sleep 20; rm /tmp/healthy; echo 'Health file removed'; sleep 300"]
      livenessProbe:
        exec:
          command: ["sh", "-c", "test -f /tmp/healthy"]
        initialDelaySeconds: 5
        periodSeconds: 5
        failureThreshold: 2
```

**Watch timeline:**

```
19:32:44 lifecycle-liveness      0/1     Pending             0          0s
19:32:44 lifecycle-liveness      0/1     ContainerCreating   0          0s
19:32:45 lifecycle-liveness          1/1     Running             0          1s
```

```
$ kubectl -n s10 get pod lifecycle-liveness -o wide
NAME                 READY   STATUS    RESTARTS      AGE    IP            NODE                  NOMINATED NODE   READINESS GATES
lifecycle-liveness   1/1     Running   1 (48s ago)   108s   10.244.2.98   devops-heros-worker   <none>           <none>

$ kubectl -n s10 get pod lifecycle-liveness -o jsonpath='{.status.phase}{"\n"}'
Running

$ kubectl -n s10 describe pod lifecycle-liveness
Name:             lifecycle-liveness
Namespace:        s10
...
Node:             devops-heros-worker/172.18.0.4
...
Status:           Running
...
Containers:
  app:
    Image:         busybox:1.36
    Command:
      sh
      -c
      echo 'App started'; touch /tmp/healthy; sleep 20; rm /tmp/healthy; echo 'Health file removed'; sleep 300
    State:          Running
      Started:      Tue, 06 Oct 2026 19:33:44 +0800
    Last State:     Terminated
      Reason:       Error
      Exit Code:    137
      Started:      Tue, 06 Oct 2026 19:32:45 +0800
      Finished:     Tue, 06 Oct 2026 19:33:44 +0800
    Ready:          True
    Restart Count:  1
    Liveness:       exec [sh -c test -f /tmp/healthy] delay=5s timeout=1s period=5s #success=1 #failure=2
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
...
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  108s                default-scheduler  Successfully assigned s10/lifecycle-liveness to devops-heros-worker
  Normal   Pulled     48s (x2 over 108s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal   Created    48s (x2 over 108s)  kubelet            spec.containers{app}: Container created
  Normal   Started    48s (x2 over 107s)  kubelet            spec.containers{app}: Container started
  Warning  Unhealthy  18s (x4 over 83s)   kubelet            spec.containers{app}: Liveness probe failed:
  Normal   Killing    18s (x2 over 78s)   kubelet            spec.containers{app}: Container app failed liveness probe, will be restarted
```

```
$ kubectl -n s10 logs lifecycle-liveness --previous
App started
Health file removed
```

**Observed:** The app deletes `/tmp/healthy` after 20 s. The liveness probe (`period 5s`, `failureThreshold 2`) then fails twice, the kubelet **kills the container** (`Exit Code 137` = SIGKILL) and restarts it (`Restart Count: 1`). This repeats every ~60 s. The pod phase stays Running. Unlike readiness, a failing liveness probe **restarts** the container.

---

## 09. Startup probe - `09-startup.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-startup
spec:
  containers:
    - name: slow-app
      image: busybox:1.36
      command: ["sh", "-c", "echo 'Application starting...'; sleep 30; touch /tmp/started; echo 'Application started'; sleep 300"]
      startupProbe:
        exec:
          command: ["sh", "-c", "test -f /tmp/started"]
        periodSeconds: 5
        failureThreshold: 10
```

**Watch timeline:**

```
19:32:44 lifecycle-startup       0/1     Pending             0          0s
19:32:44 lifecycle-startup       0/1     ContainerCreating   0          0s
19:32:45 lifecycle-startup           0/1     Running             0          1s
19:33:19 lifecycle-startup           1/1     Running             0             35s
```

```
$ kubectl -n s10 get pod lifecycle-startup -o wide
NAME                READY   STATUS    RESTARTS   AGE    IP             NODE                   NOMINATED NODE   READINESS GATES
lifecycle-startup   1/1     Running   0          108s   10.244.1.118   devops-heros-worker2   <none>           <none>

$ kubectl -n s10 get pod lifecycle-startup -o jsonpath='{.status.phase}{"\n"}'
Running

$ kubectl -n s10 describe pod lifecycle-startup
Name:             lifecycle-startup
Namespace:        s10
...
Node:             devops-heros-worker2/172.18.0.2
...
Status:           Running
...
Containers:
  slow-app:
    Image:         busybox:1.36
    Command:
      sh
      -c
      echo 'Application starting...'; sleep 30; touch /tmp/started; echo 'Application started'; sleep 300
    State:          Running
      Started:      Tue, 06 Oct 2026 19:32:45 +0800
    Ready:          True
    Restart Count:  0
    Startup:        exec [sh -c test -f /tmp/started] delay=0s timeout=1s period=5s #success=1 #failure=10
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
...
Events:
  Type     Reason     Age                 From               Message
  ----     ------     ----                ----               -------
  Normal   Scheduled  108s                default-scheduler  Successfully assigned s10/lifecycle-startup to devops-heros-worker2
  Normal   Pulled     108s                kubelet            spec.containers{slow-app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal   Created    108s                kubelet            spec.containers{slow-app}: Container created
  Normal   Started    107s                kubelet            spec.containers{slow-app}: Container started
  Warning  Unhealthy  78s (x6 over 103s)  kubelet            spec.containers{slow-app}: Startup probe failed:
```

```
$ kubectl -n s10 logs lifecycle-startup
Application starting...
Application started
```

**Observed:** The app needs 30 s before it creates `/tmp/started`. The startup probe allows `10 x 5s = 50 s`. While it is failing, liveness and readiness checks are not run, and the pod is `Running 0/1` with `Startup probe failed` warnings (x6). At ~35 s it passes and the pod becomes `1/1` with **no restart**. Without the startup probe, an aggressive liveness probe would have killed this slow-starting app.

---

## 10. Init container - `10-init-container.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-init
spec:
  initContainers:
    - name: setup
      image: busybox:1.36
      command: ["sh", "-c", "echo 'Init container running'; sleep 10; echo 'Init complete'"]
  containers:
    - name: app
      image: nginx:1.27
```

**Watch timeline:**

```
19:32:44 lifecycle-init          0/1     Pending             0          0s
19:32:44 lifecycle-init          0/1     Init:0/1            0          0s
19:32:55 lifecycle-init              0/1     PodInitializing     0            11s
19:32:56 lifecycle-init              1/1     Running             0            12s
```

```
$ kubectl -n s10 get pod lifecycle-init -o wide
NAME             READY   STATUS    RESTARTS   AGE    IP            NODE                  NOMINATED NODE   READINESS GATES
lifecycle-init   1/1     Running   0          108s   10.244.2.99   devops-heros-worker   <none>           <none>

$ kubectl -n s10 get pod lifecycle-init -o jsonpath='{.status.phase}{"\n"}'
Running

$ kubectl -n s10 describe pod lifecycle-init
Name:             lifecycle-init
Namespace:        s10
...
Node:             devops-heros-worker/172.18.0.4
...
Status:           Running
...
Init Containers:
  setup:
    Image:         busybox:1.36
    Command:
      sh
      -c
      echo 'Init container running'; sleep 10; echo 'Init complete'
    State:          Terminated
      Reason:       Completed
      Exit Code:    0
      Started:      Tue, 06 Oct 2026 19:32:45 +0800
      Finished:     Tue, 06 Oct 2026 19:32:55 +0800
    Ready:          True
    Restart Count:  0
Containers:
  app:
    Image:          nginx:1.27
    State:          Running
      Started:      Tue, 06 Oct 2026 19:32:56 +0800
    Ready:          True
    Restart Count:  0
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  108s  default-scheduler  Successfully assigned s10/lifecycle-init to devops-heros-worker
  Normal  Pulled     108s  kubelet            spec.initContainers{setup}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal  Created    108s  kubelet            spec.initContainers{setup}: Container created
  Normal  Started    107s  kubelet            spec.initContainers{setup}: Container started
  Normal  Pulled     97s   kubelet            spec.containers{app}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    97s   kubelet            spec.containers{app}: Container created
  Normal  Started    96s   kubelet            spec.containers{app}: Container started
```

```
$ kubectl -n s10 logs lifecycle-init -c setup
Init container running
Init complete
```

**Observed:** The init container `setup` must finish successfully before the app container starts. `kubectl get` showed `Init:0/1`, then `PodInitializing`, then `Running`. In the describe output, the init container finished at 19:32:55 (`Completed / 0`) and nginx started at 19:32:56. Events show `spec.initContainers{setup}` before `spec.containers{app}`. The condition `Initialized=True` is set only after that.

---

## 11. Multi-container (sidecar) pod - `11-multi-container.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-multi-container
spec:
  containers:
    - name: app
      image: nginx:1.27
    - name: sidecar
      image: busybox:1.36
      command: ["sh", "-c", "while true; do echo 'Sidecar is running'; sleep 10; done"]
```

**Watch timeline:**

```
19:32:44 lifecycle-multi-container   0/2     Pending             0          0s
19:32:44 lifecycle-multi-container   0/2     ContainerCreating   0          0s
19:32:45 lifecycle-multi-container   2/2     Running             0          1s
```

```
$ kubectl -n s10 get pod lifecycle-multi-container -o wide
NAME                        READY   STATUS    RESTARTS   AGE    IP             NODE                   NOMINATED NODE   READINESS GATES
lifecycle-multi-container   2/2     Running   0          108s   10.244.1.119   devops-heros-worker2   <none>           <none>

$ kubectl -n s10 get pod lifecycle-multi-container -o jsonpath='{.status.phase}{"\n"}'
Running

$ kubectl -n s10 describe pod lifecycle-multi-container
Name:             lifecycle-multi-container
Namespace:        s10
...
Node:             devops-heros-worker2/172.18.0.2
...
Status:           Running
...
Containers:
  app:
    Image:          nginx:1.27
    State:          Running
      Started:      Tue, 06 Oct 2026 19:32:45 +0800
    Ready:          True
    Restart Count:  0
  sidecar:
    Image:         busybox:1.36
    Command:
      sh
      -c
      while true; do echo 'Sidecar is running'; sleep 10; done
    State:          Running
      Started:      Tue, 06 Oct 2026 19:32:45 +0800
    Ready:          True
    Restart Count:  0
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  108s  default-scheduler  Successfully assigned s10/lifecycle-multi-container to devops-heros-worker2
  Normal  Pulled     107s  kubelet            spec.containers{app}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    107s  kubelet            spec.containers{app}: Container created
  Normal  Started    107s  kubelet            spec.containers{app}: Container started
  Normal  Pulled     107s  kubelet            spec.containers{sidecar}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal  Created    107s  kubelet            spec.containers{sidecar}: Container created
  Normal  Started    107s  kubelet            spec.containers{sidecar}: Container started
```

```
$ kubectl -n s10 logs lifecycle-multi-container -c sidecar --tail=3
Sidecar is running
Sidecar is running
Sidecar is running

$ kubectl -n s10 get pod lifecycle-multi-container -o jsonpath='{range .status.containerStatuses[*]}{.name}{" ready="}{.ready}{"\n"}{end}'
app ready=true
sidecar ready=true

$ kubectl -n s10 exec lifecycle-multi-container -c sidecar -- wget -qO- localhost:80 | grep title
<title>Welcome to nginx!</title>
```

**Observed:** Two containers in one pod, `2/2` Ready. They share the network namespace, so the sidecar reaches nginx on `localhost:80`. The pod is Ready only when **every** container is ready.

---

## 12. Graceful termination - `12-termination.yaml`

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-termination
spec:
  terminationGracePeriodSeconds: 20
  containers:
    - name: graceful-app
      image: busybox:1.36
      command:
        - sh
        - -c
        - |
          trap 'echo "SIGTERM received; cleaning up..."; sleep 10; echo "Cleanup complete"; exit 0' TERM
          echo "Application running"
          while true; do sleep 2; done
```

I applied this pod alone, streamed its logs (`kubectl logs -f`, timestamps added), then deleted it:

```
$ kubectl apply -n s10 -f /Users/Dhruv/SST/devops-heros/.claude/worktrees/agent-a456476b1a4325742/session10-k8s-core-objects/pod-lifecycle/12-termination.yaml
pod/lifecycle-termination created

$ kubectl -n s10 get pod lifecycle-termination
NAME                    READY   STATUS    RESTARTS   AGE
lifecycle-termination   1/1     Running   0          3s

delete started at 19:35:48
$ time kubectl -n s10 delete pod lifecycle-termination
pod "lifecycle-termination" deleted from s10 namespace

real	0m10.933s
user	0m0.028s
sys	0m0.015s

delete returned at 19:35:59
19:35:46 [log] Application running
19:35:48 [log] SIGTERM received; cleaning up...
19:35:58 [log] Cleanup complete
```

**Observed:** `kubectl delete` sets a deletion timestamp (the pod shows `Terminating`), and the kubelet sends **SIGTERM** to PID 1. The shell's
`trap` caught it at 19:35:48, cleaned up for 10 s and exited 0 at 19:35:58. The delete returned after ~11 s, inside the
`terminationGracePeriodSeconds: 20` limit, so no SIGKILL was needed. If cleanup had taken longer than 20 s, the kubelet would have sent SIGKILL.

---

## 13. Lifecycle hooks (extra) - [`13-lifecycle-hooks.yaml`](13-lifecycle-hooks.yaml)

```yaml
# Extra example (not in the course folder): postStart and preStop container lifecycle hooks.
# Both hooks write into a shared emptyDir so we can read the order of events from a 2nd container.
apiVersion: v1
kind: Pod
metadata:
  name: lifecycle-hooks
  namespace: s10
spec:
  terminationGracePeriodSeconds: 15
  volumes:
    - name: shared
      emptyDir: {}
  containers:
    - name: app
      image: busybox:1.36
      command: ["sh", "-c", "echo \"$(date +%T) main process started\" >> /shared/events.log; while true; do sleep 1; done"]
      volumeMounts:
        - { name: shared, mountPath: /shared }
      lifecycle:
        postStart:
          exec:
            command: ["sh", "-c", "echo \"$(date +%T) postStart hook ran\" >> /shared/events.log"]
        preStop:
          exec:
            command: ["sh", "-c", "echo \"$(date +%T) preStop hook ran (draining)\" >> /shared/events.log; sleep 3"]
    - name: log-reader
      image: busybox:1.36
      command: ["sh", "-c", "touch /shared/events.log; tail -f /shared/events.log"]
      volumeMounts:
        - { name: shared, mountPath: /shared }
```

```
$ kubectl apply -f /Users/Dhruv/SST/devops-heros/.claude/worktrees/agent-a456476b1a4325742/session10-k8s-core-objects/24BCS10204-Dhruv-prabhat/pod-lifecycle/13-lifecycle-hooks.yaml
pod/lifecycle-hooks created

$ kubectl -n s10 get pod lifecycle-hooks
NAME              READY   STATUS    RESTARTS   AGE
lifecycle-hooks   2/2     Running   0          2s

delete started at 19:36:03
$ kubectl -n s10 delete pod lifecycle-hooks
pod "lifecycle-hooks" deleted from s10 namespace

delete returned at 19:36:19
$ kubectl -n s10 logs -f lifecycle-hooks -c log-reader   (captured until the pod died)
11:36:00 main process started
11:36:00 postStart hook ran
11:36:03 preStop hook ran (draining)
```

(The log-reader container's clock is UTC: 11:36:03 UTC = 19:36:03 local, the moment the delete started.)

**Observed:**
- `postStart` runs right after the container is created, at the same time as the main process (both logged at 11:36:00). There is no guarantee
  which one runs first. The container is not marked Running/Ready until `postStart` finishes.
- `preStop` runs **before** SIGTERM is sent, as soon as the delete is issued (11:36:03). This is where you drain connections
  (the same idea as the `preStop` sleep that fixed the failed request in my rolling update).
- The delete took **16 s**. `preStop` took 3 s, then SIGTERM went to `sh -c 'while ...'` and `tail -f`. As PID 1
  they have no SIGTERM handler, so they ignored it, and the kubelet sent SIGKILL when the 15 s grace period ran out.
  Lesson: PID 1 must handle SIGTERM (see `trap` in 12), otherwise every pod deletion waits the full grace period.

## Summary

| Manifest | STATUS shown | `.status.phase` | Key evidence |
|---|---|---|---|
| 01-running | Running 1/1 | Running | all conditions True |
| 02-pending | Pending | Pending | `PodScheduled=False`, `FailedScheduling: Insufficient memory` |
| 03-succeeded | Completed | Succeeded | exit 0, restartPolicy Never |
| 04-failed | Error | Failed | exit 1, restartPolicy Never |
| 05-crashloopbackoff | CrashLoopBackOff / Error | Running | restarts increasing, `BackOff` event |
| 06-imagepullbackoff | ErrImagePull / ImagePullBackOff | Pending | `pull access denied, repository does not exist` |
| 07-readiness | Running 0/1 -> 1/1 | Running | Ready flips after probe |
| 08-liveness | Running, restarts | Running | `Liveness probe failed`, exit 137, restart |
| 09-startup | Running 0/1 -> 1/1 (35 s) | Running | `Startup probe failed` x6, no restart |
| 10-init-container | Init:0/1 -> PodInitializing -> Running | Pending -> Running | init `Completed` before app start |
| 11-multi-container | Running 2/2 | Running | shared localhost |
| 12-termination | Terminating | Running -> deleted | SIGTERM trapped, clean exit in 10 s |
| 13-hooks (mine) | Running 2/2 | Running | postStart / preStop order in log |
