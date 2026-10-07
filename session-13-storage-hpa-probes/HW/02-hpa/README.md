# 02 — HPA Hands-on

**Submitted by:** Piyush Bansal

I used the session's `04-hpa/` files (Deployment `hpa-demo` = nginx with `cpu: 100m` request /
`200m` limit, a ClusterIP Service, and the HPA 1–5 replicas at 50% CPU). Namespace `p13-hpa`.
All output is real. My cluster was a shared Docker Desktop node that was under heavy load from other
work at the same time, which shows up below (metrics gaps, slow scheduling).

| File | What it is |
|---|---|
| [deployment.yaml](deployment.yaml), [service.yaml](service.yaml) | Copied from `../../04-hpa/` |
| [hpa.yaml](hpa.yaml) | Session HPA + `behavior.scaleDown.stabilizationWindowSeconds: 60` (default 300) so scale-down fits in the run |
| [load-generator.yaml](load-generator.yaml) | busybox Pods running 4 parallel `wget` loops against the Service |
| [load-generator-ab.yaml](load-generator-ab.yaml) | Stronger loader: ApacheBench with keep-alive, 20 concurrent |

## 1–3. Deploy, configure and verify HPA

```text
$ kubectl create namespace p13-hpa
namespace/p13-hpa created
$ kubectl apply -n p13-hpa -f deployment.yaml -f service.yaml
deployment.apps/hpa-demo created
service/hpa-demo-service created
$ kubectl get deploy,pods,svc -n p13-hpa
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hpa-demo   1/1     1            1           52s

NAME                            READY   STATUS    RESTARTS   AGE
pod/hpa-demo-6949d84d5b-rfjfv   1/1     Running   0          34s

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/hpa-demo-service   ClusterIP   10.96.142.119   <none>        80/TCP    52s
$ kubectl top pods -n p13-hpa
error: metrics not available yet
$ kubectl apply -n p13-hpa -f hpa.yaml
horizontalpodautoscaler.autoscaling/hpa-demo created
$ kubectl get hpa -n p13-hpa
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         1          47s
$ kubectl describe hpa hpa-demo -n p13-hpa
Name:                                                  hpa-demo
Namespace:                                             p13-hpa
Labels:                                                <none>
Annotations:                                           <none>
CreationTimestamp:                                     Wed, 07 Oct 2026 21:33:03 +0530
Reference:                                             Deployment/hpa-demo
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  0% (0) / 50%
Min replicas:                                          1
Max replicas:                                          5
Behavior:
  Scale Up:
    Stabilization Window: 0 seconds
    Select Policy: Max
    Policies:
      - Type: Pods     Value: 4    Period: 15 seconds
      - Type: Percent  Value: 100  Period: 15 seconds
  Scale Down:
    Stabilization Window: 60 seconds
    Select Policy: Max
    Policies:
      - Type: Percent  Value: 100  Period: 15 seconds
Deployment pods:       1 current / 1 desired
Conditions:
  Type            Status  Reason               Message
  ----            ------  ------               -------
  AbleToScale     True    ScaleDownStabilized  recent recommendations were higher than current one, applying the highest recent recommendation
  ScalingActive   True    ValidMetricFound     the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  False   DesiredWithinRange   the desired count is within the acceptable range
Events:
  Type     Reason                        Age   From                       Message
  ----     ------                        ----  ----                       -------
  Warning  FailedGetResourceMetric       33s   horizontal-pod-autoscaler  failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Warning  FailedComputeMetricsReplicas  33s   horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
```

The first warnings are normal: metrics-server needs one scrape of a new Pod before the HPA has a number.
Utilization = usage / **request** (`0m / 100m`), which is why a CPU request is required for HPA.

## 4–7. Load generator, CPU and scaling

### Attempt 1: one busybox loader — not enough

With `replicas: 1` in the loader, nginx only reached 31–44% (the loader itself hit its 300m limit
just forking `wget` processes), so the HPA correctly did nothing:

```text
$ kubectl top pods -n p13-hpa
NAME                              CPU(cores)   MEMORY(bytes)   
hpa-demo-6949d84d5b-rfjfv         35m          13Mi            
load-generator-7bfd77d597-2kj77   286m         4Mi             
$ kubectl get hpa -n p13-hpa -w
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         1          5m37s
hpa-demo   Deployment/hpa-demo   cpu: 14%/50%   1         5         1          6m7s
hpa-demo   Deployment/hpa-demo   cpu: 36%/50%   1         5         1          6m22s
hpa-demo   Deployment/hpa-demo   cpu: 35%/50%   1         5         1          6m37s
hpa-demo   Deployment/hpa-demo   cpu: 44%/50%   1         5         1          6m53s
hpa-demo   Deployment/hpa-demo   cpu: 37%/50%   1         5         1          7m10s
hpa-demo   Deployment/hpa-demo   cpu: 35%/50%   1         5         1          7m24s
hpa-demo   Deployment/hpa-demo   cpu: 31%/50%   1         5         1          7m38s
```

(First lines of the watch; it stayed between 27% and 44% with 1 replica for the whole 5 minutes.)

### Attempt 2: three busybox loaders — scale 1 → 2 → 1

I set the loader to `replicas: 3` (the committed file). `kubectl get hpa -w` in one terminal,
`kubectl get pods -w` in another:

```text
$ kubectl apply -n p13-hpa -f load-generator.yaml
deployment.apps/load-generator configured
$ kubectl get hpa -n p13-hpa -w
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         1          39m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         1          41m
hpa-demo   Deployment/hpa-demo   cpu: 38%/50%   1         5         1          42m
hpa-demo   Deployment/hpa-demo   cpu: <unknown>/50%   1         5         1          42m
hpa-demo   Deployment/hpa-demo   cpu: 63%/50%         1         5         1          44m
hpa-demo   Deployment/hpa-demo   cpu: 49%/50%         1         5         2          45m
hpa-demo   Deployment/hpa-demo   cpu: 38%/50%         1         5         2          45m
hpa-demo   Deployment/hpa-demo   cpu: 56%/50%         1         5         2          45m
hpa-demo   Deployment/hpa-demo   cpu: 49%/50%         1         5         2          46m
hpa-demo   Deployment/hpa-demo   cpu: 36%/50%         1         5         2          46m
hpa-demo   Deployment/hpa-demo   cpu: 30%/50%         1         5         2          46m
hpa-demo   Deployment/hpa-demo   cpu: 29%/50%         1         5         2          47m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%          1         5         2          47m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%          1         5         2          48m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%          1         5         1          48m
$ kubectl get pods -n p13-hpa -l app=hpa-demo -w
NAME                        READY   STATUS    RESTARTS   AGE
hpa-demo-6949d84d5b-rfjfv   1/1     Running   0          40m
hpa-demo-6949d84d5b-rfjfv   1/1     Running   0          43m
hpa-demo-6949d84d5b-rfjfv   1/1     Running   0          44m
hpa-demo-6949d84d5b-hgbvg   0/1     Pending   0          0s
hpa-demo-6949d84d5b-hgbvg   0/1     Pending   0          5s
hpa-demo-6949d84d5b-hgbvg   0/1     ContainerCreating   0          22s
hpa-demo-6949d84d5b-hgbvg   0/1     ContainerCreating   0          39s
hpa-demo-6949d84d5b-hgbvg   1/1     Running             0          44s
hpa-demo-6949d84d5b-hgbvg   1/1     Running             0          2m9s
hpa-demo-6949d84d5b-hgbvg   0/1     Completed           0          3m31s
hpa-demo-6949d84d5b-hgbvg   0/1     Completed           0          3m31s
hpa-demo-6949d84d5b-rfjfv   1/1     Running             0          50m
hpa-demo-6949d84d5b-rfjfv   1/1     Running             0          51m
```

(The watch output above is the full capture, including the scale-down at the end.)

`<unknown>` is a moment when metrics-server did not answer (it was restarting on the busy node).
At 63% the HPA computed `ceil(1 × 63/50) = 2` replicas. `kubectl top` while loaded:

```text
$ kubectl top pods -n p13-hpa
NAME                              CPU(cores)   MEMORY(bytes)   
hpa-demo-6949d84d5b-rfjfv         83m          14Mi            
load-generator-7bfd77d597-9kxdv   281m         2Mi             
load-generator-7bfd77d597-ckh9d   282m         2Mi             
load-generator-7bfd77d597-llv2g   288m         3Mi             
$ kubectl get pods -n p13-hpa -o wide
NAME                              READY   STATUS    RESTARTS   AGE     IP            NODE                    NOMINATED NODE   READINESS GATES
hpa-demo-6949d84d5b-hgbvg         1/1     Running   0          63s     10.244.0.81   desktop-control-plane   <none>           <none>
hpa-demo-6949d84d5b-rfjfv         1/1     Running   0          46m     10.244.0.41   desktop-control-plane   <none>           <none>
load-generator-7bfd77d597-9kxdv   1/1     Running   0          4m31s   10.244.0.72   desktop-control-plane   <none>           <none>
load-generator-7bfd77d597-ckh9d   1/1     Running   0          4m32s   10.244.0.73   desktop-control-plane   <none>           <none>
load-generator-7bfd77d597-llv2g   1/1     Running   0          4m31s   10.244.0.71   desktop-control-plane   <none>           <none>
```

Stopping the load and the scale-down (60 s window):

```text
$ kubectl scale deploy/load-generator -n p13-hpa --replicas=0
deployment.apps/load-generator scaled
$ kubectl describe hpa hpa-demo -n p13-hpa | sed -n '/^Events/,$p'
Events:
  Type     Reason                        Age    From                       Message
  ----     ------                        ----   ----                       -------
  Warning  FailedGetResourceMetric       52m    horizontal-pod-autoscaler  failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Warning  FailedComputeMetricsReplicas  52m    horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Warning  FailedGetResourceMetric       18m    horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedGetResourceMetric       9m55s  horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: unable to fetch metrics from resource metrics API: the server is currently unable to handle the request (get pods.metrics.k8s.io)
  Warning  FailedComputeMetricsReplicas  9m52s  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: unable to fetch metrics from resource metrics API: the server is currently unable to handle the request (get pods.metrics.k8s.io)
  Normal   SuccessfulRescale             7m38s  horizontal-pod-autoscaler  New size: 2; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             4m17s  horizontal-pod-autoscaler  New size: 1; reason: All metrics below target
```

### Attempt 3: ApacheBench loader — CPU at the limit, scale to 4

`wget` in a loop wastes most CPU on starting processes, so I switched to `ab -k -c 20`
([load-generator-ab.yaml](load-generator-ab.yaml)). nginx went straight to its 200m limit (200% of the request):

```text
$ kubectl top pods -n p13-hpa
NAME                                 CPU(cores)   MEMORY(bytes)   
hpa-demo-6949d84d5b-rfjfv            198m         9Mi             
load-generator-ab-6ff476f486-krdx7   75m          16Mi            
$ kubectl get hpa -n p13-hpa -w
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         1          67m
hpa-demo   Deployment/hpa-demo   cpu: 179%/50%   1         5         1          74m
hpa-demo   Deployment/hpa-demo   cpu: 164%/50%   1         5         4          74m
hpa-demo   Deployment/hpa-demo   cpu: 176%/50%   1         5         4          74m
hpa-demo   Deployment/hpa-demo   cpu: 22%/50%    1         5         4          74m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%     1         5         4          75m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%     1         5         4          75m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%     1         5         1          76m
$ kubectl describe hpa hpa-demo -n p13-hpa | sed -n '/^Events/,$p'
Events:
  Type     Reason                        Age    From                       Message
  ----     ------                        ----   ----                       -------
  Warning  FailedGetResourceMetric       46m    horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedGetResourceMetric       37m    horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: unable to fetch metrics from resource metrics API: the server is currently unable to handle the request (get pods.metrics.k8s.io)
  Warning  FailedComputeMetricsReplicas  37m    horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: unable to fetch metrics from resource metrics API: the server is currently unable to handle the request (get pods.metrics.k8s.io)
  Normal   SuccessfulRescale             35m    horizontal-pod-autoscaler  New size: 2; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             31m    horizontal-pod-autoscaler  New size: 1; reason: All metrics below target
  Normal   SuccessfulRescale             5m53s  horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             4m6s   horizontal-pod-autoscaler  New size: 1; reason: All metrics below target
```

179% → `ceil(1 × 179/50) = 4` replicas (capped by the scale-up policy of +4 Pods / 15 s).
**Honest note:** on this run metrics-server was lagging minutes behind (the node's control plane was
restarting under load from other work), so the HPA only saw the high CPU after I had already stopped the
loader. The 3 new Pods stayed `Pending` for ~108 s because the scheduler was also slow, and they were
removed before they ever ran. A fourth, longer run was cut short when the API server itself restarted,
so I don't have a clean "4–5 Pods all Running under load" capture. Attempt 2 shows the full cycle working.

## Cleanup

```bash
kubectl delete ns p13-hpa
```

## What I learned

- HPA percentage is relative to the **request**, not the limit. With request 100m and limit 200m the
  Pod can show up to 200%.
- The load generator must not be the bottleneck. Forking `wget` capped out before nginx did; `ab` with
  keep-alive moved the load to nginx.
- HPA depends completely on metrics-server: `<unknown>` and `FailedGetResourceMetric` mean no scaling decisions.
- Scale-up is fast (0 s window), scale-down waits for the stabilization window to avoid flapping.
