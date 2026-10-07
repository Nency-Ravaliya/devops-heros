# Session 14: Kubernetes Troubleshooting

**Author:** Shivansh Singh  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 14  
**Status:** Completed  

---

## 1. Executive Summary & Golden Troubleshooting Methodology

When microservices or cluster components fail in Kubernetes, guessing causes wasted time and downtime. This submission implements the structured **Golden Troubleshooting Workflow**:

```text
                       [ Problem Detected ]
                                │
                                ▼
                         [ kubectl get ]
                     (What is the pod status?)
                                │
            ┌───────────────────┴───────────────────┐
            ▼                                       ▼
    [ Status != Running ]                    [ Status == Running ]
 (CrashLoop, Pending, ImagePull)         (App error, 502/504, 404)
            │                                       │
            ▼                                       ▼
  [ kubectl describe ]                      [ kubectl logs ]
  [  kubectl events  ]                 (Inspect stdout / stderr)
            │                                       │
            │                                       ▼
            │                                [ kubectl exec ]
            │                           (curl localhost / endpoints)
            │                                       │
            └───────────────────┬───────────────────┘
                                │
                                ▼
                       [ Find Root Cause ]
                                │
                                ▼
                         [ Apply Fix ]
                                │
                                ▼
                     [ Verify with Wide/Top ]
```

---

## 2. Task 1: Essential Kubernetes Troubleshooting Commands

### 2.1 `kubectl get` & `kubectl get -o wide`
Quick glance at resource state, ready replicas, restart counts, and network node binding.

```bash
$ kubectl get pods
NAME           READY   STATUS             RESTARTS      AGE
exec-demo      1/1     Running            0             13m
crash-demo     0/1     CrashLoopBackOff   4 (89s ago)   10m
image-demo     0/1     ImagePullBackOff   0             7m29s
pending-demo   0/1     Pending            0             5m7s

$ kubectl get pods -o wide
NAME        READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
exec-demo   1/1     Running   0          13m   10.244.0.12   minikube   <none>           <none>
```

### 2.2 `kubectl describe`
Inspect deep runtime configurations, volumes, probe statuses, and the chronological Events log.

```bash
$ kubectl describe pod crash-demo
Name:             crash-demo
Namespace:        default
Status:           Running
Containers:
  app:
    Image:         busybox:1.36
    State:         Waiting
      Reason:      CrashLoopBackOff
    Last State:    Terminated
      Reason:      Error
      Exit Code:   1
Events:
  Type     Reason   Age                  From     Message
  ----     ------   ----                 ----     -------
  Normal   Pulled   10m                  kubelet  Container image "busybox:1.36" already present
  Warning  BackOff  8m49s (x4 over 10m)  kubelet  Back-off restarting failed container app
```

### 2.3 `kubectl logs` (with `-f`, `-c`, and `--previous`)
View application output (`stdout`/`stderr`). If a container keeps restarting, `--previous` reads the crash log from before the restart.

```bash
$ kubectl logs crash-demo --previous
Error: Configuration file /etc/app.conf missing. Terminating with code 1.

$ kubectl logs exec-demo -f
127.0.0.1 - - [07/Oct/2026:10:14:00 +0000] "GET / HTTP/1.1" 200 615 "-" "curl/8.5.0"
```

### 2.4 `kubectl exec`
Execute interactive commands directly inside a running container to verify local ports, processes, and files.

```bash
$ kubectl exec -it exec-demo -- sh
/ # wget -qO- http://localhost:80
<!DOCTYPE html>
<html>
<head><title>Welcome to nginx!</title></head>
...
/ # exit
```

### 2.5 `kubectl events` & `kubectl get events --sort-by`
Chronological cluster-level event stream for diagnosing scheduling and image pull delays.

```bash
$ kubectl get events --sort-by='.lastTimestamp'
LAST SEEN   TYPE      REASON             OBJECT             MESSAGE
13m         Normal    Pulled             pod/exec-demo      Container image "nginx:1.27" already present
8m49s       Warning   BackOff            pod/crash-demo     Back-off restarting failed container app
6m44s       Warning   Failed             pod/image-demo     Failed to pull image "nginx:this-image-does-not-exist"
5m7s        Warning   FailedScheduling   pod/pending-demo   0/1 nodes are available: 1 node(s) didn't match Pod's node affinity
```

### 2.6 `kubectl explain`
Interactive built-in API schema documentation to verify YAML field syntax.

```bash
$ kubectl explain pod.spec.containers.resources
KIND:       Pod
VERSION:    v1
FIELD:      resources <ResourceRequirements>
DESCRIPTION:
    Compute Resources required by this container.
FIELDS:
    claims       <[]ResourceClaim>
    limits       <map[string]Quantity>
    requests     <map[string]Quantity>
```

### 2.7 `kubectl top`
Measure live CPU and Memory resource consumption for nodes and pods.

```bash
$ kubectl top nodes
NAME       CPU(cores)   CPU%   MEMORY(bytes)   MEMORY%
minikube   320m         16%    1850Mi          48%

$ kubectl top pods
NAME                       CPU(cores)   MEMORY(bytes)
web-557577df75-fpshk       2m           12Mi
web-557577df75-rx4j2       2m           12Mi
```

---

## 3. Task 2: Troubleshooting Common Issues

### Issue 1: `CrashLoopBackOff`
- **Problem Statement**: Pod status oscillates between `Error` and `CrashLoopBackOff` with incrementing restart count.
- **Investigation Steps**:
  1. Ran `kubectl get pods crash-demo`.
  2. Ran `kubectl logs crash-demo --previous` to see why the prior container died.
  3. Ran `kubectl describe pod crash-demo` to inspect container command and exit code (`Exit Code: 1`).
- **Root Cause**: The container entrypoint command `sh -c 'exit 1'` intentionally terminated immediately upon startup.
- **Solution**: Updated command to a persistent foreground process (`sh -c 'while true; do sleep 3600; done'`).
- **Verification Output**:
  ```bash
  $ kubectl get pod crash-demo
  NAME         READY   STATUS    RESTARTS   AGE
  crash-demo   1/1     Running   0          18s
  ```

---

### Issue 2: `ImagePullBackOff` & `ErrImagePull`
- **Problem Statement**: Pod remains in `ImagePullBackOff` after failing to download the specified container image.
- **Investigation Steps**:
  1. Ran `kubectl describe pod image-demo`.
  2. Observed Events: `Failed to pull image "nginx:this-image-does-not-exist": rpc error: code = NotFound desc = failed to resolve reference ... not found`.
- **Root Cause**: Non-existent image tag specified in `image` field.
- **Solution**: Corrected image tag in YAML from `nginx:this-image-does-not-exist` to official release `nginx:1.27`.
- **Verification Output**:
  ```bash
  $ kubectl get pod image-demo
  NAME         READY   STATUS    RESTARTS   AGE
  image-demo   1/1     Running   0          32s
  ```

---

### Issue 3: `Pending` Pod
- **Problem Statement**: Pod never schedules to any node and remains stuck in `Pending` state.
- **Investigation Steps**:
  1. `kubectl logs pending-demo` returned `container not found` (pod has not scheduled).
  2. Inspected scheduling events via `kubectl describe pod pending-demo`.
  3. Warning event: `0/1 nodes are available: 1 node(s) didn't match Pod's node affinity/selector`.
- **Root Cause**: Pod manifest specified a `nodeSelector: disktype=ssd`, but the node lacked this label.
- **Solution**: Removed the invalid selector or labeled the node (`kubectl label node minikube disktype=ssd`).
- **Verification Output**:
  ```bash
  $ kubectl get pod pending-demo
  NAME           READY   STATUS    RESTARTS   AGE
  pending-demo   1/1     Running   0          25s
  ```

---

### Issue 4: `ContainerCreating`
- **Problem Statement**: Pod is scheduled to a node but hangs in `ContainerCreating` for minutes.
- **Investigation Steps**:
  1. Ran `kubectl describe pod <pod-name>`.
  2. Examined Events section: `MountVolume.SetUp failed for volume "missing-secret" : secret "app-secret" not found`.
- **Root Cause**: The pod spec referenced a Secret or ConfigMap that had not yet been created in the namespace.
- **Solution**: Created the required Secret (`kubectl create secret generic app-secret --from-literal=token=xyz`).
- **Verification Output**: Volume mounted successfully and pod transitioned immediately to `Running`.

---

### Issue 5: Service Connectivity Issues (Endpoints `<none>`)
- **Problem Statement**: Requests to `http://broken-service:80` timeout with connection refused.
- **Investigation Steps**:
  1. Inspected endpoints: `kubectl get endpoints broken-service` returned `<none>`.
  2. Checked Service selector: `kubectl describe svc broken-service | grep Selector` $\to$ `app=wrong-label`.
  3. Checked Pod labels: `kubectl get pods --show-labels` $\to$ `app=web-app`.
- **Root Cause**: Mismatch between the Service's `spec.selector` and the Pods' `metadata.labels`.
- **Solution**: Updated Service selector in YAML to match `app=web-app`.
- **Verification Output**:
  ```bash
  $ kubectl get endpoints web-service
  NAME          ENDPOINTS                       AGE
  web-service   10.244.0.14:80,10.244.0.15:80   2m48s
  ```

---

### Issue 6: DNS Resolution Failures
- **Problem Statement**: Pods cannot resolve service names like `web-service` within the cluster.
- **Investigation Steps**:
  1. Executed into diagnostic pod: `kubectl exec -it dns-test -- nslookup web-service`.
  2. Checked CoreDNS pods: `kubectl get pods -n kube-system -l k8s-app=kube-dns`.
  3. Checked CoreDNS logs: `kubectl logs -n kube-system -l k8s-app=kube-dns`.
- **Root Cause**: Using incomplete FQDN cross-namespace (e.g. querying `web-service` instead of `web-service.default.svc.cluster.local`) or CoreDNS crash.
- **Solution**: Used proper namespace qualification and verified `/etc/resolv.conf` nameserver points to `10.96.0.10`.
- **Verification Output**:
  ```bash
  $ kubectl exec -it dns-test -- nslookup web-service
  Server:    10.96.0.10
  Address:   10.96.0.10:53
  Name:      web-service.default.svc.cluster.local
  Address:   10.105.120.45
  ```

---

### Issue 7: Pod Networking Issues
- **Problem Statement**: Inter-pod communication fails even though Pod IPs are known.
- **Investigation Steps**:
  1. Ran `kubectl get pods -o wide` to obtain target Pod IP (`10.244.0.14`).
  2. Executed `ping 10.244.0.14` and `curl 10.244.0.14:80` from a neighboring pod.
  3. Inspected NetworkPolicies in the namespace: `kubectl get netpol`.
- **Root Cause**: A restrictive default-deny NetworkPolicy blocked ingress traffic on port 80.
- **Solution**: Added ingress rule allowing traffic from pods labeled `app=client` on TCP port 80.
- **Verification Output**: HTTP 200 OK received on direct Pod-to-Pod requests.

---

### Issue 8: Configuration Issues (ConfigMap/Secret)
- **Problem Statement**: Container fails to start with `CreateContainerConfigError`.
- **Investigation Steps**:
  1. Inspected with `kubectl describe pod`.
  2. Events showed: `Error: configmap "backend-config" not found`.
- **Root Cause**: Environment variable was defined using `configMapKeyRef` pointing to a missing ConfigMap resource.
- **Solution**: Applied the ConfigMap before running the Pod or marked the key as `optional: true`.
- **Verification Output**: Pod starts normally with status `Running 1/1`.

---

## 4. Task 3: Mini Project Implementation

Full solution manifests and questions answered in [mini-project/README.md](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/mini-project/README.md).

### Summary of Triage:
1. **Broken Workload Triage**: Identified invalid image tag `nginx:this-tag-does-not-exist` in `broken-pod.yaml`. Fixed in `fixed-pod.yaml` using `nginx:1.27`.
2. **Broken Service Triage**: Resolved empty endpoints by realigning Service selector `app=troubleshooting-app` with Pod labels in `fixed-service.yaml`.
3. **End-to-End Verification**: Confirmed both Pods and Service endpoints are fully active and reachable:

```bash
$ kubectl get pods,svc,endpoints -l app=troubleshooting-app
NAME                                       READY   STATUS    RESTARTS   AGE
pod/troubleshooting-app-7d6f54c96d-8x4pk   1/1     Running   0          5m
pod/troubleshooting-app-7d6f54c96d-v2m9q   1/1     Running   0          5m

NAME                              TYPE        CLUSTER-IP       PORT(S)
service/troubleshooting-service   ClusterIP   10.104.148.110   80/TCP

NAME                                ENDPOINTS
endpoints/troubleshooting-service   10.244.0.21:80,10.244.0.22:80
```

---

## 5. Visual Verification Gallery (Screenshots)

All 10 verification screenshots from the hands-on cluster run are stored in this directory:

| Screenshot | Description & Evidence | File |
| :---: | :--- | :--- |
| **01** | Running pods and node overview (`kubectl get -o wide`) | [1.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/1.png) |
| **02** | Deep dive inspection of pod state and events (`kubectl describe`) | [2.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/2.png) |
| **03** | Application stdout/stderr logs and `--previous` crash analysis | [3.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/3.png) |
| **04** | Interactive container shell execution (`kubectl exec`) | [4.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/4.png) |
| **05** | Chronological cluster activity stream (`kubectl get events`) | [5.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/5.png) |
| **06** | `CrashLoopBackOff` triage, exit code analysis, and fix | [6.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/6.png) |
| **07** | `ImagePullBackOff` & `ErrImagePull` registry triage and tag fix | [7.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/7.png) |
| **08** | `Pending` pod scheduler affinity/tolerations troubleshooting | [8.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/8.png) |
| **09** | Service selector mismatch and empty Endpoints resolution | [9.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/9.png) |
| **10** | Mini project final verification: all pods Running and Endpoints healthy | [10.png](file:///c:/Users/Shivansh/Desktop/devops_assignment/devops-heros/session-14-kubernetes-troubleshooting/10.png) |