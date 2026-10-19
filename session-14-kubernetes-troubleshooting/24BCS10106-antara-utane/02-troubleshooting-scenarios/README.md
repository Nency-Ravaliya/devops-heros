# Task 2 - Reproduce and troubleshoot common Kubernetes failures

**Session 14 - Kubernetes Troubleshooting - Antara Srivastva - 24BCS10106**

All scenarios ran in namespace `s14` on the kind cluster. Where the course has a broken manifest, I used it unchanged, applied with `-n s14`:
- `scenarios/scenario-1..5`
- `06-crashloopbackoff`
- `08-pending-pods`
- `09-service-dns-troubleshooting/dns-test-pod.yaml`

My own broken and fixed manifests are in the numbered sub-folders here. Commands were run from `session-14-kubernetes-troubleshooting/`. In some commands, `.../` is short for `Antara-24BCS10106/02-troubleshooting-scenarios/`.

Each scenario follows the same pattern: **Problem -> Investigation (commands + real output) -> Root cause -> Fix -> Verify (before/after)**.

| # | Scenario | Symptom (STATUS) | Root cause |
|---|---|---|---|
| 1 | CrashLoopBackOff | `Error` / `CrashLoopBackOff`, restarts climbing | App exits 1: required env `DATABASE_URL` missing |
| 2 | ImagePullBackOff / ErrImagePull | `ErrImagePull`, then `ImagePullBackOff` | Image repo/tag does not exist |
| 3 | Pending | `Pending`, no node | (a) requests 500 CPU / 1000Gi; (b) nodeSelector matches no node |
| 4 | ContainerCreating | stuck `ContainerCreating` | ConfigMap and Secret used as volumes don't exist |
| 5 | Service connectivity | `curl: (7) Couldn't connect`, endpoints `<none>` | Service selector doesn't match pod labels, and targetPort is wrong |
| 6 | DNS | `curl: (6) Could not resolve host` (NXDOMAIN) | Wrong Service name and wrong namespace in the URL |
| 7 | Pod networking | `curl: (28) Connection timed out` | Default-deny NetworkPolicy |
| 8 | Configuration | `CreateContainerConfigError`, then `Error` | Wrong ConfigMap key, then invalid env value |
| 9 | OOMKilled (bonus, course scenario 5) | `OOMKilled`, exit 137 | Memory limit 20Mi, app allocates ~1000MB |

Starting state: every broken pod applied at once, like the course's `triage_all.sh` but in `s14`:

```console
$ kubectl apply -n s14 -f scenarios/scenario-1-crashloop/broken.yaml
pod/fail-1-crashloop-pod created
$ kubectl apply -n s14 -f scenarios/scenario-2-imagepull/broken.yaml
pod/fail-2-imagepull-pod created
$ kubectl apply -n s14 -f scenarios/scenario-3-pending/broken.yaml
pod/fail-3-pending-pod created
$ kubectl apply -n s14 -f 08-pending-pods/broken-pod.yaml
pod/pending-demo created
$ kubectl apply -n s14 -f Antara-24BCS10106/02-troubleshooting-scenarios/04-containercreating/broken.yaml
pod/config-volume-pod created
$ kubectl apply -n s14 -f Antara-24BCS10106/02-troubleshooting-scenarios/08-config-issue/configmap.yaml -f Antara-24BCS10106/02-troubleshooting-scenarios/08-config-issue/broken.yaml
configmap/app-config created
pod/config-app created
$ kubectl apply -n s14 -f scenarios/scenario-5-oomkilled/broken.yaml
pod/fail-5-oomkilled-pod created

$ kubectl get pods -n s14          # t+4s
NAME                   READY   STATUS                       RESTARTS   AGE
config-app             0/1     CreateContainerConfigError   0          4s
config-volume-pod      0/1     ContainerCreating            0          4s
fail-1-crashloop-pod   0/1     ContainerCreating            0          4s
fail-2-imagepull-pod   0/1     ErrImagePull                 0          4s
fail-3-pending-pod     0/1     Pending                      0          4s
fail-5-oomkilled-pod   0/1     ContainerCreating            0          4s
pending-demo           0/1     Pending                      0          4s

$ kubectl get pods -n s14          # t+80s
NAME                   READY   STATUS                       RESTARTS      AGE
config-app             0/1     CreateContainerConfigError   0             79s
config-volume-pod      0/1     ContainerCreating            0             79s
fail-1-crashloop-pod   0/1     Error                        2 (35s ago)   79s
fail-2-imagepull-pod   0/1     ImagePullBackOff             0             79s
fail-3-pending-pod     0/1     Pending                      0             79s
fail-5-oomkilled-pod   0/1     OOMKilled                    2 (33s ago)   79s
pending-demo           0/1     Pending                      0             79s
```

---

## 1. CrashLoopBackOff

**Problem.** `fail-1-crashloop-pod` (course `scenarios/scenario-1-crashloop`) never stays up. Its RESTARTS count keeps rising.

**Investigation.**

```console
$ kubectl get pod fail-1-crashloop-pod -n s14
NAME                   READY   STATUS   RESTARTS      AGE
fail-1-crashloop-pod   0/1     Error    3 (58s ago)   116s

$ kubectl describe pod fail-1-crashloop-pod -n s14 | sed -n '/Containers:/,/Ready:/p'
Containers:
  python-app:
    Container ID:  containerd://57e5fdcf0f11d782f181de5c6bee79f025f003beb13bf974f9ad87fe6655f229
    Image:         python:3.11-alpine
    ...
    Command:
      python3
      -c
      import os, sys
      db_url = os.environ.get("DATABASE_URL")
      if not db_url:
          print("[FATAL ERROR]: DATABASE_URL environment variable is MISSING!", file=sys.stderr)
          sys.exit(1)
      print("Application started successfully!")
      
    State:          Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Tue, 06 Oct 2026 19:09:00 +0800
      Finished:     Tue, 06 Oct 2026 19:09:00 +0800
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Tue, 06 Oct 2026 19:08:38 +0800
      Finished:     Tue, 06 Oct 2026 19:08:38 +0800
    Ready:          False

$ kubectl describe pod fail-1-crashloop-pod -n s14 | sed -n '/Events:/,$p'
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  116s               default-scheduler  Successfully assigned s14/fail-1-crashloop-pod to devops-heros-worker
  Normal   Pulling    116s               kubelet            spec.containers{python-app}: Pulling image "python:3.11-alpine"
  Normal   Pulled     73s                kubelet            spec.containers{python-app}: Successfully pulled image "python:3.11-alpine" in 12.049s (43.137s including waiting). Image size: 23808448 bytes.
  Normal   Created    36s (x4 over 73s)  kubelet            spec.containers{python-app}: Container created
  Normal   Started    36s (x4 over 72s)  kubelet            spec.containers{python-app}: Container started
  Normal   Pulled     36s (x3 over 72s)  kubelet            spec.containers{python-app}: Container image "python:3.11-alpine" already present on machine and can be accessed by the pod
  Warning  BackOff    36s (x4 over 71s)  kubelet            spec.containers{python-app}: Back-off restarting failed container python-app in pod fail-1-crashloop-pod_s14(6486a231-0f89-447f-8cd8-bafa7dfc9e26)

$ kubectl logs fail-1-crashloop-pod -n s14
[FATAL ERROR]: DATABASE_URL environment variable is MISSING!
```

The image pulled and the container started, so this is not an image or scheduling problem. It **exits with code 1 within a second** (Started = Finished). The kubelet restarts it with an exponential back-off (10s, 20s, 40s ... up to 5 minutes), which shows up as the `BackOff` warning. The log names the cause directly.

What the STATUS column shows on this v1.37 cluster: it alternates between `Error` (the instant the container dies) and `CrashLoopBackOff` (while waiting out the back-off). I watched the course's simpler `06-crashloopbackoff/broken-pod.yaml` to see the full cycle:

```console
$ kubectl apply -n s14 -f 06-crashloopbackoff/broken-pod.yaml
pod/crash-demo created
$ kubectl get pod crash-demo -n s14 -w      # watched for ~100s
NAME         READY   STATUS              RESTARTS   AGE
crash-demo   0/1     ContainerCreating   0          0s
crash-demo   0/1     ContainerCreating   0          1s
crash-demo   1/1     Running             0          1s
crash-demo   0/1     Error               0          2s
crash-demo   1/1     Running             1 (1s ago)   2s
crash-demo   0/1     Error               1 (2s ago)   3s
crash-demo   0/1     CrashLoopBackOff    1 (14s ago)   16s
crash-demo   1/1     Running             2 (14s ago)   16s
crash-demo   0/1     Error               2 (15s ago)   17s
crash-demo   0/1     CrashLoopBackOff    2 (21s ago)   37s
crash-demo   1/1     Running             3 (21s ago)   37s
crash-demo   0/1     Error               3 (22s ago)   38s
crash-demo   0/1     CrashLoopBackOff    3 (57s ago)   94s
crash-demo   1/1     Running             4 (57s ago)   94s
crash-demo   0/1     Error               4 (58s ago)   95s

$ kubectl logs crash-demo -n s14
Application starting...
Something went wrong!
$ kubectl logs crash-demo -n s14 --previous
unable to retrieve container logs for containerd://c97483f514e3acb9c1ee674f1075b14ffb81049d73bd26ed469d1f2171a41d4e
```

A note on `--previous`: while a crash-looping container is between restarts, the *current* container is the dead one (`State: Terminated`), so plain `kubectl logs` already shows the crash output. `--previous` points one instance further back, and the kubelet had already garbage-collected that container, hence the error. (`--previous` does work once a new instance is running. See the `restarter` pod in Task 1, where it showed `fatal: lost connection, exiting`.)

**Root cause.** The required environment variable `DATABASE_URL` is not set, so the app exits 1 on start-up, and `restartPolicy: Always` restarts it forever.

**Fix.** `01-crashloopbackoff/fixed.yaml` adds `env: DATABASE_URL=...` and keeps the process running. The original script printed "started" and then *exited 0*. With `restartPolicy: Always` that would still loop, because a Deployment or Pod container is expected to run forever. Env vars of a running pod cannot be edited, so I deleted and re-created it:

```console
$ kubectl delete pod fail-1-crashloop-pod -n s14 --grace-period=0 --force
Warning: Immediate deletion does not wait for confirmation that the running resource has been terminated. The resource may continue to run on the cluster indefinitely.
pod "fail-1-crashloop-pod" force deleted from s14 namespace

$ kubectl apply -n s14 -f Antara-24BCS10106/02-troubleshooting-scenarios/01-crashloopbackoff/fixed.yaml
pod/fail-1-crashloop-pod created
```

**Verify.**

```console
$ kubectl get pod fail-1-crashloop-pod -n s14
NAME                   READY   STATUS    RESTARTS   AGE
fail-1-crashloop-pod   1/1     Running   0          20s

$ kubectl logs fail-1-crashloop-pod -n s14
Application started successfully!
Using DATABASE_URL=postgres://postgres-db.s14.svc.cluster.local:5432/app
```

The course's own pair `06-crashloopbackoff/fixed-pod.yaml` was fixed the same way:

```console
$ kubectl delete pod crash-demo -n s14 --grace-period=0 --force
pod "crash-demo" force deleted from s14 namespace
$ kubectl apply -n s14 -f 06-crashloopbackoff/fixed-pod.yaml
pod/crash-demo created
$ kubectl get pod crash-demo -n s14
NAME         READY   STATUS    RESTARTS   AGE
crash-demo   1/1     Running   0          11s
$ kubectl logs crash-demo -n s14
Application starting...
Application is healthy
```

---

## 2. ImagePullBackOff / ErrImagePull

**Problem.** `fail-2-imagepull-pod` (course `scenarios/scenario-2-imagepull`) never starts. At t+4s it showed `ErrImagePull`, and at t+80s `ImagePullBackOff` (see the starting state above).

**Investigation.**

```console
$ kubectl get pod fail-2-imagepull-pod -n s14
NAME                   READY   STATUS             RESTARTS   AGE
fail-2-imagepull-pod   0/1     ImagePullBackOff   0          2m16s

$ kubectl describe pod fail-2-imagepull-pod -n s14 | sed -n '/Containers:/,/Ready:/p'
Containers:
  web-app:
    Container ID:   
    Image:          yatri-api-service:v999-invalid-tag-does-not-exist
    Image ID:       
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       ImagePullBackOff
    Ready:          False

$ kubectl describe pod fail-2-imagepull-pod -n s14 | sed -n '/Events:/,$p'
Events:
  Type     Reason     Age                  From               Message
  ----     ------     ----                 ----               -------
  Normal   Scheduled  2m16s                default-scheduler  Successfully assigned s14/fail-2-imagepull-pod to devops-heros-worker2
  Normal   Pulling    44s (x4 over 2m16s)  kubelet            spec.containers{web-app}: Pulling image "yatri-api-service:v999-invalid-tag-does-not-exist"
  Warning  Failed     42s (x4 over 2m12s)  kubelet            spec.containers{web-app}: Failed to pull image "yatri-api-service:v999-invalid-tag-does-not-exist": failed to pull and unpack image "docker.io/library/yatri-api-service:v999-invalid-tag-does-not-exist": failed to resolve reference "docker.io/library/yatri-api-service:v999-invalid-tag-does-not-exist": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
  Warning  Failed     42s (x4 over 2m12s)  kubelet            spec.containers{web-app}: Error: ErrImagePull
  Normal   BackOff    14s (x6 over 2m12s)  kubelet            spec.containers{web-app}: Back-off pulling image "yatri-api-service:v999-invalid-tag-does-not-exist"
  Warning  Failed     14s (x6 over 2m12s)  kubelet            spec.containers{web-app}: Error: ImagePullBackOff

$ kubectl events -n s14 --for pod/fail-2-imagepull-pod --types=Warning
LAST SEEN             TYPE      REASON   OBJECT                     MESSAGE
43s (x4 over 2m13s)   Warning   Failed   Pod/fail-2-imagepull-pod   Failed to pull image "yatri-api-service:v999-invalid-tag-does-not-exist": failed to pull and unpack image "docker.io/library/yatri-api-service:v999-invalid-tag-does-not-exist": failed to resolve reference "docker.io/library/yatri-api-service:v999-invalid-tag-does-not-exist": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
43s (x4 over 2m13s)   Warning   Failed   Pod/fail-2-imagepull-pod   Error: ErrImagePull
15s (x6 over 2m13s)   Warning   Failed   Pod/fail-2-imagepull-pod   Error: ImagePullBackOff
```

- **ErrImagePull** means a pull attempt just failed.
- **ImagePullBackOff** means the kubelet is waiting (with exponential back-off) before trying again.

The message tells you which case you are in:
- `pull access denied, repository does not exist or may require authorization`: wrong repository name, or a private repo with no `imagePullSecrets`. That is this scenario. A short name like `yatri-api-service` expands to `docker.io/library/yatri-api-service`, which does not exist.
- `... : not found`: the repository exists but the tag doesn't. The course's `07-imagepullbackoff` and the mini project `nginx:this-tag-does-not-exist` show this one (see `03-mini-project`).

**Root cause.** The image reference `yatri-api-service:v999-invalid-tag-does-not-exist` does not exist in any registry.

**Fix.** A container's `image` is one of the few Pod fields that can be changed in place, so there is no need to re-create the pod:

```console
$ kubectl set image pod/fail-2-imagepull-pod -n s14 web-app=nginx:1.27
pod/fail-2-imagepull-pod image updated
```

**Verify.**

```console
$ kubectl get pod fail-2-imagepull-pod -n s14
NAME                   READY   STATUS    RESTARTS   AGE
fail-2-imagepull-pod   1/1     Running   0          2m17s

$ kubectl describe pod fail-2-imagepull-pod -n s14 | sed -n '/Events:/,$p' | tail -5
  Normal   BackOff    15s (x6 over 2m13s)  kubelet            spec.containers{web-app}: Back-off pulling image "yatri-api-service:v999-invalid-tag-does-not-exist"
  Warning  Failed     15s (x6 over 2m13s)  kubelet            spec.containers{web-app}: Error: ImagePullBackOff
  Normal   Pulled     0s                   kubelet            spec.containers{web-app}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal   Created    0s                   kubelet            spec.containers{web-app}: Container created
  Normal   Started    0s                   kubelet            spec.containers{web-app}: Container started
```

(In real life the fix is the correct image name or tag, or adding `imagePullSecrets` for a private registry.)

### Bonus finding: a course manifest has the same problem

The course's DNS helper `09-service-dns-troubleshooting/dns-test-pod.yaml` fails the same way on this cluster:

```console
$ kubectl get pod dns-test -n s14
NAME       READY   STATUS             RESTARTS   AGE
dns-test   0/1     ImagePullBackOff   0          5m17s

$ kubectl events -n s14 --for pod/dns-test --types=Warning | tail -3
2m21s (x5 over 5m15s)   Warning   Failed   Pod/dns-test   Failed to pull image "registry.k8s.io/e2e-test-images/dnsutils:1.3": rpc error: code = NotFound desc = failed to pull and unpack image "registry.k8s.io/e2e-test-images/dnsutils:1.3": failed to resolve reference "registry.k8s.io/e2e-test-images/dnsutils:1.3": registry.k8s.io/e2e-test-images/dnsutils:1.3: not found
2m21s (x5 over 5m15s)   Warning   Failed   Pod/dns-test   Error: ErrImagePull
14s (x19 over 5m15s)    Warning   Failed   Pod/dns-test   Error: ImagePullBackOff
```

`registry.k8s.io/e2e-test-images/dnsutils:1.3` returns `not found`. I replaced it with `busybox:1.36`, which ships `nslookup`, in `06-dns/dns-test-pod.yaml`. That pod is used in scenario 6.

---

## 3. Pending

### 3a. Unschedulable resource requests

**Problem.** `fail-3-pending-pod` (course `scenarios/scenario-3-pending`) stays `Pending` and has no node or IP.

**Investigation.**

```console
$ kubectl get pod fail-3-pending-pod -n s14 -o wide
NAME                 READY   STATUS    RESTARTS   AGE     IP       NODE     NOMINATED NODE   READINESS GATES
fail-3-pending-pod   0/1     Pending   0          2m17s   <none>   <none>   <none>           <none>

$ kubectl describe pod fail-3-pending-pod -n s14 | sed -n '/Requests:/,/memory/p'
    Requests:
      cpu:        500
      memory:     1000Gi

$ kubectl describe pod fail-3-pending-pod -n s14 | sed -n '/Events:/,$p'
Events:
  Type     Reason            Age                  From               Message
  ----     ------            ----                 ----               -------
  Warning  FailedScheduling  21s (x3 over 2m17s)  default-scheduler  0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 Insufficient cpu, 2 Insufficient memory. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.

$ kubectl get nodes -o custom-columns=NAME:.metadata.name,CPU:.status.allocatable.cpu,MEMORY:.status.allocatable.memory
NAME                         CPU   MEMORY
devops-heros-control-plane   10    8124516Ki
devops-heros-worker          10    8124516Ki
devops-heros-worker2         10    8124516Ki
```

Pending means the **scheduler** could not place the pod. Unlike the other scenarios there are no kubelet events, because no node was ever chosen. The `FailedScheduling` message explains each node: the control-plane has a taint the pod doesn't tolerate, and both workers have `Insufficient cpu` and `Insufficient memory`.

**Root cause.** The pod requests 500 CPUs and 1000Gi of memory. The largest node offers 10 CPUs and about 7.7Gi.

**Fix.** Use realistic requests (`03-pending/fixed-resources.yaml`: 100m / 64Mi, limits 250m / 128Mi). Resource requests cannot be changed on an existing pod, so I re-created it.

```console
$ kubectl delete pod fail-3-pending-pod -n s14
pod "fail-3-pending-pod" deleted from s14 namespace

$ kubectl apply -n s14 -f Antara-24BCS10106/02-troubleshooting-scenarios/03-pending/fixed-resources.yaml
pod/fail-3-pending-pod created
```

**Verify.**

```console
$ kubectl get pod fail-3-pending-pod -n s14 -o wide
NAME                 READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
fail-3-pending-pod   1/1     Running   0          30s   10.244.1.36   devops-heros-worker2   <none>           <none>
```

### 3b. nodeSelector that matches no node

**Problem.** The course's `08-pending-pods/broken-pod.yaml` (`pending-demo`) is also stuck in `Pending`.

```console
$ kubectl get pod pending-demo -n s14 -o wide
NAME           READY   STATUS    RESTARTS   AGE     IP       NODE     NOMINATED NODE   READINESS GATES
pending-demo   0/1     Pending   0          2m47s   <none>   <none>   <none>           <none>

$ kubectl describe pod pending-demo -n s14 | grep -A1 Node-Selectors
Node-Selectors:              kubernetes.io/hostname=node-that-does-not-exist
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s

$ kubectl describe pod pending-demo -n s14 | sed -n '/Events:/,$p'
Events:
  Type     Reason            Age    From               Message
  ----     ------            ----   ----               -------
  Warning  FailedScheduling  2m47s  default-scheduler  0/3 nodes are available: 1 node(s) had untolerated taint(s), 2 node(s) didn't match Pod's node affinity/selector. preemption: 0/3 nodes are available: 3 Preemption is not helpful for scheduling.

$ kubectl get nodes -L kubernetes.io/hostname
NAME                         STATUS   ROLES           AGE   VERSION   HOSTNAME
devops-heros-control-plane   Ready    control-plane   21m   v1.37.0   devops-heros-control-plane
devops-heros-worker          Ready    <none>          21m   v1.37.0   devops-heros-worker
devops-heros-worker2         Ready    <none>          21m   v1.37.0   devops-heros-worker2
```

**Root cause.** `nodeSelector: kubernetes.io/hostname=node-that-does-not-exist` matches no node (`2 node(s) didn't match Pod's node affinity/selector`).

**Fix.** Select a node whose label actually exists (`03-pending/fixed-nodeselector.yaml` targets `devops-heros-worker`), or drop the selector. Other options are to label a node to match, or to fix taints and tolerations.

```console
$ kubectl delete pod pending-demo -n s14
pod "pending-demo" deleted from s14 namespace

$ kubectl apply -n s14 -f Antara-24BCS10106/02-troubleshooting-scenarios/03-pending/fixed-nodeselector.yaml
pod/pending-demo created

$ kubectl get pod pending-demo -n s14 -o wide
NAME           READY   STATUS    RESTARTS   AGE   IP            NODE                  NOMINATED NODE   READINESS GATES
pending-demo   1/1     Running   0          0s    10.244.2.26   devops-heros-worker   <none>           <none>
```

---

## 4. ContainerCreating (missing ConfigMap / Secret volume)

**Problem.** `config-volume-pod` (`04-containercreating/broken.yaml`) was scheduled to a node but never leaves `ContainerCreating`.

**Investigation.** The `describe` output is from the first run. The `get` checks are from a second, clean reproduction, because in the first run I typed a wrong combined `kubectl get configmap ... secret ...` command.

```console
$ kubectl get pod config-volume-pod -n s14
NAME                READY   STATUS              RESTARTS   AGE
config-volume-pod   0/1     ContainerCreating   0          2m3s

$ kubectl describe pod config-volume-pod -n s14 | sed -n '/Volumes:/,/Optional/p'
Volumes:
  site-config:
    Type:      ConfigMap (a volume populated by a ConfigMap)
    Name:      site-config
    Optional:  false

$ kubectl describe pod config-volume-pod -n s14 | sed -n '/Events:/,$p'
Events:
  Type     Reason       Age                  From               Message
  ----     ------       ----                 ----               -------
  Normal   Scheduled    2m48s                default-scheduler  Successfully assigned s14/config-volume-pod to devops-heros-worker
  Warning  FailedMount  40s (x9 over 2m48s)  kubelet            MountVolume.SetUp failed for volume "tls" : secret "site-tls" not found
  Warning  FailedMount  40s (x9 over 2m48s)  kubelet            MountVolume.SetUp failed for volume "site-config" : configmap "site-config" not found

$ kubectl get configmap site-config -n s14
Error from server (NotFound): configmaps "site-config" not found

$ kubectl get secret site-tls -n s14
Error from server (NotFound): secrets "site-tls" not found
```

`ContainerCreating` means the pod is on a node, but the kubelet cannot finish setting it up. Typical reasons are volume mounts, CNI/IP allocation, or a very slow image pull. The `FailedMount` events name both missing objects.

**Root cause.** The pod mounts ConfigMap `site-config` and Secret `site-tls`, and neither exists in the namespace. Neither is marked `optional: true`.

**Fix.** Create the missing objects (`04-containercreating/fix-configmap-secret.yaml`). The pod spec does not need to change, because the kubelet keeps retrying the mount.

```console
$ kubectl apply -n s14 -f Antara-24BCS10106/02-troubleshooting-scenarios/04-containercreating/fix-configmap-secret.yaml
configmap/site-config created
secret/site-tls created
```

**Verify.** The same pod (no restart, AGE keeps counting) started by itself:

```console
$ kubectl get pod config-volume-pod -n s14
NAME                READY   STATUS    RESTARTS   AGE
config-volume-pod   1/1     Running   0          2m17s

$ kubectl exec config-volume-pod -n s14 -- curl -s localhost
<h1>served from ConfigMap site-config (24BCS10106)</h1>

$ kubectl exec config-volume-pod -n s14 -- ls /etc/tls
tls.key
```

---

## 5. Service connectivity (selector and port mismatch, empty endpoints)

**Problem.** A client pod cannot reach the `shop-api` Service, although both backend pods are `Running`.

```console
$ kubectl apply -n s14 -f .../05-service-connectivity/app.yaml -f .../05-service-connectivity/broken-service.yaml
deployment.apps/shop-api created
pod/client created
service/shop-api created

$ kubectl get pods -n s14 -l app=shop-api -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
shop-api-647848474-5fcft   1/1     Running   0          11s   10.244.2.51   devops-heros-worker    <none>           <none>
shop-api-647848474-hpj8d   1/1     Running   0          11s   10.244.1.72   devops-heros-worker2   <none>           <none>

$ kubectl get svc shop-api -n s14
NAME       TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
shop-api   ClusterIP   10.96.220.88   <none>        80/TCP    11s

$ kubectl exec client -n s14 -- curl -sS --max-time 5 http://shop-api
curl: (7) Failed to connect to shop-api port 80 after 3 ms: Couldn't connect to server
command terminated with exit code 7
```

DNS resolved the name (otherwise curl would print error 6), but nothing accepted the connection.

**Investigation.** Endpoints first:

```console
$ kubectl get endpoints shop-api -n s14
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME       ENDPOINTS   AGE
shop-api   <none>      11s

$ kubectl get endpointslices -n s14 -l kubernetes.io/service-name=shop-api
NAME             ADDRESSTYPE   PORTS     ENDPOINTS   AGE
shop-api-mfppn   IPv4          <unset>   <unset>     11s

$ kubectl describe svc shop-api -n s14
Name:                     shop-api
Namespace:                s14
Labels:                   <none>
Annotations:              <none>
Selector:                 app=shop-api-v2
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.220.88
IPs:                      10.96.220.88
Port:                     <unset>  80/TCP
TargetPort:               8080/TCP
Endpoints:                
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>

$ kubectl get pods -n s14 -l app=shop-api --show-labels
NAME                       READY   STATUS    RESTARTS   AGE   LABELS
shop-api-647848474-5fcft   1/1     Running   0          11s   app=shop-api,pod-template-hash=647848474
shop-api-647848474-hpj8d   1/1     Running   0          11s   app=shop-api,pod-template-hash=647848474

$ kubectl get pods -n s14 -l app=shop-api-v2
No resources found in s14 namespace.
```

**Root cause #1: selector mismatch.** The Service selects `app=shop-api-v2`, but the pods are labelled `app=shop-api`. No pod matches, so the endpoints are empty.

Fixing only the selector shows there is a **second** bug:

```console
$ kubectl patch svc shop-api -n s14 -p '{"spec":{"selector":{"app":"shop-api"}}}'
service/shop-api patched

$ kubectl get endpoints shop-api -n s14
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME       ENDPOINTS                           AGE
shop-api   10.244.1.72:8080,10.244.2.51:8080   11s

$ kubectl exec client -n s14 -- curl -sS --max-time 5 http://shop-api
curl: (7) Failed to connect to shop-api port 80 after 0 ms: Couldn't connect to server
command terminated with exit code 7

$ kubectl exec client -n s14 -- curl -sS --max-time 5 http://$(kubectl get pods -n s14 -l app=shop-api -o jsonpath='{.items[0].status.podIP}'):8080
curl: (7) Failed to connect to 10.244.2.51 port 8080 after 0 ms: Couldn't connect to server
command terminated with exit code 7

$ kubectl exec deploy/shop-api -n s14 -- sh -c 'grep -h listen /etc/nginx/conf.d/*.conf'
    listen       80;
    listen  [::]:80;
    # proxy the PHP scripts to Apache listening on 127.0.0.1:80
    # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
```

**Root cause #2: targetPort mismatch.** Endpoints now exist but point to `:8080`, while nginx listens on `80`. Curling a pod IP directly on 8080 proves the pod itself refuses that port.

**Fix.** `05-service-connectivity/fixed-service.yaml`: `selector: app=shop-api`, `targetPort: 80`.

**Verify.** For a clean before/after I re-applied the broken Service and then the fixed one:

```console
$ kubectl apply -n s14 -f .../05-service-connectivity/broken-service.yaml
service/shop-api configured

$ kubectl get endpoints shop-api -n s14
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME       ENDPOINTS   AGE
shop-api   <none>      5m52s

$ kubectl exec client -n s14 -- curl -sS --max-time 5 -o /dev/null -w 'HTTP %{http_code}\n' http://shop-api
HTTP 000
curl: (7) Failed to connect to shop-api port 80 after 1 ms: Couldn't connect to server
command terminated with exit code 7

$ kubectl apply -n s14 -f .../05-service-connectivity/fixed-service.yaml
service/shop-api configured

$ kubectl get endpoints shop-api -n s14
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME       ENDPOINTS                       AGE
shop-api   10.244.1.72:80,10.244.2.51:80   5m55s

$ kubectl exec client -n s14 -- curl -sS --max-time 5 http://shop-api | grep -i title
<title>Welcome to nginx!</title>

$ kubectl exec client -n s14 -- curl -sS --max-time 5 -o /dev/null -w 'HTTP %{http_code}\n' http://shop-api.s14.svc.cluster.local
HTTP 200
```

(In my very first attempt, I curled in the same instant that I applied the fixed Service, and it still failed. kube-proxy needs a moment to program the new endpoints. Waiting about 3 seconds, as above, fixed that.)

---

## 6. DNS issues

**Problem.** `fail-4-dns-failure-pod` (course `scenarios/scenario-4-dns-failure`) is `Running`, but it never reaches its database. Its log shows no response at all, because `curl -s` hides the error.

For this scenario I created a real target: Service `postgres-db` (port 5432) in `s14`, backed by nginx (`06-dns/postgres-db.yaml`).

```console
$ kubectl apply -n s14 -f .../06-dns/postgres-db.yaml
deployment.apps/postgres-db created
service/postgres-db created

$ kubectl apply -n s14 -f scenarios/scenario-4-dns-failure/broken.yaml
pod/fail-4-dns-failure-pod created

$ kubectl get pod fail-4-dns-failure-pod -n s14
NAME                     READY   STATUS    RESTARTS   AGE
fail-4-dns-failure-pod   1/1     Running   0          19s

$ kubectl logs fail-4-dns-failure-pod -n s14
Attempting connection to internal database...
Process sleeping...
```

**Investigation.** Run the request without `-s`, so the error is visible:

```console
$ kubectl exec fail-4-dns-failure-pod -n s14 -- curl -sS --connect-timeout 3 http://postgres-db-wrong-name.production.svc.cluster.local:5432
curl: (6) Could not resolve host: postgres-db-wrong-name.production.svc.cluster.local
command terminated with exit code 6
```

Exit code 6 means a name-resolution failure. Next I checked DNS itself from a debug pod (busybox, see the bonus finding in scenario 2), and checked CoreDNS:

```console
$ kubectl exec dns-test -n s14 -- cat /etc/resolv.conf
search s14.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

$ kubectl exec dns-test -n s14 -- nslookup postgres-db-wrong-name.production.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find postgres-db-wrong-name.production.svc.cluster.local: NXDOMAIN

** server can't find postgres-db-wrong-name.production.svc.cluster.local: NXDOMAIN

command terminated with exit code 1

$ kubectl exec dns-test -n s14 -- nslookup kubernetes.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	kubernetes.default.svc.cluster.local
Address: 10.96.0.1

$ kubectl get pods -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-559f6c778d-9v66h   1/1     Running   0          34m
coredns-559f6c778d-jrrhj   1/1     Running   0          34m

$ kubectl get svc kube-dns -n kube-system
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   34m

$ kubectl logs -n kube-system -l k8s-app=kube-dns --tail=5
maxprocs: Leaving GOMAXPROCS=10: CPU quota undefined
.:53
[INFO] plugin/reload: Running configuration SHA512 = 1b226df79860026c6a52e67daa10d7f0d57ec5b023288ec00c5e05f93523c894564e15b91770d3a07ae1cfbe861d15b37d4a0027e69c546ab112970993a3b03b
CoreDNS-1.14.6
linux/arm64, go1.26.5, 424d125
...
```

CoreDNS is healthy: both pods are running, there are no errors in its log, the `kube-dns` Service sits at 10.96.0.10 (the same nameserver as in the pod's `resolv.conf`), and `kubernetes.default` resolves. So DNS works. It answers **NXDOMAIN**, meaning "that name does not exist". The problem is the *name*, not DNS. Next, find the real name:

```console
$ kubectl get svc -A --field-selector metadata.name=postgres-db
NAMESPACE   NAME          TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
s14         postgres-db   ClusterIP   10.96.175.29   <none>        5432/TCP   3m21s

$ kubectl get ns production
Error from server (NotFound): namespaces "production" not found

$ kubectl exec dns-test -n s14 -- nslookup postgres-db.s14.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	postgres-db.s14.svc.cluster.local
Address: 10.96.175.29

$ kubectl exec dns-test -n s14 -- nslookup postgres-db
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find postgres-db.cluster.local: NXDOMAIN

Name:	postgres-db.s14.svc.cluster.local
Address: 10.96.175.29

** server can't find postgres-db.cluster.local: NXDOMAIN

** server can't find postgres-db.svc.cluster.local: NXDOMAIN

** server can't find postgres-db.svc.cluster.local: NXDOMAIN


command terminated with exit code 1
```

The short name `postgres-db` resolves through the `search` list (`s14.svc.cluster.local` comes first). busybox `nslookup` also prints the NXDOMAIN answers for the other search domains it tried and then exits 1. The `Name/Address` line is the real answer.

**Root cause.** Wrong hostname. The Service is called `postgres-db`, not `postgres-db-wrong-name`, and it lives in namespace `s14`. There is no namespace `production`. The DNS form is `<service>.<namespace>.svc.cluster.local`.

**Fix.** `06-dns/fixed.yaml` uses `http://postgres-db.s14.svc.cluster.local:5432`. Pod args cannot be changed, so I re-created the pod:

```console
$ kubectl delete pod fail-4-dns-failure-pod -n s14 --grace-period=0 --force
pod "fail-4-dns-failure-pod" force deleted from s14 namespace

$ kubectl apply -n s14 -f .../06-dns/fixed.yaml
pod/fail-4-dns-failure-pod created
```

**Verify.**

```console
$ kubectl logs fail-4-dns-failure-pod -n s14
Attempting connection to internal database...
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
Process sleeping...
```

---

## 7. Pod networking: NetworkPolicy blocks traffic

**Does kind enforce NetworkPolicy?** kind's default CNI is **kindnet**. Older kindnet ignored NetworkPolicy objects. Newer kindnet (2024 and later) includes a network-policy controller. This cluster runs:

```console
$ kubectl get pods -n kube-system -l app=kindnet -o jsonpath='{.items[0].spec.containers[0].image}{"\n"}'
docker.io/kindest/kindnetd:v20260820-69b56db7
```

That is a recent build. The test below shows the policies really are enforced.

**Problem.** It worked before. Then a default-deny policy was applied (as if by another team), and the client's requests to `shop-api` started timing out.

```console
$ kubectl exec client -n s14 -- curl -sS --max-time 5 -o /dev/null -w 'HTTP %{http_code}\n' http://shop-api
HTTP 200

$ kubectl apply -n s14 -f .../07-network-policy/deny-all.yaml
networkpolicy.networking.k8s.io/default-deny-ingress created

$ kubectl exec client -n s14 -- curl -sS --max-time 5 -o /dev/null -w 'HTTP %{http_code}\n' http://shop-api
HTTP 000
curl: (28) Connection timed out after 5002 milliseconds
command terminated with exit code 28
```

**Investigation.** The symptom differs from scenario 5:
- **Timeout (28)**: packets are silently dropped.
- **Connection refused (7)**: nothing is listening.

The Service and its endpoints are fine, so the next suspect is policy:

```console
$ kubectl get endpoints shop-api -n s14
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME       ENDPOINTS                       AGE
shop-api   10.244.1.72:80,10.244.2.51:80   3m48s

$ kubectl get networkpolicy -n s14
NAME                   POD-SELECTOR   AGE
default-deny-ingress   <none>         10s

$ kubectl describe networkpolicy default-deny-ingress -n s14
Name:         default-deny-ingress
Namespace:    s14
Created on:   2026-10-06 19:23:17 +0800 WITA
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    <none> (Selected pods are isolated for ingress connectivity)
  Not affecting egress traffic
  Policy Types: Ingress
```

**Root cause.** `podSelector: {}` together with `policyTypes: [Ingress]` and no `ingress` rules isolates **every pod in the namespace** for inbound traffic. Once any policy selects a pod, only traffic that some policy explicitly allows is let in.

**Fix.** Keep default-deny (good practice) and add an explicit allow rule: pods labelled `role=client` may reach `app=shop-api` on TCP/80 (`07-network-policy/allow-client.yaml`).

```console
$ kubectl apply -n s14 -f .../07-network-policy/allow-client.yaml
networkpolicy.networking.k8s.io/allow-client-to-shop-api created

$ kubectl get networkpolicy -n s14
NAME                       POD-SELECTOR   AGE
allow-client-to-shop-api   app=shop-api   5s
default-deny-ingress       <none>         15s
```

**Verify.** The allowed client gets through. A pod without the `role=client` label is still blocked, which proves the policy is enforced selectively and the cluster is not simply open again:

```console
$ kubectl exec client -n s14 -- curl -sS --max-time 5 -o /dev/null -w 'HTTP %{http_code}\n' http://shop-api
HTTP 200

$ kubectl run np-intruder -n s14 --image=curlimages/curl:8.6.0 --restart=Never --rm -i --quiet -- curl -sS --max-time 5 -o /dev/null -w 'HTTP %{http_code}\n' http://shop-api
curl: (28) Connection timed out after 5002 milliseconds
HTTP 000
pod s14/np-intruder terminated (Error)
```

Afterwards I deleted both policies, so they would not interfere with the later re-check of scenario 5.

---

## 8. Configuration issues (wrong ConfigMap key and invalid env value)

**Problem.** `config-app` (`08-config-issue/broken.yaml`) never starts. Its STATUS is `CreateContainerConfigError`.

**Investigation.**

```console
$ kubectl get pod config-app -n s14
NAME         READY   STATUS                       RESTARTS   AGE
config-app   0/1     CreateContainerConfigError   0          4m11s

$ kubectl describe pod config-app -n s14 | sed -n '/Environment:/,/Mounts:/p'
    Environment:
      DB_HOST:    <set to the key 'DB_HOST' of config map 'app-config'>  Optional: false
      LOG_LEVEL:  verbose
    Mounts:

$ kubectl describe pod config-app -n s14 | sed -n '/Events:/,$p'
Events:
  Type     Reason     Age                   From               Message
  ----     ------     ----                  ----               -------
  Normal   Scheduled  4m11s                 default-scheduler  Successfully assigned s14/config-app to devops-heros-worker2
  Normal   Pulled     11s (x21 over 4m10s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Warning  Failed     11s (x21 over 4m10s)  kubelet            spec.containers{app}: Error: couldn't find key DB_HOST in ConfigMap s14/app-config

$ kubectl get configmap app-config -n s14 -o yaml
apiVersion: v1
data:
  db_host: postgres-db.s14.svc.cluster.local
  log_level: info
kind: ConfigMap
metadata:
  ...
  name: app-config
  namespace: s14
```

**Root cause #1.** The pod asks for the key `DB_HOST`, but the ConfigMap's key is `db_host`. Keys are case-sensitive. The container cannot even be created, so there are no logs, only the event.

First fix attempt: correct only the key name (`sed 's/key: DB_HOST/key: db_host/'`), and re-create the pod:

```console
$ kubectl get pod config-app -n s14
NAME         READY   STATUS   RESTARTS      AGE
config-app   0/1     Error    4 (96s ago)   2m17s

$ kubectl logs config-app -n s14
DB_HOST=postgres-db.s14.svc.cluster.local LOG_LEVEL=verbose
invalid LOG_LEVEL 'verbose'

$ kubectl describe pod config-app -n s14 | sed -n '/Environment:/,/Mounts:/p'
    Environment:
      DB_HOST:    <set to the key 'db_host' of config map 'app-config'>  Optional: false
      LOG_LEVEL:  verbose
    Mounts:
```

**Root cause #2.** The container now starts. `DB_HOST` is correct, but `LOG_LEVEL` is hard-coded to `verbose`, which the app rejects (it accepts only debug, info, warn or error). The pod moves from a *config error* to a *crash loop*. Many config bugs hide behind each other like this.

**Fix.** `08-config-issue/fixed.yaml` takes both values from the ConfigMap with the correct lower-case keys:

```console
$ kubectl delete pod config-app -n s14 --grace-period=0 --force
pod "config-app" force deleted from s14 namespace

$ kubectl apply -n s14 -f .../08-config-issue/fixed.yaml
pod/config-app created
```

**Verify.**

```console
$ kubectl get pod config-app -n s14
NAME         READY   STATUS    RESTARTS   AGE
config-app   1/1     Running   0          1s

$ kubectl logs config-app -n s14
DB_HOST=postgres-db.s14.svc.cluster.local LOG_LEVEL=info
config OK, app running

$ kubectl exec config-app -n s14 -- env | grep -E 'DB_HOST|LOG_LEVEL'
DB_HOST=postgres-db.s14.svc.cluster.local
LOG_LEVEL=info
```

---

## 9. Bonus: OOMKilled (course scenario 5)

**Problem.** `fail-5-oomkilled-pod` restarts constantly. Its STATUS shows `OOMKilled`.

```console
$ kubectl get pod fail-5-oomkilled-pod -n s14
NAME                   READY   STATUS      RESTARTS        AGE
fail-5-oomkilled-pod   0/1     OOMKilled   5 (2m21s ago)   4m37s

$ kubectl describe pod fail-5-oomkilled-pod -n s14 | sed -n '/State:/,/Restart Count/p'
    State:          Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Tue, 06 Oct 2026 19:11:17 +0800
      Finished:     Tue, 06 Oct 2026 19:11:17 +0800
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Tue, 06 Oct 2026 19:09:56 +0800
      Finished:     Tue, 06 Oct 2026 19:09:56 +0800
    Ready:          False
    Restart Count:  5

$ kubectl describe pod fail-5-oomkilled-pod -n s14 | grep -A3 Limits
    Limits:
      memory:  20Mi
    Requests:
      memory:     20Mi

$ kubectl logs fail-5-oomkilled-pod -n s14

```

**Root cause.** Exit code **137** = 128 + 9 (SIGKILL). The kernel's OOM killer stopped the process because it tried to allocate 100 x 10MB with a 20Mi memory limit. The log is empty: the process was killed before Python flushed its stdout buffer.

**Fix.** `09-oomkilled/fixed.yaml` allocates a bounded 50MB and sets `requests 64Mi / limits 128Mi`. In a real app the fix would be to fix the leak *and* size the limit from measurements (`kubectl top`).

```console
$ kubectl delete pod fail-5-oomkilled-pod -n s14 --grace-period=0 --force
pod "fail-5-oomkilled-pod" force deleted from s14 namespace
$ kubectl apply -n s14 -f .../09-oomkilled/fixed.yaml
pod/fail-5-oomkilled-pod created

$ kubectl get pod fail-5-oomkilled-pod -n s14
NAME                   READY   STATUS    RESTARTS   AGE
fail-5-oomkilled-pod   1/1     Running   0          101s

$ kubectl logs fail-5-oomkilled-pod -n s14
Allocated 50MB, running within limits
```

---

## Final state - everything fixed

```console
$ kubectl get pods -n s14
NAME                   READY   STATUS    RESTARTS   AGE
config-app             1/1     Running   0          1s
config-volume-pod      1/1     Running   0          2m21s
fail-1-crashloop-pod   1/1     Running   0          1s
fail-2-imagepull-pod   1/1     Running   0          9m28s
fail-3-pending-pod     1/1     Running   0          7m11s
fail-5-oomkilled-pod   1/1     Running   0          1s
pending-demo           1/1     Running   0          6m40s
```

(This was taken right after re-applying the fixed manifests a second time. I had re-broken scenarios 1, 4, 8 and 9 once to capture clean outputs, so some pods show a young AGE.)

## Cheat sheet: symptom -> first command

| STATUS / symptom | Look at | Usual cause |
|---|---|---|
| `Pending` | `describe pod` -> FailedScheduling | Not enough resources, nodeSelector/affinity, taints, PVC unbound |
| `ContainerCreating` (stuck) | `describe pod` -> FailedMount / CNI events | Missing ConfigMap/Secret/PVC, CNI problem |
| `ErrImagePull` / `ImagePullBackOff` | `describe pod` -> Failed to pull | Wrong repo/tag, private registry without imagePullSecret |
| `CreateContainerConfigError` | `describe pod` -> events | Missing ConfigMap/Secret **key** used in env |
| `CrashLoopBackOff` / `Error` | `logs` (and `--previous`), exit code | App crashes: bad config/env, missing dependency |
| `OOMKilled`, exit 137 | `describe pod` -> Last State, `top` | Memory limit too low, or a leak |
| Running but `0/1` READY | `describe pod` -> readiness probe | Failing readiness probe, so the pod is not in endpoints |
| Service: refused (curl 7) | `get endpoints`, `describe svc` | Selector/label mismatch, wrong targetPort |
| Name not resolved (curl 6) | `nslookup` from a pod, CoreDNS pods/logs | Wrong service name/namespace, CoreDNS down |
| Timeout (curl 28) | `get networkpolicy`, `describe networkpolicy` | NetworkPolicy dropping traffic, routing |
