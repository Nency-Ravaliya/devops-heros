# Kubernetes Troubleshooting Challenge - Mini Project Solution

**Author:** Shivansh Singh  
**Course:** SST DevOps & Cloud [SWE]  
**Session:** 14 Mini Project  

---

## 1. Project Scenario
The production environment deployed an NGINX web application stack consisting of a Deployment, a ClusterIP Service, and additional auxiliary Pods. Multiple anomalies were detected:
1. Pod image pull failures preventing container initialization.
2. Service selector mismatch leading to empty endpoints (`<none>`) and client timeouts.

---

## 2. Step-by-Step Triage & Resolution

### Step 2.1: Deploy Baseline Application
```bash
$ kubectl apply -f deployment.yaml
$ kubectl apply -f service.yaml

$ kubectl get pods -o wide
NAME                                   READY   STATUS    RESTARTS   AGE   IP            NODE
troubleshooting-app-7d6f54c96d-8x4pk   1/1     Running   0          45s   10.244.0.21   minikube
troubleshooting-app-7d6f54c96d-v2m9q   1/1     Running   0          45s   10.244.0.22   minikube
```

### Step 2.2: Triage of Broken Pod (`broken-pod.yaml`)
```bash
$ kubectl apply -f broken-pod.yaml
pod/project-broken-pod created

$ kubectl get pod project-broken-pod
NAME                 READY   STATUS             RESTARTS   AGE
project-broken-pod   0/1     ImagePullBackOff   0          25s
```

Inspection via `kubectl describe pod project-broken-pod`:
```bash
$ kubectl describe pod project-broken-pod
...
Events:
  Type     Reason     Age                From               Message
  ----     ------     ----               ----               -------
  Normal   Scheduled  45s                default-scheduler  Successfully assigned default/project-broken-pod to minikube
  Normal   Pulling    20s (x2 over 44s)  kubelet            Pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     18s (x2 over 42s)  kubelet            Failed to pull image "nginx:this-tag-does-not-exist": rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": not found
  Warning  Failed     18s (x2 over 42s)  kubelet            Error: ErrImagePull
  Normal   BackOff    5s (x3 over 41s)   kubelet            Back-off pulling image "nginx:this-tag-does-not-exist"
  Warning  Failed     5s (x3 over 41s)   kubelet            Error: ImagePullBackOff
```

#### Answers to Section 7 Task Questions:
- **Question 1 (Pod status):** `ImagePullBackOff` (initially `ErrImagePull`).
- **Question 2 (Actual error):** `rpc error: code = NotFound desc = failed to pull and unpack image "docker.io/library/nginx:this-tag-does-not-exist": not found`.
- **Question 3 (Command used):** `kubectl describe pod project-broken-pod` (inspected the `Events` section).
- **Question 4 (Image issue):** The image tag `this-tag-does-not-exist` does not exist on Docker Hub (`docker.io/library/nginx`).
- **Question 5 (Fix):** Correct image to a valid version tag such as `nginx:1.27` or `nginx:alpine` in `fixed-pod.yaml`.

```bash
$ kubectl apply -f fixed-pod.yaml
pod/project-broken-pod configured

$ kubectl get pod project-broken-pod
NAME                 READY   STATUS    RESTARTS   AGE
project-broken-pod   1/1     Running   0          14s
```

---

### Step 2.3: Service Selector Mismatch & Endpoint Triage
Simulating or investigating Service failure:
```bash
$ kubectl get service troubleshooting-service
NAME                      TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)   AGE
troubleshooting-service   ClusterIP   10.104.148.110   <none>        80/TCP    3m

$ kubectl get endpoints troubleshooting-service
NAME                      ENDPOINTS   AGE
troubleshooting-service   <none>      3m
```

#### Investigation:
```bash
$ kubectl get pods --show-labels
NAME                                   READY   STATUS    RESTARTS   AGE   LABELS
troubleshooting-app-7d6f54c96d-8x4pk   1/1     Running   0          4m    app=troubleshooting-app,pod-template-hash=7d6f54c96d
troubleshooting-app-7d6f54c96d-v2m9q   1/1     Running   0          4m    app=troubleshooting-app,pod-template-hash=7d6f54c96d

$ kubectl describe service troubleshooting-service | grep Selector
Selector:          app=wrong-app
```

#### Root Cause:
The service selector was searching for Pods with `app=wrong-app`, whereas the deployed Pods had the label `app=troubleshooting-app`. As a result, the Endpoint controller could not associate any Pod IPs with the Service.

#### Fix & Verification:
Applied `fixed-service.yaml` updating `selector.app: troubleshooting-app`:
```bash
$ kubectl apply -f fixed-service.yaml
service/troubleshooting-service configured

$ kubectl get endpoints troubleshooting-service
NAME                      ENDPOINTS                       AGE
troubleshooting-service   10.244.0.21:80,10.244.0.22:80   5m
```

---

## 3. Section 11: Troubleshooting Table

| Problem | What I Saw | Command I Used | Root Cause | Fix |
| :--- | :--- | :--- | :--- | :--- |
| **Broken Pod** | Status: `ImagePullBackOff` | `kubectl describe pod project-broken-pod` | Image tag `this-tag-does-not-exist` not found on registry | Updated image to `nginx:1.27` |
| **Service Problem**| `ENDPOINTS: <none>` | `kubectl describe service troubleshooting-service` & `kubectl get pods --show-labels` | Selector `app=wrong-app` did not match Pod label `app=troubleshooting-app` | Changed Service selector to `app=troubleshooting-app` |
| **Image Problem** | `rpc error: code = NotFound` in Events | `kubectl describe pod` | Typo in image repository / tag specification | Verified registry tag and reapplied valid manifest |

---

## 4. Section 12: README Answers to Questions

1. **What does `kubectl get` tell us?**  
   It provides a fast, high-level summary of resources (e.g. name, ready replicas, status, restart count, age).
2. **What is the difference between `get` and `describe`?**  
   `kubectl get` prints tabular high-level status; `kubectl describe` inspects deep runtime state, controller details, resource limits, mount points, and chronological cluster **Events**.
3. **Why do we use `kubectl logs`?**  
   To read standard output (`stdout`) and standard error (`stderr`) generated by the application process inside the container.
4. **When would you use `kubectl exec`?**  
   To enter a running container to test local network routing (e.g., `curl localhost`, `ping`), verify mounted filesystem contents, or test DNS resolution.
5. **What does `CrashLoopBackOff` mean?**  
   The container repeatedly starts, fails/exits with a non-zero code, and Kubernetes puts it into an exponential back-off delay before restarting.
6. **What does `ImagePullBackOff` mean?**  
   Kubernetes failed to download the container image (wrong image name/tag, private registry auth failure, or rate limit) and is waiting before retrying.
7. **Why can a Pod remain `Pending`?**  
   The Kubernetes Scheduler cannot find a node satisfying constraints (insufficient CPU/memory, node selector/affinity mismatch, or taints without tolerations).
8. **Why can a Service have no endpoints?**  
   Either no Pods are running, all Pods are failing readiness probes, or the Service `spec.selector` does not match the Pods' `metadata.labels`.
9. **What is the relationship between a Service selector and Pod labels?**  
   The Service controller queries Pods whose labels match the Service selector key-value pairs; matched Pod IPs are automatically populated into the Service's `Endpoints` / `EndpointSlice`.
10. **What is Kubernetes DNS?**  
    An internal cluster DNS service (CoreDNS) that resolves Kubernetes service names to their ClusterIPs (e.g. `service-name.namespace.svc.cluster.local`).