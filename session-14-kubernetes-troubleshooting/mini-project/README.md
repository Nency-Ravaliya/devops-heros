# Kubernetes Troubleshooting Challenge

**Name:** Durga Prasad  
**Enrollment Number:** 10012  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 14 - Kubernetes Troubleshooting  
**Repository:** devops-heros / session-14-kubernetes-troubleshooting / mini-project  

---

## Troubleshooting Methodology

```text
Deploy
  │
  ▼
Observe
  │
  ▼
Break
  │
  ▼
Investigate
  │
  ▼
Find root cause
  │
  ▼
Fix
  │
  ▼
Verify
```

---

## Project Scenario

You have a simple Nginx application running inside Kubernetes:
* **Deployment** (`deployment.yaml`): 2 replicas of `nginx:1.27` with label `app: troubleshooting-app`.
* **Service** (`service.yaml`): ClusterIP Service targeting port 80 with selector `app: troubleshooting-app`.
* **Broken Pod** (`broken-pod.yaml`): Diagnostic pod configured with an invalid image tag.

The goal is to deploy the baseline, observe healthy operations, systematically reproduce failures, investigate using the 5 core commands without guessing, resolve root causes, and verify recovery.

---

## 1. Deploy The Application

Apply deployment and service:
```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
```

**Live Cluster Output:**
```text
deployment.apps/troubleshooting-app created
service/troubleshooting-service created
```

Check resources:
```bash
kubectl get pods -l app=troubleshooting-app
kubectl get service troubleshooting-service
```

**Live Cluster Output:**
```text
NAME                                   READY   STATUS    RESTARTS   AGE
troubleshooting-app-59d4957864-s67v9   1/1     Running   0          25s
troubleshooting-app-59d4957864-sdc6r   1/1     Running   0          25s

NAME                      TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.100.252.71   <none>        80/TCP    25s
```

---

## 2. Check The Application

Check pods with IP and node allocations:
```bash
kubectl get pods -l app=troubleshooting-app -o wide
```

**Live Cluster Output:**
```text
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
troubleshooting-app-59d4957864-s67v9   1/1     Running   0          30s   10.244.0.57   minikube   <none>           <none>
troubleshooting-app-59d4957864-sdc6r   1/1     Running   0          30s   10.244.0.56   minikube   <none>           <none>
```

Describe pod:
```bash
kubectl describe pod troubleshooting-app-59d4957864-s67v9
```

Check application logs:
```bash
kubectl logs troubleshooting-app-59d4957864-s67v9
```

Execute inside container to test local connectivity:
```bash
kubectl exec -it troubleshooting-app-59d4957864-s67v9 -- curl -s localhost
```

**Live Cluster Output:**
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
</body>
</html>
```

---

## 3. Check The Service

Inspect the service configuration:
```bash
kubectl describe service troubleshooting-service
```

**Live Cluster Output:**
```text
Name:              troubleshooting-service
Namespace:         default
Labels:            <none>
Annotations:       <none>
Selector:          app=troubleshooting-app
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                10.100.252.71
IPs:               10.100.252.71
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         10.244.0.56:80,10.244.0.57:80
Session Affinity:  None
Events:            <none>
```

Key observations:
* **Selector:** `app=troubleshooting-app`
* **TargetPort:** `80/TCP`
* **Endpoints:** `10.244.0.56:80,10.244.0.57:80` (Both pod IPs are bound)

---

## 4. Check Endpoints

Inspect endpoints directly:
```bash
kubectl get endpoints troubleshooting-service
```

**Live Cluster Output:**
```text
NAME                      ENDPOINTS                       AGE
troubleshooting-service   10.244.0.56:80,10.244.0.57:80   45s
```

---

## 5. Create A Broken Pod

Apply the broken pod manifest:
```bash
kubectl apply -f broken-pod.yaml
```

**Live Cluster Output:**
```text
pod/project-broken-pod created
```

Check the pod status:
```bash
kubectl get pod project-broken-pod
```

**Live Cluster Output:**
```text
NAME                 READY   STATUS         RESTARTS   AGE
project-broken-pod   0/1     ErrImagePull   0          4s
```

After a few seconds:
```text
NAME                 READY   STATUS             RESTARTS   AGE
project-broken-pod   0/1     ImagePullBackOff   0          18s
```

---

## 6. Troubleshoot It (Without Modifying YAML First)

Inspect the pod using `describe` to identify what Kubernetes attempted:
```bash
kubectl describe pod project-broken-pod
```

**Live Cluster Output (Events Section):**
```text
Events:
  Type     Reason     Age   From               Message
  ----     ------     ----  ----               -------
  Normal   Scheduled  15s   default-scheduler  Successfully assigned default/project-broken-pod to minikube
  Normal   Pulling    15s   kubelet            spec.containers{app}: Pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     13s   kubelet            spec.containers{app}: Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": failed to resolve reference "docker.io/library/nginx:this-tag-does-not-exist": docker.io/library/nginx:this-tag-does-not-exist: not found
  Warning  Failed     13s   kubelet            spec.containers{app}: Error: ErrImagePull
  Normal   BackOff    12s   kubelet            spec.containers{app}: Back-off pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     12s   kubelet            spec.containers{app}: Error: ImagePullBackOff
```

---

## 7. Challenge Task 1: Broken Pod Analysis

**Question 1: What is the Pod status?**  
**Answer:** The pod is in `0/1 ErrImagePull`, quickly transitioning to `0/1 ImagePullBackOff`. The container is not ready and cannot start.

**Question 2: What is the actual error?**  
**Answer:** `rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": failed to resolve reference "docker.io/library/nginx:this-tag-does-not-exist": docker.io/library/nginx:this-tag-does-not-exist: not found`.

**Question 3: Which command helped you find the reason?**  
**Answer:** `kubectl describe pod project-broken-pod` (specifically the **Events** section at the bottom). Alternatively, `kubectl get events --field-selector involvedObject.name=project-broken-pod`.

**Question 4: What is wrong with the image?**  
**Answer:** The image tag `this-tag-does-not-exist` does not exist on the public container registry (`docker.io/library/nginx`). The registry returned an HTTP 404 NotFound error.

**Question 5: How would you fix it?**  
**Answer:** Edit `broken-pod.yaml` to specify a valid image tag (such as `nginx:1.27` or `nginx:latest`), delete the broken pod (`kubectl delete pod project-broken-pod`), and apply the updated manifest (`kubectl apply -f broken-pod.yaml`).

---

## 8. Service Troubleshooting Challenge

Intentionally break the Service selector:
```bash
kubectl set selector service troubleshooting-service app=wrong-app
```

Verify service and endpoints:
```bash
kubectl get service troubleshooting-service
kubectl get endpoints troubleshooting-service
```

**Live Cluster Output:**
```text
service/troubleshooting-service selector updated

NAME                      ENDPOINTS   AGE
troubleshooting-service   <none>      65s
```

Notice: Endpoints is now `<none>`! Traffic to the Service ClusterIP will now be dropped with connection timeout / refused.

---

## 9. Find The Root Cause & Fix It

Run command to inspect pod labels:
```bash
kubectl get pods -l app=troubleshooting-app --show-labels
```

**Live Cluster Output:**
```text
NAME                                   READY   STATUS    RESTARTS   AGE   LABELS
troubleshooting-app-59d4957864-s67v9   1/1     Running   0          70s   app=troubleshooting-app,pod-template-hash=59d4957864
troubleshooting-app-59d4957864-sdc6r   1/1     Running   0          70s   app=troubleshooting-app,pod-template-hash=59d4957864
```

Inspect service selector:
```bash
kubectl describe service troubleshooting-service | grep "Selector:"
```

**Live Cluster Output:**
```text
Selector:  app=wrong-app
```

**Diagnosis:**
* Pods have label: `app=troubleshooting-app`
* Service has selector: `app=wrong-app`
* Mismatch: No pods match `app=wrong-app`, resulting in empty endpoints.

**Fix:**
Update the selector back to match the pod labels:
```bash
kubectl set selector service troubleshooting-service app=troubleshooting-app
```

**Verify Fix:**
```bash
kubectl get endpoints troubleshooting-service
```

**Live Cluster Output:**
```text
NAME                      ENDPOINTS                       AGE
troubleshooting-service   10.244.0.56:80,10.244.0.57:80   85s
```
Both pod endpoints are immediately restored!

---

## 10. Final Troubleshooting Checklist

Before escalating or restarting workloads:
```bash
kubectl get pods
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- sh
kubectl get events
```

For Service & Networking issues:
```bash
kubectl describe service <service-name>
kubectl get endpoints <service-name>
kubectl exec <client-pod> -- nslookup <service-name>
kubectl exec <client-pod> -- wget -qO- http://<service-name>
```

---

## 11. Troubleshooting Table

| Problem | What I Saw | Command I Used | Root Cause | Fix |
| :--- | :--- | :--- | :--- | :--- |
| **Broken Pod** | Pod stuck in `0/1 ErrImagePull` / `ImagePullBackOff` | `kubectl describe pod project-broken-pod` | Image tag `nginx:this-tag-does-not-exist` does not exist on Docker Hub registry (NotFound) | Changed image to a valid tag `nginx:1.27`, recreated pod |
| **Service Problem** | Service endpoints showed `<none>`, service unreachable | `kubectl get endpoints troubleshooting-service` & `kubectl describe service troubleshooting-service` | Service selector was configured as `app: wrong-app`, which did not match Pod labels `app: troubleshooting-app` | Changed Service selector to `app: troubleshooting-app` to match Pod labels |
| **Image Problem** | Pod repeatedly failed to pull image with backoff events | `kubectl get events --sort-by=.lastTimestamp` | Non-existent repository/tag, typo in image URI, or missing `imagePullSecrets` for private registry | Verified image existence, fixed typo, or configured registry credentials |

---

## 12. README Questions & In-Depth Technical Answers

### 1. What does `kubectl get` tell us?
`kubectl get` provides a high-level tabular summary of the current state of Kubernetes resources in the cluster. It displays resource names, readiness status (`READY`), lifecycle phases (`STATUS` like Running, Pending, CrashLoopBackOff), restart count (`RESTARTS`), and resource creation age (`AGE`). With `-o wide`, it additionally shows internal Pod IPs, assigned worker nodes, nominated nodes, and readiness gates. It answers: *"What is currently happening in the cluster?"*

### 2. What is the difference between `get` and `describe`?
* `kubectl get`: Queries the API server and returns a concise, scannable table of one or many resources. It does not provide explanations or controller event logs.
* `kubectl describe`: Makes detailed API queries to assemble a comprehensive, multi-section inspection report of a specific resource. It reveals metadata (labels, annotations), container specifications, resource limits/requests, volume mounts, current lifecycle states, previous termination exit codes, readiness/liveness probe status, and critically, the **Events** log generated by the kube-scheduler, kubelet, and controllers. It answers: *"Why is the resource in its current state?"*

### 3. Why do we use `kubectl logs`?
We use `kubectl logs` to access the application-level standard output (`stdout`) and standard error (`stderr`) streams emitted by processes running inside containerized applications. While Kubernetes API objects only track container lifecycle events (e.g. exit codes, restarts), `kubectl logs` exposes application stack traces, runtime exceptions, uncaught database connectivity errors, and HTTP server access logs. It answers: *"What is the application code itself complaining about?"*

### 4. When would you use `kubectl exec`?
You use `kubectl exec` when you need to execute ad-hoc commands or start an interactive shell (`-it -- sh/bash`) directly inside an active container environment. Key use cases include:
* Validating network connectivity and DNS resolution from within the pod network namespace (`curl localhost`, `nslookup <service>`, `ping <ip>`).
* Inspecting container file system state, configuration files, and dynamically mounted secrets or configmaps (`cat /etc/nginx/nginx.conf`).
* Checking runtime environment variables (`env`).
* Verifying local Unix socket or port bindings (`netstat -tulpn` or `ss`).

### 5. What does `CrashLoopBackOff` mean?
`CrashLoopBackOff` is a Kubernetes container state where a container continuously starts, crashes or exits unexpectedly, and is restarted by the `kubelet` in an automated loop. To prevent a crashing application from overwhelming the host node CPU and Docker/containerd daemon, Kubernetes enforces an exponential backoff delay between restarts (10s, 20s, 40s, 80s... up to a maximum cap of 300 seconds / 5 minutes). Common root causes include application errors (exit code != 0), missing required environment variables, configuration syntax errors, failed database connections, or failing liveness probes.

### 6. What does `ImagePullBackOff` mean?
`ImagePullBackOff` indicates that Kubernetes attempted to pull a container image from a container registry via the node's Container Runtime Interface (CRI), failed, and is now waiting with exponential backoff before retrying. The initial failure status is `ErrImagePull`, followed by `ImagePullBackOff`. Root causes include:
* Non-existent image tag or typo in the image name.
* Repository does not exist.
* The image registry requires authentication, and no `imagePullSecrets` were configured in the PodSpec.
* Node network failure or registry rate limiting (e.g., Docker Hub rate limits).

### 7. Why can a Pod remain `Pending`?
A Pod remains in `Pending` state when it has been accepted by the Kubernetes API server, but cannot be scheduled onto any node or cannot begin starting containers. Key reasons include:
* **Resource Exhaustion:** Nodes do not have sufficient unreserved CPU or Memory requests to satisfy the Pod's `resources.requests`.
* **NodeSelector / Affinity Mismatch:** The Pod specifies a `nodeSelector` or `nodeAffinity` label that matches 0 nodes in the cluster.
* **Taints and Tolerations:** All available nodes have taints (e.g. `node-role.kubernetes.io/control-plane:NoSchedule`) that the Pod does not tolerate.
* **Storage Dependencies:** The Pod requests a PersistentVolumeClaim (PVC) that is not yet bound to any PersistentVolume (PV).

### 8. Why can a Service have no endpoints?
A Service will show `<none>` under `ENDPOINTS` when:
* **Selector Mismatch:** The key-value pairs specified in `service.spec.selector` do not match the `metadata.labels` on any Pod in that namespace.
* **Pods Not Ready:** Matching Pods exist, but none of them are passing their configured `readinessProbe` (unready pods are excluded from service endpoints).
* **Zero Replicas:** The backing Deployment or ReplicaSet is scaled to 0 replicas.
* **Namespace Isolation:** The target Pods are deployed in a different namespace than the Service.
* **Headless / ExternalName:** The service is defined without a selector or is of type `ExternalName`.

### 9. What is the relationship between a Service selector and Pod labels?
Kubernetes uses loose coupling via **Label Selectors**:
1. Pods declare key-value labels in `metadata.labels` (e.g. `app: troubleshooting-app`).
2. Services define matching criteria in `spec.selector` (e.g. `app: troubleshooting-app`).
3. The Kubernetes Endpoints / EndpointSlice controller constantly watches for Pods whose labels match the Service selector.
4. When a matching Pod becomes `Ready`, its pod IP address and port are dynamically added to the Service's Endpoints object.
5. `kube-proxy` writes routing rules (via `iptables` or `IPVS`) so that traffic addressed to the Service's virtual `ClusterIP` is load balanced across the endpoints.

### 10. What is Kubernetes DNS?
Kubernetes DNS is an internal cluster DNS service (typically implemented via **CoreDNS**) deployed as a set of pods in the `kube-system` namespace. It automatically creates DNS `A/AAAA` and `SRV` records for every Service created in the cluster following the Fully Qualified Domain Name (FQDN) standard:
```text
<service-name>.<namespace>.svc.cluster.local
```
This enables decoupled service discovery: client pods can simply communicate with `http://troubleshooting-service` or `http://troubleshooting-service.default.svc.cluster.local` without needing to discover or hardcode dynamic, ephemeral Pod IP addresses.

---

## 13. Final Architecture

```text
                    Kubernetes Cluster (Minikube)
                                 │
                                 ▼
                     ┌───────────────────────┐
                     │ troubleshooting-service│
                     │  ClusterIP: 10.100.x  │
                     │        Port: 80       │
                     └───────────┬───────────┘
                                 │
                          Service Selector
                     [app: troubleshooting-app]
                                 │
                  ┌──────────────┴──────────────┐
                  │                             │
                  ▼                             ▼
        ┌───────────────────┐         ┌───────────────────┐
        │       Pod 1       │         │       Pod 2       │
        │ IP: 10.244.0.56   │         │ IP: 10.244.0.57   │
        │ Port: 80          │         │ Port: 80          │
        │ [nginx:1.27]      │         │ [nginx:1.27]      │
        └───────────────────┘         └───────────────────┘
```

---

## 14. Golden Troubleshooting Rule

```text
GET
 │
 ▼
DESCRIBE
 │
 ▼
EVENTS
 │
 ▼
LOGS
 │
 ▼
EXEC
 │
 ▼
TEST
 │
 ▼
FIX
 │
 ▼
VERIFY
```

When an issue arises: **DO NOT GUESS.** Inspect the status, check the events, read the logs, verify connectivity from inside the cluster, diagnose the root cause, apply the fix, and verify resolution.
