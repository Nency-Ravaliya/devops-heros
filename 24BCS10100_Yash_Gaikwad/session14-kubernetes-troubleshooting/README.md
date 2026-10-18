# Session 14: Kubernetes Troubleshooting

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

| Task | Topic | Section |
|---|---|---|
| 1 | Hands-on practice of the important troubleshooting commands | [Task 1](#task-1-troubleshooting-commands) |
| 2 | Troubleshoot 9 common issues (identify, investigate, root cause, fix, verify, document) | [Task 2](#task-2-troubleshoot-common-issues) |
| 3 | Troubleshooting mini project | [Task 3](#task-3-mini-project) |

**Environment:** Minikube (Docker driver) on Windows 11, Kubernetes v1.37.0. Every command and output is real. The exercise manifests (`issues/*/broken*.yaml`, the fixed versions and the mini project) are the course files, used unchanged; the manifests for ContainerCreating, configuration and networking issues are my own.

### The method I follow every time

```
Observe (get)  ->  Describe (events!)  ->  Logs  ->  Exec / test from inside  ->  Root cause  ->  Fix  ->  Verify
```

| Symptom (STATUS) | Usually means | First command |
|---|---|---|
| `Pending` | cannot be scheduled | `describe pod` -> Events |
| `ContainerCreating` (stuck) | volume / image / network setup failing | `describe pod` -> Events |
| `ErrImagePull`, `ImagePullBackOff` | image cannot be pulled | `describe pod` -> Events |
| `CrashLoopBackOff` | the container starts and exits | `logs --previous` |
| `CreateContainerConfigError` | bad env / ConfigMap / Secret reference | `describe pod` -> Events |
| `OOMKilled` | memory limit exceeded | `describe pod` -> Last State |
| `Running` but traffic fails | Service / DNS / network problem | `get endpoints`, test from a Pod |

---

## Task 1: Troubleshooting commands

A small healthy application to practise on: the Deployment `web` (nginx, 2 replicas) with a Service, and the Pod `logs-demo` that prints log lines.

_Create the practice workloads._

```console
$ kubectl apply -f 01-commands/web-deployment.yaml -f 01-commands/logs-pod.yaml && kubectl rollout status deployment/web --timeout=180s && kubectl wait --for=condition=Ready pod/logs-demo --timeout=120s
deployment.apps/web created
service/web created
pod/logs-demo created
Waiting for deployment "web" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "web" rollout to finish: 1 of 2 updated replicas are available...
deployment "web" successfully rolled out
pod/logs-demo condition met
```

### `kubectl get`: what exists and in what state

_Names, READY (ready containers / total), STATUS, RESTARTS, AGE._

```console
$ kubectl get pods
NAME                   READY   STATUS    RESTARTS   AGE
logs-demo              1/1     Running   0          3s
web-69749f556d-2sckl   1/1     Running   0          3s
web-69749f556d-4rh22   1/1     Running   0          3s
```

_`-o wide` adds the Pod IP, the node and more._

```console
$ kubectl get pods -o wide
NAME                   READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
logs-demo              1/1     Running   0          3s    10.244.0.18   minikube   <none>           <none>
web-69749f556d-2sckl   1/1     Running   0          3s    10.244.0.16   minikube   <none>           <none>
web-69749f556d-4rh22   1/1     Running   0          3s    10.244.0.17   minikube   <none>           <none>
```

_Labels, and selecting by label._

```console
$ kubectl get pods --show-labels; kubectl get pods -l app=web
NAME                   READY   STATUS    RESTARTS   AGE   LABELS
logs-demo              1/1     Running   0          3s    <none>
web-69749f556d-2sckl   1/1     Running   0          3s    app=web,pod-template-hash=69749f556d
web-69749f556d-4rh22   1/1     Running   0          3s    app=web,pod-template-hash=69749f556d
NAME                   READY   STATUS    RESTARTS   AGE
web-69749f556d-2sckl   1/1     Running   0          3s
web-69749f556d-4rh22   1/1     Running   0          3s
```

_Several kinds at once: the whole chain Deployment -> ReplicaSet -> Pods, plus Services._

```console
$ kubectl get deployment,replicaset,pod,service
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   2/2     2            2           4s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-69749f556d   2         2         2       4s

NAME                       READY   STATUS    RESTARTS   AGE
pod/logs-demo              1/1     Running   0          4s
pod/web-69749f556d-2sckl   1/1     Running   0          4s
pod/web-69749f556d-4rh22   1/1     Running   0          4s

NAME                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   39s
service/web          ClusterIP   10.105.20.235   <none>        80/TCP    4s
```

_Extract single fields with jsonpath._

```console
$ kubectl get pod logs-demo -o jsonpath="{.status.phase}  podIP={.status.podIP}  node={.spec.nodeName}{\"\\n\"}"
Running  podIP=10.244.0.18  node=minikube
```

_`-A` = all namespaces._

```console
$ kubectl get pods -A | head -n 6
NAMESPACE       NAME                                       READY   STATUS      RESTARTS      AGE
default         logs-demo                                  1/1     Running     0             4s
default         web-69749f556d-2sckl                       1/1     Running     0             4s
default         web-69749f556d-4rh22                       1/1     Running     0             4s
ingress-nginx   ingress-nginx-admission-create-zx7lf       0/1     Completed   0             55m
ingress-nginx   ingress-nginx-admission-patch-zpp6m        0/1     Completed   2 (55m ago)   55m
```

### `kubectl describe`: the details and, above all, the **Events**

_Status, IP, node, container image and state, restart count, conditions._

```console
$ kubectl describe pod logs-demo | head -n 36
Name:             logs-demo
Namespace:        default
Priority:         0
Service Account:  default
Node:             minikube/192.168.49.2
Start Time:       Sun, 18 Oct 2026 20:28:32 +0530
Labels:           <none>
Annotations:      <none>
Status:           Running
IP:               10.244.0.18
IPs:
  IP:  10.244.0.18
Containers:
  app:
    Container ID:  containerd://f410e2d6f2568a2ed04ae28bd77cfbef7d3cedb236a5493e4771c9557bebf2da
    Image:         busybox:1.36
    Image ID:      docker.io/library/busybox@sha256:73aaf090f3d85aa34ee199857f03fa3a95c8ede2ffd4cc2cdb5b94e566b11662
    Port:          <none>
    Host Port:     <none>
    Command:
      sh
      -c
      echo "Application started"
      echo "Connecting to database..."
      echo "Database connection successful"
      echo "Application is running"
      while true; do
        echo "Application is healthy"
        sleep 5
      done
      
    State:          Running
      Started:      Sun, 18 Oct 2026 20:28:33 +0530
    Ready:          True
    Restart Count:  0
    Environment:    <none>
```

_The Events at the bottom: the Pod lifecycle step by step. This is the most important part when something is wrong._

```console
$ kubectl describe pod logs-demo | sed -n "/^Events:/,\$p"
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  5s    default-scheduler  Successfully assigned default/logs-demo to minikube
  Normal  Pulled     5s    kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal  Created    4s    kubelet            spec.containers{app}: Container created
  Normal  Started    4s    kubelet            spec.containers{app}: Container started
```

### `kubectl logs`: what the application printed

_The last 5 lines._

```console
$ kubectl logs logs-demo --tail=5
Connecting to database...
Database connection successful
Application is running
Application is healthy
Application is healthy
```

_Only the last 20 seconds._

```console
$ kubectl logs logs-demo --since=20s
Application started
Connecting to database...
Database connection successful
Application is running
Application is healthy
Application is healthy
```

_Logs by Deployment or by label (`--prefix` shows which Pod each line came from)._

```console
$ kubectl logs deployment/web --tail=3; kubectl logs -l app=web --tail=1 --prefix
Found 2 pods, using pod/web-69749f556d-2sckl
2026/10/18 14:58:34 [notice] 1#1: start worker process 38
2026/10/18 14:58:34 [notice] 1#1: start worker process 39
2026/10/18 14:58:34 [notice] 1#1: start worker process 40
[pod/web-69749f556d-4rh22/nginx] 2026/10/18 14:58:35 [notice] 1#1: start worker process 40
[pod/web-69749f556d-2sckl/nginx] 2026/10/18 14:58:34 [notice] 1#1: start worker process 40
```

_`-f` follows the log live (stopped here after 8 seconds). `-p`/`--previous` shows the log of the previous, crashed container; `-c` picks a container in a multi-container Pod._

```console
$ kubectl logs logs-demo -f --tail=2 & sleep 8; kill %1
Application is healthy
Application is healthy
Application is healthy
```

### `kubectl exec`: look from the inside

_Run commands in the container (filesystem, DNS settings)._

```console
$ kubectl exec logs-demo -- ls /; kubectl exec logs-demo -- cat /etc/resolv.conf
bin
dev
etc
home
lib
lib64
proc
root
sys
tmp
usr
var
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

_Run a command in a Pod of a Deployment._

```console
$ kubectl exec deployment/web -- nginx -v
nginx version: nginx/1.27.5
```

_Test the application from inside its own Pod: it answers on localhost:80, so the container itself is healthy. (Interactive shell: `kubectl exec -it <pod> -- sh`.)_

```console
$ kubectl exec deployment/web -- sh -c "curl -s localhost | head -n 4"
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

### `kubectl events`: what the cluster did recently

_Events of one object (the `kubectl events` command)._

```console
$ kubectl events --for pod/logs-demo
LAST SEEN   TYPE     REASON      OBJECT          MESSAGE
26m         Normal   Scheduled   Pod/logs-demo   Successfully assigned default/logs-demo to minikube
26m         Normal   Pulled      Pod/logs-demo   Container image "busybox:1.36" already present on machine and can be accessed by the pod
26m         Normal   Created     Pod/logs-demo   Container created
26m         Normal   Started     Pod/logs-demo   Container started
25m         Normal   Killing     Pod/logs-demo   Stopping container app
18s         Normal   Scheduled   Pod/logs-demo   Successfully assigned default/logs-demo to minikube
18s         Normal   Pulled      Pod/logs-demo   Container image "busybox:1.36" already present on machine and can be accessed by the pod
17s         Normal   Created     Pod/logs-demo   Container created
17s         Normal   Started     Pod/logs-demo   Container started
```

_The latest events of the namespace, in time order (the classic form)._

```console
$ kubectl get events --sort-by=.lastTimestamp | tail -n 8
17s         Normal    Created                        pod/web-69749f556d-2sckl                           Container created
17s         Normal    Created                        pod/logs-demo                                      Container created
17s         Normal    Pulled                         pod/web-69749f556d-4rh22                           Container image "nginx:1.27" already present on machine and can be accessed by the pod
17s         Normal    Started                        pod/logs-demo                                      Container started
17s         Normal    Pulled                         pod/web-69749f556d-2sckl                           Container image "nginx:1.27" already present on machine and can be accessed by the pod
17s         Normal    Created                        pod/web-69749f556d-4rh22                           Container created
16s         Normal    Started                        pod/web-69749f556d-4rh22                           Container started
16s         Normal    Started                        pod/web-69749f556d-2sckl                           Container started
```

### `kubectl explain`: built-in documentation

_What a field means and which sub-fields it has, straight from the API._

```console
$ kubectl explain pod.spec.containers.livenessProbe | head -n 18
KIND:       Pod
VERSION:    v1

FIELD: livenessProbe <Probe>


DESCRIPTION:
    Periodic probe of container liveness. Container will be restarted if the
    probe fails. Cannot be updated. More info:
    https://kubernetes.io/docs/concepts/workloads/pods/pod-lifecycle#container-probes
    Probe describes a health check to be performed against a container to
    determine whether it is alive or ready to receive traffic.
    
FIELDS:
  exec	<ExecAction>
    Exec specifies a command to execute in the container.

  failureThreshold	<integer>
```

_Another field._

```console
$ kubectl explain deployment.spec.strategy.rollingUpdate
GROUP:      apps
KIND:       Deployment
VERSION:    v1

FIELD: rollingUpdate <RollingUpdateDeployment>


DESCRIPTION:
    Rolling update config params. Present only if DeploymentStrategyType =
    RollingUpdate.
    Spec to control the desired behavior of rolling update.
    
FIELDS:
  maxSurge	<IntOrString>
    The maximum number of pods that can be scheduled above the desired number of
    pods. Value can be an absolute number (ex: 5) or a percentage of desired
    pods (ex: 10%). This can not be 0 if MaxUnavailable is 0. Absolute number is
    calculated from percentage by rounding up. Defaults to 25%. Example: when
    this is set to 30%, the new ReplicaSet can be scaled up immediately when the
    rolling update starts, such that the total number of old and new pods do not
    exceed 130% of desired pods. Once old pods have been killed, new ReplicaSet
    can be scaled up further, ensuring that total number of pods running at any
    time during the update is at most 130% of desired pods.

  maxUnavailable	<IntOrString>
    The maximum number of pods that can be unavailable during the update. Value
    can be an absolute number (ex: 5) or a percentage of desired pods (ex: 10%).
    Absolute number is calculated from percentage by rounding down. This can not
    be 0 if MaxSurge is 0. Defaults to 25%. Example: when this is set to 30%,
    the old ReplicaSet can be scaled down to 70% of desired pods immediately
    when the rolling update starts. Once new pods are ready, old ReplicaSet can
    be scaled down further, followed by scaling up the new ReplicaSet, ensuring
    that the total number of pods available at all times during the update is at
    least 70% of desired pods.
```

### `kubectl top`: resource usage (needs the metrics-server addon)

_Current CPU and memory of the node and of the Pods._

```console
$ minikube addons list | sed "s/\x1b\[[0-9;]*m//g" | grep metrics-server; kubectl top nodes; kubectl top pods
│ metrics-server              │ minikube │ enabled ✅ │ Kubernetes                             │
NAME       CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
minikube   786m         6%       1171Mi          10%         
NAME                   CPU(cores)   MEMORY(bytes)   
logs-demo              9m           0Mi             
web-69749f556d-2sckl   13m          9Mi             
web-69749f556d-4rh22   12m          10Mi            
```

_Per container._

```console
$ kubectl top pods --containers
POD                    NAME    CPU(cores)   MEMORY(bytes)   
logs-demo              app     9m           0Mi             
web-69749f556d-2sckl   nginx   13m          9Mi             
web-69749f556d-4rh22   nginx   12m          10Mi            
```

_`-o wide` for nodes (IP, OS, runtime) and Services (selector)._

```console
$ kubectl get nodes -o wide; kubectl get svc -o wide
NAME       STATUS   ROLES           AGE    VERSION   INTERNAL-IP    EXTERNAL-IP   OS-IMAGE                         KERNEL-VERSION                             CONTAINER-RUNTIME
minikube   Ready    control-plane   116m   v1.37.0   192.168.49.2   <none>        Debian GNU/Linux 12 (bookworm)   6.6.87.2-microsoft-standard-WSL2 (amd64)   containerd://2.3.4
NAME         TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE   SELECTOR
kubernetes   ClusterIP   10.96.0.1       <none>        443/TCP   56s   <none>
web          ClusterIP   10.105.20.235   <none>        80/TCP    21s   app=web
```

_Cleanup._

```console
$ kubectl delete -f 01-commands/web-deployment.yaml -f 01-commands/logs-pod.yaml
deployment.apps "web" deleted from default namespace
service "web" deleted from default namespace
pod "logs-demo" deleted from default namespace
```

---

## Task 2: Troubleshoot common issues

For every issue: **identify, investigate, root cause, fix, verify, document**. A small client Pod is used for the network tests:

_busybox with wget and nslookup._

```console
$ kubectl run net-client --image=busybox:1.36 --restart=Never -- sleep 7200 && kubectl wait --for=condition=Ready pod/net-client --timeout=120s
pod/net-client created
pod/net-client condition met
```

### Issue 1: CrashLoopBackOff

_**Identify:** the Pod keeps restarting and the status alternates between Error and CrashLoopBackOff (RESTARTS grows)._

```console
$ kubectl apply -f issues/crashloopbackoff/broken-pod.yaml && sleep 45 && kubectl get pod crash-demo
pod/crash-demo created
NAME         READY   STATUS   RESTARTS      AGE
crash-demo   0/1     Error    3 (30s ago)   46s
```

_**Investigate (describe):** Last State Terminated with Exit Code 1, and the event "Back-off restarting failed container"._

```console
$ kubectl describe pod crash-demo | awk "/^    State:/,/Ready:/{print} /^Events:/{e=1} e{print}"
    State:          Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Sun, 18 Oct 2026 20:30:11 +0530
      Finished:     Sun, 18 Oct 2026 20:30:11 +0530
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Sun, 18 Oct 2026 20:29:42 +0530
      Finished:     Sun, 18 Oct 2026 20:29:42 +0530
    Ready:          False
Events:
  Type     Reason     Age               From               Message
  ----     ------     ----              ----               -------
  Normal   Scheduled  46s               default-scheduler  Successfully assigned default/crash-demo to minikube
  Normal   Pulled     1s (x4 over 45s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Normal   Created    1s (x4 over 45s)  kubelet            spec.containers{app}: Container created
  Normal   Started    1s (x4 over 45s)  kubelet            spec.containers{app}: Container started
  Warning  BackOff    1s (x4 over 43s)  kubelet            spec.containers{app}: Back-off restarting failed container app in pod crash-demo_default(914832aa-8e0c-48b1-a80d-625a77e26642)
```

_**Investigate (logs):** what the application printed before it died. (While the container waits for its next restart, plain `kubectl logs` returns the crashed run; `--previous` asks for the instance before the current one and is useful once the container is running again. On this Minikube only the most recent dead container is kept, so `--previous` can report "unable to retrieve container logs".)_

```console
$ kubectl logs crash-demo
Application starting...
Something went wrong!
```

**Root cause:** the container's command ends with `exit 1` right after printing "Something went wrong!", so the container stops, and the default `restartPolicy: Always` restarts it again and again with growing delays (the back-off). (In real life the log shows the actual exception, a missing config value, or a bad command.)

_**Fix and verify:** a Pod command cannot be edited in place, so I recreate it from the fixed manifest. It runs, stays Running with 0 restarts, and the log shows a healthy application._

```console
$ kubectl delete pod crash-demo --wait=true && kubectl apply -f issues/crashloopbackoff/fixed-pod.yaml && kubectl wait --for=condition=Ready pod/crash-demo --timeout=120s && sleep 3 && kubectl get pod crash-demo && kubectl logs crash-demo
pod "crash-demo" deleted from default namespace
pod/crash-demo created
pod/crash-demo condition met
NAME         READY   STATUS    RESTARTS   AGE
crash-demo   1/1     Running   0          4s
Application starting...
Application is healthy
```

_Cleanup._

```console
$ kubectl delete pod crash-demo --wait=false
pod "crash-demo" deleted from default namespace
```

### Issue 2: ImagePullBackOff / ErrImagePull

_**Identify:** the Pod is never ready. A few seconds after the start it is still `ContainerCreating` (the image is being pulled); after the pull fails it goes through `ErrImagePull` (the events below show it) and settles on `ImagePullBackOff` (Kubernetes waits longer between retries)._

```console
$ kubectl apply -f issues/imagepullbackoff/broken-pod.yaml && sleep 6 && kubectl get pod image-demo && sleep 30 && kubectl get pod image-demo
pod/image-demo created
NAME         READY   STATUS              RESTARTS   AGE
image-demo   0/1     ContainerCreating   0          6s
NAME         READY   STATUS         RESTARTS   AGE
image-demo   0/1     ErrImagePull   0          37s
```

_**Investigate:** the events say exactly which image failed and why (the tag does not exist)._

```console
$ kubectl describe pod image-demo | awk "/^    State:/,/Ready:/{print} /^Events:/{e=1} e{print}" | cut -c1-220
    State:          Waiting
      Reason:       ErrImagePull
    Ready:          False
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  37s                default-scheduler  Successfully assigned default/image-demo to minikube
  Normal   Pulling    17s (x2 over 36s)  kubelet            spec.containers{app}: Pulling image "nginx:this-image-does-not-exist"
  Warning  Failed     15s (x2 over 29s)  kubelet            spec.containers{app}: Failed to pull image "nginx:this-image-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/libra
  Warning  Failed     15s (x2 over 29s)  kubelet            spec.containers{app}: Error: ErrImagePull
  Normal   BackOff    3s (x2 over 29s)   kubelet            spec.containers{app}: Back-off pulling image "nginx:this-image-does-not-exist"
  Warning  Failed     3s (x2 over 29s)   kubelet            spec.containers{app}: Error: ImagePullBackOff
```

**Root cause:** the image tag `nginx:this-image-does-not-exist` is not in the registry. (Other causes of the same symptom: typo in the image name, private registry without `imagePullSecrets`, registry unreachable.)

_**Fix and verify:** the image field of a Pod can be changed in place; with a valid tag the Pod pulls the image and becomes Ready._

```console
$ kubectl apply -f issues/imagepullbackoff/fixed-pod.yaml && kubectl wait --for=condition=Ready pod/image-demo --timeout=180s && kubectl get pod image-demo -o jsonpath="image={.spec.containers[0].image}  phase={.status.phase}{\"\\n\"}"
pod/image-demo configured
pod/image-demo condition met
image=nginx:1.27  phase=Running
```

_Cleanup._

```console
$ kubectl delete pod image-demo --wait=false
pod "image-demo" deleted from default namespace
```

### Issue 3: Pending

_**Identify:** Pending, and the NODE column is empty: the scheduler has not found a node._

```console
$ kubectl apply -f issues/pending/broken-pod.yaml && sleep 6 && kubectl get pod pending-demo -o wide
pod/pending-demo created
NAME           READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
pending-demo   0/1     Pending   0          6s    <none>   <none>   <none>           <none>
```

_**Investigate:** the Pod has a node selector, and the event is FailedScheduling: no node matches._

```console
$ kubectl describe pod pending-demo | sed -n "/^Node-Selectors:/p;/^Events:/,\$p" | cut -c1-200
Node-Selectors:              kubernetes.io/hostname=node-that-does-not-exist
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  7s    default-scheduler  0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector. preemption: 0/1 nodes are available: 1 Preemption is not helpful for
```

_Compare with the real node labels: the node name is `minikube`, not what the selector asks for._

```console
$ kubectl get nodes --show-labels | cut -c1-210
NAME       STATUS   ROLES           AGE    VERSION   LABELS
minikube   Ready    control-plane   119m   v1.37.0   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=minikube,kubernetes.io/os=linux,minikube.k8s.io/com
```

**Root cause:** `nodeSelector: kubernetes.io/hostname: node-that-does-not-exist` asks for a node that does not exist, so the scheduler can never place the Pod. (Other causes of Pending: not enough CPU/memory, taints without tolerations, unbound PVC, affinity rules.)

_**Fix and verify:** the scheduling fields cannot be changed on an existing Pod, so I recreate it without the bad selector. It is scheduled on minikube and Running._

```console
$ kubectl delete pod pending-demo --wait=true && kubectl apply -f issues/pending/fixed-pod.yaml && kubectl wait --for=condition=Ready pod/pending-demo --timeout=120s && kubectl get pod pending-demo -o wide
pod "pending-demo" deleted from default namespace
pod/pending-demo created
pod/pending-demo condition met
NAME           READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
pending-demo   1/1     Running   0          1s    10.244.0.23   minikube   <none>           <none>
```

_Cleanup._

```console
$ kubectl delete pod pending-demo --wait=false
pod "pending-demo" deleted from default namespace
```

### Issue 4: ContainerCreating (stuck)

_**Identify:** the Pod was scheduled but never starts: stuck in ContainerCreating._

```console
$ kubectl apply -f issues/containercreating/broken-pod.yaml && sleep 15 && kubectl get pod creating-demo
pod/creating-demo created
NAME            READY   STATUS              RESTARTS   AGE
creating-demo   0/1     ContainerCreating   0          15s
```

_**Investigate:** the event is FailedMount: the ConfigMap volume refers to a ConfigMap that is not found._

```console
$ kubectl describe pod creating-demo | sed -n "/^Events:/,\$p" | cut -c1-200
Events:
  Type     Reason       Age               From               Message
  ----     ------       ----              ----               -------
  Normal   Scheduled    15s               default-scheduler  Successfully assigned default/creating-demo to minikube
  Warning  FailedMount  8s (x5 over 15s)  kubelet            MountVolume.SetUp failed for volume "settings" : configmap "app-settings" not found
```

_Confirm: there is no ConfigMap named app-settings._

```console
$ kubectl get configmap
NAME               DATA   AGE
kube-root-ca.crt   1      3m35s
```

**Root cause:** the Pod mounts the ConfigMap `app-settings` as a volume, but it was never created, so the kubelet cannot prepare the volume and cannot start the container. (The same symptom appears with a missing Secret, an unbound PVC, or a CNI/network problem.)

_**Fix and verify:** create the missing ConfigMap. The kubelet keeps retrying the mount, so the same Pod starts by itself a little later (no need to recreate it) and prints the value from the ConfigMap._

```console
$ cat issues/containercreating/fix-configmap.yaml; kubectl apply -f issues/containercreating/fix-configmap.yaml && kubectl wait --for=condition=Ready pod/creating-demo --timeout=240s && kubectl get pod creating-demo && kubectl logs creating-demo
# FIX: create the ConfigMap the Pod is waiting for
apiVersion: v1
kind: ConfigMap
metadata:
  name: app-settings
data:
  mode: "production"
configmap/app-settings created
pod/creating-demo condition met
NAME            READY   STATUS    RESTARTS   AGE
creating-demo   1/1     Running   0          32s
```

_Cleanup._

```console
$ kubectl delete -f issues/containercreating/broken-pod.yaml -f issues/containercreating/fix-configmap.yaml --wait=false
pod "creating-demo" deleted from default namespace
configmap "app-settings" deleted from default namespace
```

### Issue 5: Configuration issue (CreateContainerConfigError)

_**Identify:** the status is `CreateContainerConfigError`: the container cannot even be created._

```console
$ kubectl apply -f issues/config-issue/broken-pod.yaml && sleep 12 && kubectl get pod config-demo
configmap/db-config created
pod/config-demo created
NAME          READY   STATUS                       RESTARTS   AGE
config-demo   0/1     CreateContainerConfigError   0          13s
```

_**Investigate:** the event names the exact problem: key DB_HOST not found in ConfigMap db-config. Looking at the ConfigMap confirms it only has DB_PORT._

```console
$ kubectl describe pod config-demo | sed -n "/^Events:/,\$p" | cut -c1-200; kubectl get configmap db-config -o jsonpath="keys in db-config: {.data}{\"\\n\"}"
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  13s                default-scheduler  Successfully assigned default/config-demo to minikube
  Normal   Pulled     11s (x2 over 12s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Warning  Failed     11s (x2 over 12s)  kubelet            spec.containers{app}: Error: couldn't find key DB_HOST in ConfigMap default/db-config
keys in db-config: {"DB_PORT":"5432"}
```

**Root cause:** the Pod asks for `DB_HOST` through `configMapKeyRef`, but the ConfigMap has no such key (a typo or a forgotten entry).

_**Fix and verify:** add the missing key. The kubelet retries, the Pod starts without being recreated, and the application sees both values._

```console
$ kubectl apply -f issues/config-issue/fixed-configmap.yaml && kubectl wait --for=condition=Ready pod/config-demo --timeout=240s && kubectl get pod config-demo && kubectl logs config-demo
configmap/db-config configured
pod/config-demo condition met
NAME          READY   STATUS    RESTARTS   AGE
config-demo   1/1     Running   0          15s
connecting to db.internal:5432
```

_Cleanup._

```console
$ kubectl delete -f issues/config-issue/broken-pod.yaml --wait=false
configmap "db-config" deleted from default namespace
pod "config-demo" deleted from default namespace
```

### Issue 6: Service connectivity (no endpoints)

_The application Pods are healthy and the Service exists._

```console
$ kubectl apply -f issues/service-selector/web-deployment.yaml -f issues/service-selector/broken-service.yaml && kubectl rollout status deployment/web --timeout=180s && kubectl get pods -l app=web && kubectl get svc web-service
deployment.apps/web created
service/web-service created
Waiting for deployment "web" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "web" rollout to finish: 1 of 2 updated replicas are available...
deployment "web" successfully rolled out
NAME                   READY   STATUS    RESTARTS   AGE
web-557577df75-7wkvp   1/1     Running   0          1s
web-557577df75-tc724   1/1     Running   0          1s
NAME          TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
web-service   ClusterIP   10.107.112.103   <none>        80/TCP    2s
```

_**Identify:** the request to the Service fails (it hangs or is refused) although the Pods are Running._

```console
$ kubectl exec net-client -- wget -T 3 -qO- http://web-service; echo "wget exit code: $?"
wget: can't connect to remote host (10.107.112.103): Connection refused
command terminated with exit code 1
wget exit code: 1
```

_**Investigate:** the Service has **no endpoints**. Its selector is `app=web-ahsgdf`, but the Pods carry the label `app=web`._

```console
$ kubectl get endpoints web-service 2>/dev/null; kubectl describe svc web-service | grep -E "Selector|Endpoints"; kubectl get pods --show-labels -l app=web | head -n 3
NAME          ENDPOINTS   AGE
web-service   <none>      3s
Selector:                 app=web-ahsgdf
Endpoints:                
NAME                   READY   STATUS    RESTARTS   AGE   LABELS
web-557577df75-7wkvp   1/1     Running   0          4s    app=web,pod-template-hash=557577df75
web-557577df75-tc724   1/1     Running   0          4s    app=web,pod-template-hash=557577df75
```

**Root cause:** the Service selector does not match any Pod label, so no Pod IP is behind the Service. This is the most common Service problem.

_**Fix and verify:** correct the selector. Two endpoints appear and the request now returns the nginx page._

```console
$ kubectl patch svc web-service -p "{\"spec\":{\"selector\":{\"app\":\"web\"}}}" && kubectl get endpoints web-service 2>/dev/null && sleep 4 && kubectl exec net-client -- wget -T 5 -qO- http://web-service | head -n 4
service/web-service patched
NAME          ENDPOINTS                       AGE
web-service   10.244.0.26:80,10.244.0.27:80   5s
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

### Issue 7: Pod networking / wrong port (connection refused)

_A new application whose Service has **endpoints** this time, but they point to port 8080._

```console
$ kubectl apply -f issues/networking/web-wrong-targetport.yaml && kubectl rollout status deployment/net-web --timeout=180s && kubectl get endpoints net-web 2>/dev/null
deployment.apps/net-web created
service/net-web created
Waiting for deployment "net-web" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "net-web" rollout to finish: 1 of 2 updated replicas are available...
deployment "net-web" successfully rolled out
NAME      ENDPOINTS                           AGE
net-web   10.244.0.28:8080,10.244.0.29:8080   1s
```

_**Identify:** the Service answers immediately with "Connection refused": the traffic reaches a Pod, but nothing listens on that port._

```console
$ kubectl exec net-client -- wget -T 3 -qO- http://net-web; echo "wget exit code: $?"
wget: can't connect to remote host (10.97.231.166): Connection refused
command terminated with exit code 1
wget exit code: 1
```

_**Investigate:** testing the Pod directly shows the application works on port **80** and refuses connections on **8080**, so the Pod is fine and the Service configuration is wrong._

```console
$ POD_IP=$(kubectl get pod -l app=net-web -o jsonpath="{.items[0].status.podIP}"); echo "Pod IP $POD_IP"; kubectl exec net-client -- wget -T 3 -qO- http://$POD_IP:80 | head -n 4; kubectl exec net-client -- wget -T 3 -qO- http://$POD_IP:8080; echo "port 8080 exit code: $?"
Pod IP 10.244.0.28
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
wget: can't connect to remote host (10.244.0.28): Connection refused
command terminated with exit code 1
port 8080 exit code: 1
```

**Root cause:** the Service `targetPort` is 8080 but the container listens on 80, so Service traffic goes to a closed port.

_**Fix and verify:** set `targetPort: 80`; the Service works._

```console
$ kubectl patch svc net-web -p "{\"spec\":{\"ports\":[{\"port\":80,\"targetPort\":80}]}}" && sleep 3 && kubectl exec net-client -- wget -T 5 -qO- http://net-web | head -n 4
service/net-web patched
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

**A second networking problem: a NetworkPolicy blocks the traffic.** Everything is configured correctly, but a policy denies all incoming connections to the Pods:

_**Identify:** the request now **times out** (no refusal message, no answer): a silent drop is the typical sign of a firewall-style rule such as a NetworkPolicy._

```console
$ kubectl apply -f issues/networking/deny-all-policy.yaml && sleep 3 && kubectl exec net-client -- wget -T 4 -qO- http://net-web; echo "wget exit code: $?"
networkpolicy.networking.k8s.io/deny-all-ingress created
wget: download timed out
command terminated with exit code 1
wget exit code: 1
```

_**Investigate:** DNS still resolves the name (so it is not a DNS problem), and a NetworkPolicy selecting `app=net-web` with Ingress and no allow rules exists._

```console
$ kubectl exec net-client -- nslookup net-web.default.svc.cluster.local | tail -n 3; kubectl get networkpolicy; kubectl describe networkpolicy deny-all-ingress | sed -n "/^Spec:/,\$p"
Address: 10.97.231.166


NAME               POD-SELECTOR   AGE
deny-all-ingress   app=net-web    8s
Spec:
  PodSelector:     app=net-web
  Allowing ingress traffic:
    <none> (Selected pods are isolated for ingress connectivity)
  Not affecting egress traffic
  Policy Types: Ingress
```

**Root cause:** `deny-all-ingress` selects the Pods and lists no ingress rules, so no incoming traffic is allowed.

_**Fix and verify:** remove the policy (in production one would add an allow rule for the right clients instead); traffic flows again._

```console
$ kubectl delete networkpolicy deny-all-ingress && sleep 3 && kubectl exec net-client -- wget -T 5 -qO- http://net-web | head -n 4
networkpolicy.networking.k8s.io "deny-all-ingress" deleted from default namespace
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

_Cleanup._

```console
$ kubectl delete -f issues/networking/web-wrong-targetport.yaml --wait=false; kubectl delete -f issues/service-selector/web-deployment.yaml -f issues/service-selector/broken-service.yaml --wait=false
deployment.apps "net-web" deleted from default namespace
service "net-web" deleted from default namespace
deployment.apps "web" deleted from default namespace
service "web-service" deleted from default namespace
```

### Issue 8: DNS issues

_The course file for the DNS test Pod. It named the image `dnsutils:1.3`, which does **not exist** in the registry: with that name the Pod itself ends up in ImagePullBackOff, exactly like Issue 2. The correct name is `jessie-dnsutils:1.3`, which I use (see the note at the top of the file)._

```console
$ head -n 12 issues/dns/dns-test-pod.yaml
# NOTE: the course file used the image name registry.k8s.io/e2e-test-images/dnsutils:1.3, which does not exist
# (ImagePullBackOff); the real name is jessie-dnsutils:1.3 and is used here.
apiVersion: v1
kind: Pod

metadata:
  name: dns-test

spec:
  containers:
    - name: dns-test
      image: registry.k8s.io/e2e-test-images/jessie-dnsutils:1.3
```

_A Pod with DNS tools (`nslookup`, `dig`). Its resolver points at the cluster DNS._

```console
$ kubectl apply -f issues/dns/dns-test-pod.yaml && kubectl wait --for=condition=Ready pod/dns-test --timeout=240s && kubectl exec dns-test -- cat /etc/resolv.conf
pod/dns-test created
pod/dns-test condition met
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

_**Identify:** a built-in service name resolves, but the name the application uses (`postgres-db-wrong-name.production...`) returns no address and `nslookup` exits with code 1: the name does not exist in cluster DNS (NXDOMAIN). This is what the course scenario "dns-failure" does._

```console
$ kubectl exec dns-test -- nslookup kubernetes.default; echo "exit: $?"; kubectl exec dns-test -- nslookup postgres-db-wrong-name.production.svc.cluster.local; echo "exit: $?"
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	kubernetes.default.svc.cluster.local
Address: 10.96.0.1

exit: 0
Server:		10.96.0.10
Address:	10.96.0.10#53

** server can't find postgres-db-wrong-name.production.svc.cluster.local: NXDOMAIN

command terminated with exit code 1
exit: 1
```

_**Investigate:** there is no namespace `production` and no such Service anywhere._

```console
$ kubectl get svc -A; kubectl get namespace production 2>&1
NAMESPACE       NAME                                 TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE
default         kubernetes                           ClusterIP   10.96.0.1       <none>        443/TCP                      4m36s
ingress-nginx   ingress-nginx-controller             NodePort    10.97.125.231   <none>        80:31846/TCP,443:30130/TCP   59m
ingress-nginx   ingress-nginx-controller-admission   ClusterIP   10.96.220.137   <none>        443/TCP                      59m
kube-system     kube-dns                             ClusterIP   10.96.0.10      <none>        53/UDP,53/TCP,9153/TCP       120m
kube-system     metrics-server                       ClusterIP   10.96.61.247    <none>        443/TCP                      51m
Error from server (NotFound): namespaces "production" not found
```

**Root cause:** the application is configured with a Service name (and namespace) that does not exist. Nothing is wrong with CoreDNS itself; compare the [CoreDNS outage](../session11-kubernetes-services/coredns/README.md) where *every* name failed.

_**Fix and verify:** the correct fix is to use the real Service name. Here I create the Service in the right namespace, and both the full name and the short `<service>.<namespace>` form now resolve._

```console
$ kubectl create namespace production && kubectl create service clusterip postgres-db -n production --tcp=5432:5432 && sleep 3 && kubectl exec dns-test -- nslookup postgres-db.production.svc.cluster.local && kubectl exec dns-test -- nslookup postgres-db.production
namespace/production created
service/postgres-db created
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	postgres-db.production.svc.cluster.local
Address: 10.105.181.3

Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	postgres-db.production.svc.cluster.local
Address: 10.105.181.3
```

_Cleanup._

```console
$ kubectl delete namespace production --wait=false; kubectl delete pod dns-test --wait=false
namespace "production" deleted
pod "dns-test" deleted from default namespace
```

### Issue 9: OOMKilled (resource limit)

_The Pod has a 20Mi memory limit but the program allocates up to 1000 MB._

```console
$ grep -B1 -A2 "limits" issues/oomkilled/broken.yaml
      resources:
        limits:
          memory: "20Mi"
```

_**Identify:** the Pod is restarted again and again: `OOMKilled` / `CrashLoopBackOff`._

```console
$ kubectl apply -f issues/oomkilled/broken.yaml && sleep 40 && kubectl get pod fail-5-oomkilled-pod
pod/fail-5-oomkilled-pod created
NAME                   READY   STATUS      RESTARTS      AGE
fail-5-oomkilled-pod   0/1     OOMKilled   3 (25s ago)   40s
```

_**Investigate:** Last State Terminated, **Reason: OOMKilled, Exit Code 137** (128 + signal 9: the kernel killed the process for exceeding its memory limit)._

```console
$ kubectl describe pod fail-5-oomkilled-pod | awk "/^    State:/,/Ready:/{print}"
    State:          Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Sun, 18 Oct 2026 20:33:18 +0530
      Finished:     Sun, 18 Oct 2026 20:33:18 +0530
    Last State:     Terminated
      Reason:       OOMKilled
      Exit Code:    137
      Started:      Sun, 18 Oct 2026 20:32:54 +0530
      Finished:     Sun, 18 Oct 2026 20:32:54 +0530
    Ready:          False
```

**Root cause:** the container needs far more memory than its limit, so the kernel OOM killer stops it. Either the limit is too low or the application has a memory problem.

_**Fix and verify:** with a bounded allocation and a 128Mi limit the Pod runs without restarts._

```console
$ kubectl delete pod fail-5-oomkilled-pod --wait=true && kubectl apply -f issues/oomkilled/fixed.yaml && kubectl wait --for=condition=Ready pod/fail-5-oomkilled-pod --timeout=120s && sleep 8 && kubectl get pod fail-5-oomkilled-pod && kubectl logs fail-5-oomkilled-pod
pod "fail-5-oomkilled-pod" deleted from default namespace
pod/fail-5-oomkilled-pod created
pod/fail-5-oomkilled-pod condition met
NAME                   READY   STATUS    RESTARTS   AGE
fail-5-oomkilled-pod   1/1     Running   0          9s
```

_Cleanup._

```console
$ kubectl delete pod fail-5-oomkilled-pod --wait=false; kubectl delete pod net-client --wait=false
pod "fail-5-oomkilled-pod" deleted from default namespace
pod "net-client" deleted from default namespace
```

### Summary of the nine issues

| # | Status seen | How I found it | Root cause | Fix |
|---|---|---|---|---|
| 1 | CrashLoopBackOff | `logs --previous`, describe (exit code 1) | process exits with error | corrected the command |
| 2 | ErrImagePull / ImagePullBackOff | describe -> Events | image tag does not exist | valid tag |
| 3 | Pending | describe -> FailedScheduling | nodeSelector matches no node | removed bad selector |
| 4 | ContainerCreating | describe -> FailedMount | ConfigMap volume refers to a missing ConfigMap | created the ConfigMap |
| 5 | CreateContainerConfigError | describe -> Events | missing key in ConfigMap | added the key |
| 6 | Running but Service fails | `get endpoints` (none) | Service selector does not match Pod labels | fixed the selector |
| 7 | Running but connection refused / timeout | test the Pod IP directly; `get networkpolicy` | wrong `targetPort`; a deny-all NetworkPolicy | `targetPort: 80`; removed the policy |
| 8 | NXDOMAIN | `nslookup`, `get svc -A` | name of a non-existent Service | use the real Service name |
| 9 | OOMKilled | describe -> Last State (exit 137) | memory limit too low | right-sized limit |

---

## Task 3: Mini project

The course's troubleshooting project: **Deploy, Observe, Break, Investigate, Find root cause, Fix, Verify** with an nginx Deployment and Service (files from the course, unchanged).

### 1. Deploy the application

_Deployment (2 replicas) and Service._

```console
$ kubectl apply -f 03-mini-project/deployment.yaml -f 03-mini-project/service.yaml && kubectl rollout status deployment/troubleshooting-app --timeout=180s && kubectl get pods && kubectl get service
deployment.apps/troubleshooting-app created
service/troubleshooting-service created
Waiting for deployment "troubleshooting-app" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "troubleshooting-app" rollout to finish: 1 of 2 updated replicas are available...
deployment "troubleshooting-app" successfully rolled out
NAME                                   READY   STATUS        RESTARTS   AGE
fail-5-oomkilled-pod                   1/1     Terminating   0          11s
net-client                             1/1     Terminating   0          4m8s
troubleshooting-app-59d4957864-gnwfx   1/1     Running       0          1s
troubleshooting-app-59d4957864-tjb6k   1/1     Running       0          1s
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
kubernetes                ClusterIP   10.96.0.1       <none>        443/TCP   5m36s
troubleshooting-service   ClusterIP   10.103.29.215   <none>        80/TCP    1s
```

### 2. Observe: is everything healthy?

_Pods Running with IPs, and nginx answers on localhost inside the Pod._

```console
$ kubectl get pods -o wide; kubectl exec deployment/troubleshooting-app -- sh -c "curl -s localhost | head -n 4"
NAME                                   READY   STATUS        RESTARTS   AGE    IP            NODE       NOMINATED NODE   READINESS GATES
fail-5-oomkilled-pod                   1/1     Terminating   0          12s    10.244.0.32   minikube   <none>           <none>
net-client                             1/1     Terminating   0          4m9s   10.244.0.19   minikube   <none>           <none>
troubleshooting-app-59d4957864-gnwfx   1/1     Running       0          2s     10.244.0.34   minikube   <none>           <none>
troubleshooting-app-59d4957864-tjb6k   1/1     Running       0          2s     10.244.0.33   minikube   <none>           <none>
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

_Check the three things the README lists for a Service: **Selector**, **TargetPort** and **Endpoints**. Two endpoints: healthy._

```console
$ kubectl describe service troubleshooting-service | grep -E "Selector|TargetPort|Endpoints"; kubectl get endpoints troubleshooting-service 2>/dev/null
Selector:                 app=troubleshooting-app
TargetPort:               80/TCP
Endpoints:                10.244.0.33:80,10.244.0.34:80
NAME                      ENDPOINTS                       AGE
troubleshooting-service   10.244.0.33:80,10.244.0.34:80   3s
```

_A client Pod confirms the Service works end to end (the baseline)._

```console
$ kubectl run mini-client --image=busybox:1.36 --restart=Never -- sleep 3600 && kubectl wait --for=condition=Ready pod/mini-client --timeout=120s && kubectl exec mini-client -- wget -T 5 -qO- http://troubleshooting-service | head -n 4
pod/mini-client created
pod/mini-client condition met
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

### 3. Break, investigate, find the root cause, fix and verify

**Break 1: a bad image tag during an update**

_**Break:** update to a tag that does not exist. **Observe:** a new Pod is in ErrImagePull/ImagePullBackOff and the rollout never completes, but the two old Pods are **still running** (a rolling update protects the service)._

```console
$ kubectl set image deployment/troubleshooting-app app=nginx:1.99.99 && sleep 25 && kubectl get pods && kubectl rollout status deployment/troubleshooting-app --timeout=20s; echo "rollout exit code: $?"
deployment.apps/troubleshooting-app image updated
NAME                                   READY   STATUS             RESTARTS   AGE
mini-client                            1/1     Running            0          27s
troubleshooting-app-59d4957864-gnwfx   1/1     Running            0          30s
troubleshooting-app-59d4957864-tjb6k   1/1     Running            0          30s
troubleshooting-app-d6757f7cc-wlg88    0/1     ImagePullBackOff   0          25s
Waiting for deployment "troubleshooting-app" rollout to finish: 1 out of 2 new replicas have been updated...
error: timed out waiting for the condition
rollout exit code: 1
```

_**Investigate / root cause:** the events show the pull failure for `nginx:1.99.99`. The Service still answers because the old Pods serve the traffic._

```console
$ kubectl get events --sort-by=.lastTimestamp | grep -E "Failed to pull image|ErrImagePull" | tail -n 3 | cut -c1-210; kubectl exec mini-client -- wget -T 5 -qO- http://troubleshooting-service | head -n 2
3m42s       Warning   Failed                         pod/image-demo                                     Failed to pull image "nginx:this-image-does-not-exist": rpc error: code = NotFound desc = failed to pull a
26s         Warning   Failed                         pod/troubleshooting-app-d6757f7cc-wlg88            Failed to pull image "nginx:1.99.99": rpc error: code = NotFound desc = failed to pull and unpack image "d
26s         Warning   Failed                         pod/troubleshooting-app-d6757f7cc-wlg88            Error: ErrImagePull
<!DOCTYPE html>
<html>
```

_**Fix and verify:** `rollout undo` returns to the working revision; all Pods are Running on the original image._

```console
$ kubectl rollout undo deployment/troubleshooting-app && kubectl rollout status deployment/troubleshooting-app --timeout=120s && kubectl get pods && kubectl get deployment troubleshooting-app -o jsonpath="image={.spec.template.spec.containers[0].image}{\"\\n\"}"
Warning: resource deployments/troubleshooting-app was previously managed with 'kubectl apply'. Rolling back will not update the kubectl.kubernetes.io/last-applied-configuration annotation, which may cause unexpected behavior on future 'kubectl apply' operations. Consider using 'kubectl apply' with your previous configuration file instead.
deployment.apps/troubleshooting-app rolled back
deployment "troubleshooting-app" successfully rolled out
NAME                                   READY   STATUS        RESTARTS   AGE
mini-client                            1/1     Running       0          50s
troubleshooting-app-59d4957864-gnwfx   1/1     Running       0          53s
troubleshooting-app-59d4957864-tjb6k   1/1     Running       0          53s
troubleshooting-app-d6757f7cc-wlg88    0/1     Terminating   0          48s
image=nginx:1.27
```

**Break 2: the Service selector**

_**Break + observe:** endpoints are empty and requests fail although the Pods are healthy._

```console
$ kubectl patch service troubleshooting-service -p "{\"spec\":{\"selector\":{\"app\":\"troubleshooting-app-v2\"}}}" && sleep 3 && kubectl get endpoints troubleshooting-service 2>/dev/null; kubectl exec mini-client -- wget -T 3 -qO- http://troubleshooting-service; echo "wget exit code: $?"
service/troubleshooting-service patched
NAME                      ENDPOINTS   AGE
troubleshooting-service   <none>      57s
wget: can't connect to remote host (10.103.29.215): Connection refused
command terminated with exit code 1
wget exit code: 1
```

_**Investigate / root cause:** the selector is `app=troubleshooting-app-v2` but the Pods are labelled `app=troubleshooting-app`._

```console
$ kubectl describe service troubleshooting-service | grep -E "Selector|Endpoints"; kubectl get pods --show-labels | head -n 3
Selector:                 app=troubleshooting-app-v2
Endpoints:                
NAME                                   READY   STATUS    RESTARTS   AGE   LABELS
mini-client                            1/1     Running   0          56s   run=mini-client
troubleshooting-app-59d4957864-gnwfx   1/1     Running   0          59s   app=troubleshooting-app,pod-template-hash=59d4957864
```

_**Fix and verify:** restore the selector; endpoints return and the Service answers._

```console
$ kubectl patch service troubleshooting-service -p "{\"spec\":{\"selector\":{\"app\":\"troubleshooting-app\"}}}" && sleep 4 && kubectl get endpoints troubleshooting-service 2>/dev/null && kubectl exec mini-client -- wget -T 5 -qO- http://troubleshooting-service | head -n 2
service/troubleshooting-service patched
NAME                      ENDPOINTS                       AGE
troubleshooting-service   10.244.0.33:80,10.244.0.34:80   64s
<!DOCTYPE html>
<html>
```

**Break 3: the Service targetPort**

_**Break + observe:** the endpoints exist but now end in :8080, and the requests are refused._

```console
$ kubectl patch service troubleshooting-service -p "{\"spec\":{\"ports\":[{\"port\":80,\"targetPort\":8080}]}}" && sleep 4 && kubectl get endpoints troubleshooting-service 2>/dev/null; kubectl exec mini-client -- wget -T 3 -qO- http://troubleshooting-service; echo "wget exit code: $?"
service/troubleshooting-service patched
NAME                      ENDPOINTS                           AGE
troubleshooting-service   10.244.0.33:8080,10.244.0.34:8080   69s
wget: can't connect to remote host (10.103.29.215): Connection refused
command terminated with exit code 1
wget exit code: 1
```

_**Investigate / root cause:** the Pod answers on port 80; the Service forwards to 8080, where nothing listens._

```console
$ kubectl describe service troubleshooting-service | grep -E "TargetPort|Endpoints"; kubectl exec deployment/troubleshooting-app -- sh -c "curl -s -o /dev/null -w \"inside the Pod, port 80: HTTP %{http_code}\n\" localhost:80"
TargetPort:               8080/TCP
Endpoints:                10.244.0.33:8080,10.244.0.34:8080
inside the Pod, port 80: HTTP 200
```

_**Fix and verify:** `targetPort: 80`; the Service works again._

```console
$ kubectl patch service troubleshooting-service -p "{\"spec\":{\"ports\":[{\"port\":80,\"targetPort\":80}]}}" && sleep 4 && kubectl exec mini-client -- wget -T 5 -qO- http://troubleshooting-service | head -n 2
service/troubleshooting-service patched
<!DOCTYPE html>
<html>
```

**The course file `broken-pod.yaml`** (a standalone Pod with a bad image tag):

_**Observe / investigate:** ImagePullBackOff; the events show that `nginx:this-tag-does-not-exist` cannot be pulled._

```console
$ kubectl apply -f 03-mini-project/broken-pod.yaml && sleep 20 && kubectl get pod project-broken-pod && kubectl describe pod project-broken-pod | sed -n "/^Events:/,\$p" | tail -n 4 | cut -c1-200
pod/project-broken-pod created
NAME                 READY   STATUS         RESTARTS   AGE
project-broken-pod   0/1     ErrImagePull   0          20s
  Warning  Failed     15s   kubelet            spec.containers{app}: Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/
  Warning  Failed     15s   kubelet            spec.containers{app}: Error: ErrImagePull
  Normal   BackOff    15s   kubelet            spec.containers{app}: Back-off pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     15s   kubelet            spec.containers{app}: Error: ImagePullBackOff
```

_**Fix and verify:** set a valid image; the Pod becomes Ready._

```console
$ kubectl set image pod/project-broken-pod app=nginx:1.27 && kubectl wait --for=condition=Ready pod/project-broken-pod --timeout=180s && kubectl get pod project-broken-pod
pod/project-broken-pod image updated
pod/project-broken-pod condition met
NAME                 READY   STATUS    RESTARTS   AGE
project-broken-pod   1/1     Running   0          21s
```

### 4. Final verification

_Everything is healthy again and the application is reachable through the Service._

```console
$ kubectl get deployment,pods,svc,endpoints 2>/dev/null; kubectl exec mini-client -- wget -T 5 -qO- http://troubleshooting-service | head -n 4
NAME                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/troubleshooting-app   2/2     2            2           97s

NAME                                       READY   STATUS    RESTARTS   AGE
pod/mini-client                            1/1     Running   0          94s
pod/project-broken-pod                     1/1     Running   0          22s
pod/troubleshooting-app-59d4957864-gnwfx   1/1     Running   0          97s
pod/troubleshooting-app-59d4957864-tjb6k   1/1     Running   0          97s

NAME                              TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/kubernetes                ClusterIP   10.96.0.1       <none>        443/TCP   7m12s
service/troubleshooting-service   ClusterIP   10.103.29.215   <none>        80/TCP    97s

NAME                                ENDPOINTS                       AGE
endpoints/kubernetes                192.168.49.2:8443               7m12s
endpoints/troubleshooting-service   10.244.0.33:80,10.244.0.34:80   97s
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

_Cleanup._

```console
$ kubectl delete -f 03-mini-project/ --wait=false; kubectl delete pod mini-client --wait=false
pod "project-broken-pod" deleted from default namespace
deployment.apps "troubleshooting-app" deleted from default namespace
service "troubleshooting-service" deleted from default namespace
pod "mini-client" deleted from default namespace
```

## What I learned

- Start with `kubectl get` and `kubectl describe` (read the **Events**), then `logs` (`--previous` for crashes), then test from **inside** the cluster with `exec` or a client Pod.
- The STATUS word narrows the cause: Pending (scheduling), ContainerCreating (volumes/network), ImagePullBackOff (image), CrashLoopBackOff (application exits), CreateContainerConfigError (references), OOMKilled (memory).
- For "the Pod is Running but the Service fails", check **endpoints**: no endpoints means a selector problem; endpoints on the wrong port means a `targetPort` problem; a timeout (not a refusal) points at a NetworkPolicy or firewall; NXDOMAIN means a wrong name.
- A rolling update keeps the old Pods alive when the new image is broken, and `kubectl rollout undo` is the fastest repair.
