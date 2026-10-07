# 03 — Mini Project: Kubernetes Troubleshooting Challenge

**Submitted by:** Piyush Bansal
**Source:** [`../../mini-project/`](../../mini-project/README.md)

Deploy → observe → break → investigate → root cause → fix → verify, on the project's nginx app.
Namespace `p14-mini`. All output is real.

| File | What it is |
|---|---|
| [deployment.yaml](deployment.yaml), [service.yaml](service.yaml), [broken-pod.yaml](broken-pod.yaml) | From the project, unchanged |
| [service-wrong-selector.yaml](service-wrong-selector.yaml) | Step 8: selector changed to `app: wrong-app` |
| [fixed-pod.yaml](fixed-pod.yaml) | Broken Pod with a real tag (`nginx:1.27`) |

## 1–4. Deploy and check the application, Service and endpoints

```text
$ kubectl create namespace p14-mini
namespace/p14-mini created
$ kubectl apply -n p14-mini -f deployment.yaml -f service.yaml
deployment.apps/troubleshooting-app created
service/troubleshooting-service created
$ kubectl get pods,service -n p14-mini
NAME                                       READY   STATUS    RESTARTS   AGE
pod/troubleshooting-app-5b97965b56-tkjqr   1/1     Running   0          5s
pod/troubleshooting-app-5b97965b56-tnnxl   1/1     Running   0          5s

NAME                              TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
service/troubleshooting-service   ClusterIP   10.96.77.168   <none>        80/TCP    5s
$ kubectl get pods -n p14-mini -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP             NODE                    NOMINATED NODE   READINESS GATES
troubleshooting-app-5b97965b56-tkjqr   1/1     Running   0          5s    10.244.0.153   desktop-control-plane   <none>           <none>
troubleshooting-app-5b97965b56-tnnxl   1/1     Running   0          5s    10.244.0.154   desktop-control-plane   <none>           <none>
$ kubectl describe pod troubleshooting-app-5b97965b56-tkjqr -n p14-mini | grep -E '^(Status|IP):|Image:|Ready:|Restart'
Status:           Running
IP:               10.244.0.153
    Image:          nginx:1.27
    Ready:          True
    Restart Count:  0
$ kubectl logs troubleshooting-app-5b97965b56-tkjqr -n p14-mini --tail=3
2026/10/07 18:26:30 [notice] 1#1: start worker process 37
2026/10/07 18:26:30 [notice] 1#1: start worker process 38
2026/10/07 18:26:30 [notice] 1#1: start worker process 39
$ kubectl exec troubleshooting-app-5b97965b56-tkjqr -n p14-mini -- curl -s localhost | grep title
<title>Welcome to nginx!</title>
$ kubectl describe service troubleshooting-service -n p14-mini
Name:                     troubleshooting-service
Namespace:                p14-mini
Labels:                   <none>
Annotations:              <none>
Selector:                 app=troubleshooting-app
Type:                     ClusterIP
IP Family Policy:         SingleStack
IP Families:              IPv4
IP:                       10.96.77.168
IPs:                      10.96.77.168
Port:                     <unset>  80/TCP
TargetPort:               80/TCP
Endpoints:                10.244.0.153:80,10.244.0.154:80
Session Affinity:         None
Internal Traffic Policy:  Cluster
Events:                   <none>
$ kubectl get endpoints troubleshooting-service -n p14-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS                         AGE
troubleshooting-service   10.244.0.153:80,10.244.0.154:80   7s
```

Selector `app=troubleshooting-app`, TargetPort 80, and the endpoints are exactly the two Pod IPs from `-o wide`.
(I ran `exec ... curl` non-interactively instead of `exec -it ... bash`.)

## 5–7. The broken Pod

```text
$ kubectl apply -n p14-mini -f broken-pod.yaml
pod/project-broken-pod created
$ kubectl get pod project-broken-pod -n p14-mini
NAME                 READY   STATUS             RESTARTS   AGE
project-broken-pod   0/1     ImagePullBackOff   0          32s
$ kubectl describe pod project-broken-pod -n p14-mini | sed -n '/^Events/,$p'
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  31s                default-scheduler  Successfully assigned p14-mini/project-broken-pod to desktop-control-plane
  Normal   BackOff    24s                kubelet            spec.containers{app}: Back-off pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     24s                kubelet            spec.containers{app}: Error: ImagePullBackOff
  Normal   Pulling    13s (x2 over 30s)  kubelet            spec.containers{app}: Pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     9s (x2 over 25s)   kubelet            spec.containers{app}: Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": failed to resolve reference "docker.io/library/nginx:this-tag-does-not-exist": docker.io/library/nginx:this-tag-does-not-exist: not found
  Warning  Failed     9s (x2 over 25s)   kubelet            spec.containers{app}: Error: ErrImagePull
```

**Question 1: What is the Pod status?**
`ImagePullBackOff` (`0/1`, alternating with `ErrImagePull`).

**Question 2: What is the actual error?**
`failed to resolve reference "docker.io/library/nginx:this-tag-does-not-exist": ... not found` (gRPC `NotFound`).

**Question 3: Which command helped you find the reason?**
`kubectl describe pod project-broken-pod`, the `Failed` event in the Events section.

**Question 4: What is wrong with the image?**
The repository `nginx` exists, but the tag `this-tag-does-not-exist` does not, so there is nothing to pull.

**Question 5: How would you fix it?**
Use an existing tag (e.g. `nginx:1.27`). I changed it in the YAML ([fixed-pod.yaml](fixed-pod.yaml)), then deleted and re-applied the Pod:

```text
$ kubectl delete pod project-broken-pod -n p14-mini
pod "project-broken-pod" deleted from p14-mini namespace
$ kubectl apply -n p14-mini -f fixed-pod.yaml
pod/project-broken-pod created
$ kubectl get pods -n p14-mini
NAME                                   READY   STATUS    RESTARTS   AGE
project-broken-pod                     1/1     Running   0          16s
troubleshooting-app-5b97965b56-tkjqr   1/1     Running   0          76s
troubleshooting-app-5b97965b56-tnnxl   1/1     Running   0          76s
```

## 8–9. Service selector challenge

```text
$ kubectl apply -n p14-mini -f service-wrong-selector.yaml
service/troubleshooting-service configured
$ kubectl get service -n p14-mini
NAME                      TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.96.77.168   <none>        80/TCP    43s
$ kubectl get endpoints troubleshooting-service -n p14-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS   AGE
troubleshooting-service   <none>      43s
$ kubectl get pods -n p14-mini --show-labels
NAME                                   READY   STATUS             RESTARTS   AGE   LABELS
project-broken-pod                     0/1     ImagePullBackOff   0          36s   <none>
troubleshooting-app-5b97965b56-tkjqr   1/1     Running            0          43s   app=troubleshooting-app,pod-template-hash=5b97965b56
troubleshooting-app-5b97965b56-tnnxl   1/1     Running            0          43s   app=troubleshooting-app,pod-template-hash=5b97965b56
$ kubectl describe service troubleshooting-service -n p14-mini | grep -E 'Selector|Endpoints'
Selector:                 app=wrong-app
Endpoints:                
```

`get service` looks perfectly normal; only the endpoints show the problem. **Root cause:** selector
`app=wrong-app` vs Pod label `app=troubleshooting-app`, so no Pod matches. **Fix:** re-apply the original
selector, then verify endpoints, DNS and an actual request:

```text
$ kubectl apply -n p14-mini -f service.yaml
service/troubleshooting-service configured
$ kubectl get endpoints troubleshooting-service -n p14-mini
Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                      ENDPOINTS                         AGE
troubleshooting-service   10.244.0.153:80,10.244.0.154:80   48s
$ kubectl run dns-check -n p14-mini --image=busybox:1.36 --restart=Never --rm -i --quiet -- nslookup troubleshooting-service
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find troubleshooting-service.cluster.local: NXDOMAIN


Name:	troubleshooting-service.p14-mini.svc.cluster.local
Address: 10.96.77.168

** server can't find troubleshooting-service.svc.cluster.local: NXDOMAIN

** server can't find troubleshooting-service.svc.cluster.local: NXDOMAIN

** server can't find troubleshooting-service.cluster.local: NXDOMAIN

warning: couldn't attach to pod/dns-check, falling back to streaming logs: Internal error occurred: Internal error occurred: error attaching to container: container is in CONTAINER_EXITED state
Server:		10.96.0.10
Address:	10.96.0.10:53

** server can't find troubleshooting-service.cluster.local: NXDOMAIN


Name:	troubleshooting-service.p14-mini.svc.cluster.local
Address: 10.96.77.168

** server can't find troubleshooting-service.svc.cluster.local: NXDOMAIN

** server can't find troubleshooting-service.svc.cluster.local: NXDOMAIN

** server can't find troubleshooting-service.cluster.local: NXDOMAIN

pod p14-mini/dns-check terminated (Error)
$ kubectl run web-check -n p14-mini --image=busybox:1.36 --restart=Never --rm -i --quiet -- wget -T 3 -qO- http://troubleshooting-service | grep title
warning: couldn't attach to pod/web-check, falling back to streaming logs: unable to upgrade connection: container web-check not found in pod web-check_p14-mini
<title>Welcome to nginx!</title>
<title>Welcome to nginx!</title>
```

The `nslookup` output looks scary but is fine: busybox tries every `search` domain from `resolv.conf`,
the wrong ones return NXDOMAIN, and `troubleshooting-service.p14-mini.svc.cluster.local` resolves to the
Service IP `10.96.77.168`. busybox exits non-zero because some lookups failed, hence "terminated (Error)".
The output appears twice because kubectl fell back to streaming logs after the Pod finished.

## 11. Troubleshooting table

| Problem | What I Saw | Command I Used | Root Cause | Fix |
| :--- | :--- | :--- | :--- | :--- |
| **Broken Pod** | `project-broken-pod 0/1 ImagePullBackOff` | `kubectl get pod`, `kubectl describe pod` (Events) | Pod can't start because its image can't be pulled | Point to a valid image, delete + re-apply |
| **Service Problem** | Service looks normal, `ENDPOINTS <none>` | `kubectl get endpoints`, `kubectl get pods --show-labels`, `kubectl describe service` | Selector `app=wrong-app` matches no Pod label | Selector back to `app: troubleshooting-app` |
| **Image Problem** | `Failed to pull image ... nginx:this-tag-does-not-exist: not found` | `kubectl describe pod` | Tag doesn't exist in the `nginx` repo | Use `nginx:1.27` |

## 12. README questions

1. **What does `kubectl get` tell us?** A one-line summary per object: for Pods READY, STATUS, RESTARTS, AGE (and IP/node with `-o wide`). It's where you spot *that* something is wrong.
2. **Difference between `get` and `describe`?** `get` is a summary of many objects; `describe` is everything about one object, including related Events, so it shows *why*.
3. **Why `kubectl logs`?** To see what the application printed (errors, stack traces). `--previous` shows the logs of a container that already crashed.
4. **When `kubectl exec`?** When the Pod is running and I need to test from inside: `curl localhost`, check config files, env vars, DNS (`nslookup`), or connectivity to another service.
5. **CrashLoopBackOff?** The container starts and keeps exiting; kubelet restarts it with an increasing delay (10 s, 20 s, 40 s … up to 5 min). The cause is in the app: logs, exit code, missing config, failing liveness probe.
6. **ImagePullBackOff?** The image pull failed (`ErrImagePull`) and kubelet is waiting before retrying. Usual causes: wrong name/tag, private registry without credentials, no network to the registry.
7. **Why can a Pod stay `Pending`?** The scheduler can't place it: not enough CPU/memory for its requests, a nodeSelector/affinity no node matches, taints, or an unbound PVC. `describe` shows `FailedScheduling` with the reason.
8. **Why can a Service have no endpoints?** Its selector matches no Pod labels, the matching Pods are not Ready (readiness probe failing), or there are no Pods (scaled to 0 / in another namespace).
9. **Service selector vs Pod labels?** The Service sends traffic to every Ready Pod whose labels contain all key/values of its selector. That match is the only link between them.
10. **What is Kubernetes DNS?** CoreDNS running in `kube-system` behind the `kube-dns` Service (`10.96.0.10` here). Every Service gets the name `<service>.<namespace>.svc.cluster.local`, and Pods have search domains so a short name works inside the same namespace.

## Cleanup

```bash
kubectl delete ns p14-mini
```

## What I learned

- A Service with a wrong selector gives no error anywhere. `kubectl get endpoints` is the check.
- `describe pod` Events answered every image question without changing any YAML first, as the project asked.
