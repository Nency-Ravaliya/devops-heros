# Task 1 - kubectl troubleshooting commands (hands-on)

**Ujjawal Prabhat - 24BCS10267 - Session 14 (Kubernetes Troubleshooting)**

Practice workload: `debug-demo.yaml`, applied in namespace `s14`.
- Deployment **web**: 2 nginx replicas.
- Pod **multi**: two containers, `app` and `sidecar`, so I can practise `logs -c`.
- Pod **restarter**: exits with code 2 every ~15 seconds, so I can practise `logs --previous`.

```console
$ kubectl create ns s14
namespace/s14 created
$ kubectl apply -f debug-demo.yaml
deployment.apps/web created
pod/multi created
pod/restarter created
```

---

## 1. `kubectl get` - "what is happening?"

```console
$ kubectl get pods -n s14
NAME                   READY   STATUS    RESTARTS      AGE
multi                  2/2     Running   0             87s
restarter              1/1     Running   3 (30s ago)   87s
web-7f98c7b879-jdqwz   1/1     Running   0             87s
web-7f98c7b879-xhkdv   1/1     Running   0             87s
```

READY counts containers. STATUS is the pod phase or the reason it is waiting. RESTARTS shows when the last restart happened. `restarter` has already restarted 3 times.

**`-o wide`** adds the pod IP and the node:

```console
$ kubectl get pods -n s14 -o wide
NAME                   READY   STATUS    RESTARTS      AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
multi                  2/2     Running   0             87s   10.244.1.30   devops-heros-worker2   <none>           <none>
restarter              1/1     Running   3 (30s ago)   87s   10.244.2.18   devops-heros-worker    <none>           <none>
web-7f98c7b879-jdqwz   1/1     Running   0             87s   10.244.2.17   devops-heros-worker    <none>           <none>
web-7f98c7b879-xhkdv   1/1     Running   0             87s   10.244.1.31   devops-heros-worker2   <none>           <none>

$ kubectl get nodes -o wide
NAME                         STATUS   ROLES           AGE   VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION            CONTAINER-RUNTIME
devops-heros-control-plane   Ready    control-plane   17m   v1.37.0   172.18.0.3    <none>        Debian GNU/Linux 13 (trixie)   7.0.12-linuxkit (arm64)   containerd://2.3.4
devops-heros-worker          Ready    <none>          17m   v1.37.0   172.18.0.4    <none>        Debian GNU/Linux 13 (trixie)   7.0.12-linuxkit (arm64)   containerd://2.3.4
devops-heros-worker2         Ready    <none>          17m   v1.37.0   172.18.0.2    <none>        Debian GNU/Linux 13 (trixie)   7.0.12-linuxkit (arm64)   containerd://2.3.4
```

Several resource types at once, labels, and label selectors:

```console
$ kubectl get deploy,rs,svc -n s14
NAME                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web   2/2     2            2           87s

NAME                             DESIRED   CURRENT   READY   AGE
replicaset.apps/web-7f98c7b879   2         2         2       87s

$ kubectl get pods -n s14 --show-labels
NAME                   READY   STATUS    RESTARTS      AGE   LABELS
multi                  2/2     Running   0             87s   app=multi
restarter              1/1     Running   3 (30s ago)   87s   <none>
web-7f98c7b879-jdqwz   1/1     Running   0             87s   app=web,pod-template-hash=7f98c7b879
web-7f98c7b879-xhkdv   1/1     Running   0             87s   app=web,pod-template-hash=7f98c7b879

$ kubectl get pods -n s14 -l app=web
NAME                   READY   STATUS    RESTARTS   AGE
web-7f98c7b879-jdqwz   1/1     Running   0          87s
web-7f98c7b879-xhkdv   1/1     Running   0          87s
```

(There is no Service in this namespace yet, so `svc` printed nothing.)

Machine-readable output with `-o jsonpath` and `-o yaml`:

```console
$ kubectl get pod web-7f98c7b879-jdqwz -n s14 -o jsonpath='{.status.podIP}{"  "}{.spec.nodeName}{"\n"}'
10.244.2.17  devops-heros-worker

$ kubectl get pod web-7f98c7b879-jdqwz -n s14 -o yaml | head -30
apiVersion: v1
kind: Pod
metadata:
  creationTimestamp: "2026-10-06T11:04:46Z"
  generateName: web-7f98c7b879-
  generation: 1
  labels:
    app: web
    pod-template-hash: 7f98c7b879
  name: web-7f98c7b879-jdqwz
  namespace: s14
  ownerReferences:
  - apiVersion: apps/v1
    blockOwnerDeletion: true
    controller: true
    kind: ReplicaSet
    name: web-7f98c7b879
    uid: b2860e77-ca06-4e0c-a04f-7c410652e5c2
  resourceVersion: "4156"
  uid: d9f69ef1-b14f-49ee-b216-89aa8543b542
spec:
  containers:
  - image: nginx:1.27
    imagePullPolicy: IfNotPresent
    name: nginx
    ports:
    - containerPort: 80
      protocol: TCP
    resources:
      requests:
```

## 2. `kubectl describe` - "what details explain it?"

```console
$ kubectl describe pod web-7f98c7b879-jdqwz -n s14
Name:             web-7f98c7b879-jdqwz
Namespace:        s14
Priority:         0
Service Account:  default
Node:             devops-heros-worker/172.18.0.4
Start Time:       Tue, 06 Oct 2026 19:04:46 +0800
Labels:           app=web
                  pod-template-hash=7f98c7b879
Annotations:      <none>
Status:           Running
IP:               10.244.2.17
IPs:
  IP:           10.244.2.17
Controlled By:  ReplicaSet/web-7f98c7b879
Containers:
  nginx:
    Container ID:   containerd://f750b11a3cc509da9c96e58fb4a10507728e9c3f8a12deabe53cfc9d1e6563fc
    Image:          nginx:1.27
    Image ID:       docker.io/library/nginx@sha256:6784fb0834aa7dbbe12e3d7471e69c290df3e6ba810dc38b34ae33d3c1c05f7d
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 06 Oct 2026 19:04:46 +0800
    Ready:          True
    Restart Count:  0
    Requests:
      cpu:        50m
      memory:     32Mi
    Environment:  <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-bwjpg (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-bwjpg:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   Burstable
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  87s   default-scheduler  Successfully assigned s14/web-7f98c7b879-jdqwz to devops-heros-worker
  Normal  Pulled     87s   kubelet            spec.containers{nginx}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    87s   kubelet            spec.containers{nginx}: Container created
  Normal  Started    87s   kubelet            spec.containers{nginx}: Container started
```

The sections I read first when debugging:
- **State / Last State / Reason / Exit Code**: why the container is waiting or why it died.
- **Restart Count**.
- **Conditions**: whether the pod was scheduled, initialized and ready.
- **Volumes / Mounts**.
- **Events**: what the scheduler and the kubelet tried.

`describe` works on any object:

```console
$ kubectl describe deploy web -n s14 | head -25
Name:                   web
Namespace:              s14
CreationTimestamp:      Tue, 06 Oct 2026 19:04:46 +0800
Labels:                 <none>
Annotations:            deployment.kubernetes.io/revision: 1
Selector:               app=web
Replicas:               2 desired | 2 updated | 2 total | 2 available | 0 unavailable
StrategyType:           RollingUpdate
MinReadySeconds:        0
RollingUpdateStrategy:  25% max unavailable, 25% max surge
Pod Template:
  Labels:  app=web
  Containers:
   nginx:
    Image:      nginx:1.27
    Port:       80/TCP
    Host Port:  0/TCP
    Requests:
      cpu:         50m
      memory:      32Mi
    Environment:   <none>
    Mounts:        <none>
  Volumes:         <none>
  Node-Selectors:  <none>
  Tolerations:     <none>
```

## 3. `kubectl logs` - "what is the application saying?"

With no `-c`, a multi-container pod defaults to its first container and prints a note saying so:

```console
$ kubectl logs multi -n s14
Defaulted container "app" out of: app, sidecar
[app] request #1 handled
[app] request #2 handled
[app] request #3 handled
...
[app] request #29 handled
[app] request #30 handled
```

**`-c <container>`** picks the container. `--tail` limits the number of lines:

```console
$ kubectl logs multi -n s14 -c app --tail=5
[app] request #26 handled
[app] request #27 handled
[app] request #28 handled
[app] request #29 handled
[app] request #30 handled

$ kubectl logs multi -n s14 -c sidecar --tail=3
[sidecar] shipping logs at 11:06:01
[sidecar] shipping logs at 11:06:06
[sidecar] shipping logs at 11:06:11

$ kubectl logs multi -n s14 --all-containers --prefix --tail=2
[pod/multi/app] [app] request #29 handled
[pod/multi/app] [app] request #30 handled
[pod/multi/sidecar] [sidecar] shipping logs at 11:06:06
[pod/multi/sidecar] [sidecar] shipping logs at 11:06:11
```

**`-f`** follows (streams) the log, like `tail -f`:

```console
$ kubectl logs -f multi -n s14 -c app --tail=1     # stopped with Ctrl+C after ~8s
[app] request #35 handled
[app] request #36 handled
[app] request #37 handled
[app] request #38 handled
^C
```

**`--previous`** shows the log of the *previous* (crashed) container instance. This matters because a restart starts a fresh log:

```console
$ kubectl get pod restarter -n s14
NAME        READY   STATUS    RESTARTS      AGE
restarter   1/1     Running   3 (30s ago)   87s

$ kubectl logs restarter -n s14
boot at 11:06:10

$ kubectl logs restarter -n s14 --previous
boot at 11:05:28
fatal: lost connection, exiting
```

The current instance has only logged its boot line. The real error, `fatal: lost connection`, is only visible with `--previous`.

Other useful forms:

```console
$ kubectl logs web-7f98c7b879-jdqwz -n s14 --tail=3 --timestamps
2026-10-06T11:04:46.543406969Z 2026/10/06 11:04:46 [notice] 1#1: start worker process 40
2026-10-06T11:04:46.543507427Z 2026/10/06 11:04:46 [notice] 1#1: start worker process 41
2026-10-06T11:04:46.543600135Z 2026/10/06 11:04:46 [notice] 1#1: start worker process 42

$ kubectl logs deploy/web -n s14 --tail=2
Found 2 pods, using pod/web-7f98c7b879-jdqwz
2026/10/06 11:04:46 [notice] 1#1: start worker process 41
2026/10/06 11:04:46 [notice] 1#1: start worker process 42
```

(`--since=10m` and `-l app=web` for logs from all matching pods are also useful.)

## 4. `kubectl exec` - "what can I see from inside?"

```console
$ kubectl exec web-7f98c7b879-jdqwz -n s14 -- nginx -v
nginx version: nginx/1.27.5

$ kubectl exec web-7f98c7b879-jdqwz -n s14 -- sh -c 'hostname; cat /etc/resolv.conf'
web-7f98c7b879-jdqwz
search s14.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

$ kubectl exec web-7f98c7b879-jdqwz -n s14 -- curl -s -o /dev/null -w '%{http_code}\n' localhost
200

$ kubectl exec multi -n s14 -c sidecar -- ps
PID   USER     TIME  COMMAND
    1 root      0:00 sh -c while true; do echo "[sidecar] shipping logs at $(date +%T)"; sleep 5; done
   29 root      0:00 ps
```

An interactive shell is `kubectl exec -it <pod> -- sh`. Here is the same thing, non-interactive, by piping commands into the shell:

```console
$ echo 'ls /usr/share/nginx/html; exit' | kubectl exec -i web-7f98c7b879-jdqwz -n s14 -- sh
50x.html
index.html
```

`exec` is how you check, from inside the pod, whether the app answers locally, what DNS config the pod has, and what env vars and files it sees. `-c` picks the container in multi-container pods.

## 5. Events - "what did Kubernetes try?"

`kubectl events` is the newer dedicated command. It sorts by time by default and can filter by object and type:

```console
$ kubectl events -n s14 | tail -15
88s                 Normal    ScalingReplicaSet   Deployment/web              Scaled up replica set web-7f98c7b879 from 0 to 2
88s                 Normal    SuccessfulCreate    ReplicaSet/web-7f98c7b879   Created pod: web-7f98c7b879-jdqwz
88s                 Normal    Pulled              Pod/multi                   Container image "busybox:1.36" already present on machine and can be accessed by the pod
88s                 Normal    SuccessfulCreate    ReplicaSet/web-7f98c7b879   Created pod: web-7f98c7b879-xhkdv
88s                 Normal    Scheduled           Pod/restarter               Successfully assigned s14/restarter to devops-heros-worker
88s                 Normal    Pulled              Pod/web-7f98c7b879-jdqwz    Container image "nginx:1.27" already present on machine and can be accessed by the pod
88s                 Normal    Created             Pod/web-7f98c7b879-jdqwz    Container created
88s                 Normal    Scheduled           Pod/multi                   Successfully assigned s14/multi to devops-heros-worker2
88s                 Normal    Started             Pod/web-7f98c7b879-xhkdv    Container started
88s                 Normal    Pulled              Pod/web-7f98c7b879-xhkdv    Container image "nginx:1.27" already present on machine and can be accessed by the pod
88s                 Normal    Created             Pod/web-7f98c7b879-xhkdv    Container created
30s (x2 over 56s)   Warning   BackOff             Pod/restarter               Back-off restarting failed container app in pod restarter_s14(7a9a4899-a2c0-4d52-bf95-ca7786e9d7d1)
4s (x4 over 88s)    Normal    Started             Pod/restarter               Container started
4s (x4 over 88s)    Normal    Pulled              Pod/restarter               Container image "busybox:1.36" already present on machine and can be accessed by the pod
4s (x4 over 88s)    Normal    Created             Pod/restarter               Container created

$ kubectl events -n s14 --for pod/restarter
LAST SEEN           TYPE      REASON      OBJECT          MESSAGE
88s                 Normal    Scheduled   Pod/restarter   Successfully assigned s14/restarter to devops-heros-worker
30s (x2 over 56s)   Warning   BackOff     Pod/restarter   Back-off restarting failed container app in pod restarter_s14(7a9a4899-a2c0-4d52-bf95-ca7786e9d7d1)
4s (x4 over 88s)    Normal    Pulled      Pod/restarter   Container image "busybox:1.36" already present on machine and can be accessed by the pod
4s (x4 over 88s)    Normal    Created     Pod/restarter   Container created
4s (x4 over 88s)    Normal    Started     Pod/restarter   Container started

$ kubectl events -n s14 --types=Warning
LAST SEEN           TYPE      REASON    OBJECT          MESSAGE
30s (x2 over 56s)   Warning   BackOff   Pod/restarter   Back-off restarting failed container app in pod restarter_s14(7a9a4899-a2c0-4d52-bf95-ca7786e9d7d1)
```

The classic form is `kubectl get events`. It is **not** sorted by default, so you add `--sort-by`. A field selector filters it:

```console
$ kubectl get events -n s14 --sort-by=.lastTimestamp | tail -15
88s         Normal    ScalingReplicaSet   deployment/web              Scaled up replica set web-7f98c7b879 from 0 to 2
88s         Normal    SuccessfulCreate    replicaset/web-7f98c7b879   Created pod: web-7f98c7b879-jdqwz
88s         Normal    Pulled              pod/multi                   Container image "busybox:1.36" already present on machine and can be accessed by the pod
88s         Normal    SuccessfulCreate    replicaset/web-7f98c7b879   Created pod: web-7f98c7b879-xhkdv
88s         Normal    Scheduled           pod/restarter               Successfully assigned s14/restarter to devops-heros-worker
88s         Normal    Pulled              pod/web-7f98c7b879-jdqwz    Container image "nginx:1.27" already present on machine and can be accessed by the pod
88s         Normal    Created             pod/web-7f98c7b879-jdqwz    Container created
88s         Normal    Scheduled           pod/multi                   Successfully assigned s14/multi to devops-heros-worker2
88s         Normal    Started             pod/web-7f98c7b879-xhkdv    Container started
88s         Normal    Pulled              pod/web-7f98c7b879-xhkdv    Container image "nginx:1.27" already present on machine and can be accessed by the pod
88s         Normal    Created             pod/web-7f98c7b879-xhkdv    Container created
30s         Warning   BackOff             pod/restarter               Back-off restarting failed container app in pod restarter_s14(7a9a4899-a2c0-4d52-bf95-ca7786e9d7d1)
4s          Normal    Started             pod/restarter               Container started
4s          Normal    Pulled              pod/restarter               Container image "busybox:1.36" already present on machine and can be accessed by the pod
4s          Normal    Created             pod/restarter               Container created

$ kubectl get events -n s14 --field-selector type=Warning
LAST SEEN   TYPE      REASON    OBJECT          MESSAGE
30s         Warning   BackOff   pod/restarter   Back-off restarting failed container app in pod restarter_s14(7a9a4899-a2c0-4d52-bf95-ca7786e9d7d1)
```

Events are kept for only about 1 hour by default, so check them early.

## 6. `kubectl explain` - built-in API documentation

```console
$ kubectl explain pod.spec.containers.livenessProbe | head -25
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
    Minimum consecutive failures for the probe to be considered failed after
    having succeeded. Defaults to 3. Minimum value is 1.

  grpc	<GRPCAction>
    GRPC specifies a GRPC HealthCheckRequest.

  httpGet	<HTTPGetAction>

$ kubectl explain deployment.spec --recursive | head -20
GROUP:      apps
KIND:       Deployment
VERSION:    v1

FIELD: spec <DeploymentSpec>


DESCRIPTION:
    Specification of the desired behavior of the Deployment.
    DeploymentSpec is the specification of the desired behavior of the
    Deployment.
    
FIELDS:
  minReadySeconds	<integer>
  paused	<boolean>
  progressDeadlineSeconds	<integer>
  replicas	<integer>
  revisionHistoryLimit	<integer>
  selector	<LabelSelector> -required-
    matchExpressions	<[]LabelSelectorRequirement>

$ kubectl explain service.spec.selector
KIND:       Service
VERSION:    v1

FIELD: selector <map[string]string>


DESCRIPTION:
    Route service traffic to pods with label keys and values matching this
    selector. If empty or not present, the service is assumed to have an
    external process managing its endpoints, which Kubernetes will not modify.
    Only applies to types ClusterIP, NodePort, and LoadBalancer. Ignored if type
    is ExternalName. More info:
    https://kubernetes.io/docs/concepts/services-networking/service/
```

Use it when a manifest is rejected for an unknown or misspelled field, or when you are unsure of a field's type or default value.

## 7. `kubectl top` - live resource usage (needs metrics-server)

```console
$ kubectl top nodes
NAME                         CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
devops-heros-control-plane   316m         3%       1512Mi          19%         
devops-heros-worker          93m          0%       1549Mi          19%         
devops-heros-worker2         1205m        12%      740Mi           9%          

$ kubectl top pods -n s14
NAME                   CPU(cores)   MEMORY(bytes)   
multi                  1m           0Mi             
web-7f98c7b879-jdqwz   0m           8Mi             
web-7f98c7b879-xhkdv   0m           8Mi             

$ kubectl top pods -n s14 --containers
POD                    NAME      CPU(cores)   MEMORY(bytes)   
multi                  app       1m           0Mi             
multi                  sidecar   1m           0Mi             
web-7f98c7b879-jdqwz   nginx     0m           8Mi             
web-7f98c7b879-xhkdv   nginx     0m           8Mi             

$ kubectl top pods -A --sort-by=memory | head -8
NAMESPACE            NAME                                                    CPU(cores)   MEMORY(bytes)   
kube-system          kube-apiserver-devops-heros-control-plane               32m          728Mi           
monitoring           kps-grafana-5d65bffb7f-9vvcg                            10m          490Mi           
monitoring           prometheus-kps-kube-prometheus-stack-prometheus-0       14m          350Mi           
ingress-nginx        ingress-nginx-controller-7c467b649f-4q7rm               2m           125Mi           
kube-system          kube-controller-manager-devops-heros-control-plane      10m          101Mi           
kube-system          etcd-devops-heros-control-plane                         15m          99Mi            
argocd               argocd-dex-server-7d54f7f9d6-cpjd4                      5m           91Mi            
```

`restarter` does not appear in `top pods`: right after a restart, metrics-server has no sample for the new container yet. Use `top` to spot memory heading towards a limit (OOMKilled), CPU throttling, or a noisy neighbour on a node.

## Summary

| Command | Question it answers |
|---|---|
| `get [-o wide / -o yaml / -l / --show-labels]` | What exists, what state is it in, and where is it running? |
| `describe` | Why is it in this state? (container state, conditions, events) |
| `logs [-f] [--previous] [-c] [--tail] [--timestamps]` | What did the app print, now or before the last crash? |
| `exec [-it] [-c] -- cmd` | What does the world look like from inside the container? |
| `events` / `get events --sort-by=.lastTimestamp` | What did the scheduler and kubelet try, and what failed? |
| `explain` | What does this API field mean, and what type is it? |
| `top nodes/pods [--containers]` | How much CPU and memory is really being used? |
