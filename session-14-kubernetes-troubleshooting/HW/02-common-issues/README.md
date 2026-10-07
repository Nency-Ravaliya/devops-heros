# 02 — Troubleshooting Common Issues

**Submitted by:** Piyush Bansal

I broke each thing on purpose, then went through the same steps every time:
**identify → investigate → root cause → fix → verify**. Namespace `p14-issues` (and `p14-net` for the
NetworkPolicy one) on Docker Desktop. All output below is real.

| # | Issue | Files | Root cause in one line |
|---|---|---|---|
| 1 | CrashLoopBackOff | [01-crashloopbackoff/](01-crashloopbackoff/) | Required env var `DATABASE_URL` missing, app exits 1 |
| 2 | ImagePullBackOff | [02-imagepullbackoff/](02-imagepullbackoff/) | Image repo does not exist on Docker Hub |
| 3 | ErrImagePull | [03-errimagepull/](03-errimagepull/) | Repo exists, tag does not |
| 4 | Pending | [04-pending/](04-pending/) | Requests 500 CPU / 1000Gi on an 8 CPU / 4 GiB node |
| 5 | ContainerCreating | [05-containercreating/](05-containercreating/) | Mounted ConfigMap does not exist |
| 6 | Service connectivity | [06-service-connectivity/](06-service-connectivity/) | Service `targetPort: 8080`, container listens on 80 |
| 7 | DNS | [07-dns/](07-dns/) | Client uses a hostname in a namespace that doesn't exist |
| 8 | Pod networking | [08-pod-networking/](08-pod-networking/) | Default-deny NetworkPolicy blocks all ingress |
| 9 | Configuration | [09-configuration/](09-configuration/) | `configMapKeyRef` key `DB_HOST`, ConfigMap has `db_host` |

---

## 1. CrashLoopBackOff

Broken Pod is the session's `scenarios/scenario-1-crashloop` app. I added a `sleep` after the
"started" line so the *fixed* app keeps running (the original exits 0 even when it works, which under
`restartPolicy: Always` would also loop).

**Identify**

```text
$ kubectl apply -n p14-issues -f broken.yaml
pod/crashloop-app created
$ kubectl get pod crashloop-app -n p14-issues
NAME            READY   STATUS   RESTARTS      AGE
crashloop-app   0/1     Error    3 (81s ago)   2m22s
```

**Investigate**

```text
$ kubectl describe pod crashloop-app -n p14-issues | grep -A6 -E '^    State:'
    State:          Terminated
      Reason:       Error
      Exit Code:    1
      Started:      Wed, 07 Oct 2026 23:40:57 +0530
      Finished:     Wed, 07 Oct 2026 23:41:03 +0530
    Last State:     Terminated
      Reason:       Error
$ kubectl logs crashloop-app -n p14-issues --previous
[FATAL ERROR]: DATABASE_URL environment variable is MISSING!
$ kubectl events -n p14-issues --for pod/crashloop-app | tail -4
71s (x4 over 2m27s)   Normal    Pulled      Pod/crashloop-app   Container image "python:3.11-alpine" already present on machine and can be accessed by the pod
69s (x4 over 2m26s)   Normal    Created     Pod/crashloop-app   Container created
56s (x4 over 2m19s)   Normal    Started     Pod/crashloop-app   Container started
44s (x3 over 2m8s)    Warning   BackOff     Pod/crashloop-app   Back-off restarting failed container python-app in pod crashloop-app_p14-issues(aad29fc6-6cf8-4326-8d10-aa43f58a97df)
```

The status flips between `Error` and `CrashLoopBackOff`. The `BackOff` event confirms kubelet is backing off restarts.

**Root cause:** the container starts fine (image OK, scheduled OK) but the process exits with code 1.
`logs --previous` (logs of the crashed attempt) says why: `DATABASE_URL` is not set.

**Fix:** add a ConfigMap with `DATABASE_URL` and load it with `envFrom` ([fixed.yaml](01-crashloopbackoff/fixed.yaml)).
Env of a running Pod can't be changed, so delete and recreate.

```text
$ kubectl delete pod crashloop-app -n p14-issues --wait=true
pod "crashloop-app" deleted from p14-issues namespace
$ kubectl apply -n p14-issues -f fixed.yaml
configmap/crashloop-app-config created
pod/crashloop-app created
```

**Verify**

```text
$ kubectl get pod crashloop-app -n p14-issues
NAME            READY   STATUS    RESTARTS   AGE
crashloop-app   1/1     Running   0          53s
$ kubectl logs crashloop-app -n p14-issues
Application started successfully!
```

---

## 2. ImagePullBackOff

Image from `scenarios/scenario-2-imagepull`: `yatri-api-service:v999-invalid-tag-does-not-exist`.

**Identify / investigate**

```text
$ kubectl apply -n p14-issues -f broken.yaml
pod/imagepull-app created
$ kubectl get pod imagepull-app -n p14-issues
NAME            READY   STATUS         RESTARTS   AGE
imagepull-app   0/1     ErrImagePull   0          43s
$ kubectl describe pod imagepull-app -n p14-issues | grep -E 'Image:|Reason:'
    Image:          yatri-api-service:v999-invalid-tag-does-not-exist
      Reason:       ErrImagePull
$ kubectl events -n p14-issues --for pod/imagepull-app | tail -6
43s                Normal    Scheduled   Pod/imagepull-app   Successfully assigned p14-issues/imagepull-app to desktop-control-plane
23s                Normal    BackOff     Pod/imagepull-app   Back-off pulling image "yatri-api-service:v999-invalid-tag-does-not-exist"
23s                Warning   Failed      Pod/imagepull-app   Error: ImagePullBackOff
8s (x2 over 32s)   Normal    Pulling     Pod/imagepull-app   Pulling image "yatri-api-service:v999-invalid-tag-does-not-exist"
2s (x2 over 25s)   Warning   Failed      Pod/imagepull-app   Failed to pull image "yatri-api-service:v999-invalid-tag-does-not-exist": failed to pull and unpack image "docker.io/library/yatri-api-service:v999-invalid-tag-does-not-exist": failed to resolve reference "docker.io/library/yatri-api-service:v999-invalid-tag-does-not-exist": pull access denied, repository does not exist or may require authorization: server message: insufficient_scope: authorization failed
2s (x2 over 25s)   Warning   Failed      Pod/imagepull-app   Error: ErrImagePull
```

The events show the cycle: pull fails → `ErrImagePull` → kubelet waits → `ImagePullBackOff` →
retries → `ErrImagePull` again. `kubectl get` just shows whichever state it is in at that moment.

**Root cause:** a name with no registry/user means `docker.io/library/<name>`. There is no official
image `yatri-api-service`, so Docker Hub answers "repository does not exist or may require authorization"
(same message you'd get for a private repo without an `imagePullSecret`).

**Fix:** use a real image (`nginx:1.27`, [fixed.yaml](02-imagepullbackoff/fixed.yaml)). In a real
project: push the image first, fix the name, or add `imagePullSecrets` for a private registry.

**Verify**

```text
$ kubectl delete pod imagepull-app -n p14-issues --wait=true
pod "imagepull-app" deleted from p14-issues namespace
$ kubectl apply -n p14-issues -f fixed.yaml
pod/imagepull-app created
$ kubectl get pod imagepull-app -n p14-issues
NAME            READY   STATUS    RESTARTS   AGE
imagepull-app   1/1     Running   0          24s
```

---

## 3. ErrImagePull

`ErrImagePull` is the immediate error of a failed pull, `ImagePullBackOff` is the waiting period after
it (both visible in issue 2 above). Here the repo is real (`nginx`) but the tag is not:
`nginx:this-image-does-not-exist` (from `07-imagepullbackoff/broken-pod.yaml`).

**Identify / investigate**

```text
$ kubectl apply -n p14-issues -f broken.yaml
pod/errimagepull-app created
$ kubectl get pod errimagepull-app -n p14-issues -w     # stopped after 60s
NAME               READY   STATUS    RESTARTS   AGE
errimagepull-app   0/1     Pending   0          3s
errimagepull-app   0/1     ContainerCreating   0          3s
errimagepull-app   0/1     ContainerCreating   0          10s
$ kubectl describe pod errimagepull-app -n p14-issues | sed -n '/^Events/,$p'
Events:
  Type    Reason     Age   From               Message
  ----    ------     ----  ----               -------
  Normal  Scheduled  59s   default-scheduler  Successfully assigned p14-issues/errimagepull-app to desktop-control-plane
  Normal  Pulling    52s   kubelet            spec.containers{app}: Pulling image "nginx:this-image-does-not-exist"
$ curl -s -o /dev/null -w '%{http_code}\n' https://hub.docker.com/v2/repositories/library/nginx/tags/this-image-does-not-exist
404
$ curl -s -o /dev/null -w '%{http_code}\n' https://hub.docker.com/v2/repositories/library/nginx/tags/1.27
200
```

**Honest note:** in this run the registry lookup was very slow (the Docker Desktop VM's DNS was having
trouble at the time), so within my 60 s window the Pod sat in `ContainerCreating` with
`Pulling image` and never reached the `ErrImagePull` status. The investigation still found the cause:
Docker Hub returns 404 for that tag and 200 for `1.27`. The `ErrImagePull` status itself is shown in issue 2.

**Root cause:** the tag does not exist in the `nginx` repository.

**Fix / verify:** use an existing tag ([fixed.yaml](03-errimagepull/fixed.yaml)).

```text
$ kubectl delete pod errimagepull-app -n p14-issues --wait=true
pod "errimagepull-app" deleted from p14-issues namespace
$ kubectl apply -n p14-issues -f fixed.yaml
pod/errimagepull-app created
$ kubectl get pod errimagepull-app -n p14-issues
NAME               READY   STATUS    RESTARTS   AGE
errimagepull-app   1/1     Running   0          10s
```

---

## 4. Pending

From `scenarios/scenario-3-pending`: requests `cpu: "500"` and `memory: 1000Gi`.

**Identify / investigate**

```text
$ kubectl apply -n p14-issues -f broken.yaml
pod/pending-app created
$ kubectl get pod pending-app -n p14-issues -o wide
NAME          READY   STATUS    RESTARTS   AGE   IP       NODE     NOMINATED NODE   READINESS GATES
pending-app   0/1     Pending   0          15s   <none>   <none>   <none>           <none>
$ kubectl describe pod pending-app -n p14-issues | sed -n '/^Events/,$p'
Events:
  Type     Reason            Age   From               Message
  ----     ------            ----  ----               -------
  Warning  FailedScheduling  15s   default-scheduler  0/1 nodes are available: 1 Insufficient cpu, 1 Insufficient memory. no new claims to deallocate, preemption: 0/1 nodes are available: 1 Preemption is not helpful for scheduling.
$ kubectl get node desktop-control-plane -o jsonpath='{.status.allocatable.cpu}{" cpu, "}{.status.allocatable.memory}{" memory\n"}'
8 cpu, 4010356Ki memory
$ kubectl describe node desktop-control-plane | grep -A4 'Allocated resources'
Allocated resources:
  (Total limits may be over 100 percent, i.e., overcommitted.)
  Resource           Requests     Limits
  --------           --------     ------
  cpu                1630m (20%)  700m (8%)
```

`NODE <none>` and no IP: the scheduler never placed it, so there are no container logs to look at.
The `FailedScheduling` event is the whole story.

**Root cause:** no node can satisfy 500 CPUs / 1000Gi (the node has 8 CPU / ~3.8 GiB allocatable).
Other common causes with the same symptom: a `nodeSelector`/affinity no node matches (like
`08-pending-pods/broken-pod.yaml`), taints without tolerations, or an unbound PVC.

**Fix / verify:** realistic requests and limits ([fixed.yaml](04-pending/fixed.yaml)).

```text
$ kubectl delete pod pending-app -n p14-issues --wait=true
pod "pending-app" deleted from p14-issues namespace
$ kubectl apply -n p14-issues -f fixed.yaml
pod/pending-app created
$ kubectl get pod pending-app -n p14-issues -o wide
NAME          READY   STATUS    RESTARTS   AGE   IP             NODE                    NOMINATED NODE   READINESS GATES
pending-app   1/1     Running   0          45s   10.244.0.138   desktop-control-plane   <none>           <none>
```

---

## 5. ContainerCreating

A Pod that mounts ConfigMap `site-content` as nginx's html folder, but the ConfigMap was never created.

**Identify / investigate**

```text
$ kubectl apply -n p14-issues -f broken.yaml
pod/containercreating-app created
$ kubectl get pod containercreating-app -n p14-issues
NAME                    READY   STATUS              RESTARTS   AGE
containercreating-app   0/1     ContainerCreating   0          45s
$ kubectl describe pod containercreating-app -n p14-issues | sed -n '/^Events/,$p'
Events:
  Type     Reason       Age                From               Message
  ----     ------       ----               ----               -------
  Normal   Scheduled    45s                default-scheduler  Successfully assigned p14-issues/containercreating-app to desktop-control-plane
  Warning  FailedMount  14s (x7 over 46s)  kubelet            MountVolume.SetUp failed for volume "site" : configmap "site-content" not found
$ kubectl get configmap site-content -n p14-issues
Error from server (NotFound): configmaps "site-content" not found
```

**Root cause:** the Pod was scheduled, but kubelet can't prepare the volume, so the container is never
created. (Stuck `ContainerCreating` is usually a volume, Secret/ConfigMap or CNI problem; a slow image
pull also shows as `ContainerCreating`, as seen in issue 3.)

**Fix / verify:** create the ConfigMap. No need to touch the Pod; kubelet retries the mount by itself.

```text
$ kubectl apply -n p14-issues -f fix-configmap.yaml
configmap/site-content created
$ kubectl get pod containercreating-app -n p14-issues
NAME                    READY   STATUS    RESTARTS   AGE
containercreating-app   1/1     Running   0          66s
$ kubectl exec containercreating-app -n p14-issues -- curl -s localhost
<h1>site-content is here</h1>
```

---

## 6. Service connectivity

Deployment `shop` (2 × nginx) and Service `shop-svc` with the right selector but `targetPort: 8080`.

**Identify**

```text
$ kubectl apply -n p14-issues -f app.yaml -f broken-service.yaml
deployment.apps/shop created
service/shop-svc created
$ kubectl get pods -n p14-issues -l app=shop -o wide
NAME                    READY   STATUS    RESTARTS   AGE   IP             NODE                    NOMINATED NODE   READINESS GATES
shop-6ccb5944bf-2wl44   1/1     Running   0          5s    10.244.0.140   desktop-control-plane   <none>           <none>
shop-6ccb5944bf-tfbnw   1/1     Running   0          5s    10.244.0.141   desktop-control-plane   <none>           <none>
$ kubectl run svc-test -n p14-issues --image=busybox:1.36 --restart=Never --rm -i --quiet -- wget -T 3 -qO- http://shop-svc
wget: can't connect to remote host (10.96.54.82): Connection refused
warning: couldn't attach to pod/svc-test, falling back to streaming logs: unable to upgrade connection: container svc-test not found in pod svc-test_p14-issues
wget: can't connect to remote host (10.96.54.82): Connection refused
pod p14-issues/svc-test terminated (Error)
```

Pods are Running, DNS resolved `shop-svc` to `10.96.54.82`, but the connection is **refused**.
(The doubled lines are kubectl falling back to logs because the tiny Pod finished before attach.)

**Investigate**

```text
$ kubectl describe svc shop-svc -n p14-issues
Name:                     shop-svc
Namespace:                p14-issues
Labels:                   <none>
Annotations:              <none>
Selector:                 app=shop
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.54.82
IPs:                      10.96.54.82
Port:                     <unset>  80/TCP
TargetPort:               8080/TCP
Endpoints:                10.244.0.140:8080,10.244.0.141:8080
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
$ kubectl get endpointslices -n p14-issues -l kubernetes.io/service-name=shop-svc
NAME             ADDRESSTYPE   PORTS   ENDPOINTS                   AGE
shop-svc-zdqct   IPv4          8080    10.244.0.140,10.244.0.141   17s
$ kubectl run svc-test -n p14-issues --image=busybox:1.36 --restart=Never --rm -i --quiet -- wget -T 3 -qO- http://10.244.0.140:80 | grep title
warning: couldn't attach to pod/svc-test, falling back to streaming logs: unable to upgrade connection: container svc-test not found in pod svc-test_p14-issues
<title>Welcome to nginx!</title>
<title>Welcome to nginx!</title>
$ kubectl get pods -n p14-issues -l app=shop -o jsonpath='{.items[0].spec.containers[0].ports}'; echo
[{"containerPort":80,"protocol":"TCP"}]
```

**Root cause:** endpoints exist (so selector and labels are fine), but they point at port **8080**.
The Pod answers directly on port 80. Service `targetPort` and `containerPort` don't match.
(If the selector were wrong, `Endpoints` would be empty instead. That case is in the mini project.)

**Fix / verify:** `targetPort: 80` ([fixed-service.yaml](06-service-connectivity/fixed-service.yaml)).

```text
$ kubectl apply -n p14-issues -f fixed-service.yaml
service/shop-svc configured
$ kubectl get endpointslices -n p14-issues -l kubernetes.io/service-name=shop-svc
NAME             ADDRESSTYPE   PORTS   ENDPOINTS                   AGE
shop-svc-zdqct   IPv4          80      10.244.0.140,10.244.0.141   26s
$ kubectl run svc-test -n p14-issues --image=busybox:1.36 --restart=Never --rm -i --quiet -- wget -T 3 -qO- http://shop-svc | grep title
warning: couldn't attach to pod/svc-test, falling back to streaming logs: unable to upgrade connection: container svc-test not found in pod svc-test_p14-issues
<title>Welcome to nginx!</title>
<title>Welcome to nginx!</title>
<title>Welcome to nginx!</title>
```

---

## 7. DNS issue

A backend `orders-db` (Service + Deployment) in `p14-issues`, and a client that calls
`orders-db.production.svc.cluster.local` every 5 s (same idea as `scenarios/scenario-4-dns-failure`).

**Identify**

```text
$ kubectl apply -n p14-issues -f backend.yaml -f broken-client.yaml
deployment.apps/orders-db created
service/orders-db created
pod/dns-client created
$ kubectl get pods -n p14-issues -l app=orders-db
NAME                        READY   STATUS    RESTARTS   AGE
orders-db-b959bf5c8-r7mpp   1/1     Running   0          23s
$ kubectl get pod dns-client -n p14-issues
NAME         READY   STATUS    RESTARTS   AGE
dns-client   1/1     Running   0          23s
$ kubectl logs dns-client -n p14-issues --tail=3
FAIL could not reach orders-db.production.svc.cluster.local
wget: bad address 'orders-db.production.svc.cluster.local'
FAIL could not reach orders-db.production.svc.cluster.local
```

`bad address` means the name did not resolve, so it's DNS, not a refused or timed-out connection.

**Investigate:** is DNS broken in general, or only this name?

```text
$ kubectl exec dns-client -n p14-issues -- nslookup orders-db.production.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find orders-db.production.svc.cluster.local: NXDOMAIN

** server can't find orders-db.production.svc.cluster.local: NXDOMAIN

command terminated with exit code 1
$ kubectl exec dns-client -n p14-issues -- cat /etc/resolv.conf
search p14-issues.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
$ kubectl exec dns-client -n p14-issues -- nslookup kubernetes.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53


Name:	kubernetes.default.svc.cluster.local
Address: 10.96.0.1

$ kubectl get pods -n kube-system -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-589f44dc88-9rthl   1/1     Running   0          4h57m
coredns-589f44dc88-n6xkg   1/1     Running   0          4h57m
$ kubectl get svc -A --field-selector metadata.name=orders-db
NAMESPACE    NAME        TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
p14-issues   orders-db   ClusterIP   10.96.170.251   <none>        80/TCP    25s
$ kubectl get ns production
Error from server (NotFound): namespaces "production" not found
$ kubectl exec dns-client -n p14-issues -- nslookup orders-db.p14-issues.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10:53

Name:	orders-db.p14-issues.svc.cluster.local
Address: 10.96.170.251

```

CoreDNS is running and resolves other names, the Pod uses the right nameserver (`10.96.0.10`),
and the `orders-db` Service exists, but in `p14-issues`. There is no `production` namespace.

**Root cause:** the hostname format is `<service>.<namespace>.svc.cluster.local`, and the client
used the wrong namespace, so CoreDNS correctly answers NXDOMAIN.

**Fix / verify:** point `DB_HOST` to `orders-db.p14-issues.svc.cluster.local`
([fixed-client.yaml](07-dns/fixed-client.yaml)). Inside the same namespace plain `orders-db` also works
thanks to the `search` line in `resolv.conf`.

```text
$ kubectl delete pod dns-client -n p14-issues --wait=true
pod "dns-client" deleted from p14-issues namespace
$ kubectl apply -n p14-issues -f fixed-client.yaml
pod/dns-client created
$ kubectl logs dns-client -n p14-issues --tail=3
OK   reached orders-db.p14-issues.svc.cluster.local
OK   reached orders-db.p14-issues.svc.cluster.local
OK   reached orders-db.p14-issues.svc.cluster.local
```

---

## 8. Pod networking issue

`api` (nginx) and `frontend` (busybox) Pods plus an `api` Service in namespace `p14-net`.
Then someone applies a default-deny ingress NetworkPolicy. (Docker Desktop's CNI here, kindnet,
enforces NetworkPolicy; on a CNI that doesn't, policies are silently ignored.)

**Before:**

```text
$ kubectl create namespace p14-net
namespace/p14-net created
$ kubectl apply -n p14-net -f app.yaml
pod/api created
service/api created
pod/frontend created
$ kubectl get pods -n p14-net -o wide
NAME       READY   STATUS    RESTARTS   AGE   IP             NODE                    NOMINATED NODE   READINESS GATES
api        1/1     Running   0          4s    10.244.0.148   desktop-control-plane   <none>           <none>
frontend   1/1     Running   0          4s    10.244.0.149   desktop-control-plane   <none>           <none>
$ kubectl exec frontend -n p14-net -- wget -T 3 -qO- http://10.244.0.148 | grep title
<title>Welcome to nginx!</title>
$ kubectl apply -n p14-net -f broken-netpol.yaml
networkpolicy.networking.k8s.io/default-deny-ingress created
```

**Identify:** frontend can no longer reach api, not even by Pod IP.

```text
$ kubectl exec frontend -n p14-net -- wget -T 3 -qO- http://10.244.0.148
wget: download timed out
command terminated with exit code 1
$ kubectl exec frontend -n p14-net -- wget -T 3 -qO- http://api
wget: download timed out
command terminated with exit code 1
```

**Investigate**

```text
$ kubectl exec api -n p14-net -- curl -s -o /dev/null -w '%{http_code}\n' localhost
200
$ kubectl get endpointslices -n p14-net -l kubernetes.io/service-name=api
NAME        ADDRESSTYPE   PORTS   ENDPOINTS      AGE
api-rlwlr   IPv4          80      10.244.0.148   21s
$ kubectl get networkpolicy -n p14-net
NAME                   POD-SELECTOR   AGE
default-deny-ingress   <none>         16s
$ kubectl describe networkpolicy default-deny-ingress -n p14-net
Name:         default-deny-ingress
Namespace:    p14-net
Created on:   2026-10-07 23:54:51 +0530 IST
Labels:       <none>
Annotations:  <none>
Spec:
  PodSelector:     <none> (Allowing the specific traffic to all pods in this namespace)
  Allowing ingress traffic:
    <none> (Selected pods are isolated for ingress connectivity)
  Not affecting egress traffic
  Policy Types: Ingress
```

The app is healthy (200 on localhost), the Service has the right endpoint, and a direct Pod-IP call
**times out** (packets dropped, not refused). Timeouts between healthy Pods point at the network layer,
and the namespace has a policy isolating every Pod for ingress.

**Root cause:** `default-deny-ingress` selects all Pods and allows nothing in.

**Fix:** keep the default deny (it's good practice) and add an explicit allow for frontend → api:80
([fix-allow-frontend.yaml](08-pod-networking/fix-allow-frontend.yaml)).

**Verify:** frontend works again, and a Pod without the `app=frontend` label is still blocked.

```text
$ kubectl apply -n p14-net -f fix-allow-frontend.yaml
networkpolicy.networking.k8s.io/allow-frontend-to-api created
$ kubectl get networkpolicy -n p14-net
NAME                    POD-SELECTOR   AGE
allow-frontend-to-api   app=api        6s
default-deny-ingress    <none>         23s
$ kubectl exec frontend -n p14-net -- wget -T 3 -qO- http://api | grep title
<title>Welcome to nginx!</title>
$ kubectl run intruder -n p14-net --image=busybox:1.36 --restart=Never --rm -i --quiet -- wget -T 3 -qO- http://api
wget: download timed out
pod p14-net/intruder terminated (Error)
```

---

## 9. Configuration issue

Deployment `payments` reads `DB_HOST` and `LOG_LEVEL` from ConfigMap `payments-config`.

**Identify / investigate**

```text
$ kubectl apply -n p14-issues -f broken.yaml
configmap/payments-config created
deployment.apps/payments created
$ kubectl get pods -n p14-issues -l app=payments
NAME                        READY   STATUS                       RESTARTS   AGE
payments-76546766bc-hpxkm   0/1     CreateContainerConfigError   0          30s
$ kubectl describe pod payments-76546766bc-hpxkm -n p14-issues | grep -E 'State|Reason' ; kubectl describe pod payments-76546766bc-hpxkm -n p14-issues | sed -n '/^Events/,$p' | tail -3
    State:          Waiting
      Reason:       CreateContainerConfigError
  Type     Reason     Age               From               Message
  Normal   Scheduled  31s               default-scheduler  Successfully assigned p14-issues/payments-76546766bc-hpxkm to desktop-control-plane
  Normal   Pulled     3s (x4 over 30s)  kubelet            spec.containers{app}: Container image "busybox:1.36" already present on machine and can be accessed by the pod
  Warning  Failed     3s (x4 over 30s)  kubelet            spec.containers{app}: Error: couldn't find key DB_HOST in ConfigMap p14-issues/payments-config
$ kubectl get configmap payments-config -n p14-issues -o jsonpath='{.data}'; echo
{"db_host":"orders-db","log_level":"info"}
```

**Root cause:** ConfigMap keys are case-sensitive. The Deployment asks for `DB_HOST`, the ConfigMap has
`db_host`. kubelet can't build the container's environment, so it never starts (no logs exist yet).

**Fix / verify:** `key: db_host` ([fixed.yaml](09-configuration/fixed.yaml)).

```text
$ kubectl apply -n p14-issues -f fixed.yaml
configmap/payments-config unchanged
deployment.apps/payments configured
$ kubectl get pods -n p14-issues -l app=payments
NAME                       READY   STATUS    RESTARTS   AGE
payments-c667448f5-zk4s2   1/1     Running   0          8s
$ kubectl logs deploy/payments -n p14-issues
DB_HOST=orders-db LOG_LEVEL=info
```

---

## Cleanup

```bash
kubectl delete ns p14-issues p14-net
```

## What I learned

- The STATUS column already tells me where to look: `Pending` = scheduler (events), `ContainerCreating` /
  `CreateContainerConfigError` = kubelet setup (events), `ErrImagePull`/`ImagePullBackOff` = registry (events),
  `CrashLoopBackOff` = the app itself (`logs --previous`).
- For networking, the error text matters: `bad address` = DNS, `Connection refused` = nothing listening on that
  port (wrong targetPort), `timed out` = packets dropped (NetworkPolicy/CNI).
- Test step by step: inside the Pod (`localhost`), then Pod IP, then Service name. The first step that fails
  shows the broken layer.
