# Session 11 — Kubernetes Networking & Services

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Topic:** ClusterIP, NodePort, LoadBalancer, ExternalName and Headless services, plus
cluster DNS and FQDNs

Run against a real 3-node cluster. Every output block is actual terminal output.

---

## 0. Why Services exist

Pod IPs are **ephemeral**. Every rolling update, crash or reschedule gives a pod a new IP,
so nothing can hard-code one. A **Service** is a stable virtual IP plus a stable DNS name in
front of a *set* of pods chosen by a label selector. It is the abstraction that makes pods
disposable.

### The backend used throughout

```yaml
# 00-backend-deployment.yaml — 3 replicas, labelled app=backend, listening on 5678
```

```bash
kubectl apply -f 00-backend-deployment.yaml
kubectl get pods -l app=backend -o wide
```

```
backend-745f9b998b-8f7qf	10.244.2.16
backend-745f9b998b-n6vr6	10.244.1.16
backend-745f9b998b-pm98n	10.244.2.15
```

A `client` pod (netshoot, with `curl`, `dig` and `nslookup`) was also created to test from
inside the cluster.

---

## 1. ClusterIP — the default, internal only

```yaml
# 01-clusterip.yaml
apiVersion: v1
kind: Service
metadata:
  name: backend-clusterip
spec:
  type: ClusterIP          # the default - reachable only from inside the cluster
  selector:
    app: backend
  ports:
    - name: http
      port: 80             # the port the Service listens on
      targetPort: 5678     # the port on the pod
```

```bash
kubectl apply -f 01-clusterip.yaml
kubectl get svc backend-clusterip
```

```
NAME                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
backend-clusterip   ClusterIP   10.96.115.106   <none>        80/TCP    0s
```

`EXTERNAL-IP` is `<none>` — that is the definition of ClusterIP. `10.96.115.106` is a
**virtual IP**: no network interface anywhere has it. kube-proxy programs iptables/IPVS
rules on every node that rewrite traffic destined for it to a real pod IP.

### 1.1 Endpoints — the link between Service and pods

```bash
kubectl get endpoints backend-clusterip
```

```
NAME                ENDPOINTS                                            AGE
backend-clusterip   10.244.1.16:5678,10.244.2.15:5678,10.244.2.16:5678   0s
```

Those are exactly the three backend pod IPs from section 0. The endpoints controller watches
for pods matching the selector **that are Ready**, and maintains this list. `port` → the
Service's port (80), `targetPort` → the container's port (5678); the endpoints show
`targetPort`.

### 1.2 Reaching the Service

```bash
kubectl exec client -- curl -s http://backend-clusterip/
kubectl exec client -- curl -s http://10.96.115.106/
```

```
Hello from backend pod
Hello from backend pod
```

By **name** and by **ClusterIP** — both work, both from inside the cluster.

### 1.3 Load balancing — proven

To show the traffic is really spread across pods I used `traefik/whoami`, which reports the
hostname of the pod that answered:

```bash
kubectl create deployment whoami --image=traefik/whoami --replicas=3
kubectl expose deployment whoami --port=80 --target-port=80 --name=whoami-svc
kubectl get endpoints whoami-svc
```

```
whoami-769454856f-cfmjc	10.244.2.17
whoami-769454856f-tmjx5	10.244.1.18
whoami-769454856f-vfrp7	10.244.1.19

NAME         ENDPOINTS                                      AGE
whoami-svc   10.244.1.18:80,10.244.1.19:80,10.244.2.17:80   8s
```

```bash
kubectl exec client -- sh -c 'for i in $(seq 1 20); do curl -s http://whoami-svc/ | grep "^Hostname:"; done | sort | uniq -c | sort -rn'
```

```
      8 Hostname: whoami-769454856f-vfrp7
      6 Hostname: whoami-769454856f-tmjx5
      6 Hostname: whoami-769454856f-cfmjc
```

**20 requests, spread 8 / 6 / 6 across all three pods.** The distribution is random rather
than strict round-robin, which is exactly how iptables-mode kube-proxy works: it installs a
probabilistic rule per endpoint.

One full response shows what is happening underneath:

```
Hostname: whoami-769454856f-tmjx5
IP: 10.244.1.18
RemoteAddr: 10.244.1.17:39736
GET / HTTP/1.1
Host: whoami-svc
```

`RemoteAddr` is the **client pod's** IP — the Service did not proxy through any intermediate
host. The connection is rewritten by the kernel and goes pod-to-pod directly.

### 1.4 Endpoints track scaling automatically

```bash
kubectl scale deploy/whoami --replicas=1 ; kubectl get endpoints whoami-svc
```

```
NAME         ENDPOINTS        AGE
whoami-svc   10.244.2.17:80   17s
```

```bash
kubectl scale deploy/whoami --replicas=3 ; kubectl get endpoints whoami-svc
```

```
NAME         ENDPOINTS                                      AGE
whoami-svc   10.244.1.20:80,10.244.1.21:80,10.244.2.17:80   29s
```

Scaled down to 1 endpoint, back up to 3 — with **new IPs** for the new pods. Nothing had to
be reconfigured. This is the whole value of the Service abstraction.

---

## 2. Cluster DNS and FQDNs

```bash
kubectl exec client -- cat /etc/resolv.conf
```

```
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

This one file explains Kubernetes DNS:

- **`nameserver 10.96.0.10`** — CoreDNS, itself reached through a ClusterIP Service.
- **`search ...`** — the suffixes tried for a short name. From a pod in `default`, the name
  `backend-clusterip` is tried as `backend-clusterip.default.svc.cluster.local` first, which
  is why short names work.
- **`options ndots:5`** — any name with fewer than 5 dots goes through the search list first.
  (This is also a classic performance gotcha: looking up `github.com` burns several failed
  queries through the search domains before the real one succeeds.)

```bash
kubectl exec client -- nslookup backend-clusterip
```

```
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	backend-clusterip.default.svc.cluster.local
Address: 10.96.115.106
```

The short name resolved to the **FQDN** and then to the ClusterIP.

### The FQDN format

```
<service-name>.<namespace>.svc.<cluster-domain>
backend-clusterip . default   . svc . cluster.local
```

All three forms work:

```bash
curl http://whoami-svc/
curl http://whoami-svc.default/
curl http://whoami-svc.default.svc.cluster.local/
```

```
whoami-svc -> 200
whoami-svc.default -> 200
whoami-svc.default.svc.cluster.local -> 200
```

| Name form | Works from |
|---|---|
| `backend-clusterip` | Pods in the **same** namespace |
| `backend-clusterip.default` | Any namespace |
| `backend-clusterip.default.svc.cluster.local` | Anywhere — unambiguous, best for config files |

---

## 3. NodePort — exposing on every node

```yaml
# 02-nodeport.yaml
spec:
  type: NodePort
  ports:
    - port: 80
      targetPort: 5678
      nodePort: 30080      # must be in 30000-32767
```

```bash
kubectl apply -f 02-nodeport.yaml
kubectl get svc backend-nodeport
```

```
NAME               TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
backend-nodeport   NodePort   10.96.237.99   <none>        80:30080/TCP   0s
```

`80:30080/TCP` — the Service port **and** the node port. A NodePort is a superset of a
ClusterIP: it still gets a ClusterIP, and additionally opens port 30080 on **every node**.

```bash
kubectl exec client -- curl -s http://backend-nodeport/     # still works internally
```

```
Hello from backend pod
```

### 3.1 The same port answers on every node

```bash
for n in $(kubectl get nodes -o jsonpath='{.items[*].status.addresses[0].address}'); do
  curl http://$n:30080/
done
```

```
node 172.22.0.4:30080 -> Hello from backend pod
node 172.22.0.2:30080 -> Hello from backend pod
node 172.22.0.3:30080 -> Hello from backend pod
```

**All three nodes answer on port 30080** — including nodes with no backend pod on them. If
the request lands on a node without a local pod, kube-proxy forwards it to a node that has
one. That is why you can point an external load balancer at any node.

### Downsides of NodePort

- The port range is restricted to 30000–32767, so you cannot serve on 80/443 directly.
- You must know the node IPs, and they change as nodes come and go.
- One port per Service, cluster-wide.

Fine for development; for production you use LoadBalancer or an Ingress.

---

## 4. LoadBalancer — asking the cloud for an external IP

```yaml
# 03-loadbalancer.yaml
spec:
  type: LoadBalancer
```

```bash
kubectl apply -f 03-loadbalancer.yaml
kubectl get svc backend-loadbalancer
```

```
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
backend-loadbalancer   LoadBalancer   10.96.140.163   <pending>     80:32544/TCP   8s
```

**`EXTERNAL-IP: <pending>` is the correct and expected result here**, and it is worth
understanding rather than treating as a failure. A LoadBalancer Service does not implement a
load balancer itself — it asks the **cloud provider's** controller to provision one (an AWS
ELB, a GCP forwarding rule, an Azure LB). This is a local cluster with no cloud controller,
so nothing ever fulfils the request and it stays pending forever. On EKS/GKE/AKS an address
would appear within a minute. (Locally you can install MetalLB to fill that role.)

```bash
kubectl describe svc backend-loadbalancer
```

```
Type:                     LoadBalancer
IP:                       10.96.140.163
Port:                     http  80/TCP
TargetPort:               5678/TCP
NodePort:                 http  32544/TCP
Endpoints:                10.244.2.15:5678,10.244.1.16:5678,10.244.2.16:5678
Session Affinity:         None
External Traffic Policy:  Cluster
```

Note it has a **ClusterIP *and* a NodePort (32544)** of its own. The types build on each
other: `LoadBalancer ⊃ NodePort ⊃ ClusterIP`. The cloud load balancer, once provisioned,
simply forwards to that node port on every node.

`External Traffic Policy: Cluster` means any node may forward to a pod on another node —
convenient, but it hides the original client IP. Setting it to `Local` preserves the client
IP but only routes to pods on the receiving node.

---

## 5. ExternalName — a DNS alias to something outside the cluster

```yaml
# 04-externalname.yaml
spec:
  type: ExternalName       # pure DNS CNAME - no selector, no endpoints, no proxying
  externalName: github.com
```

```bash
kubectl apply -f 04-externalname.yaml
kubectl get svc external-github
```

```
NAME              TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
external-github   ExternalName   <none>       github.com    <none>    0s
```

No ClusterIP, no ports.

```bash
kubectl exec client -- nslookup external-github.default.svc.cluster.local
```

```
external-github.default.svc.cluster.local	canonical name = github.com.
Name:	github.com
Address: 20.207.73.82
```

**CoreDNS returned a CNAME.** That is all an ExternalName Service is — a DNS record. No
proxying, no load balancing, no traffic through kube-proxy at all.

```bash
kubectl get endpoints external-github
```

```
Error from server (NotFound): endpoints "external-github" not found
```

There are no endpoints, and there cannot be — there is no selector and no pods.

**Where it is genuinely useful:** point your app at `db.default.svc.cluster.local` in every
environment. In production that ExternalName aliases the managed RDS hostname; in staging
you swap it for a real ClusterIP in front of an in-cluster database. The application config
never changes.

---

## 6. Headless Service — DNS returns the pod IPs

```yaml
# 05-headless.yaml
spec:
  clusterIP: None          # headless - DNS returns the POD IPs, not a virtual IP
  selector:
    app: backend
```

```bash
kubectl apply -f 05-headless.yaml
kubectl get svc backend-headless
kubectl get svc backend-headless -o jsonpath='clusterIP={.spec.clusterIP}'
```

```
NAME               TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
backend-headless   ClusterIP   None         <none>        80/TCP    0s

clusterIP=None
```

### The defining behaviour

```bash
kubectl exec client -- nslookup backend-headless.default.svc.cluster.local
```

```
Name:	backend-headless.default.svc.cluster.local
Address: 10.244.1.16
Name:	backend-headless.default.svc.cluster.local
Address: 10.244.2.16
Name:	backend-headless.default.svc.cluster.local
Address: 10.244.2.15
```

**Three A records — one per pod.** Compare with the pod list:

```bash
kubectl get pods -l app=backend -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.status.podIP}{"\n"}{end}'
```

```
backend-745f9b998b-8f7qf	10.244.2.16
backend-745f9b998b-n6vr6	10.244.1.16
backend-745f9b998b-pm98n	10.244.2.15
```

They match exactly. A normal Service hands you **one** virtual IP and hides the pods behind
it; a headless Service hands you **all** the pod IPs and steps out of the way. There is no
kube-proxy involvement and no load balancing — the client decides which pod to talk to.

### Why that matters

- **StatefulSets.** Each pod gets its own stable DNS name
  (`mysql-0.mysql.default.svc.cluster.local`), which is how database replicas find each
  other and how you address a *specific* primary or replica.
- **Client-side load balancing.** gRPC clients want the full endpoint list so they can
  maintain persistent connections to each backend and balance per-request. A ClusterIP would
  pin them to a single pod for the life of the connection.
- **Peer discovery** for clustered software — Kafka, Cassandra, Elasticsearch.

---

## 7. All five types side by side

```bash
kubectl get svc
```

```
NAME                   TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
backend-clusterip      ClusterIP      10.96.115.106   <none>        80/TCP         13s
backend-headless       ClusterIP      None            <none>        80/TCP         1s
backend-loadbalancer   LoadBalancer   10.96.140.163   <pending>     80:32544/TCP   10s
backend-nodeport       NodePort       10.96.237.99    <none>        80:30080/TCP   11s
external-github        ExternalName   <none>          github.com    <none>         2s
kubernetes             ClusterIP      10.96.0.1       <none>        443/TCP        23m
```

```bash
kubectl get svc -o custom-columns='NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP,PORT:.spec.ports[0].port,NODEPORT:.spec.ports[0].nodePort,EXTERNALNAME:.spec.externalName'
```

```
NAME                   TYPE           CLUSTER-IP      PORT     NODEPORT   EXTERNALNAME
backend-clusterip      ClusterIP      10.96.115.106   80       <none>     <none>
backend-headless       ClusterIP      None            80       <none>     <none>
backend-loadbalancer   LoadBalancer   10.96.140.163   80       32544      <none>
backend-nodeport       NodePort       10.96.237.99    80       30080      <none>
external-github        ExternalName   <none>          <none>   <none>     github.com
```

| Type | ClusterIP | NodePort | External IP | Reachable from | Use it for |
|---|---|---|---|---|---|
| **ClusterIP** | Yes | No | No | Inside the cluster only | Internal service-to-service (the default) |
| **NodePort** | Yes | Yes | No | `<any-node-ip>:30000-32767` | Dev/test, or behind an external LB |
| **LoadBalancer** | Yes | Yes | Yes (cloud) | The internet | Production external access on a cloud provider |
| **ExternalName** | No | No | CNAME | DNS only | Aliasing an external service into cluster DNS |
| **Headless** | **None** | No | No | Inside; DNS returns pod IPs | StatefulSets, gRPC, peer discovery |

---

## 8. Debugging: the most common Service failure

```bash
kubectl create service clusterip broken-svc --tcp=80:5678
kubectl get endpoints broken-svc
```

```
NAME         ENDPOINTS   AGE
broken-svc   <none>      0s
```

**`ENDPOINTS: <none>`** is the single most useful diagnostic in Kubernetes networking. The
Service exists and DNS resolves, but there are no pods behind it, so every connection is
refused or times out. It almost always means one of:

1. The Service **selector does not match** the pod labels (a typo, or the wrong key).
2. The pods exist but are **not Ready** — failing readiness probes are excluded from
   endpoints by design.
3. `targetPort` does not match the port the container actually listens on.

### Debugging order

```bash
kubectl get svc <name>                        # does it exist? what type and ports?
kubectl get endpoints <name>                  # <none> => selector/readiness problem
kubectl get pods -l <selector> -o wide        # do matching pods exist and are they Ready?
kubectl describe svc <name>                   # selector, ports, endpoints in one view
kubectl exec <client> -- nslookup <name>      # does DNS resolve?
kubectl exec <client> -- curl -v http://<name>:<port>/
kubectl port-forward svc/<name> 8080:80       # bypass DNS and kube-proxy entirely
```

`port-forward` is the useful tie-breaker: if it works but the Service name does not, the
problem is DNS or kube-proxy, not your application.

---

## 9. How a Service actually works

1. You create a Service with a **label selector**.
2. The **endpoints controller** watches for Ready pods matching that selector and keeps an
   EndpointSlice up to date.
3. **CoreDNS** creates a DNS record for the Service name → ClusterIP (or → pod IPs, if
   headless).
4. **kube-proxy** on *every* node watches Services and endpoints, and programs
   iptables/IPVS rules that DNAT traffic for the ClusterIP to one of the pod IPs, chosen
   probabilistically.
5. A pod connects to the name → DNS gives the ClusterIP → the kernel rewrites the
   destination → the packet goes straight to a pod.

There is no proxy process in the data path, which is why Service traffic costs almost
nothing.

---

## Files in this folder

| File | Purpose |
|---|---|
| `00-backend-deployment.yaml` | 3-replica backend the Services point at |
| `01-clusterip.yaml` | ClusterIP Service |
| `02-nodeport.yaml` | NodePort Service (`nodePort: 30080`) |
| `03-loadbalancer.yaml` | LoadBalancer Service |
| `04-externalname.yaml` | ExternalName Service |
| `05-headless.yaml` | Headless Service (`clusterIP: None`) |
| `06-client-pod.yaml` | netshoot client pod used for all in-cluster tests |
| `k8s-services-transcript.txt` | Full terminal transcript |
| `k8s-services-loadbalancing-transcript.txt` | Load-balancing and DNS transcript |

## Summary

| Item | Status |
|---|---|
| ClusterIP — created, endpoints verified, reached by name and by IP | Done |
| Load balancing across 3 pods proven (20 requests spread 8/6/6) | Done |
| Endpoints shown tracking scale-down and scale-up automatically | Done |
| Cluster DNS, `/etc/resolv.conf`, search domains and all three FQDN forms | Done |
| NodePort — created and reached on port 30080 of **all three** nodes | Done |
| LoadBalancer — created; `<pending>` explained, and its built-in NodePort/ClusterIP shown | Done |
| ExternalName — created, CNAME resolution verified, absence of endpoints confirmed | Done |
| Headless — created, DNS returning all three pod IPs matched against the real pod IPs | Done |
| Service debugging — the `ENDPOINTS: <none>` failure demonstrated | Done |
