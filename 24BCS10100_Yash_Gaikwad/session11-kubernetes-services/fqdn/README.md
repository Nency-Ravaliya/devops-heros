# FQDN in Kubernetes

Author: Yash Gaikwad (24BCS10100) | Session 11 - Kubernetes Services

These notes cover how names work inside a cluster: what a fully qualified domain name is, how Services and Pods get DNS names, and why a Pod can call `http://backend` even though the real name is much longer.

---

## 1. What is an FQDN?

A **Fully Qualified Domain Name** is a domain name that spells out every label from the host all the way up to the root of the DNS tree, so there is no ambiguity about where it lives.

```
www.example.com.
 |    |     |  `-- root (the empty label, written as the trailing dot)
 |    |     `----- top-level domain
 |    `----------- second-level domain
 `---------------- host name
```

- `www` on its own is a *relative* name (a partial name). The resolver has to guess what to append to it.
- `www.example.com.` with the trailing dot is an *absolute* name. The resolver uses it exactly as written and does not apply any search list.
- In daily use most tools accept `www.example.com` without the dot and treat it as fully qualified, but a resolver configured with search domains and `ndots` may try other suffixes first (see section 5). The trailing dot is the way to say "do not append anything".

---

## 2. Kubernetes Service DNS

Kubernetes runs a DNS server inside the cluster (CoreDNS, covered in `../coredns/README.md`). Whenever I create a Service, DNS records for it are created automatically. I never register them by hand.

For a normal (ClusterIP) Service the record is an **A/AAAA record** that resolves to the Service's ClusterIP. This is the naming convention:

```
<service-name>.<namespace>.svc.<cluster-domain>
```

| Part | Meaning | Example |
|---|---|---|
| `service-name` | `metadata.name` of the Service | `backend` |
| `namespace` | Namespace the Service lives in | `default` |
| `svc` | Fixed label meaning "this is a Service record" | `svc` |
| `cluster-domain` | Cluster DNS suffix, `cluster.local` by default | `cluster.local` |

So a Service `backend` in namespace `default` is:

```
backend.default.svc.cluster.local
```

The cluster domain is configurable (kubelet `clusterDomain`, or `networking.dnsDomain` in the kubeadm config). I assume `cluster.local` in all examples because that is the default, but it is better not to hard-code it in application code.

Services with named ports also get **SRV records**, for example `_http._tcp.backend.default.svc.cluster.local`, which return the port number as well as the name.

---

## 3. Namespace-based DNS and cross-namespace calls

The namespace is part of the name, so two Services with the same name in different namespaces do not clash:

```
db.dev.svc.cluster.local      # Service "db" in namespace dev
db.prod.svc.cluster.local     # Service "db" in namespace prod
```

Rules I understood:

- A Pod can call a Service in **its own namespace** with just the Service name: `http://db`.
- To call a Service in **another namespace** it must include the namespace: `db.prod` or the full `db.prod.svc.cluster.local`.
- Kubernetes namespaces are not a network boundary by themselves. Cross-namespace traffic is allowed unless a NetworkPolicy blocks it. DNS only gives the name.

Example: Pod in `team-a` calling Service `api` in `team-b`:

```bash
kubectl create namespace team-a
kubectl create namespace team-b
kubectl -n team-b create deployment api --image=nginx:1.27 --port=80
kubectl -n team-b expose deployment api --port=80

kubectl -n team-a run client --image=busybox:1.36 --restart=Never -- sleep 3600

kubectl -n team-a exec client -- wget -qO- http://api.team-b                       # works
kubectl -n team-a exec client -- wget -qO- http://api.team-b.svc.cluster.local     # works
kubectl -n team-a exec client -- wget -qO- http://api                              # fails: looks for api in team-a
```

---

## 4. Short names vs FQDN

All of these point to the same Service when called from a Pod in `default`:

| Name used | Works from same namespace | Works from another namespace |
|---|---|---|
| `backend` | Yes | No (resolves inside the caller's namespace) |
| `backend.default` | Yes | Yes |
| `backend.default.svc` | Yes | Yes |
| `backend.default.svc.cluster.local` | Yes | Yes |
| `backend.default.svc.cluster.local.` (trailing dot) | Yes | Yes, and skips the search list |

Using the FQDN is more explicit and avoids surprises, especially in config shared between namespaces. Short names are convenient for code that should work unchanged in dev, staging and prod namespaces.

---

## 5. How short names work: resolv.conf, search domains and ndots

The kubelet writes `/etc/resolv.conf` into every Pod whose `dnsPolicy` is `ClusterFirst` (the default). For a Pod in namespace `default` it looks like this:

```
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

(The nameserver address is the ClusterIP of the `kube-dns` Service; `10.96.0.10` is the usual kubeadm value but it differs between clusters. Extra search domains from the node may be appended too.)

How the resolver uses it:

- `search` is a list of suffixes the resolver may append to a name.
- `ndots:5` means: if the name has **fewer than 5 dots**, try it with each search suffix first, and only afterwards try it as an absolute name. If it has 5 or more dots, try it as absolute first.

Trace for `backend` (0 dots, so search list first):

1. `backend.default.svc.cluster.local` : exists, so the answer is returned and the search stops.

Trace for `db.prod` (1 dot):

1. `db.prod.default.svc.cluster.local` : no such record (NXDOMAIN)
2. `db.prod.svc.cluster.local` : found

Trace for an external name like `api.example.com` (2 dots, still below 5):

1. `api.example.com.default.svc.cluster.local` : NXDOMAIN
2. `api.example.com.svc.cluster.local` : NXDOMAIN
3. `api.example.com.cluster.local` : NXDOMAIN
4. `api.example.com` : resolved through the upstream DNS

That means external lookups cost a few wasted queries. Applications that make many external calls can write the name with a trailing dot (`api.example.com.`) or lower `ndots` with `dnsConfig`:

```yaml
spec:
  dnsConfig:
    options:
    - name: ndots
      value: "2"
```

---

## 6. Pod-to-Service communication example

A frontend Pod calling a backend Service in the same namespace:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend
spec:
  replicas: 2
  selector:
    matchLabels:
      app: backend
  template:
    metadata:
      labels:
        app: backend
    spec:
      containers:
      - name: nginx
        image: nginx:1.27
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: backend
spec:
  selector:
    app: backend
  ports:
  - port: 80
    targetPort: 80
---
apiVersion: v1
kind: Pod
metadata:
  name: frontend
spec:
  containers:
  - name: frontend
    image: busybox:1.36
    command: ["sleep", "3600"]
```

Calling it from the frontend Pod, all three forms are equivalent:

```bash
kubectl exec frontend -- wget -qO- http://backend
kubectl exec frontend -- wget -qO- http://backend.default
kubectl exec frontend -- wget -qO- http://backend.default.svc.cluster.local
```

Flow: the frontend asks the DNS server in its `resolv.conf` for `backend`, the search list turns it into `backend.default.svc.cluster.local`, CoreDNS answers with the Service ClusterIP, and kube-proxy rules then forward the connection to one of the backend Pods.

---

## 7. Headless Services and StatefulSet Pod DNS

A Service with `clusterIP: None` is **headless**. It has no virtual IP and no kube-proxy load balancing. Instead:

- a DNS lookup of the Service name returns the **A records of all ready Pods** behind it (the client picks one or uses them all);
- if the Pods belong to a StatefulSet (or set `hostname` and `subdomain` themselves), each Pod also gets its own stable name.

```
<pod-name>.<headless-service>.<namespace>.svc.<cluster-domain>
```

For a StatefulSet `web` using the headless Service `web` in namespace `shop`:

```
web-0.web.shop.svc.cluster.local
web-1.web.shop.svc.cluster.local
web-2.web.shop.svc.cluster.local
```

This is what lets a database replica always find "the primary" at `mysql-0.mysql...` even after the Pod has been rescheduled and its IP has changed.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: web
  namespace: shop
spec:
  clusterIP: None
  selector:
    app: web
  ports:
  - port: 80
```

---

## 8. Pod A records

Every Pod IP can also be addressed by a DNS name built from the IP with the dots replaced by dashes:

```
<pod-ip-with-dashes>.<namespace>.pod.<cluster-domain>
10-244-1-5.default.pod.cluster.local      # Pod IP 10.244.1.5 in namespace default
```

This form carries no information beyond the IP itself, and whether it resolves depends on the CoreDNS `pods` setting (`pods insecure` in the default config answers it without checking that the Pod exists). I would not use it in applications; Service names are the right abstraction.

---

## 9. ExternalName Services

An `ExternalName` Service has no selector and no ClusterIP. DNS answers with a **CNAME** pointing at an external hostname. It lets Pods use an internal name for something outside the cluster, such as a managed database.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: orders-db
  namespace: prod
spec:
  type: ExternalName
  externalName: orders.abc123.ap-south-1.rds.amazonaws.com
```

`orders-db.prod.svc.cluster.local` now resolves to a CNAME for the RDS hostname. No proxying happens. The redirection is purely in DNS, so protocols that care about the original host name (HTTP `Host` header, TLS certificate names) can behave unexpectedly when the client connects using the internal name.

---

## 10. Table of example FQDNs

| Resource | Example FQDN | What it resolves to |
|---|---|---|
| ClusterIP Service `backend` in `default` | `backend.default.svc.cluster.local` | Service ClusterIP |
| Service `db` in namespace `prod` | `db.prod.svc.cluster.local` | Service ClusterIP |
| Kubernetes API Service | `kubernetes.default.svc.cluster.local` | API server ClusterIP |
| DNS Service | `kube-dns.kube-system.svc.cluster.local` | Cluster DNS ClusterIP |
| Headless Service `mysql` in `data` | `mysql.data.svc.cluster.local` | A records of all ready Pods |
| StatefulSet Pod `mysql-0` | `mysql-0.mysql.data.svc.cluster.local` | IP of that one Pod |
| Pod with IP 10.244.1.5 in `default` | `10-244-1-5.default.pod.cluster.local` | 10.244.1.5 |
| Named port `http` (TCP) on `backend` | `_http._tcp.backend.default.svc.cluster.local` | SRV record (port + target) |
| ExternalName Service `orders-db` in `prod` | `orders-db.prod.svc.cluster.local` | CNAME to the external host |

---

## 11. Commands to try

Run these on minikube or any cluster to see the names for myself.

```bash
# Quick lookups from a throw-away Pod
kubectl run dns-test --rm -it --image=busybox:1.36 --restart=Never -- nslookup kubernetes.default
kubectl run dns-test --rm -it --image=busybox:1.36 --restart=Never -- nslookup kubernetes.default.svc.cluster.local
kubectl run dns-test --rm -it --image=busybox:1.36 --restart=Never -- nslookup backend.default.svc.cluster.local
kubectl run dns-test --rm -it --image=busybox:1.36 --restart=Never -- nslookup kube-dns.kube-system.svc.cluster.local

# Look at resolv.conf inside an existing Pod (search domains and ndots)
kubectl exec -it frontend -- cat /etc/resolv.conf

# Same, for a Pod in another namespace
kubectl -n team-a exec client -- cat /etc/resolv.conf

# Headless Service / StatefulSet Pod names
kubectl run dns-test --rm -it --image=busybox:1.36 --restart=Never -- nslookup mysql.data.svc.cluster.local
kubectl run dns-test --rm -it --image=busybox:1.36 --restart=Never -- nslookup mysql-0.mysql.data.svc.cluster.local

# Find the cluster DNS Service IP
kubectl -n kube-system get svc kube-dns

# Trailing dot vs no trailing dot
kubectl exec frontend -- nslookup backend.default.svc.cluster.local.
```

The `nslookup` bundled in busybox is quite basic: it does not apply the `search` list like a full resolver does. For the real runs below I therefore used an image that ships `dig` and the full `nslookup` (`infoblox/dnstools`); the Kubernetes DNS debugging docs use the `agnhost` test image for the same purpose.

---

## Hands-on output (real)

Everything below was run in my Minikube cluster (Kubernetes v1.37.0), using the objects from the [Service exercise](../README.md): the `whoami` Deployment, the `whoami-clusterip` Service (port 8080), the `web` StatefulSet with the `web-headless` Service, and a `dns-client` Pod (image with `dig`, `nslookup` and `curl`) in the `default` namespace.

### 1. What the Pod uses to resolve names (`/etc/resolv.conf`)

_The nameserver is the cluster DNS Service (CoreDNS). The `search` line lists the suffixes appended to short names, and `ndots:5` means a name with fewer than 5 dots is tried with those suffixes first._

```console
$ kubectl exec dns-client -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

_The same IP as the nameserver above: the DNS Service._

```console
$ kubectl get svc kube-dns -n kube-system -o jsonpath="kube-dns ClusterIP = {.spec.clusterIP}{\"\\n\"}"
kube-dns ClusterIP = 10.96.0.10
```

### 2. Short name, partial name and full FQDN

_The address that every form of the name below should return._

```console
$ kubectl get svc whoami-clusterip -o jsonpath="Service ClusterIP = {.spec.clusterIP}{\"\\n\"}"
Service ClusterIP = 10.99.227.182
```

_**Short name** `whoami-clusterip`: resolved because the `search` list adds `default.svc.cluster.local`._

```console
$ kubectl exec dns-client -- nslookup whoami-clusterip
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	whoami-clusterip.default.svc.cluster.local
Address: 10.99.227.182
```

_**Partial name** `<service>.<namespace>`: also works._

```console
$ kubectl exec dns-client -- nslookup whoami-clusterip.default
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	whoami-clusterip.default.svc.cluster.local
Address: 10.99.227.182
```

_**Full FQDN** `<service>.<namespace>.svc.<cluster-domain>`: always works, from any namespace. All three return the same ClusterIP._

```console
$ kubectl exec dns-client -- nslookup whoami-clusterip.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	whoami-clusterip.default.svc.cluster.local
Address: 10.99.227.182
```

_With the trailing dot the name is absolute (no search list is applied). The answer shows the record type A and the TTL._

```console
$ kubectl exec dns-client -- dig whoami-clusterip.default.svc.cluster.local. +noall +answer

; <<>> DiG 9.11.3 <<>> whoami-clusterip.default.svc.cluster.local. +noall +answer
;; global options: +cmd
whoami-clusterip.default.svc.cluster.local. 30 IN A 10.99.227.182
```

### 3. Namespace-based DNS

The same short name means different things in different namespaces. I create a second namespace with its own client:

_A client Pod in the namespace demo-ns._

```console
$ kubectl create namespace demo-ns && kubectl run client -n demo-ns --image=infoblox/dnstools:latest --restart=Never --command -- sleep 900 && kubectl wait -n demo-ns --for=condition=Ready pod/client --timeout=120s
namespace/demo-ns created
pod/client created
pod/client condition met
```

_Its search list starts with its **own** namespace: demo-ns.svc.cluster.local._

```console
$ kubectl exec -n demo-ns client -- grep search /etc/resolv.conf
search demo-ns.svc.cluster.local svc.cluster.local cluster.local
```

_The short name fails here: it would be looked up as whoami-clusterip.demo-ns.svc.cluster.local, and there is no such Service in demo-ns (exit code 6 = could not resolve host)._

```console
$ kubectl exec -n demo-ns client -- curl -s -m 5 http://whoami-clusterip:8080; echo "curl exit code: $?"
command terminated with exit code 6
curl exit code: 6
```

_Adding the namespace (`<service>.<namespace>`) reaches the Service in `default`: this is how Pods call Services in other namespaces._

```console
$ kubectl exec -n demo-ns client -- curl -s http://whoami-clusterip.default:8080 | head -n 3
Hostname: whoami-784794f757-6h7zz
IP: 127.0.0.1
IP: ::1
```

_The FQDN gives the same answer as from the default namespace._

```console
$ kubectl exec -n demo-ns client -- nslookup whoami-clusterip.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	whoami-clusterip.default.svc.cluster.local
Address: 10.99.227.182
```

### 4. Pod-to-Service communication

A frontend Pod talks to a backend Service by name; DNS turns the name into the ClusterIP and kube-proxy sends the traffic to one of the Pods.

_The client calls the Service by FQDN and gets an answer from one backend Pod (Hostname = the Pod that answered)._

```console
$ kubectl exec dns-client -- curl -s http://whoami-clusterip.default.svc.cluster.local:8080 | head -n 4
Hostname: whoami-784794f757-6h7zz
IP: 127.0.0.1
IP: ::1
IP: 10.244.0.148
```

### 5. Other kinds of Kubernetes DNS names

_**Headless Service**: the name resolves to all Pod IPs._

```console
$ kubectl exec dns-client -- dig +short web-headless.default.svc.cluster.local
10.244.0.150
10.244.0.151
10.244.0.152
```

_**Stable StatefulSet Pod name** `<pod>.<headless-service>.<ns>.svc.cluster.local`: one specific Pod._

```console
$ kubectl exec dns-client -- dig +short web-0.web-headless.default.svc.cluster.local
10.244.0.150
```

_**Pod A record**: the Pod IP with dots replaced by dashes, in the `pod.cluster.local` zone._

```console
$ POD_IP=$(kubectl get pod web-1 -o jsonpath="{.status.podIP}"); DASHED=$(echo $POD_IP | tr . -); echo "Pod IP $POD_IP -> $DASHED.default.pod.cluster.local"; kubectl exec dns-client -- dig +short $DASHED.default.pod.cluster.local
Pod IP 10.244.0.151 -> 10-244-0-151.default.pod.cluster.local
10.244.0.151
```

_**SRV record** for a named Service port: format `_<port-name>._<protocol>.<service>.<namespace>.svc.cluster.local` (the answer carries port 8080 and the target name)._

```console
$ kubectl exec dns-client -- dig +short SRV _http._tcp.whoami-clusterip.default.svc.cluster.local
0 100 8080 whoami-clusterip.default.svc.cluster.local.
```

_**ExternalName Service**: a CNAME to the external name (from the Service exercise)._

```console
$ kubectl exec dns-client -- dig external-web.default.svc.cluster.local +noall +answer

; <<>> DiG 9.11.3 <<>> external-web.default.svc.cluster.local +noall +answer
;; global options: +cmd
external-web.default.svc.cluster.local.	30 IN CNAME example.com.
example.com.		30	IN	A	172.66.147.243
example.com.		30	IN	A	104.20.23.154
```

_The cluster domain `cluster.local` is set by the `kubernetes` plugin in the CoreDNS configuration._

```console
$ kubectl get configmap coredns -n kube-system -o jsonpath="{.data.Corefile}" | grep kubernetes
    kubernetes cluster.local in-addr.arpa ip6.arpa {
```

### Summary table of real names from this cluster

| Object | Name that resolved |
|---|---|
| Service | `whoami-clusterip.default.svc.cluster.local` |
| Service from another namespace (shortest form) | `whoami-clusterip.default` |
| Headless Service | `web-headless.default.svc.cluster.local` (all Pod IPs) |
| StatefulSet Pod | `web-0.web-headless.default.svc.cluster.local` |
| Pod | `<ip-with-dashes>.default.pod.cluster.local` |
| ExternalName | `external-web.default.svc.cluster.local` (CNAME `example.com.`) |

_Cleanup of the test namespace._

```console
$ kubectl delete namespace demo-ns --wait=false
namespace "demo-ns" deleted
```
