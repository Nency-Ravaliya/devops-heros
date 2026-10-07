## 1. Differences Between StatefulSet, Deployment, and DaemonSet

| Architectural Dimension | Deployment | StatefulSet | DaemonSet |
| :--- | :--- | :--- | :--- |
| **Primary Design Purpose** | Manages stateless, interchangeable workloads requiring automated rollout and scaling strategies. | Manages stateful applications requiring unique network identities, ordered execution, and persistent storage. | Ensures that all (or a designated subset of) cluster nodes run exactly one copy of a Pod. |
| **Pod Identity & Naming** | Dynamic and non-deterministic (e.g., `web-deployment-7f98b6988f-k2m9x`). Pods are completely interchangeable. | Deterministic, sequential, and sticky (e.g., `db-statefulset-0`, `db-statefulset-1`). Indices are preserved across restarts. | Node-bound with random hash suffixes (e.g., `fluentd-ds-g7x4q`). Exactly one pod runs per targeted node. |
| **Lifecycle & Ordering** | Unordered. Pods can be provisioned, updated, and terminated concurrently according to rolling update quotas (`maxSurge`, `maxUnavailable`). | Strictly ordered. Scaled up monotonically from index `0` to `N-1`. Scaled down or terminated in reverse order (`N-1` to `0`). | Parallel or sequential provisioning triggered automatically upon node discovery, node joining, or node taint clearance. |
| **Storage Architecture** | Typically shares a single volume (e.g., `ReadWriteMany` NFS) or operates on ephemeral storage (`emptyDir`). | Employs `volumeClaimTemplates` to automatically provision a dedicated, permanent `PersistentVolumeClaim` (PVC) for every individual pod index. | Mounts host filesystem paths directly via `hostPath`, or accesses node-local storage. |
| **Network & Discovery** | Routes traffic across pods via standard Kubernetes Services (Round-Robin/IPTables/IPVS). | Requires a Headless Service (`clusterIP: None`) to establish predictable SRV and A-records per pod for inter-node clustering. | Accesses network interfaces typically via standard services, `hostPort`, or `hostNetwork: true`. |
| **Standard Enterprise Workloads** | Web servers, stateless REST APIs, frontend interfaces, worker queue processors. | Distributed databases (PostgreSQL clusters, Cassandra), message brokers (Apache Kafka, RabbitMQ), distributed state engines (etcd, ZooKeeper). | Node-level monitoring agents (Prometheus `node-exporter`), log collectors (Fluentd, Vector), network plugins (Calico, Cilium, kube-proxy). |

---

## 2. Differences Between ReplicaSet and Deployment

A **ReplicaSet** and a **Deployment** are closely related resources within the `apps/v1` API group, but they operate at different levels of abstraction in the Kubernetes control plane.

### Core Architectural Distinction
* A **ReplicaSet** is a low-level reconciliation controller responsible solely for maintaining a specified number of identical Pod replicas running at all times using label selectors.
* A **Deployment** is a higher-level orchestrator that manages ReplicaSets declaratively. It provides automated lifecycle capabilities, including versioning, canary releases, rolling updates, and rollbacks.

## Screenshots

### Rolling Update

![Screenshot 4](screenshots/Screenshot%202026-09-17%20220359.png)

![Screenshot 3](screenshots/Screenshot%202026-09-17%20220112.png)

### Blue-Green

![Screenshot 6](screenshots/Screenshot%202026-09-17%20220732.png)



![Screenshot 5](screenshots/Screenshot%202026-09-17%20220658.png)


![Screenshot 8](screenshots/Screenshot%202026-09-17%20220901.png)

![Screenshot 7](screenshots/Screenshot%202026-09-17%20220804.png)


### Canary
![Screenshot 9](screenshots/Screenshot%202026-09-17%20221856.png)

![Screenshot 10](screenshots/Screenshot%202026-09-17%20221907.png)

![Screenshot 11](screenshots/Screenshot%202026-09-17%20221935.png)

![Screenshot 12](screenshots/Screenshot%202026-09-17%20221948.png)

![Screenshot 13](screenshots/Screenshot%202026-09-17%20221959.png)

![Screenshot 14](screenshots/Screenshot%202026-09-17%20222010.png)

### Recreate

![Screenshot 15](screenshots/Screenshot%202026-09-17%20223046.png)

![Screenshot 16](screenshots/Screenshot%202026-09-17%20223100.png)

![Screenshot 17](screenshots/Screenshot%202026-09-17%20223111.png)



# Fully Qualified Domain Name (FQDN) & CoreDNS in Kubernetes

This technical reference explains cluster DNS resolution, the role of **CoreDNS**, and the structural anatomy of **Fully Qualified Domain Names (FQDNs)** for Services and Pods in Kubernetes.

---

## 1. Overview: Service Discovery in Kubernetes

In Kubernetes, Pod IPs are ephemeral—they change whenever a Pod restarts, reschedules, or scales. To provide reliable networking between services without hardcoding changing IP addresses, Kubernetes implements a built-in internal DNS service (implemented by default via **CoreDNS**).

Every Service and Pod registered in the cluster receives an internal DNS record that can be addressed via an FQDN.

---

## 2. Anatomy of a Kubernetes FQDN

A Fully Qualified Domain Name (FQDN) is an unambiguous domain name that specifies its exact location in the DNS hierarchy down to the root domain. In Kubernetes, the default cluster root domain is `cluster.local`.

### A. Standard Service FQDN
For standard ClusterIP, NodePort, and LoadBalancer services:

$$\text{<service-name>}.\text{<namespace>}.\text{svc}.\text{<cluster-domain>}$$

* **`<service-name>`**: Name of the Kubernetes Service object.
* **`<namespace>`**: Kubernetes namespace where the Service resides.
* **`svc`**: Indicates the resource type is a Service.
* **`<cluster-domain>`**: The cluster base domain (default: `cluster.local`).

**Example:**
```text
frontend-svc.production.svc.cluster.local
```


# Pod Lifecycle

## Task 1: Continuous Running State
**Observation:** The Pod successfully pulls the `nginx:1.27` image and enters the `Running` phase. It remains running continuously as a background web server process exposed on port 80 unless manually deleted or evicted by the node.
- ![Task 1 - screenshot (28)](screenshots/Screenshot%20(28).png)
- ![Task 1 - Screenshot 2026-10-06 191756](screenshots/Screenshot%202026-10-06%20191756.png)

## Task 2: Pending State (Resource Exhaustion)
**Observation:** The Pod remains stuck in the `Pending` phase. The Kubernetes scheduler cannot place the pod onto any node because the memory request of `256Gi` heavily exceeds the allocatable capacity of a standard node, resulting in a persistent `FailedScheduling` event.
- ![Task 2 - screenshot (29)](screenshots/Screenshot%20(29).png)

## Task 3: Succeeded Phase
**Observation:** The container executes its shell script, sleeps for 5 seconds, prints a success message, and exits with code `0`. Because `restartPolicy: Never` is defined in the manifest, Kubernetes does not restart the container, and the Pod's lifecycle successfully concludes in the `Succeeded` phase (displayed as `Completed`).
- ![Task 3 - screenshot (30)](screenshots/Screenshot%20(30).png)
- ![Task 3 - Screenshot 2026-10-06 192324](screenshots/Screenshot%202026-10-06%20192324.png)

## Task 4: Failed Phase
**Observation:** The container script intentionally exits with an error code (`exit 1`) after sleeping for 5 seconds. Due to the explicit `restartPolicy: Never` configuration, the kubelet does not attempt to restart the container, forcing the Pod directly into the terminal `Failed` phase (displayed as `Error`).
- ![Task 4 - screenshot (31)](screenshots/Screenshot%20(31).png)
- ![Task 4 - Screenshot 2026-10-06 192422](screenshots/Screenshot%202026-10-06%20192422.png)

## Task 5: CrashLoopBackOff State
**Observation:** The application starts but predictably crashes and exits with an error (`exit 1`) every 3 seconds. Because the default restart policy is `Always`, the kubelet repeatedly restarts the container. After consecutive rapid failures, Kubernetes applies an exponential back-off delay, placing the Pod into the `CrashLoopBackOff` state to prevent systemic resource drain.
- ![Task 5 - screenshot (32)](screenshots/Screenshot%20(32).png)
- ![Task 5 - Screenshot 2026-10-06 192527](screenshots/Screenshot%202026-10-06%20192527.png)

## Task 6: ImagePullBackOff State
**Observation:** The Pod cannot enter the `Running` state because the specified image (`jakwehrgkaejw:kahsdfgkhj`) does not exist. The kubelet continuously fails to pull the image from the registry, resulting in a continuous loop of `ErrImagePull` and subsequently `ImagePullBackOff` statuses.
- ![Task 6 - screenshot (33)](screenshots/Screenshot%20(33).png)
- ![Task 6 - Screenshot 2026-10-06 192617](screenshots/Screenshot%202026-10-06%20192617.png)

## Task 7: Readiness Probe
**Observation:** The Pod enters the `Running` phase immediately upon creation, but network readiness is deliberately delayed. The kubelet waits 5 seconds (`initialDelaySeconds`) before sending an HTTP GET request to port 80. Only after Nginx responds with a successful HTTP status code does the `READY` condition flip to `1/1`, allowing the Pod to accept traffic.
- ![Task 7 - screenshot (34)](screenshots/Screenshot%20(34).png)
- ![Task 7 - Screenshot 2026-10-06 192801](screenshots/Screenshot%202026-10-06%20192801.png)

## Task 8: Liveness Probe (Automated Recovery)
**Observation:** The container initially runs healthy, but a simulated failure removes the `/tmp/healthy` marker file after 20 seconds. The liveness probe, which checks for this file every 5 seconds, fails twice in a row (meeting the `failureThreshold: 2` limit). The kubelet identifies the deadlock, forcefully kills the container, and initiates a restart to self-heal the workload.
- ![Task 8 - screenshot (35)](screenshots/Screenshot%20(35).png)
- ![Task 8 - Screenshot 2026-10-06 192940](screenshots/Screenshot%202026-10-06%20192940.png)

## Task 9: Startup Probe
**Observation:** The application simulates a slow initialization window by taking 30 seconds to generate the `/tmp/started` file. The `startupProbe` fails repeatedly during this window, but the `failureThreshold: 10` (coupled with a 5-second period) provides a safe 50-second startup budget. Once the file is created, the probe passes, protecting the container from being prematurely terminated by any subsequent liveness checks.
- ![Task 9 - screenshot (36)](screenshots/Screenshot%20(36).png)
- ![Task 9 - Screenshot 2026-10-06 193614](screenshots/Screenshot%202026-10-06%20193614.png)

## Task 10: Init Containers
**Observation:** The Pod follows a strict sequential startup. The `setup` init container runs its command, sleeps for 10 seconds, and completes successfully before the main `nginx` container is permitted to launch. If the init container had failed, the Pod would have remained blocked in the initialization phase.
- ![Task 10 - screenshot (37)](screenshots/Screenshot%20(37).png)
- ![Task 10 - Screenshot 2026-10-06 193759](screenshots/Screenshot%202026-10-06%20193759.png)

## Task 11: Multi-Container Sidecar Pattern
**Observation:** The primary `app` container and the auxiliary `sidecar` container start concurrently within the same Pod execution boundary. The Pod's status displays `READY: 2/2`, indicating that both containers are active. Because they share the same lifecycle, the Pod is only fully operational if both processes are running successfully.
- ![Task 11 - screenshot (38)](screenshots/Screenshot%20(38).png)
- ![Task 11 - Screenshot 2026-10-06 194041](screenshots/Screenshot%202026-10-06%20194041.png)

## Task 12: Graceful Termination
**Observation:** Upon receiving a deletion command, the Pod enters the `Terminating` phase rather than disappearing instantly. The container intercepts the `SIGTERM` signal via a shell `trap` and executes a clean 10-second teardown routine. Because this routine finishes well within the `terminationGracePeriodSeconds` of 20 seconds, the Pod shuts down cleanly without the kubelet resorting to an abrupt `SIGKILL`.
- ![Task 12 - Screenshot 2026-10-06 194318](screenshots/Screenshot%202026-10-06%20194318.png)
- ![Task 12 - Screenshot 2026-10-06 194328](screenshots/Screenshot%202026-10-06%20194328.png)
- ![Task 12 - Screenshot 2026-10-06 194343](screenshots/Screenshot%202026-10-06%20194343.png)
