# 01 — Kubernetes Troubleshooting Commands

**Submitted by:** Piyush Bansal

Hands-on with the main troubleshooting commands, using the session's demo Pods
([get-demo.yaml](get-demo.yaml) from `01-kubectl-get`, [logs-demo.yaml](logs-demo.yaml) from `03-kubectl-logs`,
[exec-demo.yaml](exec-demo.yaml) from `04-kubectl-exec`) in namespace `p14-cmds`. All output is real.

| Command | What I use it for |
|---|---|
| `kubectl get` | Quick status: READY, STATUS, RESTARTS, AGE |
| `kubectl get -o wide` | Plus Pod IP and node |
| `kubectl describe` | Full detail of one object + its **Events** |
| `kubectl logs` | What the app printed (`--previous` for the crashed container) |
| `kubectl exec` | Run commands inside the container (curl, cat config, env) |
| `kubectl events` | Events for a namespace or one object, filterable by type |
| `kubectl explain` | Built-in docs for any YAML field |
| `kubectl top` | Live CPU/memory from metrics-server |

```text
$ kubectl create namespace p14-cmds
namespace/p14-cmds created
$ kubectl apply -n p14-cmds -f get-demo.yaml -f logs-demo.yaml -f exec-demo.yaml
pod/get-demo created
pod/logs-demo created
pod/exec-demo created
```

## kubectl get / get -o wide

```text
$ kubectl get pods -n p14-cmds
NAME        READY   STATUS    RESTARTS   AGE
exec-demo   1/1     Running   0          2m20s
get-demo    1/1     Running   0          2m20s
logs-demo   1/1     Running   0          2m20s
$ kubectl get pods -n p14-cmds -o wide
NAME        READY   STATUS    RESTARTS   AGE     IP             NODE                    NOMINATED NODE   READINESS GATES
exec-demo   1/1     Running   0          2m22s   10.244.0.112   desktop-control-plane   <none>           <none>
get-demo    1/1     Running   0          2m22s   10.244.0.111   desktop-control-plane   <none>           <none>
logs-demo   1/1     Running   0          2m22s   10.244.0.113   desktop-control-plane   <none>           <none>
$ kubectl get pods -n p14-cmds --show-labels
NAME        READY   STATUS    RESTARTS   AGE     LABELS
exec-demo   1/1     Running   0          2m24s   <none>
get-demo    1/1     Running   0          2m24s   app=get-demo
logs-demo   1/1     Running   0          2m24s   <none>
$ kubectl get pods -n p14-cmds -l app=get-demo
NAME       READY   STATUS    RESTARTS   AGE
get-demo   1/1     Running   0          2m26s
$ kubectl get pod get-demo -n p14-cmds -o jsonpath='{.status.podIP}{" "}{.spec.nodeName}{" "}{.status.phase}{"\n"}'
10.244.0.111 desktop-control-plane Running
$ kubectl get pod get-demo -n p14-cmds -o yaml | grep -A4 '^status:' | head -5
status:
  conditions:
  - lastProbeTime: null
    lastTransitionTime: "2026-10-07T17:49:59Z"
    observedGeneration: 1
$ kubectl get all -n p14-cmds
NAME            READY   STATUS    RESTARTS   AGE
pod/exec-demo   1/1     Running   0          2m31s
pod/get-demo    1/1     Running   0          2m31s
pod/logs-demo   1/1     Running   0          2m31s
$ kubectl get nodes -o wide
NAME                    STATUS   ROLES           AGE     VERSION   INTERNAL-IP   EXTERNAL-IP   OS-IMAGE                       KERNEL-VERSION            CONTAINER-RUNTIME
desktop-control-plane   Ready    control-plane   4h26m   v1.36.1   172.18.0.2    <none>        Debian GNU/Linux 13 (trixie)   7.0.12-linuxkit (arm64)   containerd://2.3.1
```

`--show-labels` is how I check that a Service selector will match. `-o jsonpath` / `-o yaml` pull out exact fields.

## kubectl describe

```text
$ kubectl describe pod get-demo -n p14-cmds | grep -E '^(Name|Namespace|Node|Status|IP):|Image:|Ready|Restart Count'
Name:             get-demo
Namespace:        p14-cmds
Node:             desktop-control-plane/172.18.0.2
Status:           Running
IP:               10.244.0.111
    Image:          nginx:1.27
    Ready:          True
    Restart Count:  0
  PodReadyToStartContainers   True 
  Ready                       True 
  ContainersReady             True 
$ kubectl describe pod get-demo -n p14-cmds | sed -n '/^Conditions/,$p'
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
Volumes:
  kube-api-access-fhffr:
    Type:                    Projected (a volume that contains injected data from multiple sources)
    TokenExpirationSeconds:  3607
    ConfigMapName:           kube-root-ca.crt
    Optional:                false
    DownwardAPI:             true
QoS Class:                   BestEffort
Node-Selectors:              <none>
Tolerations:                 node.kubernetes.io/not-ready:NoExecute op=Exists for 300s
                             node.kubernetes.io/unreachable:NoExecute op=Exists for 300s
Events:
  Type    Reason     Age    From               Message
  ----    ------     ----   ----               -------
  Normal  Scheduled  2m48s  default-scheduler  Successfully assigned p14-cmds/get-demo to desktop-control-plane
  Normal  Pulled     2m25s  kubelet            spec.containers{nginx}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    2m21s  kubelet            spec.containers{nginx}: Container created
  Normal  Started    117s   kubelet            spec.containers{nginx}: Container started
```

The Events at the bottom are the most useful part: the whole life of the Pod, scheduled → pulled → created → started.

## kubectl logs

```text
$ kubectl logs logs-demo -n p14-cmds | head -5
Application started
Connecting to database...
Database connection successful
Application is running
Application is healthy
$ kubectl logs logs-demo -n p14-cmds --tail=6
Application is healthy
Application is healthy
Application is healthy
Application is healthy
Application is healthy
Application is healthy
$ kubectl logs logs-demo -n p14-cmds --since=10s
Application is healthy
Application is healthy
$ kubectl logs logs-demo -n p14-cmds --timestamps --tail=2
2026-10-07T17:52:26.990969262Z Application is healthy
2026-10-07T17:52:32.084068250Z Application is healthy
$ kubectl logs -f logs-demo -n p14-cmds --tail=1    # stopped after ~12s
Application is healthy
Application is healthy
```

Other options I used in Task 2: `--previous` (logs of the last crashed container, the key to
CrashLoopBackOff) and `deploy/<name>` (logs of a Pod picked from a Deployment).

## kubectl exec

```text
$ kubectl exec exec-demo -n p14-cmds -- nginx -v
nginx version: nginx/1.27.5
$ kubectl exec exec-demo -n p14-cmds -- cat /etc/resolv.conf
search p14-cmds.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
$ kubectl exec exec-demo -n p14-cmds -- curl -s -o /dev/null -w '%{http_code}\n' localhost
200
$ kubectl exec exec-demo -n p14-cmds -- sh -c 'hostname; env | grep -i kubernetes_service'
exec-demo
KUBERNETES_SERVICE_PORT=443
KUBERNETES_SERVICE_PORT_HTTPS=443
KUBERNETES_SERVICE_HOST=10.96.0.1
```

`curl localhost` from inside answers "is the app itself working?" before I look at Services or networking.
`resolv.conf` shows which DNS server and search domains the Pod uses.

## kubectl events

```text
$ kubectl events -n p14-cmds
LAST SEEN   TYPE     REASON      OBJECT          MESSAGE
4m49s       Normal   Scheduled   Pod/get-demo    Successfully assigned p14-cmds/get-demo to desktop-control-plane
4m49s       Normal   Scheduled   Pod/logs-demo   Successfully assigned p14-cmds/logs-demo to desktop-control-plane
4m49s       Normal   Scheduled   Pod/exec-demo   Successfully assigned p14-cmds/exec-demo to desktop-control-plane
4m27s       Normal   Pulled      Pod/get-demo    Container image "nginx:1.27" already present on machine and can be accessed by the pod
4m27s       Normal   Pulled      Pod/logs-demo   Container image "busybox:1.36" already present on machine and can be accessed by the pod
4m25s       Normal   Pulled      Pod/exec-demo   Container image "nginx:1.27" already present on machine and can be accessed by the pod
4m23s       Normal   Created     Pod/exec-demo   Container created
4m23s       Normal   Created     Pod/get-demo    Container created
4m23s       Normal   Created     Pod/logs-demo   Container created
3m59s       Normal   Started     Pod/get-demo    Container started
3m53s       Normal   Started     Pod/exec-demo   Container started
3m46s       Normal   Started     Pod/logs-demo   Container started
$ kubectl get events -n p14-cmds --sort-by=.lastTimestamp | tail -5
4m23s       Normal   Created     pod/get-demo    Container created
4m23s       Normal   Created     pod/logs-demo   Container created
3m59s       Normal   Started     pod/get-demo    Container started
3m53s       Normal   Started     pod/exec-demo   Container started
3m46s       Normal   Started     pod/logs-demo   Container started
$ kubectl events -n p14-cmds --for pod/exec-demo
LAST SEEN   TYPE     REASON      OBJECT          MESSAGE
4m51s       Normal   Scheduled   Pod/exec-demo   Successfully assigned p14-cmds/exec-demo to desktop-control-plane
4m27s       Normal   Pulled      Pod/exec-demo   Container image "nginx:1.27" already present on machine and can be accessed by the pod
4m25s       Normal   Created     Pod/exec-demo   Container created
3m55s       Normal   Started     Pod/exec-demo   Container started
$ kubectl events -n p14-cmds --types=Warning
No events found in p14-cmds namespace.
```

`kubectl events` is sorted by time already (unlike plain `get events`). `--types=Warning` on a healthy
namespace returns nothing, which is itself a good sign. Events expire after about an hour.

## kubectl explain

```text
$ kubectl explain pod.spec.containers.livenessProbe | head -20
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
$ kubectl explain deployment.spec.strategy --recursive | head -20
GROUP:      apps
KIND:       Deployment
VERSION:    v1

FIELD: strategy <DeploymentStrategy>


DESCRIPTION:
    The deployment strategy to use to replace existing pods with new ones.
    DeploymentStrategy describes how to replace existing pods with new ones.
    
FIELDS:
  rollingUpdate	<RollingUpdateDeployment>
    maxSurge	<IntOrString>
    maxUnavailable	<IntOrString>
  type	<string>
  enum: Recreate, RollingUpdate
```

## kubectl top

My first run of `kubectl top` failed with `error: Metrics API not available`: on the shared node,
metrics-server was itself in `CrashLoopBackOff` at that moment (the control plane was overloaded).
After it recovered:

```text
$ kubectl top nodes
NAME                    CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
desktop-control-plane   1055m        13%      2015Mi          51%         
$ kubectl top pods -n p14-cmds
NAME        CPU(cores)   MEMORY(bytes)   
exec-demo   0m           7Mi             
get-demo    0m           7Mi             
logs-demo   1m           0Mi             
$ kubectl top pods -n p14-cmds --containers
POD         NAME    CPU(cores)   MEMORY(bytes)   
exec-demo   nginx   0m           7Mi             
get-demo    nginx   0m           7Mi             
logs-demo   app     1m           0Mi             
$ kubectl top pods -A --sort-by=cpu | head -6
NAMESPACE            NAME                                            CPU(cores)   MEMORY(bytes)   
kube-system          kube-apiserver-desktop-control-plane            161m         698Mi           
kube-system          kube-controller-manager-desktop-control-plane   66m          89Mi            
kube-system          etcd-desktop-control-plane                      65m          77Mi            
ingress-nginx        ingress-nginx-controller-78657859f8-qvlbq       36m          99Mi            
kube-system          coredns-589f44dc88-n6xkg                        21m          31Mi            
```

## Cleanup

```bash
kubectl delete ns p14-cmds
```

## What I learned

- Order that works for me: `get` (what's wrong) → `describe`/`events` (why, from Kubernetes' side) →
  `logs` (why, from the app's side) → `exec` (test from inside).
- `kubectl top` depends on metrics-server. If it says "Metrics API not available", check
  `kubectl get pods -n kube-system` before blaming the app.
- `kubectl explain` saves a trip to the docs when writing YAML.
