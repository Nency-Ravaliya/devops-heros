# Session 13: Kubernetes Storage, HPA and Probes

**Name:** Yash Gaikwad  |  **Roll No:** 24BCS10100

| Task | Topic | Where |
|---|---|---|
| 1 | Kubernetes volumes (emptyDir, hostPath, PV, PVC, StorageClass, dynamic provisioning) | [01-kubernetes-volumes/README.md](01-kubernetes-volumes/README.md) (with real hands-on output at the end) |
| 2 | HPA hands-on with `hpa.yaml` | [Task 2](#task-2-hpa-hands-on) |
| 3 | Mini project (PVC + HPA + probes) | [Task 3](#task-3-mini-project) |

**Deliverables:** volume documentation, HPA YAML (`02-hpa/hpa.yaml`), load generator (`02-hpa/load-generator.yaml`), HPA output, mini-project implementation (`mini-project/`), README documentation.

**Environment:** Minikube (Docker driver) on Windows 11, Kubernetes v1.37.0, metrics-server addon. All output is real. Results are included as the exact command and its terminal output.

---

## Task 1: Kubernetes volumes

The full write-up (what each volume type is, access modes, reclaim policies, comparison table) and the **real hands-on run of every example** are in [01-kubernetes-volumes/README.md](01-kubernetes-volumes/README.md). Short version of the experiments: `emptyDir` loses its data when the Pod is deleted, `hostPath` keeps it on the same node, a static PV/PVC keeps it and the PV becomes *Released* after the claim is deleted, and a dynamic PVC makes the `standard` StorageClass create (and later delete) the volume automatically.

---

## Task 2: HPA hands-on

A **HorizontalPodAutoscaler** watches a metric (here CPU utilisation compared with the Pods' CPU **request**) and changes the Deployment's replica count between `minReplicas` and `maxReplicas` to keep the average near the target.

### Prerequisite: metrics-server

The HPA reads CPU usage from the Metrics API, which the **metrics-server** provides.

_Enable the metrics-server addon._

```console
$ minikube addons enable metrics-server 2>&1 | tail -n 3
You can view the list of minikube maintainers at: https://github.com/kubernetes/minikube/blob/master/OWNERS
  - Using image registry.k8s.io/metrics-server/metrics-server:v0.9.0
* The 'metrics-server' addon is enabled
```

_Wait until it is serving: `kubectl top nodes` returns node CPU and memory._

```console
$ kubectl rollout status deployment/metrics-server -n kube-system --timeout=180s && sleep 45 && kubectl top nodes
Waiting for deployment "metrics-server" rollout to finish: 0 of 1 updated replicas are available...
deployment "metrics-server" successfully rolled out
NAME       CPU(cores)   CPU(%)   MEMORY(bytes)   MEMORY(%)   
minikube   443m         3%       979Mi           8%          
```

### 1. Deploy the application

_The application (nginx with `requests.cpu: 100m` and `limits.cpu: 200m`; the request is what utilisation is measured against) and its Service. These files come from the course repository._

```console
$ cat 02-hpa/deployment.yaml 02-hpa/service.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: hpa-demo
spec:
  replicas: 1
  selector:
    matchLabels:
      app: hpa-demo
  template:
    metadata:
      labels:
        app: hpa-demo
    spec:
      containers:
        - name: nginx
          image: nginx:1.27
          resources:
            requests:
              cpu: 100m
            limits:
              cpu: 200m
          ports:
            - containerPort: 80
apiVersion: v1
kind: Service
metadata:
  name: hpa-demo-service
spec:
  selector:
    app: hpa-demo
  ports:
    - port: 80
      targetPort: 80
  type: ClusterIP
```

_Deploy the application: one Pod running._

```console
$ kubectl apply -f 02-hpa/deployment.yaml -f 02-hpa/service.yaml && kubectl rollout status deployment/hpa-demo --timeout=180s && kubectl get deployment,pods,svc -l app=hpa-demo 2>/dev/null; kubectl get svc hpa-demo-service
deployment.apps/hpa-demo created
service/hpa-demo-service created
Waiting for deployment "hpa-demo" rollout to finish: 0 of 1 updated replicas are available...
deployment "hpa-demo" successfully rolled out
NAME                            READY   STATUS    RESTARTS   AGE
pod/hpa-demo-5d6676989b-ndvh9   1/1     Running   0          2s
NAME               TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
hpa-demo-service   ClusterIP   10.109.236.32   <none>        80/TCP    2s
```

### 2. Configure the HPA

_The HPA: 1 to 5 replicas, target average CPU utilisation 50% of the request (50m of the 100m)._

```console
$ cat 02-hpa/hpa.yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: hpa-demo
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: hpa-demo
  minReplicas: 1
  maxReplicas: 5
  metrics:
    - type: Resource
      resource:
        name: cpu
        target:
          type: Utilization
          averageUtilization: 50
```

_Create it._

```console
$ kubectl apply -f 02-hpa/hpa.yaml
horizontalpodautoscaler.autoscaling/hpa-demo created
```

### 3. Verify the HPA

_Right after creation TARGETS shows `<unknown>`: the HPA has no CPU sample for the new Pod yet, because metrics-server needs about a minute to collect the first one. Once it has, TARGETS shows current/target utilisation (for example `69%/50%` in the next section)._

```console
$ sleep 40 && kubectl get hpa hpa-demo
NAME       REFERENCE             TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: <unknown>/50%   1         5         1          41s
```

_Details: the metric, the target and the min/max. The condition `ScalingActive` is False at this moment and the events say why: metrics for the new Pod are not available yet (it becomes True a minute later)._

```console
$ kubectl describe hpa hpa-demo | head -n 22
Name:                                                  hpa-demo
Namespace:                                             default
Labels:                                                <none>
Annotations:                                           <none>
CreationTimestamp:                                     Sun, 18 Oct 2026 19:42:41 +0530
Reference:                                             Deployment/hpa-demo
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  <unknown> / 50%
Min replicas:                                          1
Max replicas:                                          5
Deployment pods:                                       1 current / 0 desired
Conditions:
  Type           Status  Reason                   Message
  ----           ------  ------                   -------
  AbleToScale    True    SucceededGetScale        the HPA controller was able to get the target's current scale
  ScalingActive  False   FailedGetResourceMetric  the HPA was unable to compute the replica count: failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
Events:
  Type     Reason                        Age                From                       Message
  ----     ------                        ----               ----                       -------
  Warning  FailedGetResourceMetric       41s                horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedComputeMetricsReplicas  41s                horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedGetResourceMetric       11s (x2 over 26s)  horizontal-pod-autoscaler  failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
```

_The idle CPU and memory of the Pod._

```console
$ kubectl top pods -l app=hpa-demo
NAME                        CPU(cores)   MEMORY(bytes)   
hpa-demo-5d6676989b-ndvh9   32m          10Mi            
```

### 4. Deploy a load generator

_Three busybox Pods, each with three endless `wget` loops against the Service._

```console
$ cat 02-hpa/load-generator.yaml
# Load generator: three Pods, each running three endless request loops against the Service.
# Deleting this Deployment removes the load.
apiVersion: apps/v1
kind: Deployment
metadata:
  name: load-generator
spec:
  replicas: 3
  selector:
    matchLabels:
      app: load-generator
  template:
    metadata:
      labels:
        app: load-generator
    spec:
      containers:
        - name: busybox
          image: busybox:1.36
          command: ["sh", "-c"]
          args:
            - |
              for i in 1 2 3; do
                (while true; do wget -q -O- http://hpa-demo-service > /dev/null; done) &
              done
              wait
```

_**Increase the application load:** start the load generator._

```console
$ kubectl apply -f 02-hpa/load-generator.yaml && kubectl rollout status deployment/load-generator --timeout=180s
deployment.apps/load-generator created
Waiting for deployment "load-generator" rollout to finish: 0 of 3 updated replicas are available...
Waiting for deployment "load-generator" rollout to finish: 1 of 3 updated replicas are available...
Waiting for deployment "load-generator" rollout to finish: 2 of 3 updated replicas are available...
deployment "load-generator" successfully rolled out
```

### 5. Observe CPU utilisation and Pod scaling

Every 25 seconds: the HPA line, the CPU of the application Pods (`kubectl top pods`) and the Pod list. Read it from top to bottom.

_**Observe CPU utilisation and Pod scaling** under load: TARGETS climbs above 50%, REPLICAS rises step by step (1, 2, 3, 4 in this series; the events further down show that it reached the maximum of 5 shortly afterwards) and the CPU per Pod falls as the load is shared._

```console
$ for i in 1 2 3 4 5 6 7 8 9 10; do echo "[$(date +%T)] $(kubectl get hpa hpa-demo --no-headers)"; kubectl top pods -l app=hpa-demo --no-headers | sed "s/^/            /"; sleep 25; done
[19:43:26] hpa-demo   Deployment/hpa-demo   cpu: <unknown>/50%   1     5     1     45s
            hpa-demo-5d6676989b-ndvh9   32m   10Mi   
[19:43:52] hpa-demo   Deployment/hpa-demo   cpu: <unknown>/50%   1     5     1     71s
            hpa-demo-5d6676989b-ndvh9   69m   10Mi   
[19:44:18] hpa-demo   Deployment/hpa-demo   cpu: 69%/50%   1     5     2     97s
            hpa-demo-5d6676989b-ndvh9   69m   10Mi   
[19:44:44] hpa-demo   Deployment/hpa-demo   cpu: 69%/50%   1     5     2     2m3s
            hpa-demo-5d6676989b-ndvh9   69m   10Mi   
[19:45:10] hpa-demo   Deployment/hpa-demo   cpu: 138%/50%   1     5     2     2m29s
            hpa-demo-5d6676989b-ndvh9   138m   10Mi   
            hpa-demo-5d6676989b-pn64t   123m   10Mi   
[19:45:36] hpa-demo   Deployment/hpa-demo   cpu: 138%/50%   1     5     3     2m55s
            hpa-demo-5d6676989b-ndvh9   138m   10Mi   
            hpa-demo-5d6676989b-pn64t   123m   10Mi   
[19:46:01] hpa-demo   Deployment/hpa-demo   cpu: 90%/50%   1     5     3     3m21s
            hpa-demo-5d6676989b-9plsl   86m   10Mi   
            hpa-demo-5d6676989b-ndvh9   93m   10Mi   
            hpa-demo-5d6676989b-pn64t   88m   10Mi   
[19:46:27] hpa-demo   Deployment/hpa-demo   cpu: 90%/50%   1     5     4     3m47s
            hpa-demo-5d6676989b-9plsl   86m   10Mi   
            hpa-demo-5d6676989b-ndvh9   93m   10Mi   
            hpa-demo-5d6676989b-pn64t   88m   10Mi   
[19:46:53] hpa-demo   Deployment/hpa-demo   cpu: 90%/50%   1     5     4     4m13s
            hpa-demo-5d6676989b-2sv4p   65m   10Mi   
            hpa-demo-5d6676989b-9plsl   61m   10Mi   
            hpa-demo-5d6676989b-ndvh9   67m   10Mi   
            hpa-demo-5d6676989b-pn64t   65m   10Mi   
[19:47:20] hpa-demo   Deployment/hpa-demo   cpu: 64%/50%   1     5     4     4m39s
            hpa-demo-5d6676989b-2sv4p   65m   10Mi   
            hpa-demo-5d6676989b-9plsl   61m   10Mi   
            hpa-demo-5d6676989b-ndvh9   67m   10Mi   
            hpa-demo-5d6676989b-pn64t   65m   10Mi   
```

_The Pods created by the autoscaler._

```console
$ kubectl get pods -l app=hpa-demo && kubectl get hpa hpa-demo
NAME                        READY   STATUS    RESTARTS   AGE
hpa-demo-5d6676989b-2sv4p   1/1     Running   0          109s
hpa-demo-5d6676989b-9plsl   1/1     Running   0          2m49s
hpa-demo-5d6676989b-ndvh9   1/1     Running   0          5m8s
hpa-demo-5d6676989b-pn64t   1/1     Running   0          3m50s
NAME       REFERENCE             TARGETS        MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 64%/50%   1         5         4          5m6s
```

_The autoscaler explains its decisions in the events (`SuccessfulRescale`, reason: cpu resource utilization above target)._

```console
$ kubectl describe hpa hpa-demo | sed -n "/^Metrics:/,/^Conditions:/p;/^Events:/,\$p"
Metrics:                                               ( current / target )
  resource cpu on pods  (as a percentage of request):  64% (64m) / 50%
Min replicas:                                          1
Max replicas:                                          5
Deployment pods:                                       4 current / 4 desired
Conditions:
Events:
  Type     Reason                        Age                   From                       Message
  ----     ------                        ----                  ----                       -------
  Warning  FailedGetResourceMetric       5m7s                  horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedComputeMetricsReplicas  5m7s                  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedGetResourceMetric       4m7s (x4 over 4m52s)  horizontal-pod-autoscaler  failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Warning  FailedComputeMetricsReplicas  4m7s (x4 over 4m52s)  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Normal   SuccessfulRescale             3m52s                 horizontal-pod-autoscaler  New size: 2; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             2m51s                 horizontal-pod-autoscaler  New size: 3; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             111s                  horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
```

### 6. Remove the load and watch it scale back down

The HPA scales **down** slowly on purpose: by default it waits for a **5 minute stabilisation window** so that a short dip does not remove Pods that will be needed again.

_Load removed. TARGETS falls to 0% within about two minutes, but REPLICAS stays at 5 for the whole stabilisation window (about 5 minutes) and only then drops (to 3 here, see the event below). The recording stops while the HPA is still stepping down towards minReplicas._

```console
$ kubectl delete deployment load-generator && for i in 1 2 3 4 5 6 7 8 9 10 11 12 13; do echo "[$(date +%T)] $(kubectl get hpa hpa-demo --no-headers)"; sleep 30; done
deployment.apps "load-generator" deleted from default namespace
[19:47:49] hpa-demo   Deployment/hpa-demo   cpu: 64%/50%   1     5     4     5m9s
[19:48:20] hpa-demo   Deployment/hpa-demo   cpu: 57%/50%   1     5     5     5m39s
[19:48:51] hpa-demo   Deployment/hpa-demo   cpu: 57%/50%   1     5     5     6m10s
[19:49:21] hpa-demo   Deployment/hpa-demo   cpu: 35%/50%   1     5     5     6m40s
[19:49:51] hpa-demo   Deployment/hpa-demo   cpu: 35%/50%   1     5     5     7m11s
[19:50:22] hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1     5     5     7m41s
[19:50:52] hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1     5     5     8m11s
[19:51:22] hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1     5     5     8m42s
[19:51:53] hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1     5     5     9m12s
[19:52:23] hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1     5     5     9m43s
[19:52:54] hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1     5     5     10m
[19:53:24] hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1     5     5     10m
[19:53:55] hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1     5     5     11m
```

_Final state, and the scale-down events._

```console
$ kubectl get hpa hpa-demo && kubectl get pods -l app=hpa-demo && kubectl describe hpa hpa-demo | sed -n "/^Events:/,\$p"
NAME       REFERENCE             TARGETS       MINPODS   MAXPODS   REPLICAS   AGE
hpa-demo   Deployment/hpa-demo   cpu: 0%/50%   1         5         3          11m
NAME                        READY   STATUS    RESTARTS   AGE
hpa-demo-5d6676989b-9plsl   1/1     Running   0          9m29s
hpa-demo-5d6676989b-ndvh9   1/1     Running   0          11m
hpa-demo-5d6676989b-pn64t   1/1     Running   0          10m
Events:
  Type     Reason                        Age                From                       Message
  ----     ------                        ----               ----                       -------
  Warning  FailedGetResourceMetric       11m                horizontal-pod-autoscaler  failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedComputeMetricsReplicas  11m                horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: unable to get metrics for resource cpu: no metrics returned from resource metrics API
  Warning  FailedGetResourceMetric       10m (x4 over 11m)  horizontal-pod-autoscaler  failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Warning  FailedComputeMetricsReplicas  10m (x4 over 11m)  horizontal-pod-autoscaler  invalid metrics (1 invalid out of 1), first error is: failed to get cpu resource metric value: failed to get cpu utilization: did not receive metrics for targeted pods (pods might be unready)
  Normal   SuccessfulRescale             10m                horizontal-pod-autoscaler  New size: 2; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             9m29s              horizontal-pod-autoscaler  New size: 3; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             8m29s              horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             6m28s              horizontal-pod-autoscaler  New size: 5; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             43s                horizontal-pod-autoscaler  New size: 3; reason: All metrics below target
```

### Useful commands (from the task)

| Command | Purpose |
|---|---|
| `kubectl get hpa` (`-w` to watch) | current/target utilisation and replica count |
| `kubectl get pods` | the Pods being added or removed |
| `kubectl top pods` | real CPU and memory (from metrics-server) |
| `kubectl describe hpa <name>` | metric details, conditions and the scaling events |

### What I learned

- HPA utilisation is **relative to the CPU request**, so a Deployment without `resources.requests.cpu` cannot be autoscaled.
- The autoscaler needs the metrics-server; without it TARGETS shows `<unknown>`.
- Scale **up** reacts within a minute or two; scale **down** waits for the stabilisation window to avoid flapping.

_Cleanup._

```console
$ kubectl delete -f 02-hpa/hpa.yaml -f 02-hpa/deployment.yaml -f 02-hpa/service.yaml
horizontalpodautoscaler.autoscaling "hpa-demo" deleted from default namespace
deployment.apps "hpa-demo" deleted from default namespace
service "hpa-demo-service" deleted from default namespace
```

---

## Task 3: Mini project

The course's mini project: a production-style web app combining **persistent storage** (PVC), **elastic scaling** (HPA) and **health probes** (startup, readiness, liveness). The manifests in [`mini-project/`](mini-project/) are the ones provided for this session, applied unchanged.

```
                 Service web-service (port 80)
                          |
        +-----------------+-----------------+
        |                                   |
   Pod web-app (nginx)                 Pod web-app (nginx)    <-- HPA: 2 to 5 replicas at 50% CPU
   startup + readiness + liveness probes, /data mounted from the PVC
        |
   PVC web-data (500Mi, ReadWriteOnce)  ->  StorageClass standard  ->  PV (created automatically)
```

### Deploy

_Namespace and the PersistentVolumeClaim. The claim is **Bound** straight away: the default StorageClass provisioned a volume for it._

```console
$ kubectl apply -f mini-project/namespace.yaml && kubectl apply -f mini-project/pvc.yaml && kubectl get pvc -n production-webapp
namespace/production-webapp created
persistentvolumeclaim/web-data created
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
web-data   Bound    pvc-d5d7ee4c-6187-4db5-a4d2-d911edd8fc67   500Mi      RWO            standard       <unset>                 1s
```

_Deployment (2 replicas with all three probes, the PVC mounted at /data) and Service._

```console
$ kubectl apply -f mini-project/deployment.yaml -f mini-project/service.yaml && kubectl rollout status deployment/web-app -n production-webapp --timeout=240s && kubectl get pods,svc -n production-webapp
deployment.apps/web-app created
service/web-service created
Waiting for deployment "web-app" rollout to finish: 0 of 2 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 1 of 2 updated replicas are available...
deployment "web-app" successfully rolled out
NAME                          READY   STATUS    RESTARTS   AGE
pod/web-app-d45775485-22kwg   1/1     Running   0          11s
pod/web-app-d45775485-hwbpd   1/1     Running   0          11s

NAME                  TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
service/web-service   ClusterIP   10.99.189.203   <none>        80/TCP    11s
```

_The autoscaler: min 2, max 5, target 50% CPU._

```console
$ kubectl apply -f mini-project/hpa.yaml && sleep 40 && kubectl get hpa -n production-webapp
horizontalpodautoscaler.autoscaling/web-app-hpa created
NAME          REFERENCE            TARGETS              MINPODS   MAXPODS   REPLICAS   AGE
web-app-hpa   Deployment/web-app   cpu: <unknown>/50%   2         5         2          40s
```

_The PV behind the claim, and the probes and the volume mount as Kubernetes understood them._

```console
$ kubectl get pv; kubectl describe deployment web-app -n production-webapp | grep -E "Liveness|Readiness|Startup|Mounts|/data|web-data"
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                        STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-d5d7ee4c-6187-4db5-a4d2-d911edd8fc67   500Mi      RWO            Delete           Bound    production-webapp/web-data   standard       <unset>                          53s
    Liveness:     http-get http://:80/ delay=5s timeout=2s period=5s successThreshold=1 failureThreshold=3
    Readiness:    http-get http://:80/ delay=5s timeout=2s period=5s successThreshold=1 failureThreshold=2
    Startup:      http-get http://:80/ delay=0s timeout=1s period=2s successThreshold=1 failureThreshold=30
    Mounts:
      /data from persistent-storage (rw)
    ClaimName:     web-data
```

### Verification task 1: storage persistence

I write a file into the volume, delete the Pod, and check the file from the replacement Pod.

_Write my name to `/data/student.txt` and read it back._

```console
$ POD_NAME=$(kubectl get pods -n production-webapp -l app=web-app -o jsonpath="{.items[0].metadata.name}"); echo "writing in $POD_NAME"; kubectl exec -n production-webapp "$POD_NAME" -- sh -c "echo \"Student: Yash Gaikwad (24BCS10100)\" > /data/student.txt" && kubectl exec -n production-webapp "$POD_NAME" -- cat /data/student.txt
writing in web-app-d45775485-22kwg
Student: Yash Gaikwad (24BCS10100)
```

_Delete that Pod; the Deployment starts a replacement (note the new Pod name)._

```console
$ POD_NAME=$(kubectl get pods -n production-webapp -l app=web-app -o jsonpath="{.items[0].metadata.name}"); kubectl delete pod -n production-webapp "$POD_NAME" && kubectl rollout status deployment/web-app -n production-webapp --timeout=240s && kubectl get pods -n production-webapp
pod "web-app-d45775485-22kwg" deleted from production-webapp namespace
Waiting for deployment "web-app" rollout to finish: 1 of 2 updated replicas are available...
deployment "web-app" successfully rolled out
NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-ddn27   1/1     Running   0          9s
web-app-d45775485-hwbpd   1/1     Running   0          63s
```

_**The file is still there**, in the new Pod and also in the second replica (both mount the same ReadWriteOnce claim on the single node). The data lives in the PersistentVolume, not in the Pod._

```console
$ for p in $(kubectl get pods -n production-webapp -l app=web-app -o jsonpath="{.items[*].metadata.name}"); do echo -n "$p: "; kubectl exec -n production-webapp "$p" -- cat /data/student.txt; done
web-app-d45775485-ddn27: Student: Yash Gaikwad (24BCS10100)
web-app-d45775485-hwbpd: Student: Yash Gaikwad (24BCS10100)
```

### Verification task 2: the Service

_Port-forward to the Service and fetch the page: the nginx welcome page answers._

```console
$ kubectl port-forward -n production-webapp svc/web-service 8081:80 > /tmp/pf-mini.txt 2>&1 & sleep 4; curl -s http://localhost:8081 | head -n 6; kill %1
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
```

### Verification task 3: elastic scaling under load

The provided load generator is a single Pod running one endless `wget` loop.

_Start the load generator._

```console
$ kubectl run load-generator -n production-webapp --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://web-service; done"
pod/load-generator created
```

_Watch the autoscaler for about two and a half minutes: TARGETS and REPLICAS with the provided single load generator._

```console
$ for i in 1 2 3 4 5 6; do echo "[$(date +%T)] $(kubectl get hpa -n production-webapp --no-headers)"; sleep 25; done
[20:14:05] web-app-hpa   Deployment/web-app   cpu: <unknown>/50%   2     5     2     59s
[20:14:30] web-app-hpa   Deployment/web-app   cpu: <unknown>/50%   2     5     2     85s
[20:14:56] web-app-hpa   Deployment/web-app   cpu: 30%/50%   2     5     2     110s
[20:15:21] web-app-hpa   Deployment/web-app   cpu: 30%/50%   2     5     2     2m16s
[20:15:47] web-app-hpa   Deployment/web-app   cpu: 30%/50%   2     5     2     2m41s
[20:16:12] web-app-hpa   Deployment/web-app   cpu: 50%/50%   2     5     2     3m6s
```

_CPU per Pod and the Pods that exist now._

```console
$ kubectl top pods -n production-webapp --no-headers; kubectl get pods -n production-webapp -l app=web-app
load-generator            858m   5Mi    
web-app-d45775485-ddn27   52m    11Mi   
web-app-d45775485-hwbpd   49m    10Mi   
NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-ddn27   1/1     Running   0          2m49s
web-app-d45775485-hwbpd   1/1     Running   0          3m43s
```

**Observation:** with this single request loop the CPU of each Pod settles at about the target (the TARGETS column climbs to about 50% of the request, right at the 50% target), so the HPA does **not** scale out: REPLICAS stays at 2. The provided generator is just a little too gentle on this machine, so I add three more of them.

_**Stronger load:** three more copies of the same generator (four request loops in total)._

```console
$ for i in 2 3 4; do kubectl run load-generator-$i -n production-webapp --image=busybox:1.36 --restart=Never -- /bin/sh -c "while true; do wget -q -O- http://web-service; done"; done
pod/load-generator-2 created
pod/load-generator-3 created
pod/load-generator-4 created
```

_TARGETS rises clearly above 50% and REPLICAS follows: the autoscaler adds Pods (2 up to a maximum of 5)._

```console
$ for i in 1 2 3 4 5 6 7 8 9; do echo "[$(date +%T)] $(kubectl get hpa -n production-webapp --no-headers)"; sleep 25; done
[20:16:40] web-app-hpa   Deployment/web-app   cpu: 50%/50%   2     5     2     3m34s
[20:17:06] web-app-hpa   Deployment/web-app   cpu: 52%/50%   2     5     2     4m
[20:17:32] web-app-hpa   Deployment/web-app   cpu: 52%/50%   2     5     2     4m26s
[20:17:57] web-app-hpa   Deployment/web-app   cpu: 111%/50%   2     5     2     4m52s
[20:18:23] web-app-hpa   Deployment/web-app   cpu: 111%/50%   2     5     5     5m17s
[20:18:48] web-app-hpa   Deployment/web-app   cpu: 111%/50%   2     5     5     5m43s
[20:19:14] web-app-hpa   Deployment/web-app   cpu: 75%/50%   2     5     5     6m8s
[20:19:39] web-app-hpa   Deployment/web-app   cpu: 75%/50%   2     5     5     6m34s
[20:20:05] web-app-hpa   Deployment/web-app   cpu: 47%/50%   2     5     5     6m59s
```

_The extra Pods exist and share the load._

```console
$ kubectl get pods -n production-webapp -l app=web-app; kubectl top pods -n production-webapp --no-headers -l app=web-app
NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-89wzp   1/1     Running   0          2m39s
web-app-d45775485-8sn2n   1/1     Running   0          2m24s
web-app-d45775485-ddn27   1/1     Running   0          6m42s
web-app-d45775485-gzkt5   1/1     Running   0          2m39s
web-app-d45775485-hwbpd   1/1     Running   0          7m36s
web-app-d45775485-89wzp   47m   10Mi   
web-app-d45775485-8sn2n   46m   10Mi   
web-app-d45775485-ddn27   48m   10Mi   
web-app-d45775485-gzkt5   47m   10Mi   
web-app-d45775485-hwbpd   49m   10Mi   
```

_Stop all the load. The HPA events record why it scaled out (reason: cpu resource utilization above target). The scale-down after the stabilisation window was demonstrated in full in Task 2._

```console
$ kubectl delete pod load-generator load-generator-2 load-generator-3 load-generator-4 -n production-webapp --wait=false; kubectl describe hpa web-app-hpa -n production-webapp | sed -n "/^Events:/,\$p" | grep -v FailedGet | grep -v FailedCompute
pod "load-generator" deleted from production-webapp namespace
pod "load-generator-2" deleted from production-webapp namespace
pod "load-generator-3" deleted from production-webapp namespace
pod "load-generator-4" deleted from production-webapp namespace
Events:
  Type     Reason                        Age                    From                       Message
  ----     ------                        ----                   ----                       -------
  Normal   SuccessfulRescale             2m41s                  horizontal-pod-autoscaler  New size: 4; reason: cpu resource utilization (percentage of request) above target
  Normal   SuccessfulRescale             2m26s                  horizontal-pod-autoscaler  New size: 5; reason:
```

### Probe diagnostics (the bonus challenges)

| Probe | Question | On failure |
|---|---|---|
| Startup | Has the app finished starting? | restarts the container; other probes wait for it |
| Readiness | May the Pod receive traffic? | removes the Pod from the Service endpoints (no restart) |
| Liveness | Is the container still healthy? | the kubelet restarts the container |

**Challenge: readiness gating.** I point the readiness probe to a path that does not exist:

_The Pods are `Running` but **0/1 Ready**, and the Service has **no endpoints**: traffic is not sent to them, yet nothing is restarted._

```console
$ kubectl patch deployment web-app -n production-webapp --type=json -p "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/path\",\"value\":\"/does-not-exist\"}]" && sleep 45 && kubectl get pods -n production-webapp -l app=web-app && kubectl get endpoints web-service -n production-webapp 2>/dev/null
deployment.apps/web-app patched
NAME                       READY   STATUS    RESTARTS   AGE
web-app-5945bfc776-cjvb5   0/1     Running   0          43s
web-app-5945bfc776-jrmdx   0/1     Running   0          43s
web-app-5945bfc776-scrgk   0/1     Running   0          43s
web-app-5945bfc776-vf4cs   0/1     Running   0          43s
web-app-5945bfc776-x97zh   0/1     Running   0          43s
NAME          ENDPOINTS   AGE
web-service               8m25s
```

_The probe event: the readiness probe fails with HTTP status 404._

```console
$ kubectl get events -n production-webapp --sort-by=.lastTimestamp | grep -E "Readiness probe failed" | tail -n 2 | cut -c1-200
2s          Warning   Unhealthy                      pod/web-app-5945bfc776-cjvb5          Readiness probe failed: HTTP probe failed with statuscode: 404
2s          Warning   Unhealthy                      pod/web-app-5945bfc776-scrgk          Readiness probe failed: HTTP probe failed with statuscode: 404
```

**Challenge: liveness restart loop.** I restore readiness and break the liveness probe instead:

_With a liveness path that returns 404 the kubelet keeps killing the container: RESTARTS keeps increasing._

```console
$ kubectl patch deployment web-app -n production-webapp --type=json -p "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/readinessProbe/httpGet/path\",\"value\":\"/\"},{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/livenessProbe/httpGet/path\",\"value\":\"/crash\"}]" && sleep 75 && kubectl get pods -n production-webapp -l app=web-app
deployment.apps/web-app patched
NAME                      READY   STATUS             RESTARTS      AGE
web-app-85d86b65d-7mq6g   0/1     CrashLoopBackOff   3 (3s ago)    74s
web-app-85d86b65d-87vnn   0/1     CrashLoopBackOff   3 (8s ago)    74s
web-app-85d86b65d-9fkfv   0/1     CrashLoopBackOff   3 (8s ago)    74s
web-app-85d86b65d-mbnj6   0/1     CrashLoopBackOff   3 (8s ago)    74s
web-app-85d86b65d-xmq58   1/1     Running            3 (13s ago)   74s
```

_The events: "Liveness probe failed ... 404" followed by "Container nginx failed liveness probe, will be restarted"._

```console
$ kubectl get events -n production-webapp --sort-by=.lastTimestamp | grep -E "Liveness probe failed|failed liveness probe" | tail -n 4 | cut -c1-210
8s          Normal    Killing                        pod/web-app-85d86b65d-9fkfv           Container nginx failed liveness probe, will be restarted
4s          Warning   Unhealthy                      pod/web-app-85d86b65d-xmq58           Liveness probe failed: HTTP probe failed with statuscode: 404
3s          Normal    Killing                        pod/web-app-85d86b65d-7mq6g           Container nginx failed liveness probe, will be restarted
3s          Warning   Unhealthy                      pod/web-app-85d86b65d-7mq6g           Liveness probe failed: HTTP probe failed with statuscode: 404
```

_Fix: put the correct path back; the Pods become healthy again._

```console
$ kubectl patch deployment web-app -n production-webapp --type=json -p "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/containers/0/livenessProbe/httpGet/path\",\"value\":\"/\"}]" && kubectl rollout status deployment/web-app -n production-webapp --timeout=240s && kubectl get pods -n production-webapp
deployment.apps/web-app patched
Waiting for deployment "web-app" rollout to finish: 0 out of 5 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 5 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 5 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 5 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 5 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 5 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 out of 5 new replicas have been updated...
Waiting for deployment "web-app" rollout to finish: 0 of 5 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 1 of 5 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 2 of 5 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 3 of 5 updated replicas are available...
Waiting for deployment "web-app" rollout to finish: 4 of 5 updated replicas are available...
deployment "web-app" successfully rolled out
NAME                      READY   STATUS    RESTARTS   AGE
web-app-d45775485-26s4f   1/1     Running   0          11s
web-app-d45775485-4ltrp   1/1     Running   0          11s
web-app-d45775485-h9r7c   1/1     Running   0          11s
web-app-d45775485-n9q6z   1/1     Running   0          11s
web-app-d45775485-rrt6n   1/1     Running   0          11s
```

_Cleanup of the mini project._

```console
$ kubectl delete namespace production-webapp --wait=false
namespace "production-webapp" deleted
```

## Summary

| Requirement | Evidence |
|---|---|
| Persistent state | file written to `/data` survived deletion of the Pod |
| Elastic scaling | the HPA scales out when the load is heavy enough (the provided single generator stayed just under the 50% target; four generators pushed it over, see above) and scales back after the stabilisation window (Task 2) |
| Probes | readiness failure removed the Pod from the endpoints without a restart; liveness failure caused restarts |
| Service | nginx page served through `web-service` |
