# Session 14: Kubernetes Troubleshooting

| | |
|---|---|
| **Name** | Ankita Tripathi |
| **Roll Number** | 24bcs10062 |
| **Session** | 14 – Kubernetes Troubleshooting |

---

## Table of Contents

1. [Objective](#objective)
2. [Troubleshooting Methodology](#troubleshooting-methodology)
3. [Task 1: Troubleshooting Commands](#task-1-troubleshooting-commands)
4. [Task 2: Troubleshoot Common Issues](#task-2-troubleshoot-common-issues)
5. [Task 3: Mini Project](#task-3-mini-project)
6. [Troubleshooting Cheat Sheet](#troubleshooting-cheat-sheet)
7. [Before / After Summary](#before--after-summary)
8. [Review Questions](#review-questions)
9. [Key Learnings and Conclusion](#key-learnings-and-conclusion)
10. [Cleanup](#cleanup)
11. [Deliverables Checklist](#deliverables-checklist)

---

## Objective

The objective of this session was to practice Kubernetes troubleshooting with the important `kubectl` commands, and to diagnose, fix and verify common problems: container crashes, image pull failures, scheduling problems, Service connectivity issues, DNS, Pod networking and configuration errors.

---

## Troubleshooting Methodology

Every issue in this session was investigated with the same evidence-based workflow instead of guessing:

```text
GET → DESCRIBE → EVENTS → LOGS → EXEC → TEST → FIX → VERIFY
```

| Step | Question it answers | Command |
|---|---|---|
| GET | What is failing and in what state? | `kubectl get pods` |
| DESCRIBE | What does Kubernetes know about it? | `kubectl describe pod <name>` |
| EVENTS | What happened, and in what order? | `kubectl events --for pod/<name>` |
| LOGS | What did the application report? | `kubectl logs <name> [--previous]` |
| EXEC | What does it look like from inside? | `kubectl exec -it <name> -- sh` |
| TEST | Can components reach each other? | `nslookup`, `curl` from a test Pod |
| FIX | Correct the **root cause**, not the symptom | edit manifest → `kubectl apply` |
| VERIFY | Is it really fixed? | re-run `get`, `logs`, `curl` |

For every issue in Task 2 the same six steps were documented: **identify → investigate → root cause → fix → verify → document**.

---

# Task 1: Troubleshooting Commands

Hands-on practice with every important inspection command.

## 1.1 `kubectl get`

```bash
kubectl get pods
kubectl get pods --show-labels
kubectl get nodes
```

**Purpose:** quick overview of resources. For Pods it shows `READY`, `STATUS`, `RESTARTS` and `AGE`.

**Observation:** the application Pods were listed as

```text
troubleshooting-app-5b97965b56-b2bbb   1/1   Running
troubleshooting-app-5b97965b56-cpwb4   1/1   Running
```

A `READY` value of `0/1`, a `STATUS` other than `Running` or a rising `RESTARTS` count marks the Pod to investigate. `--show-labels` shows the Pod labels that Service selectors must match.

## 1.2 `kubectl describe`

```bash
kubectl describe pod <pod-name>
```

**Purpose:** detailed view of one resource: image, container state, conditions, node, restart count and the **Events** section.

**Observation:** the key fields are `State`, `Last State`, `Reason`, `Exit Code`, `Restart Count` and the Events at the bottom, which explain *why* a Pod is in its current state.

## 1.3 `kubectl logs`

```bash
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
kubectl logs <pod-name> --tail=20
```

**Purpose:** shows the application's own output, which exposes crashes, startup errors and configuration problems.

**Observation:** `--previous` shows the output of the container that crashed before the latest restart, which is essential for `CrashLoopBackOff`.

## 1.4 `kubectl exec`

```bash
kubectl exec -it <pod-name> -- bash        # or sh
kubectl exec <pod-name> -- env
kubectl exec <pod-name> -- cat /etc/resolv.conf
```

**Purpose:** run commands inside a running container to inspect files, environment variables and connectivity.

**Observation:** inside an application Pod, `curl localhost` returned the Nginx `Welcome to nginx!` page, confirming the container serves HTTP.

## 1.5 `kubectl events`

```bash
kubectl events
kubectl events --for pod/<pod-name>
kubectl get events --sort-by=.lastTimestamp
```

**Purpose:** a timeline of cluster actions: scheduling, image pulls, container starts, restarts and failures.

**Observation:** events to watch for are `FailedScheduling`, `Failed` / `ErrImagePull`, `BackOff` and `FailedMount`. Each one maps to a specific class of problem diagnosed in Task 2.

## 1.6 `kubectl explain`

```bash
kubectl explain pod
kubectl explain pod.spec.nodeSelector
kubectl explain service.spec.selector
kubectl explain service.spec.ports.targetPort
```

**Purpose:** built-in documentation for any manifest field.

**Observation:** the nested examples above are exactly the fields behind the Pending, Service selector and `targetPort` problems troubleshot later in this session.

## 1.7 `kubectl top`

```bash
kubectl top nodes
kubectl top pods
kubectl top pods --containers
```

**Purpose:** current CPU and memory usage per node, Pod and container, used to spot resource pressure. (It relies on metrics-server.)

## 1.8 `kubectl get -o wide`

```bash
kubectl get pods -o wide
```

**Purpose:** adds the **IP**, **NODE**, **NOMINATED NODE** and **READINESS GATES** columns.

**Observation:** the application Pods had the IPs `10.244.0.19` and `10.244.0.20`. The Pod IP is used for direct networking tests, and the node name for scheduling problems.

## Task 1 Result

| Command | Best used for |
|---|---|
| `get` | First look; spotting a bad status |
| `describe` | Kubernetes-level root cause; Events |
| `events` | Timeline of scheduling / pull / restart failures |
| `logs` / `logs --previous` | Application-level root cause |
| `exec` | Testing from inside a Pod |
| `explain` | Understanding a manifest field |
| `top` | Resource pressure |
| `get -o wide` | Pod IP and node placement |

---

# Task 2: Troubleshoot Common Issues

> The YAML snippets show the essential change only; the complete manifests are in the repository.

---

## 2.1 CrashLoopBackOff

### Problem statement
The Pod `crash-demo` repeatedly started, failed and was restarted until Kubernetes placed it in `CrashLoopBackOff`.

### Investigation

```bash
kubectl apply -f broken-pod.yaml
kubectl get pod crash-demo
kubectl describe pod crash-demo
kubectl events --for pod/crash-demo
kubectl logs crash-demo
kubectl logs crash-demo --previous
```

The logs showed:

```text
Application starting...
Something went wrong!
```

`describe` showed `Last State: Terminated`, `Reason: Error`, `Exit Code: 1`, an increasing `Restart Count`, and the event `Back-off restarting failed container`.

### Root cause
The container command deliberately ended with `exit 1`, so the process failed on every start. Kubernetes restarted it with an increasing delay, producing `CrashLoopBackOff`. The status is only a symptom; the logs and exit code show the cause.

| Exit code | Usual meaning |
|---|---|
| 1 | Application error (this case) |
| 127 | Command not found |
| 137 | Killed (SIGKILL), often OOMKilled |
| 143 | Terminated (SIGTERM) |

### Fix

```diff
 command: ["sh", "-c"]
-args: ["echo 'Application starting...'; echo 'Something went wrong!'; exit 1"]
+args: ["echo 'Application starting...'; echo 'Application running'; sleep 3600"]
```

```bash
kubectl delete pod crash-demo
kubectl apply -f fixed-pod.yaml
kubectl get pod crash-demo
kubectl logs crash-demo
```

### Verification
The Pod reached `Running`, stopped restarting, and its logs showed a healthy application.

| Before | After |
|---|---|
| `crash-demo   0/1   CrashLoopBackOff` | `crash-demo   1/1   Running` |

**Result: resolved.**

---

## 2.2 ErrImagePull and ImagePullBackOff

### Problem statement
The Pod `image-demo` could not start because its container image could not be pulled.

### Investigation

```bash
kubectl apply -f broken-pod.yaml
kubectl get pod image-demo
kubectl describe pod image-demo
kubectl events --for pod/image-demo
```

The status first showed `ErrImagePull` and later `ImagePullBackOff`. The Events contained `Failed to pull image "nginx:this-image-does-not-exist"` with a "not found" style message.

### Root cause
The manifest referenced a tag that does not exist. `ErrImagePull` is the failed pull attempt; `ImagePullBackOff` means Kubernetes is waiting before retrying.

### Fix

```diff
-image: nginx:this-image-does-not-exist
+image: nginx:1.27
```

```bash
kubectl delete pod image-demo
kubectl apply -f fixed-pod.yaml
kubectl get pod image-demo
```

### Verification
The image was pulled and the Pod is `Running`.

| Before | After |
|---|---|
| `image-demo   0/1   ErrImagePull` → `ImagePullBackOff` | `image-demo   1/1   Running` |

**Result: resolved.**

---

## 2.3 Pending Pod

### Problem statement
The Pod `pending-demo` stayed in `Pending` and was never scheduled.

### Investigation

```bash
kubectl apply -f broken-pod.yaml
kubectl get pod pending-demo
kubectl describe pod pending-demo
kubectl events --for pod/pending-demo
kubectl get nodes --show-labels
```

The cluster node was `Ready`, so capacity was not the problem. The Events showed a `FailedScheduling` message stating that no node matched the Pod's node selector.

### Root cause

```yaml
nodeSelector:
  kubernetes.io/hostname: node-that-does-not-exist
```

The Pod requested a node that does not exist, so the scheduler had nowhere to place it. (`nodeSelector` cannot be edited on an existing Pod, so the Pod must be deleted and recreated.)

### Fix

```diff
-nodeSelector:
-  kubernetes.io/hostname: node-that-does-not-exist
```

(Removing it lets the scheduler choose a node; alternatively use the real hostname shown by `kubectl get nodes`.)

```bash
kubectl delete pod pending-demo
kubectl apply -f fixed-pod.yaml
kubectl get pod pending-demo
```

### Verification

| Before | After |
|---|---|
| `pending-demo   0/1   Pending` | `pending-demo   1/1   Running` |

**Result: resolved.**

---

## 2.4 ContainerCreating

`ContainerCreating` is not an error by itself: it is the normal stage where Kubernetes pulls the image, configures networking and mounts volumes. It becomes a problem only when it does not finish, so both situations were covered.

### Part A: normal, transient state
While creating the DNS test Pod the status briefly showed `dns-test   0/1   ContainerCreating` and then moved to `1/1 Running` without any change.

### Part B: stuck ContainerCreating

**Problem statement:** a Pod mounts a ConfigMap that does not exist and never leaves `ContainerCreating`.

```yaml
# configmap-demo.yaml
apiVersion: v1
kind: Pod
metadata:
  name: configmap-demo
spec:
  containers:
    - name: app
      image: nginx:1.27
      volumeMounts:
        - name: config-volume
          mountPath: /etc/app-config
  volumes:
    - name: config-volume
      configMap:
        name: app-config        # does not exist yet
```

**Investigation**

```bash
kubectl apply -f configmap-demo.yaml
kubectl get pod configmap-demo
kubectl describe pod configmap-demo
kubectl events --for pod/configmap-demo
```

The Pod stayed in `ContainerCreating`. `kubectl logs` has nothing to show because the container never started, so Events are the right tool: they report a `FailedMount` event with `configmap "app-config" not found`.

**Root cause:** the Pod references the ConfigMap `app-config`, which had not been created, so the volume could not be mounted.

**Fix**

```bash
kubectl create configmap app-config --from-literal=APP_MODE=production
kubectl get pod configmap-demo -w
```

The kubelet retries the mount automatically, so the Pod does not need to be recreated.

**Verification**

| Before | After |
|---|---|
| `configmap-demo   0/1   ContainerCreating` | `configmap-demo   1/1   Running` |

**Result: resolved.**

---

## 2.5 Service Connectivity Issue

### Problem statement
The Service `web-service` existed but had no endpoints, so it could not route traffic to any Pod.

### Investigation

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods --show-labels
kubectl describe service web-service
kubectl get endpoints web-service
```

```text
NAME          ENDPOINTS
web-service   <none>
```

> On newer Kubernetes versions `kubectl get endpointslices` is the modern equivalent of `kubectl get endpoints`.

### Root cause
The Pods were labelled `app: web`, but the Service selector did not match this label. A Service creates endpoints only for Pods whose labels match its selector.

### Fix

```yaml
selector:
  app: web
```

```bash
kubectl apply -f service.yaml
kubectl get endpoints web-service
```

### Verification

| Before | After |
|---|---|
| `web-service   <none>` | `web-service   10.244.0.32:80,10.244.0.33:80` |

Both application Pod IPs now appear as endpoints.

**Result: resolved.**

---

## 2.6 DNS Troubleshooting

### Problem statement
Verify that Kubernetes DNS resolves Service names from inside a Pod, and confirm the DNS infrastructure is healthy.

### Investigation

**1. Resolve from a Pod:**

```bash
kubectl apply -f dns-test-pod.yaml
kubectl get pod dns-test
kubectl exec -it dns-test -- nslookup web-service
kubectl exec -it dns-test -- nslookup web-service.default.svc.cluster.local
```

```text
Server:         10.96.0.10
Address:        10.96.0.10#53

Name:   web-service.default.svc.cluster.local
Address: 10.96.90.164
```

Both the short name and the fully qualified name resolved to the same ClusterIP, `10.96.90.164`.

**2. Check the DNS components:**

```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
kubectl get svc kube-dns -n kube-system
kubectl exec dns-test -- cat /etc/resolv.conf
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=20
```

The `nameserver` in the Pod's `resolv.conf` matches the `kube-dns` Service IP (`10.96.0.10`, the `Server:` line above), and the search path includes `default.svc.cluster.local`.

**3. Negative control:**

```bash
kubectl exec dns-test -- nslookup does-not-exist
```

A name that does not exist returns `NXDOMAIN`, which confirms the earlier successful answers were genuine lookups.

### Root cause / finding
Cluster DNS was healthy: CoreDNS was running and Service names resolved correctly.

| DNS symptom | Likely cause |
|---|---|
| `NXDOMAIN` | Wrong Service name or namespace |
| Timeout | CoreDNS not running, or port 53 blocked by a NetworkPolicy |
| Resolves, but connection fails | Not DNS; check endpoints and `targetPort` |

### Verification
Short-name and fully qualified lookups succeeded and the DNS components were healthy.

**Result: DNS verified.**

---

## 2.7 Test Pod with an HTTP Client

DNS only proves name resolution, so HTTP-level tests need a test Pod that includes an HTTP client. A dedicated test Pod with `curl` was created for sections 2.8, 2.9 and 3.6:

```bash
kubectl run net-test --image=curlimages/curl --restart=Never --command -- sleep 3600
kubectl get pod net-test
```

The Pod reached `1/1 Running` and was used for all connectivity tests below.

---

## 2.8 Pod Networking

### Problem statement
Verify that traffic actually flows Pod → Pod, Pod → Service IP and Pod → Service name.

### Investigation

```bash
kubectl get pods -l app=web -o wide
kubectl exec net-test -- curl -sI --max-time 5 http://10.244.0.32      # 1. Pod IP
kubectl exec net-test -- curl -sI --max-time 5 http://10.96.90.164     # 2. Service ClusterIP
kubectl exec net-test -- curl -sI --max-time 5 http://web-service      # 3. Service DNS name
```

Each request returned `HTTP/1.1 200 OK`.

### Reading the results

| Pod IP | ClusterIP | DNS name | Conclusion |
|---|---|---|---|
| ✅ | ✅ | ✅ | Networking fully healthy |
| ❌ | ❌ | ❌ | Pod network (CNI) problem, or the app is not listening |
| ✅ | ❌ | ❌ | Service configuration / kube-proxy problem |
| ✅ | ✅ | ❌ | DNS / CoreDNS problem |

### Root cause / finding
All three layers succeeded, so Pod networking, Service routing and DNS were all healthy, and the endpoints from 2.5 and the DNS results from 2.6 are confirmed end to end.

### Verification
The Service `web-service` is reachable by Pod IP, ClusterIP and DNS name.

**Result: Pod networking verified.**

---

## 2.9 Configuration Issue (wrong `targetPort`)

This is a different configuration fault from 2.5: the Service **has** endpoints, but traffic still does not reach the application.

### Problem statement
A Service selects the correct Pods but forwards traffic to a port on which nothing is listening.

```yaml
# config-demo-service.yaml
apiVersion: v1
kind: Service
metadata:
  name: config-demo-service
spec:
  selector:
    app: web
  ports:
    - port: 80
      targetPort: 8080      # Nginx actually listens on 80
```

### Investigation

```bash
kubectl apply -f config-demo-service.yaml
kubectl get endpoints config-demo-service
kubectl describe service config-demo-service
kubectl exec net-test -- curl -sI --max-time 5 http://config-demo-service
kubectl exec net-test -- curl -sI --max-time 5 http://10.244.0.32:80
```

The endpoints existed but pointed at port `8080`, and `describe` showed `TargetPort: 8080`. A request through the Service failed, while a direct request to the Pod on port 80 succeeded. This narrows the fault to the Service configuration, not the application or the network.

### Root cause
`targetPort` (8080) did not match the port the container listens on (80).

### Fix

```diff
 ports:
   - port: 80
-    targetPort: 8080
+    targetPort: 80
```

```bash
kubectl apply -f config-demo-service.yaml
kubectl get endpoints config-demo-service
kubectl exec net-test -- curl -sI --max-time 5 http://config-demo-service
```

### Verification

| Before | After |
|---|---|
| Endpoints on `:8080`; request through Service fails | Endpoints on `:80`; `HTTP/1.1 200 OK` |

**Result: resolved.**

---

## Task 2 Summary

| Issue | Investigation | Root cause | Fix |
|---|---|---|---|
| CrashLoopBackOff | `get`, `describe`, `events`, `logs --previous` | Container ran `exit 1` | Fixed command |
| ErrImagePull | `get`, `describe`, `events` | Non-existent image tag | Valid image tag |
| ImagePullBackOff | `get`, `describe`, `events` | Repeated pull failure (back-off) | Valid image tag |
| Pending | `describe`, `events`, `get nodes --show-labels` | `nodeSelector` for a missing node | Removed / corrected selector |
| ContainerCreating | `describe`, `events` | Normal state; stuck case = missing ConfigMap | Created the ConfigMap |
| Service connectivity | `get endpoints`, `--show-labels` | Selector did not match Pod labels | Selector set to `app: web` |
| DNS | `nslookup`, CoreDNS checks, negative control | No fault; DNS healthy | Verified |
| Pod networking | Layered `curl` from `net-test` | No fault; all layers healthy | Verified |
| Configuration | `get endpoints`, `describe svc`, direct vs Service `curl` | `targetPort` ≠ container port | `targetPort: 80` |

---

# Task 3: Mini Project

## Objective

Deploy a working application, inspect it, introduce two different faults (invalid image, wrong Service selector), diagnose both with evidence, fix them and verify the final working state.

```text
Client ──► troubleshooting-service ──selector app=troubleshooting-app──► Pod 10.244.0.19:80
                                                                     └─► Pod 10.244.0.20:80
```

## 3.1 Deploy the application

```bash
kubectl apply -f deployment.yaml
kubectl apply -f service.yaml
kubectl get pods
kubectl get service
kubectl get pods -o wide
```

Two replicas were running:

```text
troubleshooting-app-5b97965b56-b2bbb   1/1   Running   (IP 10.244.0.19)
troubleshooting-app-5b97965b56-cpwb4   1/1   Running   (IP 10.244.0.20)
```

## 3.2 Inspect the application

```bash
kubectl describe pod <pod-name>
kubectl logs <pod-name>
kubectl exec -it <pod-name> -- bash
curl localhost
```

The logs showed a normal Nginx startup and `curl localhost` returned the `Welcome to nginx!` page. This confirms the container is running, Nginx started successfully and the application serves HTTP inside the Pod.

## 3.3 Verify the Service

```bash
kubectl get service
kubectl describe service troubleshooting-service
kubectl get endpoints troubleshooting-service
```

The selector was `app=troubleshooting-app` and the endpoints were `10.244.0.19:80,10.244.0.20:80`. Both Deployment Pods are registered, so the Service is correctly connected to the application.

## 3.4 Broken image

### Problem statement
A Pod `project-broken-pod` was deployed with an invalid Nginx image tag.

### Investigation

```bash
kubectl apply -f broken-pod.yaml
kubectl get pod project-broken-pod
kubectl describe pod project-broken-pod
kubectl events --for pod/project-broken-pod
```

The Pod reported `Reason: ErrImagePull` and later `ImagePullBackOff`.

### Root cause
The tag `nginx:this-tag-does-not-exist` does not exist, so Kubernetes could not pull the image.

### Fix

```diff
-image: nginx:this-tag-does-not-exist
+image: nginx:1.27
```

```bash
kubectl apply -f broken-pod.yaml
kubectl get pod project-broken-pod
```

### Verification

| Before | After |
|---|---|
| `project-broken-pod   0/1   ErrImagePull` → `ImagePullBackOff` | `project-broken-pod   1/1   Running` |

**Result: resolved.**

## 3.5 Broken Service selector

### Problem statement
The Service selector was deliberately changed so that it no longer matched the application Pods.

```yaml
selector:
  app: wrong-app
```

### Investigation

```bash
kubectl get service
kubectl get endpoints troubleshooting-service
kubectl get pods --show-labels
kubectl describe service troubleshooting-service
```

```text
troubleshooting-service   <none>
```

The Pods carried `app=troubleshooting-app`, while the Service selector was `app=wrong-app`.

### Root cause
The selector did not match the Pod labels, so Kubernetes could not associate any Pod with the Service.

### Fix

```diff
 selector:
-  app: wrong-app
+  app: troubleshooting-app
```

```bash
kubectl apply -f service.yaml
kubectl get endpoints troubleshooting-service
```

### Verification

| Before | After |
|---|---|
| `troubleshooting-service   <none>` | `troubleshooting-service   10.244.0.19:80,10.244.0.20:80` |

**Result: resolved.**

## 3.6 Final end-to-end verification

Endpoints show the wiring; a real request proves the application is reachable through the Service.

```bash
kubectl get pods,svc,endpoints
kubectl exec net-test -- curl -sI --max-time 5 http://troubleshooting-service
```

The Service returned `HTTP/1.1 200 OK`, so the full path (DNS → Service → endpoints → Pod → Nginx) works.

## Mini Project Troubleshooting Table

| Problem | What I saw | Commands used | Root cause | Fix |
|---|---|---|---|---|
| Broken image | `ErrImagePull` / `ImagePullBackOff` | `get`, `describe`, `events` | Invalid Nginx tag | `nginx:1.27` |
| Service problem | Endpoints `<none>` | `get endpoints`, `describe svc`, `--show-labels` | Selector did not match Pod labels | Restored `app: troubleshooting-app` |
| Application verification | Runtime proof needed | `logs`, `exec`, `curl` | No fault | Welcome page; 200 OK through the Service |

---

# Troubleshooting Cheat Sheet

| Symptom | Meaning | First commands | Common causes |
|---|---|---|---|
| `CrashLoopBackOff` | Container keeps crashing | `logs --previous`, `describe` (exit code) | App error, bad command, missing config, OOMKilled, failing probe |
| `ErrImagePull` / `ImagePullBackOff` | Image cannot be pulled | `describe`, `events` | Wrong name/tag, missing `imagePullSecret`, registry unreachable |
| `Pending` | Not scheduled | `describe`, `events` | Insufficient CPU/memory, `nodeSelector`/affinity, taints, unbound PVC |
| `ContainerCreating` (stuck) | Setup not finishing | `describe`, `events` | `FailedMount` (missing ConfigMap/Secret/PVC), image pull, CNI problem |
| `CreateContainerConfigError` | Bad container configuration | `describe` | Missing ConfigMap/Secret or key |
| Service has no endpoints | No matching Pods | `get endpoints`, `get pods --show-labels` | Selector ≠ labels, Pods not Ready |
| Endpoints exist, no traffic | Wrong port or blocked | `describe svc`, direct Pod-IP `curl` | Wrong `targetPort`, NetworkPolicy, app bound to localhost |
| DNS failure | Names not resolving | CoreDNS pods, `resolv.conf`, `nslookup` | CoreDNS down, wrong name/namespace, port 53 blocked |

---

# Before / After Summary

| Problem | Before | After |
|---|---|---|
| CrashLoopBackOff | `0/1 CrashLoopBackOff` | `1/1 Running` |
| Image pull | `ErrImagePull` / `ImagePullBackOff` | `1/1 Running` |
| Pending Pod | `0/1 Pending` | `1/1 Running` |
| ContainerCreating (stuck) | `0/1 ContainerCreating` (`FailedMount`) | `1/1 Running` |
| Web Service selector | Endpoints `<none>` | `10.244.0.32:80,10.244.0.33:80` |
| DNS | Needed verification | Resolved to `10.96.90.164` |
| Pod networking | Needed end-to-end proof | Pod IP, ClusterIP and DNS name all return 200 |
| Wrong `targetPort` | Endpoints on `:8080`, requests fail | Endpoints on `:80`, 200 OK |
| Mini project image | `ErrImagePull` / `ImagePullBackOff` | `1/1 Running` |
| Mini project Service | Endpoints `<none>` | `10.244.0.19:80,10.244.0.20:80` |

---

# Review Questions

**1. What does `kubectl get` tell us?**
A quick overview of resources and their state: readiness, status, restarts and age for Pods.

**2. What is the difference between `kubectl get` and `kubectl describe`?**
`get` is a concise summary. `describe` shows full configuration, container state, conditions, scheduling information and Events.

**3. Why are logs important?**
They show what the application printed, revealing crashes, startup failures, runtime errors and configuration problems. `--previous` shows the output of a crashed container.

**4. When should `kubectl exec` be used?**
When a running container must be inspected from inside: files, environment variables, connectivity and diagnostic commands.

**5. What does CrashLoopBackOff mean?**
A container repeatedly starts, fails and is restarted, with Kubernetes increasing the delay between attempts. It is a symptom; logs and exit codes reveal the cause.

**6. What does ImagePullBackOff mean?**
Kubernetes failed to pull the image and is waiting before retrying. Causes include a wrong image name or tag, private-registry authentication, an unreachable registry or network problems.

**7. Why can a Pod remain Pending?**
The scheduler cannot place it: insufficient CPU or memory, an invalid `nodeSelector`, affinity rules, taints without tolerations, or an unbound PersistentVolumeClaim.

**8. Why can a Service have no endpoints?**
Its selector matches no running, Ready Pods, so there are no backends to route to.

**9. What is the relationship between a Service selector and Pod labels?**
The selector chooses which Pods receive traffic. The Pod labels must contain every key/value in the selector (for example `app: web`) for the Pod to become an endpoint.

**10. What is Kubernetes DNS?**
Cluster DNS (CoreDNS) gives Services stable names such as `web-service` or `web-service.default.svc.cluster.local`, so applications do not depend on changing Pod IPs.

---

# Key Learnings and Conclusion

1. A status such as `CrashLoopBackOff` is a **symptom**; logs, exit codes and Events reveal the root cause.
2. `describe` and Events explain Kubernetes-level failures; `logs` explain application-level failures.
3. `logs --previous` is essential for containers that keep restarting.
4. `ContainerCreating` is normal and temporary, but when stuck, Events (`FailedMount`) explain why.
5. Scheduling constraints such as `nodeSelector` can leave a Pod `Pending`.
6. Service selectors must match Pod labels; no match means no endpoints.
7. Endpoints existing does not guarantee traffic flows: `targetPort` must match the container's port.
8. Successful DNS resolution does not prove HTTP connectivity; test the Pod IP, ClusterIP and DNS name separately.
9. Always end with **VERIFY**: re-run the commands and confirm the resource has recovered.

Session 14 covered Pod lifecycle failures, image problems, scheduling, ConfigMap mounts, Service selectors and ports, endpoints, DNS and Pod networking, and combined them in a mini project. The key lesson is to **diagnose with evidence rather than guesswork**, following the workflow:

```text
GET → DESCRIBE → EVENTS → LOGS → EXEC → TEST → FIX → VERIFY
```

---

# Cleanup

```bash
kubectl delete pod crash-demo image-demo pending-demo dns-test net-test configmap-demo project-broken-pod --ignore-not-found
kubectl delete svc config-demo-service --ignore-not-found
kubectl delete configmap app-config --ignore-not-found
kubectl delete -f deployment.yaml -f service.yaml --ignore-not-found
```

---

# Deliverables Checklist

| Deliverable | Status | Where |
|---|---|---|
| Commands | ✅ | Tasks 1, 2 and 3 |
| Problem statements | ✅ | Every issue in Tasks 2 and 3 |
| Investigation steps | ✅ | Every issue in Tasks 2 and 3 |
| Root causes | ✅ | Every issue in Tasks 2 and 3 |
| Solutions | ✅ | Every issue in Tasks 2 and 3 |
| Before / after output | ✅ | Per issue and in the summary table |
| Screenshots | ✅ | Submitted separately with the assignment |
| README.md | ✅ | This file |

**End of Session 14: Kubernetes Troubleshooting**