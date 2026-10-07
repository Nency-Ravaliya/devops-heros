# Task 1

### clusterip

![Screenshot 1](screenshots/Screenshot%202026-09-17%20143555.png)

![Screenshot 2](screenshots/Screenshot%202026-09-17%20143626.png)

![Screenshot 3](screenshots/Screenshot%202026-09-17%20143800.png)

### nodeport

![Screenshot 4](screenshots/Screenshot%202026-09-17%20144441.png)

![Screenshot 5](screenshots/Screenshot%202026-09-17%20144458.png)

### loadbalancer

![Screenshot 6](screenshots/Screenshot%202026-09-17%20233658.png)

![Screenshot 7](screenshots/Screenshot%202026-09-17%20233702.png)

![Screenshot 8](screenshots/Screenshot%202026-09-17%20233708.png)

![Screenshot 9](screenshots/Screenshot%202026-09-17%20233921.png)

![Screenshot 10](screenshots/Screenshot%202026-09-17%20233926.png)

### externalname

![Screenshot 11](screenshots/Screenshot%202026-09-18%20001022.png)

![Screenshot 12](screenshots/Screenshot%202026-09-18%20001034.png)

### headless

![Screenshot 13](screenshots/Screenshot%202026-09-18%20001337.png)

![Screenshot 14](screenshots/Screenshot%202026-09-18%20001345.png)


# Task 2: Kubernetes Object Comparison

## 1. Deployment vs ReplicaSet

* **Purpose:** A ReplicaSet ensures that a specified number of pod replicas are running at any given time. A Deployment is a higher-level concept that manages ReplicaSets and provides declarative updates to Pods.
* **Pod Management:** A ReplicaSet directly manages Pods based on label selectors. A Deployment manages ReplicaSets, which in turn manage the Pods.
* **Scaling:** Both can be scaled up or down manually or via Horizontal Pod Autoscalers (HPA). However, you typically scale the Deployment, which propagates the desired state down to the ReplicaSet.
* **Rolling Updates:** ReplicaSets do **not** support rolling updates. If you change a Pod template in a ReplicaSet, existing Pods are not affected. Deployments **do** support rolling updates; when a Deployment's pod template is updated, it creates a new ReplicaSet, scales it up, and gracefully scales down the old ReplicaSet.
* **Relationship:** A Deployment owns and manages ReplicaSets. You should almost never create a ReplicaSet directly; instead, create a Deployment and let it manage the ReplicaSet lifecycle under the hood.

## 2. Deployment vs DaemonSet vs StatefulSet

| Feature | Deployment | DaemonSet | StatefulSet |
| :--- | :--- | :--- | :--- |
| **Use Cases** | Stateless applications (web servers, APIs). | Node-level agents (logging, monitoring, networking). | Stateful applications (databases, message queues). |
| **Pod Creation** | Scheduled across any available nodes based on resources. | Exactly one Pod created on *every* eligible node. | Created sequentially with predictable, persistent identities (e.g., `web-0`, `web-1`). |
| **Scaling** | Replicas can be added/removed dynamically and randomly. | Scales automatically as nodes are added/removed from the cluster. | Scaled strictly in sequential order (0 to N) and terminated in reverse order. |
| **Networking** | Pods get random IPs; usually fronted by a standard Service. | Pods get random IPs; often use host networking or NodePorts. | Requires a Headless Service to provide stable DNS network identities for each Pod. |
| **Storage** | Ephemeral or shared persistent storage; Pods do not retain state. | Typically mounts host paths (`/var/log`, `/var/lib/docker`). | Uses VolumeClaimTemplates so each Pod gets its own dedicated, persistent volume. |
| **Examples** | Nginx, Node.js backend, Python web app. | Fluentd, Prometheus Node Exporter, Calico. | MySQL, MongoDB, Kafka, Elasticsearch. |

## 3. ReplicaSet vs Service

* **ReplicaSet Responsibility:** Ensures the correct number of identical Pod copies are running. It handles application compute availability and redundancy.
* **Service Responsibility:** Provides a stable network endpoint (IP and DNS) and load balances traffic across a dynamic set of Pods.
* **Why a Service is required:** Pod IPs are ephemeral. When a ReplicaSet replaces a crashed Pod, the new Pod gets a completely different IP address. A Service acts as a static anchor, meaning clients do not need to keep track of changing Pod IPs.
* **How traffic reaches Pods:** The Service uses a `selector` (e.g., `app: my-frontend`) to continuously monitor running Pods. It updates its internal Endpoints object with the current IPs of all healthy Pods matching that label. Traffic sent to the Service is routed via kube-proxy (using iptables or IPVS) to one of those underlying Pod IPs.

# Task 3: Fully Qualified Domain Name (FQDN) in Kubernetes

## What is FQDN?
A Fully Qualified Domain Name (FQDN) is the complete domain name for a specific computer, or host, on the internet. In Kubernetes, it refers to the exact, absolute DNS name used to resolve Services and Pods across the entire cluster network.

## Kubernetes Service DNS
When you create a Service, the Kubernetes DNS add-on (like CoreDNS) automatically creates a DNS record for it. This allows applications to resolve Services by their name instead of hardcoding ephemeral ClusterIPs.

## Kubernetes DNS Naming Convention
The standard FQDN format for a Kubernetes Service is:
`<service-name>.<namespace>.svc.cluster.local`

* **`<service-name>`**: The name of the Service.
* **`<namespace>`**: The namespace where the Service resides.
* **`svc`**: Indicates this is a Service resource.
* **`cluster.local`**: The default base domain for the cluster.

## Namespace-based DNS
Kubernetes DNS routing behavior changes depending on the namespace context:
* **Same Namespace:** If Pod A and Service B are in the same namespace, Pod A can reach Service B using just its short name (e.g., `curl http://backend-service`).
* **Different Namespace:** If Pod A is in `frontend-ns` and Service B is in `backend-ns`, Pod A must use the namespace in the DNS query (e.g., `curl http://backend-service.backend-ns` or the full FQDN).

## Pod-to-Service Communication
When a Pod makes a network request to a Service name, the host's DNS resolver sends a query to the cluster's DNS server (CoreDNS). CoreDNS resolves the name to the Service's ClusterIP. The node's networking rules (kube-proxy) then intercept traffic destined for that ClusterIP and forward it to an active, backing Pod.

## Examples of Kubernetes FQDNs
* **Standard Service:** `my-database.production.svc.cluster.local`
* **ExternalName Service:** Can alias external domains (e.g., mapping `api.external` to `api.google.com`).
* **Headless Service (Pod specific):** `web-0.nginx-service.default.svc.cluster.local` (resolves directly to the IP of the Pod named `web-0`).

# Task 4: CoreDNS in Kubernetes

## What is CoreDNS?
CoreDNS is a flexible, extensible DNS server written in Go that serves as the default cluster DNS provider for Kubernetes. It runs as a set of Pods (typically managed by a Deployment) in the `kube-system` namespace.

## Why Kubernetes uses CoreDNS
Before CoreDNS, Kubernetes used `kube-dns`. CoreDNS was adopted as the standard because it is significantly more memory-efficient, highly modular (using plugins), faster, and less prone to the security vulnerabilities associated with older DNS implementations.

## How Service Discovery Works
Whenever a new Service or Pod is created, the Kubernetes API server notifies CoreDNS. CoreDNS dynamically updates its internal records. When an application inside the cluster wants to communicate with a Service, it queries CoreDNS with the Service name, and CoreDNS returns the corresponding ClusterIP or Pod IP.

## How DNS Queries are Resolved
1. A container makes an HTTP request to `my-service`.
2. The container's OS checks its `/etc/resolv.conf` file, which is configured by the kubelet to point to the CoreDNS Service IP (usually `10.96.0.10`).
3. The query hits the CoreDNS pods.
4. CoreDNS checks its Kubernetes plugin cache. If it matches a cluster resource, it returns the IP.
5. If the query is for an external site (e.g., `google.com`), CoreDNS forwards the query to the upstream DNS servers configured on the host node.

## CoreDNS Configuration
CoreDNS is configured via a ConfigMap named `coredns` in the `kube-system` namespace. The main configuration file is called the **Corefile**. It defines which plugins are active, how errors are logged, and where to forward external queries. 
Example snippet of a Corefile:
```text
.:53 {
    errors
    health
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
    }
    forward . /etc/resolv.conf
    cache 30
    loop
    reload
    loadbalance
}