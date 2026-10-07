# 03 — Mini Project: Production-Ready Kubernetes Web App

**Submitted by:** Piyush Bansal
**Source:** [`../../mini-project/`](../../mini-project/README.md)

The project combines a PVC (data in `/data` survives Pod deletion), an HPA (2–5 replicas at 50% CPU)
and startup/readiness/liveness probes on an nginx Deployment. I used the project's YAMLs unchanged
except the namespace, renamed from `production-webapp` to `p13-webapp` (shared cluster rule).

| File | What it is |
|---|---|
| [namespace.yaml](namespace.yaml) | Namespace `p13-webapp` |
| [pvc.yaml](pvc.yaml) | 500Mi RWO claim `web-data` (default StorageClass `standard`, local-path) |
| [deployment.yaml](deployment.yaml) | 2 replicas, `Recreate`, requests/limits, 3 probes, PVC at `/data` |
| [service.yaml](service.yaml) | ClusterIP `web-service` |
| [hpa.yaml](hpa.yaml) | `web-app-hpa`, min 2, max 5, 50% CPU |

## Deployment (steps 5.1–5.4)

```text
$ kubectl apply -f namespace.yaml
namespace/p13-webapp created
$ kubectl apply -f pvc.yaml
persistentvolumeclaim/web-data created
$ kubectl get pvc -n p13-webapp
NAME       STATUS    VOLUME   CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
web-data   Pending                                      standard       <unset>                 1s
$ kubectl apply -f deployment.yaml
deployment.apps/web-app created
$ kubectl apply -f service.yaml
service/web-service created
$ kubectl get pods -n p13-webapp -o wide
NAME                      READY   STATUS    RESTARTS   AGE     IP            NODE                    NOMINATED NODE   READINESS GATES
web-app-97976c695-68t4v   1/1     Running   0          3m28s   10.244.0.80   desktop-control-plane   <none>           <none>
web-app-97976c695-gg9nv   1/1     Running   0          3m26s   10.244.0.79   desktop-control-plane   <none>           <none>
$ kubectl get pvc -n p13-webapp
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
web-data   Bound    pvc-f7033771-e979-4141-8319-b274bd1ede9d   500Mi      RWO            standard       <unset>                 3m33s
$ kubectl apply -f hpa.yaml
horizontalpodautoscaler.autoscaling/web-app-hpa created
$ kubectl get hpa -n p13-webapp
NAME          REFERENCE            TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   cpu: 4%/50%   2         5         2          44s
$ kubectl describe deploy web-app -n p13-webapp | grep -E 'Liveness|Readiness|Startup|Limits|Requests|cpu|memory|/data'
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
```

The PVC is `Pending` until the first Pod uses it (`WaitForFirstConsumer`), then `Bound`. Both replicas
share one RWO volume, which works here because there is only one node (RWO = one *node*, not one Pod).

## Task 1: Storage persistence

```text
$ kubectl exec -n p13-webapp web-app-97976c695-68t4v -- sh -c 'echo "Student: Piyush Bansal" > /data/student.txt'
$ kubectl exec -n p13-webapp web-app-97976c695-68t4v -- cat /data/student.txt
Student: Piyush Bansal
$ kubectl exec -n p13-webapp web-app-97976c695-gg9nv -- cat /data/student.txt
Student: Piyush Bansal
$ kubectl delete pod -n p13-webapp web-app-97976c695-68t4v
pod "web-app-97976c695-68t4v" deleted from p13-webapp namespace
$ kubectl get pods -n p13-webapp
NAME                      READY   STATUS    RESTARTS   AGE
web-app-97976c695-gg9nv   1/1     Running   0          5m27s
web-app-97976c695-sdfnf   1/1     Running   0          39s
$ kubectl exec -n p13-webapp web-app-97976c695-sdfnf -- cat /data/student.txt
Student: Piyush Bansal
```

The replacement Pod `sdfnf` sees the file written by the deleted Pod.

## Task 2: Service verification

I used port 18130 instead of 8080 (my port range on the shared machine).

```text
$ kubectl port-forward -n p13-webapp svc/web-service 18130:80 &
$ curl -s http://localhost:18130 | head -5
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
```

## Task 3: HPA scaling

I did the load test on the identical `hpa-demo` setup in [../02-hpa/README.md](../02-hpa/README.md)
(same nginx, same 100m request, same 50% target), where it scaled 1 → 2 → 1 and later reached 4.
I did **not** get a separate scale-out capture for `web-app-hpa`: by the time I got to it, the shared
node's control plane (API server, scheduler, controller-manager, metrics-server) was restarting under
load from other work, and the run could not be completed before the deadline.

## Bonus challenges

- **Challenge 1 (30% target):** not done.
- **Challenge 2 (readiness gating) and 3 (liveness restart loop):** I tried them here with `kubectl patch`
  but the cluster was too overloaded to give clean results (probe timeouts on the *healthy* Pods too,
  rollouts timing out), so I'm not presenting that output. I did both demos cleanly with the session's
  probe files in [../04-probes/README.md](../04-probes/README.md): a wrong readiness path leaves the Pod
  `Running 0/1` and out of the Service endpoints, a wrong liveness path gives
  `RESTARTS 3` in 76 s with `Container nginx failed liveness probe, will be restarted`.

## Probe reference

| Probe | Question | On failure |
|---|---|---|
| Startup | Has the process started? | Restart after 30 × 2 s; holds back the other probes until it passes |
| Readiness | Can it take traffic? | Removed from Service endpoints, no restart |
| Liveness | Is it alive? | kubelet restarts the container |

## Cleanup

```bash
kubectl delete ns p13-webapp
```

## What I learned

- A PVC-backed Deployment keeps data across Pod replacement, but with `ReadWriteOnce` all replicas
  must land on the same node. On a multi-node cluster this Deployment would need RWX storage or a
  StatefulSet with one volume per Pod.
- `strategy: Recreate` goes well with RWO volumes: the old Pod releases the volume before the new one starts.
- Probe timeouts of 1–2 s are fine on a healthy node, but on an overloaded node even a healthy nginx
  failed them. Probe settings need some headroom.
