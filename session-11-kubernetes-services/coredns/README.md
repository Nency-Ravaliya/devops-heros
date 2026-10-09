# CoreDNS in Kubernetes

## 1. What is CoreDNS?
**CoreDNS** is a flexible, extensible, and CNCF-graduated DNS server written in Go. In modern Kubernetes clusters, CoreDNS serves as the default cluster-internal DNS provider (running as a Deployment in the `kube-system` namespace).

---

## 2. Why Kubernetes Uses CoreDNS
1. **Dynamic Service Discovery**: Watches the Kubernetes API server for Service and Pod lifecycle events and immediately updates DNS records in memory.
2. **Plugin Architecture**: Modular chaining of plugins (`kubernetes`, `errors`, `health`, `cache`, `forward`).
3. **Low Resource Footprint**: Fast, lightweight, and thread-safe compared to legacy `kube-dns`.

---

## 3. How Service Discovery Works

1. A Service manifest (`my-service`) is applied.
2. The **Kubernetes API Server** assigns a stable virtual ClusterIP (e.g., `10.96.100.50`).
3. The **CoreDNS Kubernetes Plugin** detects the new Service and registers an `A` record:
   ```text
   my-service.default.svc.cluster.local. 30 IN A 10.96.100.50
   ```
4. Pods resolving `my-service` get `10.96.100.50` automatically.

---

## 4. How DNS Queries are Resolved (Resolution Flow)

```text
[ Client Pod ]
      |
      | (1) Lookup: api.github.com OR yatri-service
      v
[/etc/resolv.conf] -> nameserver 10.96.0.10
      |
      v
[ CoreDNS Pod in kube-system ]
      |
      +---> Is it *.cluster.local?
      |         |
      |         +--> YES: Query Kubernetes Plugin (Returns ClusterIP)
      |
      +---> Is it an external domain (e.g., google.com)?
                |
                +--> NO: Forward to upstream DNS (/etc/resolv.conf or 8.8.8.8)
```

---

## 5. CoreDNS Configuration (`Corefile`)

CoreDNS configuration is managed via a ConfigMap named `coredns` in `kube-system`:

```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: coredns
  namespace: kube-system
data:
  Corefile: |
    .:53 {
        errors
        health {
           lameduck 5s
        }
        ready
        kubernetes cluster.local in-addr.arpa ip6.arpa {
           pods insecure
           fallthrough in-addr.arpa ip6.arpa
           ttl 30
        }
        prometheus :9153
        forward . /etc/resolv.conf
        cache 30
        loop
        reload
        loadbalance
    }
```

* **`kubernetes cluster.local`**: Answers authoritative queries for cluster domain.
* **`forward . /etc/resolv.conf`**: Forwards any non-cluster queries to host upstream DNS.
* **`cache 30`**: Caches DNS responses for 30 seconds to reduce lookup latency.

---

## 6. How to Troubleshoot DNS Issues

When Pods cannot resolve service names or external domains:

### Step 1: Check CoreDNS Pod Status
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns
```
*Ensure all CoreDNS pods are in `Running` status (1/1).*

### Step 2: Inspect CoreDNS Logs
```bash
kubectl logs -n kube-system -l k8s-app=kube-dns --tail=100
```
*Look for upstream network errors or loop detection warnings.*

### Step 3: Verify the `kube-dns` Service
```bash
kubectl get svc -n kube-system -l k8s-app=kube-dns
```
*Check that the ClusterIP matches the `nameserver` IP listed inside `/etc/resolv.conf` of client pods.*

### Step 4: Run an In-Cluster DNS Probe
```bash
kubectl run -i --tty --rm dnsutils --image=tianon/speedtest --restart=Never -- nslookup kubernetes.default
```
