# Task 2 - Horizontal Pod Autoscaler (HPA)

**Ujjawal Prabhat - 24BCS10267 - Session 13 (Storage, HPA & Probes)**

I used the course's own manifests from `../../04-hpa/`, applied unchanged into my namespace `s13`:
- `deployment.yaml`: `hpa-demo`, nginx:1.27, `requests.cpu: 100m`, `limits.cpu: 200m`
- `service.yaml`: `hpa-demo-service`
- `hpa.yaml`: min 1, max 5, target 50% average CPU utilization

Metrics come from metrics-server, which runs in the kind cluster with `--kubelet-insecure-tls`.

How the HPA decides:

```text
desiredReplicas = ceil( currentReplicas * currentUtilization / targetUtilization )
utilization     = pod CPU usage / pod CPU request      (e.g. 75m / 100m = 75%)
```

The controller checks every 15 seconds. Scale-up happens right away. Scale-down uses a **5-minute stabilization window**: the HPA uses the *highest* recommendation from the last 5 minutes, so the replica count does not flap.

---

## 1. Deploy the app and configure the HPA

```console
$ kubectl create ns s13
namespace/s13 created

$ kubectl apply -n s13 -f deployment.yaml -f service.yaml
deployment.apps/hpa-demo created
service/hpa-demo-service created

$ kubectl rollout status deploy/hpa-demo -n s13
Waiting for deployment "hpa-demo" rollout to finish: 0 of 1 updated replicas are available...
deployment "hpa-demo" successfully rolled out

$ kubectl apply -n s13 -f hpa.yaml
horizontalpodautoscaler.autoscaling/hpa-demo created

$ kubectl get deploy,pods,svc -n s13
NAME                       READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/hpa-demo   1/1     1            1           99s

NAME                            READY   STATUS    RESTARTS   AGE
pod/hpa-demo-5d6676989b-vlcz4   1/1     Running   0          99s

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/hpa-demo-service   ClusterIP   10.96.199.179   <none>        80/TCP    99s
```

## 2. Verify the HPA (before load)

```console
$ kubectl top nodes
NAME                         CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
devops-heros-control-plane   140m         1%       1018Mi          12%         
devops-heros-worker          20m          0%       187Mi           2%          
devops-heros-worker2         28m          0%       264Mi           3%          

$ kubectl get hpa -n s13
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         1          44s

$ kubectl top pods -n s13
NAME                        CPU(cores)   MEMORY(bytes)   
hpa-demo-5d6676989b-vlcz4   0m           8Mi             

$ kubectl describe hpa hpa-demo -n s13
Name:                                                  hpa-demo
Namespace:                                             s13
Labels:                                                <none>
Annotations:                                           <none>
CreationTimestamp:                                     Tue, 06 Oct 2026 18:57:27 +0800
Reference:                                             Deployment/hpa-demo
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  0% (0) / 50%
Min replicas:                                          1
Max replicas:                                          5
Deployment pods:                                       1 current / 1 desired
Conditions:
  Type            Status  Reason               Message
  ----            ------  ------               -------
  AbleToScale     True    ScaleDownStabilized  recent recommendations were higher than current one, applying the highest recent recommendation
  ScalingActive   True    ValidMetricFound     the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  False   DesiredWithinRange   the desired count is within the acceptable range
Events:
  Type     Reason                        Age                From                       Message
  ----     ------                        ----               ----                       -------
  Warning  FailedGetResourceMetric       29s (x2 over 44s)  horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedComputeMetricsReplicas  29s (x2 over 44s)  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
```

The two `FailedGetResourceMetric` warnings come from the first ~30 seconds after the HPA was created. metrics-server had not scraped the new pod yet, so the target showed `<unknown>`. Once a sample existed, `ScalingActive=True / ValidMetricFound` and the target read `0%/50%`.

---

## 3. Round 1 - one load generator (exactly as in the course readme)

```console
$ kubectl run load-generator -n s13 --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://hpa-demo-service; done"
pod/load-generator created
```

Output of `kubectl get hpa -n s13 -w`, running in the background for the whole round (load started at about AGE 45s and was stopped at about AGE 7m30s):

```console
$ kubectl get hpa -n s13 -w
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         1          45s
hpa-demo   Deployment/hpa-demo   cpu: 66%/50%   1         5         1          2m
hpa-demo   Deployment/hpa-demo   cpu: 66%/50%   1         5         2          2m15s
hpa-demo   Deployment/hpa-demo   cpu: 75%/50%   1         5         2          2m30s
hpa-demo   Deployment/hpa-demo   cpu: 51%/50%   1         5         2          2m45s
hpa-demo   Deployment/hpa-demo   cpu: 79%/50%   1         5         2          3m
hpa-demo   Deployment/hpa-demo   cpu: 88%/50%   1         5         2          3m15s
hpa-demo   Deployment/hpa-demo   cpu: 52%/50%   1         5         2          3m30s
hpa-demo   Deployment/hpa-demo   cpu: 51%/50%   1         5         2          3m45s
hpa-demo   Deployment/hpa-demo   cpu: 71%/50%   1         5         2          4m
hpa-demo   Deployment/hpa-demo   cpu: 49%/50%   1         5         2          4m15s
hpa-demo   Deployment/hpa-demo   cpu: 42%/50%   1         5         2          4m30s
hpa-demo   Deployment/hpa-demo   cpu: 26%/50%   1         5         2          4m45s
hpa-demo   Deployment/hpa-demo   cpu: 31%/50%   1         5         2          5m
...
hpa-demo   Deployment/hpa-demo   cpu: 36%/50%   1         5         2          7m31s
hpa-demo   Deployment/hpa-demo   cpu: 17%/50%   1         5         2          7m46s
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%    1         5         2          8m1s
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%    1         5         2          12m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%    1         5         1          12m
```

A snapshot during the load (`get hpa`, `top pods`, `get pods`, taken every 30 seconds by a script):

```console
----- snapshot 19:00:12 (under load, t+120s) -----
$ kubectl get hpa -n s13
NAME       REFERENCE             TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 75%/50%   1         5         2          2m45s
$ kubectl top pods -n s13
NAME                        CPU(cores)   MEMORY(bytes)   
hpa-demo-5d6676989b-vlcz4   51m          10Mi            
load-generator              898m         11Mi            
$ kubectl get pods -n s13
NAME                        READY   STATUS              RESTARTS   AGE
hpa-demo-5d6676989b-95x58   0/1     ContainerCreating   0          45s
hpa-demo-5d6676989b-vlcz4   1/1     Running             0          4m24s
load-generator              1/1     Running             0          2m
```

Result of round 1: CPU reached 66% of the request, so the HPA computed `ceil(1 * 66/50) = 2` and **scaled 1 -> 2**. With 2 pods sharing the load, utilization settled around 30-50%, below target, so it never went higher. `kubectl top` explains why: one `wget` loop is single-threaded and spends most of its time starting processes. The load generator itself burned about 900m CPU, while it could only push about 50-75m of work onto nginx. **The load generator was the bottleneck, not the app.**

## 4. Round 2 - three load generators (more load, to see larger scaling)

To see the HPA go further, I started three identical generators in parallel:

```console
$ kubectl run load-generator-1 -n s13 --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://hpa-demo-service; done"
pod/load-generator-1 created
$ kubectl run load-generator-2 -n s13 --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://hpa-demo-service; done"
pod/load-generator-2 created
$ kubectl run load-generator-3 -n s13 --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://hpa-demo-service; done"
pod/load-generator-3 created
```

### Observe CPU and scale-up

```console
$ kubectl get hpa -n s13 -w
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         1          30m
hpa-demo   Deployment/hpa-demo   cpu: 32%/50%   1         5         1          30m
hpa-demo   Deployment/hpa-demo   cpu: 200%/50%   1         5         1          30m
hpa-demo   Deployment/hpa-demo   cpu: 184%/50%   1         5         4          30m
hpa-demo   Deployment/hpa-demo   cpu: 57%/50%    1         5         4          31m
hpa-demo   Deployment/hpa-demo   cpu: 57%/50%    1         5         4          31m
hpa-demo   Deployment/hpa-demo   cpu: 56%/50%    1         5         5          31m
hpa-demo   Deployment/hpa-demo   cpu: 45%/50%    1         5         5          31m
hpa-demo   Deployment/hpa-demo   cpu: 46%/50%    1         5         5          32m
hpa-demo   Deployment/hpa-demo   cpu: 45%/50%    1         5         5          32m
hpa-demo   Deployment/hpa-demo   cpu: 40%/50%    1         5         5          33m
...
```

Snapshots:

```console
----- snapshot 19:27:58 (under load, t+30s) -----
$ kubectl get hpa -n s13
NAME       REFERENCE             TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 32%/50%   1         5         1          30m
$ kubectl top pods -n s13
NAME                        CPU(cores)   MEMORY(bytes)   
hpa-demo-5d6676989b-vlcz4   200m         10Mi            
load-generator-1            709m         3Mi             
load-generator-2            711m         3Mi             
load-generator-3            725m         3Mi             

----- snapshot 19:28:28 (under load, t+60s) -----
$ kubectl get hpa -n s13
NAME       REFERENCE             TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 184%/50%   1         5         4          31m
$ kubectl top pods -n s13
NAME                        CPU(cores)   MEMORY(bytes)   
hpa-demo-5d6676989b-bpjpk   57m          10Mi            
hpa-demo-5d6676989b-lszzr   61m          9Mi             
hpa-demo-5d6676989b-nk4t2   59m          8Mi             
hpa-demo-5d6676989b-vlcz4   56m          10Mi            
load-generator-1            716m         4Mi             
load-generator-2            720m         5Mi             
load-generator-3            720m         4Mi             

----- snapshot 19:29:28 (under load, t+120s) -----
$ kubectl get hpa -n s13
NAME       REFERENCE             TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 45%/50%   1         5         5          32m
$ kubectl top pods -n s13
NAME                        CPU(cores)   MEMORY(bytes)   
hpa-demo-5d6676989b-bpjpk   49m          9Mi             
hpa-demo-5d6676989b-dhdsg   45m          8Mi             
hpa-demo-5d6676989b-lszzr   44m          8Mi             
hpa-demo-5d6676989b-nk4t2   49m          8Mi             
hpa-demo-5d6676989b-vlcz4   42m          9Mi             
load-generator-1            695m         6Mi             
load-generator-2            693m         6Mi             
load-generator-3            681m         5Mi             
$ kubectl get pods -n s13
NAME                        READY   STATUS    RESTARTS   AGE
hpa-demo-5d6676989b-bpjpk   1/1     Running   0          89s
hpa-demo-5d6676989b-dhdsg   1/1     Running   0          44s
hpa-demo-5d6676989b-lszzr   1/1     Running   0          89s
hpa-demo-5d6676989b-nk4t2   1/1     Running   0          89s
hpa-demo-5d6676989b-vlcz4   1/1     Running   0          33m
load-generator-1            1/1     Running   0          2m
load-generator-2            1/1     Running   0          2m
...
```

What happened:
- The single pod hit **200m = its CPU limit**, which is 200% of its 100m request. The HPA computed `ceil(1 * 200/50) = 4` and jumped **1 -> 4** in one step.
- With 4 pods the utilization was still 57% > 50%, so `ceil(4 * 57/50) = 5` gave **4 -> 5**, which is `maxReplicas`.
- With 5 pods the average was about 45%, below target, so it stayed at 5. In total the generators pushed only about 230-250m of nginx CPU, and 5 x 100m requests absorb that.

`kubectl describe hpa`, taken at the end of the 5-minute load period, just before the generators were stopped:

```console
$ kubectl describe hpa hpa-demo -n s13
Name:                                                  hpa-demo
Namespace:                                             s13
...
Reference:                                             Deployment/hpa-demo
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  29% (29m) / 50%
Min replicas:                                          1
Max replicas:                                          5
Deployment pods:                                       5 current / 5 desired
Conditions:
  Type            Status  Reason               Message
  ----            ------  ------               -------
  AbleToScale     True    ScaleDownStabilized  recent recommendations were higher than current one, applying the highest recent recommendation
  ScalingActive   True    ValidMetricFound     the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  False   DesiredWithinRange   the desired count is within the acceptable range
  ScaledToZero    False   NotScaledToZero      the HPA controller did not scale the workload to zero
Events:
  Type     Reason                        Age                From                       Message
  ----     ------                        ----               ----                       -------
  Warning  FailedGetResourceMetric       34m (x2 over 35m)  horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedComputeMetricsReplicas  34m (x2 over 35m)  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Normal   SuccessfulRescale             33m                horizontal-pod-autoscaler  New size: 2; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             22m                horizontal-pod-autoscaler  New size: 1; reason: All metrics below target
  Normal   SuccessfulRescale             4m31s              horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             3m46s              horizontal-pod-autoscaler  New size: 5; reason: cpu resource utilization (percentage of request) above target
```

The events show the full story of both rounds: round 1 went 1 -> 2 -> 1, and round 2 went 1 -> 4 -> 5. The condition `ScaleDownStabilized` shows that, even though current usage (29%) only justifies 3 pods, the HPA keeps 5 because a higher recommendation happened within the last 5 minutes.

### Stop the load and observe scale-down

```console
$ kubectl delete pod load-generator-1 load-generator-2 load-generator-3 -n s13
pod "load-generator-1" deleted from s13 namespace
pod "load-generator-2" deleted from s13 namespace
pod "load-generator-3" deleted from s13 namespace
```

`kubectl get hpa -n s13 -w`, continued (load stopped at about AGE 36m):

```console
hpa-demo   Deployment/hpa-demo   cpu: 17%/50%    1         5         5          36m
hpa-demo   Deployment/hpa-demo   cpu: 2%/50%     1         5         5          36m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%     1         5         5          36m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%     1         5         5          38m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%     1         5         4          38m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%     1         5         4          40m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%     1         5         2          41m
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%     1         5         1          41m
```

Snapshots every 30 seconds after the load stopped (only the `get hpa` line is shown for each):

```text
19:33:32 (t+30s)   cpu: 17%/50%   REPLICAS 5
19:34:02 (t+60s)   cpu: 0%/50%    REPLICAS 5
19:35:02 (t+120s)  cpu: 0%/50%    REPLICAS 5
19:35:32 (t+150s)  cpu: 0%/50%    REPLICAS 5
19:36:03 (t+180s)  cpu: 0%/50%    REPLICAS 4
19:38:03 (t+300s)  cpu: 0%/50%    REPLICAS 4
19:38:33 (t+330s)  cpu: 0%/50%    REPLICAS 2
19:39:03 (t+360s)  cpu: 0%/50%    REPLICAS 1
19:40:03 (t+420s)  cpu: 0%/50%    REPLICAS 1
```

```console
----- snapshot 19:39:33 (after load stopped, t+390s) -----
$ kubectl get hpa -n s13
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         1          42m
$ kubectl top pods -n s13
NAME                        CPU(cores)   MEMORY(bytes)   
hpa-demo-5d6676989b-vlcz4   0m           8Mi             
$ kubectl get pods -n s13
NAME                        READY   STATUS    RESTARTS   AGE
hpa-demo-5d6676989b-vlcz4   1/1     Running   0          43m

$ kubectl describe hpa hpa-demo -n s13
...
Conditions:
  Type            Status  Reason            Message
  ----            ------  ------            -------
  AbleToScale     True    ReadyForNewScale  recommended size matches current size
  ScalingActive   True    ValidMetricFound  the HPA was able to successfully calculate a replica count from cpu resource utilization (percentage of request)
  ScalingLimited  True    TooFewReplicas    the desired replica count is less than the minimum replica count
  ScaledToZero    False   NotScaledToZero   the HPA controller did not scale the workload to zero
Events:
  Type     Reason                        Age                From                       Message
  ----     ------                        ----               ----                       -------
  ...
  Normal   SuccessfulRescale             12m                horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             11m                horizontal-pod-autoscaler  New size: 5; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             4m34s              horizontal-pod-autoscaler  New size: 4; reason: All metrics below target
  Normal   SuccessfulRescale             109s               horizontal-pod-autoscaler  New size: 2; reason: All metrics below target
  Normal   SuccessfulRescale             94s (x2 over 30m)  horizontal-pod-autoscaler  New size: 1; reason: All metrics below target
```

How the scale-down played out: CPU dropped to 0% within a minute, but replicas went **5 -> 4 -> 2 -> 1** over about 6 minutes, not all at once. This is the 5-minute stabilization window. The HPA always applies the *highest* recommendation from the last 5 minutes. Those recommendations were themselves falling while the load was still running (utilization at 5 pods slid from 45% to about 29%, so the recommendations went from 5 to 3). As each older, higher recommendation aged out of the window, the replica count stepped down. It ended at `minReplicas: 1` (`ScalingLimited True TooFewReplicas` means the formula wants fewer than 1).

## 5. Commands used

```bash
kubectl get hpa -n s13            # current/target utilization, replicas
kubectl get hpa -n s13 -w         # watch changes live
kubectl get pods -n s13           # pods being added/removed
kubectl top pods -n s13           # real CPU/memory per pod (metrics-server)
kubectl top nodes
kubectl describe hpa hpa-demo -n s13   # conditions + SuccessfulRescale events
```

## Key points

- The HPA needs **`resources.requests.cpu`** on the container, because utilization is computed against the request. It also needs **metrics-server**. Without either, TARGETS shows `<unknown>`.
- Scale-up is fast, and the formula can jump several replicas at once (1 -> 4).
- Scale-down is deliberately slow (5-minute stabilization) to avoid flapping.
- A container's CPU **limit** caps the utilization it can report (200m limit / 100m request = 200% maximum).
- The scaling you see depends on how much load you can actually generate. A single busybox `wget` loop is mostly process-spawn overhead, so it barely loads nginx.

Cleanup: `kubectl delete ns s13` (done at the end).
