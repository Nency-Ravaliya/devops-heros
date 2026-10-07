# Task 3 - Mini project: Kubernetes troubleshooting challenge

**Session 14 - Kubernetes Troubleshooting - Sourabh Srivastva - 24BCS10157**

I followed `session-14-kubernetes-troubleshooting/mini-project/README.md`, steps 1-14: Deploy -> Observe -> Break -> Investigate -> Root cause -> Fix -> Verify. I applied the course's `deployment.yaml`, `service.yaml` and `broken-pod.yaml` unchanged into my namespace **`s14-mini`**. My extra files:
- `service-wrong-selector.yaml`: the step 8 change, `app: wrong-app`.
- `fixed-pod.yaml`: the fixed broken pod.

## 1. Deploy the application

```console
$ kubectl create namespace s14-mini
namespace/s14-mini created

$ kubectl apply -n s14-mini -f deployment.yaml
deployment.apps/troubleshooting-app created

$ kubectl apply -n s14-mini -f service.yaml
service/troubleshooting-service created

$ kubectl get pods -n s14-mini
NAME                                   READY   STATUS    RESTARTS   AGE
troubleshooting-app-59d4957864-7rbz7   1/1     Running   0          0s
troubleshooting-app-59d4957864-qzh2c   1/1     Running   0          0s

$ kubectl get service -n s14-mini
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.96.106.253   <none>        80/TCP    0s
```

## 2. Check the application

```console
$ kubectl get pods -n s14-mini -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE                   NOMINATED NODE   READINESS GATES
troubleshooting-app-59d4957864-7rbz7   1/1     Running   0          1s    10.244.2.56   devops-heros-worker    <none>           <none>
troubleshooting-app-59d4957864-qzh2c   1/1     Running   0          1s    10.244.1.75   devops-heros-worker2   <none>           <none>

$ kubectl describe pod troubleshooting-app-59d4957864-7rbz7 -n s14-mini
Name:             troubleshooting-app-59d4957864-7rbz7
Namespace:        s14-mini
Priority:         0
Service Account:  default
Node:             devops-heros-worker/172.18.0.4
Start Time:       Tue, 06 Oct 2026 19:26:01 +0800
Labels:           app=troubleshooting-app
                  pod-template-hash=59d4957864
Annotations:      <none>
Status:           Running
IP:               10.244.2.56
IPs:
  IP:           10.244.2.56
Controlled By:  ReplicaSet/troubleshooting-app-59d4957864
Containers:
  app:
    Container ID:   containerd://b1526936ad3f222a8ba1cb09cfd1394b6043a368aeb3e94130a764c7a7032490
    Image:          nginx:1.27
    Image ID:       docker.io/library/nginx@sha256:6784fb0834aa7dbbe12e3d7471e69c290df3e6ba810dc38b34ae33d3c1c05f7d
    Port:           80/TCP
    Host Port:      0/TCP
    State:          Running
      Started:      Tue, 06 Oct 2026 19:26:01 +0800
    Ready:          True
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-qmk95 (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       True 
  ContainersReady             True 
  PodScheduled                True 
...
QoS Class:                   BestEffort
Node-Selectors:              <none>
...
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  1s    default-scheduler  Successfully assigned s14-mini/troubleshooting-app-59d4957864-7rbz7 to devops-heros-worker
  Normal  Pulled     1s    kubelet            spec.containers{app}: Container image "nginx:1.27" already present on machine and can be accessed by the pod
  Normal  Created    1s    kubelet            spec.containers{app}: Container created
  Normal  Started    1s    kubelet            spec.containers{app}: Container started

$ kubectl logs troubleshooting-app-59d4957864-7rbz7 -n s14-mini
/docker-entrypoint.sh: /docker-entrypoint.d/ is not empty, will attempt to perform configuration
/docker-entrypoint.sh: Looking for shell scripts in /docker-entrypoint.d/
/docker-entrypoint.sh: Launching /docker-entrypoint.d/10-listen-on-ipv6-by-default.sh
10-listen-on-ipv6-by-default.sh: info: Getting the checksum of /etc/nginx/conf.d/default.conf
10-listen-on-ipv6-by-default.sh: info: Enabled listen on IPv6 in /etc/nginx/conf.d/default.conf
/docker-entrypoint.sh: Sourcing /docker-entrypoint.d/15-local-resolvers.envsh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/20-envsubst-on-templates.sh
/docker-entrypoint.sh: Launching /docker-entrypoint.d/30-tune-worker-processes.sh
/docker-entrypoint.sh: Configuration complete; ready for start up
2026/10/06 11:26:01 [notice] 1#1: using the "epoll" event method
2026/10/06 11:26:01 [notice] 1#1: nginx/1.27.5
2026/10/06 11:26:01 [notice] 1#1: built by gcc 12.2.0 (Debian 12.2.0-14) 
2026/10/06 11:26:01 [notice] 1#1: OS: Linux 7.0.12-linuxkit
2026/10/06 11:26:01 [notice] 1#1: getrlimit(RLIMIT_NOFILE): 1073741816:1073741816
2026/10/06 11:26:01 [notice] 1#1: start worker processes
2026/10/06 11:26:01 [notice] 1#1: start worker process 33
...
2026/10/06 11:26:01 [notice] 1#1: start worker process 42
```

The spec's `kubectl exec -it <pod> -- bash`, then `curl localhost`, is an interactive session. I ran the same command non-interactively so the output could be captured:

```console
$ kubectl exec troubleshooting-app-59d4957864-7rbz7 -n s14-mini -- bash -c 'curl -s localhost | head -4'
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

## 3. Check the Service

```console
$ kubectl get service -n s14-mini
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.96.106.253   <none>        80/TCP    1s

$ kubectl describe service troubleshooting-service -n s14-mini
Name:                     troubleshooting-service
Namespace:                s14-mini
Labels:                   <none>
Annotations:              <none>
Selector:                 app=troubleshooting-app
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.106.253
IPs:                      10.96.106.253
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                10.244.2.56:80
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
```

- **Selector** `app=troubleshooting-app` matches the pod label.
- **TargetPort** 80 matches the nginx `containerPort`.
- **Endpoints**: this snapshot was taken 1 second after creation and shows only the first ready pod. A second later both pods were listed (next step).

## 4. Check the endpoints

```console
$ kubectl get endpoints troubleshooting-service -n s14-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS                       AGE
troubleshooting-service   10.244.1.75:80,10.244.2.56:80   1s
```

Both pod IPs, from step 2, appear.

## 5. Create the broken pod

```console
$ kubectl apply -n s14-mini -f broken-pod.yaml
pod/project-broken-pod created

$ kubectl get pod project-broken-pod -n s14-mini        # 30s later
NAME                 READY   STATUS         RESTARTS   AGE
project-broken-pod   0/1     ErrImagePull   0          30s
```

## 6. Troubleshoot it (without touching the YAML first)

```console
$ kubectl get pod project-broken-pod -n s14-mini
NAME                 READY   STATUS         RESTARTS   AGE
project-broken-pod   0/1     ErrImagePull   0          30s

$ kubectl describe pod project-broken-pod -n s14-mini
Name:             project-broken-pod
Namespace:        s14-mini
Priority:         0
Service Account:  default
Node:             devops-heros-worker/172.18.0.4
Start Time:       Tue, 06 Oct 2026 19:26:02 +0800
Labels:           <none>
Annotations:      <none>
Status:           Pending
IP:               10.244.2.57
IPs:
  IP:  10.244.2.57
Containers:
  app:
    Container ID:   
    Image:          nginx:this-tag-does-not-exist
    Image ID:       
    Port:           <none>
    Host Port:      <none>
    State:          Waiting
      Reason:       ErrImagePull
    Ready:          False
    Restart Count:  0
    Environment:    <none>
    Mounts:
      /var/run/secrets/kubernetes.io/serviceaccount from kube-api-access-l958d (ro)
Conditions:
  Type                        Status
  PodReadyToStartContainers   True 
  Initialized                 True 
  Ready                       False 
  ContainersReady             False 
  PodScheduled                True 
...
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  30s                default-scheduler  Successfully assigned s14-mini/project-broken-pod to devops-heros-worker
  Normal   Pulling    16s (x2 over 30s)  kubelet            spec.containers{app}: Pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     14s (x2 over 27s)  kubelet            spec.containers{app}: Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": failed to resolve reference "docker.io/library/nginx:this-tag-does-not-exist": docker.io/library/nginx:this-tag-does-not-exist: not found
  Warning  Failed     14s (x2 over 27s)  kubelet            spec.containers{app}: Error: ErrImagePull
  Normal   BackOff    1s (x2 over 27s)   kubelet            spec.containers{app}: Back-off pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     1s (x2 over 27s)   kubelet            spec.containers{app}: Error: ImagePullBackOff

$ kubectl events -n s14-mini --for pod/project-broken-pod --types=Warning
LAST SEEN           TYPE      REASON   OBJECT                   MESSAGE
14s (x2 over 27s)   Warning   Failed   Pod/project-broken-pod   Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": failed to resolve reference "docker.io/library/nginx:this-tag-does-not-exist": docker.io/library/nginx:this-tag-does-not-exist: not found
14s (x2 over 27s)   Warning   Failed   Pod/project-broken-pod   Error: ErrImagePull
1s (x2 over 27s)    Warning   Failed   Pod/project-broken-pod   Error: ImagePullBackOff
```

## 7. Answers

**Question 1: What is the Pod status?**
*Answer:* `Pending` phase. The container is `Waiting` with reason **`ErrImagePull`**, which alternates with **`ImagePullBackOff`** between retries (both appear in the events). READY is `0/1`.

**Question 2: What is the actual error?**
*Answer:* `Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound ... docker.io/library/nginx:this-tag-does-not-exist: not found`

**Question 3: Which command helped you find the reason?**
*Answer:* `kubectl describe pod project-broken-pod`, specifically the **Events** section with the kubelet's `Failed` event. `kubectl events --for pod/project-broken-pod --types=Warning` shows the same thing more compactly. `kubectl logs` cannot help here, because the container never started.

**Question 4: What is wrong with the image?**
*Answer:* The repository `nginx` (Docker Hub `library/nginx`) exists, but the **tag** `this-tag-does-not-exist` does not, so the registry returns `NotFound`. The node, the network and registry access are all fine: the scheduler placed the pod, and the kubelet reached Docker Hub.

**Question 5: How would you fix it?**
*Answer:* Point the image at a tag that exists, such as `nginx:1.27`, which the rest of the project uses. The image field can be patched in place (`kubectl set image pod/project-broken-pod app=nginx:1.27`), but I fixed the manifest (`fixed-pod.yaml`) and re-created the pod, so the YAML in Git is correct too:

```console
$ kubectl delete pod project-broken-pod -n s14-mini
pod "project-broken-pod" deleted from s14-mini namespace

$ kubectl apply -n s14-mini -f Sourabh-24BCS10157/03-mini-project/fixed-pod.yaml
pod/project-broken-pod created

$ kubectl get pod project-broken-pod -n s14-mini
NAME                 READY   STATUS    RESTARTS   AGE
project-broken-pod   1/1     Running   0          0s
```

## 8. Service troubleshooting challenge: break the selector

`service-wrong-selector.yaml` is the course `service.yaml` with `selector: app: wrong-app`.

```console
$ kubectl apply -n s14-mini -f ../Sourabh-24BCS10157/03-mini-project/service-wrong-selector.yaml
service/troubleshooting-service configured

$ kubectl get service -n s14-mini
NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.96.106.253   <none>        80/TCP    32s

$ kubectl get endpoints troubleshooting-service -n s14-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS   AGE
troubleshooting-service   <none>      32s

$ kubectl run curl-test -n s14-mini --image=curlimages/curl:8.6.0 --restart=Never --rm -i --quiet -- curl -sS --max-time 5 -o /dev/null -w 'HTTP %{http_code}\n' http://troubleshooting-service
HTTP 000
curl: (7) Failed to connect to troubleshooting-service port 80 after 0 ms: Couldn't connect to server
warning: couldn't attach to pod/curl-test, falling back to streaming logs: Internal error occurred: Internal error occurred: error attaching to container: container is in CONTAINER_EXITED state
HTTP 000
curl: (7) Failed to connect to troubleshooting-service port 80 after 0 ms: Couldn't connect to server
pod s14-mini/curl-test terminated (Error)
```

The Service still exists and still has its ClusterIP, but it has **no endpoints**, so connections are refused. (The `couldn't attach` warning is kubectl noting that the short-lived curl pod had already exited. It then printed the pod's logs, which is why the result appears twice.)

## 9. Find the root cause and fix it

```console
$ kubectl get pods -n s14-mini --show-labels
NAME                                   READY   STATUS    RESTARTS   AGE   LABELS
project-broken-pod                     1/1     Running   0          2s    <none>
troubleshooting-app-59d4957864-7rbz7   1/1     Running   0          34s   app=troubleshooting-app,pod-template-hash=59d4957864
troubleshooting-app-59d4957864-qzh2c   1/1     Running   0          34s   app=troubleshooting-app,pod-template-hash=59d4957864

$ kubectl describe service troubleshooting-service -n s14-mini
Name:                     troubleshooting-service
Namespace:                s14-mini
Labels:                   <none>
Annotations:              <none>
Selector:                 app=wrong-app
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.106.253
IPs:                      10.96.106.253
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
```

**Mismatch:** the pod label is `app=troubleshooting-app`, but the Service selector is `app=wrong-app`. No pod carries that label, so the endpoints controller finds nothing. **Fix:** restore the correct selector.

```console
$ kubectl apply -n s14-mini -f service.yaml
service/troubleshooting-service configured

$ kubectl get endpoints troubleshooting-service -n s14-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS                       AGE
troubleshooting-service   10.244.1.75:80,10.244.2.56:80   35s

$ kubectl run curl-test -n s14-mini --image=curlimages/curl:8.6.0 --restart=Never --rm -i --quiet -- curl -sS --max-time 5 -o /dev/null -w 'HTTP %{http_code}\n' http://troubleshooting-service
HTTP 200
warning: couldn't attach to pod/curl-test, falling back to streaming logs: Internal error occurred: Internal error occurred: error attaching to container: failed to load task: no running task found: task 11b58babc62aa0049415a21b602bed4d0748274135e10ba04301064216a5230b not found
HTTP 200

$ kubectl run dns-check -n s14-mini --image=busybox:1.36 --restart=Never --rm -i --quiet -- nslookup troubleshooting-service.s14-mini.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	troubleshooting-service.s14-mini.svc.cluster.local
Address: 10.96.106.253
...
```

The endpoints are back, the Service returns HTTP 200, and DNS resolves the Service name to its ClusterIP (`10.96.106.253`).

## 10. Final checklist run

```console
$ kubectl get pods -n s14-mini
NAME                                   READY   STATUS    RESTARTS   AGE
project-broken-pod                     1/1     Running   0          6s
troubleshooting-app-59d4957864-7rbz7   1/1     Running   0          38s
troubleshooting-app-59d4957864-qzh2c   1/1     Running   0          38s

$ kubectl get events -n s14-mini --sort-by=.lastTimestamp | tail -12
6s          Normal    Started             pod/project-broken-pod                      Container started
5s          Normal    Pulled              pod/curl-test                               Container image "curlimages/curl:8.6.0" already present on machine and can be accessed by the pod
5s          Normal    Created             pod/curl-test                               Container created
5s          Normal    Started             pod/curl-test                               Container started
3s          Normal    Pulled              pod/curl-test                               Container image "curlimages/curl:8.6.0" already present on machine and can be accessed by the pod
3s          Normal    Started             pod/curl-test                               Container started
3s          Normal    Created             pod/curl-test                               Container created
3s          Normal    Scheduled           pod/curl-test                               Successfully assigned s14-mini/curl-test to devops-heros-worker2
2s          Normal    Scheduled           pod/dns-check                               Successfully assigned s14-mini/dns-check to devops-heros-worker2
1s          Normal    Pulled              pod/dns-check                               Container image "busybox:1.36" already present on machine and can be accessed by the pod
1s          Normal    Created             pod/dns-check                               Container created
1s          Normal    Started             pod/dns-check                               Container started
```

## 11. Troubleshooting table

| Problem | What I saw | Command I used | Root cause | Fix |
| :--- | :--- | :--- | :--- | :--- |
| **Broken Pod** | `project-broken-pod 0/1 ErrImagePull` (then `ImagePullBackOff`), phase Pending, Restart Count 0 | `kubectl get pod`, `kubectl describe pod` (Events), `kubectl events --for pod/... --types=Warning` | The container could not be created because its image could not be pulled | Corrected the image in the manifest and re-created the pod, which became `1/1 Running` |
| **Service Problem** | Service exists with ClusterIP, but `ENDPOINTS <none>`; `curl: (7) Couldn't connect` | `kubectl get endpoints`, `kubectl get pods --show-labels`, `kubectl describe service` | Selector `app=wrong-app` does not match the pod label `app=troubleshooting-app` | Restored `selector: app: troubleshooting-app`. Endpoints show both pod IPs, HTTP 200 |
| **Image Problem** | `Failed to pull image "nginx:this-tag-does-not-exist" ... not found` | `kubectl describe pod` -> Events | The tag `this-tag-does-not-exist` does not exist in `docker.io/library/nginx` | Use an existing tag (`nginx:1.27`) |

## 12. README questions

1. **What does `kubectl get` tell us?**
   It gives a quick summary of what exists and what state it is in: name, READY containers, STATUS, RESTARTS and AGE. With `-o wide` it adds IP and node; with `-o yaml/json` it shows the full object; with `-l` it filters by label. It is the first look: what is happening?

2. **What is the difference between `get` and `describe`?**
   `get` is a one-line-per-object summary (or the raw object with `-o yaml`). `describe` is a human-readable detailed report on one object: container state and last state with exit codes, restart count, probes, mounts, conditions, and, most importantly, the **Events** related to that object. `get` tells you *that* something is wrong; `describe` usually tells you *why*.

3. **Why do we use `kubectl logs`?**
   To see what the application itself printed to stdout and stderr: stack traces, "missing env var", "connection refused" and so on. Kubernetes cannot know about application-level errors. `-c` picks a container, `-f` follows the stream, and `--previous` shows the log of the last crashed instance.

4. **When would you use `kubectl exec`?**
   When the pod is running but misbehaving and you need to look from inside: whether the app answers on localhost, what env vars and mounted files the container sees, whether it can resolve and reach another Service (`nslookup`, `curl`), and what the process list shows. It is not possible when the container isn't running (Pending, ImagePullBackOff, between crash-loop restarts). `kubectl debug` with an ephemeral container helps there.

5. **What does `CrashLoopBackOff` mean?**
   The container starts and then exits (crashes, or even exits successfully under `restartPolicy: Always`) again and again. The kubelet restarts it with an exponentially growing delay of 10s, 20s, 40s ... up to 5 minutes. "BackOff" is that waiting period. The cause is in the logs (`logs`, `logs --previous`) and the exit code (`describe`): a missing config or env var, a bad command, a failed dependency, a failing liveness probe, or OOM.

6. **What does `ImagePullBackOff` mean?**
   The kubelet failed to pull the container image (`ErrImagePull`) and is waiting, with back-off, before retrying. Causes include a wrong image name or tag, a private registry without `imagePullSecrets`, registry rate limits, or no network access to the registry. The exact registry error is in the pod Events.

7. **Why can a Pod remain `Pending`?**
   Pending means it has not been scheduled to a node, or it is waiting before its containers can be created. Common reasons:
   - Requests for CPU or memory larger than any node has free.
   - A nodeSelector or node affinity that matches no node.
   - Taints with no matching tolerations.
   - An unbound PVC.
   - A resource quota exceeded, or no nodes ready at all.

   The scheduler's `FailedScheduling` event lists the reason per node (scenario 3 in Task 2).

8. **Why can a Service have no endpoints?**
   - Its selector matches no pod labels (a typo, a wrong label, or a different namespace).
   - The matching pods are not **Ready**, for example because the readiness probe fails.
   - There are no pods at all, for example scaled to 0 or crashing.

   Endpoints only ever contain ready pods that match the selector. A wrong `targetPort` is a separate issue: endpoints exist, but connections are refused (Task 2 scenario 5).

9. **What is the relationship between a Service selector and Pod labels?**
   A Service does not know about Deployments. It holds a label selector, and the endpoints (EndpointSlice) controller continuously finds every **ready** pod in the same namespace whose labels contain all of the selector's key/value pairs, then publishes those pod IPs:port as the Service's endpoints. kube-proxy then load-balances the ClusterIP across them. Labels and selector must match exactly. Pods can have extra labels, but every selector key must be present with the same value.

10. **What is Kubernetes DNS?**
    A cluster add-on, **CoreDNS**, running as pods in `kube-system` behind the `kube-dns` Service at `10.96.0.10` here. It gives every Service a DNS name `<service>.<namespace>.svc.cluster.local` that resolves to its ClusterIP. Every pod's `/etc/resolv.conf` points at it and has `search` domains, so inside the same namespace the short name (`troubleshooting-service`) works, and across namespaces `<service>.<namespace>` works. Applications find each other by name instead of by ever-changing IPs.

## 13. Final architecture (verified)

```text
                    Kubernetes Cluster (namespace s14-mini)
                            │
                            ▼
                  ┌──────────────────────────────┐
                  │ Service troubleshooting-service │  ClusterIP 10.96.106.253:80
                  └─────────┬────────────────────┘
                     selector app=troubleshooting-app
              ┌─────────────┴─────────────┐
              ▼                           ▼
   Pod 10.244.2.56 (worker)     Pod 10.244.1.75 (worker2)
              └─────────────┬─────────────┘
                        nginx:1.27
```

Cleanup: `kubectl delete namespace s14-mini` (done at the end).
