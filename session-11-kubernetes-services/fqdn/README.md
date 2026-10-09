# Fully Qualified Domain Name (FQDN) in Kubernetes

## 1. What is an FQDN?
An **FQDN (Fully Qualified Domain Name)** is the complete, unambiguous domain name specifying its exact location in the Domain Name System (DNS) tree hierarchy. In Kubernetes, every Service automatically receives an internal FQDN managed by CoreDNS.

---

## 2. Kubernetes DNS Naming Convention

The standard syntax for a Kubernetes Service FQDN is:

```text
<service-name>.<namespace>.svc.<cluster-domain>
```

Where:
* **`<service-name>`**: The `metadata.name` defined in the Service manifest.
* **`<namespace>`**: The Kubernetes namespace where the service lives (e.g., `default`, `prod`, `dev`).
* **`svc`**: Indicates the DNS record type is a Service.
* **`<cluster-domain>`**: The cluster root domain (defaults to `cluster.local`).

### Example Breakdown:
For a service named `payment-service` deployed in namespace `production`:
```text
payment-service.production.svc.cluster.local
```

---

## 3. Namespace-Based DNS Resolution

Kubernetes configures `/etc/resolv.conf` inside every Pod with search paths:

```text
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

This allows shorthand resolution depending on where the calling Pod is located:

| Caller Location | Target Service & Namespace | Shortest Valid Name | Full FQDN |
|---|---|---|---|
| Same namespace (`default`) | `web-svc` in `default` | `web-svc` | `web-svc.default.svc.cluster.local` |
| Different namespace (`dev`) | `web-svc` in `prod` | `web-svc.prod` | `web-svc.prod.svc.cluster.local` |
| External cluster / strict | `db-svc` in `database` | `db-svc.database.svc.cluster.local` | `db-svc.database.svc.cluster.local` |

---

## 4. Pod-to-Service Communication Flow

```text
[ Client Pod ]
     |
     | (1) GET http://payment-service.production/
     v
[ CoreDNS Resolver: 10.96.0.10 ]
     |
     | (2) Returns ClusterIP: 10.105.12.80
     v
[ kube-proxy / iptables ]
     |
     | (3) Load balances to healthy backend Pod IP (e.g., 10.244.1.44)
     v
[ payment-service Pod ]
```

---

## 5. Practical Verification Commands

```bash
# 1. Run a temporary diagnostic container with curl/nslookup
kubectl run dns-test --image=busybox:1.28 --rm -it -- restart=Never -- sh

# 2. Inside the container, query FQDN
nslookup kubernetes.default.svc.cluster.local

# 3. Test cross-namespace resolution
nslookup <service-name>.<namespace>.svc.cluster.local
```
