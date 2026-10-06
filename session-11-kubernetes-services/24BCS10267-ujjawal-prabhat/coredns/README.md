# Task 4 - CoreDNS

**Ujjawal Prabhat - 24BCS10267 - Session 11**

## What is CoreDNS?

CoreDNS is the cluster DNS server for Kubernetes (it replaced kube-dns in v1.13 and is a CNCF graduated project). It is a Go DNS server
built from a chain of **plugins** configured by a `Corefile`. In the cluster it runs as a Deployment in `kube-system`, behind
a Service that is still called **`kube-dns`** for backward compatibility. Every pod's `/etc/resolv.conf` points to that Service IP.

## Why do we need it?

- Pod and Service IPs change all the time. Apps need **stable names** (`web-clusterip.s11`), not IPs.
- **Service discovery**: CoreDNS watches the API server (Services, EndpointSlices, Pods) and turns them into DNS records automatically.
  No registration step is needed.
- It forwards everything else (internet names) to the upstream resolver, so pods use one resolver for everything.
- It caches answers, which cuts latency and load on upstream DNS.

## In this cluster

```
$ kubectl -n kube-system get deploy coredns -o wide
NAME      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                    SELECTOR
coredns   2/2     2            2           62m   coredns      registry.k8s.io/coredns/coredns:v1.14.6   k8s-app=kube-dns

$ kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
NAME                       READY   STATUS    RESTARTS   AGE   IP           NODE                         NOMINATED NODE   READINESS GATES
coredns-559f6c778d-9v66h   1/1     Running   0          62m   10.244.0.4   devops-heros-control-plane   <none>           <none>
coredns-559f6c778d-jrrhj   1/1     Running   0          62m   10.244.0.3   devops-heros-control-plane   <none>           <none>

$ kubectl -n kube-system get svc kube-dns -o wide
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE   SELECTOR
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   62m   k8s-app=kube-dns

$ kubectl -n kube-system get endpointslices -l kubernetes.io/service-name=kube-dns
NAME             ADDRESSTYPE   PORTS        ENDPOINTS               AGE
kube-dns-5k2lw   IPv4          53,53,9153   10.244.0.4,10.244.0.3   62m
```

Two replicas for HA, both on the control-plane node, with the `10.96.0.10` VIP load-balancing across them. Port 9153 serves Prometheus metrics.

## The real Corefile

```
$ kubectl -n kube-system get cm coredns -o yaml
apiVersion: v1
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
        forward . /etc/resolv.conf {
           max_concurrent 1000
        }
        cache 30 {
           disable success cluster.local
           disable denial cluster.local
        }
        loop
        reload
        loadbalance
    }
kind: ConfigMap
metadata:
  creationTimestamp: "2026-10-06T10:48:38Z"
  name: coredns
  namespace: kube-system
  resourceVersion: "235"
  uid: 8705ba7f-4faf-47bd-bc91-be5c1f3118fc
```

| Plugin | What it does |
|---|---|
| `.:53` | Server block: handle **all** zones (`.`) on port 53 |
| `errors` | Log errors to stdout |
| `health { lameduck 5s }` | `:8080/health` liveness endpoint. On shutdown it keeps answering for 5 s while it drains |
| `ready` | `:8181/ready` readiness endpoint (ready once all plugins are ready) |
| `kubernetes cluster.local in-addr.arpa ip6.arpa` | **Service discovery**: answers `*.cluster.local` and reverse lookups from the Kubernetes API. `pods insecure` enables `a-b-c-d.ns.pod.cluster.local` records. `fallthrough` passes unknown reverse lookups on. `ttl 30` is the TTL of the answers (the `30` seen in every `dig` answer) |
| `prometheus :9153` | Metrics endpoint |
| `forward . /etc/resolv.conf` | Anything not answered above goes to the **node's** upstream resolver (Docker Desktop DNS here) |
| `cache 30 { disable success/denial cluster.local }` | Cache external answers up to 30 s. This newer default does **not** cache `cluster.local`, so service changes show up at once |
| `loop` | Detects forwarding loops (CoreDNS forwarding to itself) and stops |
| `reload` | Applies Corefile changes from the ConfigMap without a restart |
| `loadbalance` | Randomizes the order of A records in each answer (round-robin for headless services) |

```
$ kubectl -n kube-system logs -l k8s-app=kube-dns --tail=5 --prefix
[pod/coredns-559f6c778d-9v66h/coredns] maxprocs: Leaving GOMAXPROCS=10: CPU quota undefined
[pod/coredns-559f6c778d-9v66h/coredns] .:53
[pod/coredns-559f6c778d-9v66h/coredns] [INFO] plugin/reload: Running configuration SHA512 = 1b226df79860026c6a52e67daa10d7f0d57ec5b023288ec00c5e05f93523c894564e15b91770d3a07ae1cfbe861d15b37d4a0027e69c546ab112970993a3b03b
[pod/coredns-559f6c778d-9v66h/coredns] CoreDNS-1.14.6
[pod/coredns-559f6c778d-9v66h/coredns] linux/arm64, go1.26.5, 424d125
[pod/coredns-559f6c778d-jrrhj/coredns] maxprocs: Leaving GOMAXPROCS=10: CPU quota undefined
[pod/coredns-559f6c778d-jrrhj/coredns] .:53
[pod/coredns-559f6c778d-jrrhj/coredns] [INFO] plugin/reload: Running configuration SHA512 = 1b226df79860026c6a52e67daa10d7f0d57ec5b023288ec00c5e05f93523c894564e15b91770d3a07ae1cfbe861d15b37d4a0027e69c546ab112970993a3b03b
[pod/coredns-559f6c778d-jrrhj/coredns] CoreDNS-1.14.6
[pod/coredns-559f6c778d-jrrhj/coredns] linux/arm64, go1.26.5, 424d125
```

## Query resolution flow

```
 app in pod (namespace s11) calls  web-clusterip
   │
   ▼ 1. libc resolver reads /etc/resolv.conf (nameserver 10.96.0.10, search s11.svc.cluster.local ..., ndots:5)
   │    "web-clusterip" has 0 dots < 5  ->  tries web-clusterip.s11.svc.cluster.local first
   ▼ 2. UDP :53 to 10.96.0.10 (kube-dns ClusterIP); kube-proxy DNATs it to one CoreDNS pod (10.244.0.3 / .4)
   ▼ 3. CoreDNS plugin chain:
   │      kubernetes plugin -> zone cluster.local matches -> looks up Service s11/web-clusterip in its API watch cache
   │        ClusterIP svc  -> A 10.96.213.135
   │        headless svc   -> A <each ready pod IP>
   │        ExternalName   -> CNAME example.com (then resolves the CNAME target)
   │        not found      -> NXDOMAIN  (resolver then tries the next search suffix)
   │      other zones (example.com) -> cache -> forward to /etc/resolv.conf upstream
   ▼ 4. answer (TTL 30) back to the pod; the app connects to 10.96.213.135:8080; kube-proxy picks a backend pod
```

A full `dig` against CoreDNS. The `aa` (authoritative) flag means CoreDNS answered from its own Kubernetes data:

```
$ kubectl -n s11 exec dnsutils -- dig web-clusterip.s11.svc.cluster.local

; <<>> DiG 9.9.5-9+deb8u15-Debian <<>> web-clusterip.s11.svc.cluster.local
;; global options: +cmd
;; Got answer:
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14290
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 4096
;; QUESTION SECTION:
;web-clusterip.s11.svc.cluster.local. IN	A

;; ANSWER SECTION:
web-clusterip.s11.svc.cluster.local. 30	IN A	10.96.213.135

;; Query time: 0 msec
;; SERVER: 10.96.0.10#53(10.96.0.10)
;; WHEN: Tue Oct 06 11:51:18 UTC 2026
;; MSG SIZE  rcvd: 115
```

External name through `forward` (the upstream answer comes back with TTL 30):

```
$ kubectl -n s11 exec dnsutils -- dig +noall +answer +stats example.com | grep -E 'IN|Query time|SERVER'
example.com.		30	IN	A	104.20.23.154
example.com.		30	IN	A	172.66.147.243
;; Query time: 1 msec
;; SERVER: 10.96.0.10#53(10.96.0.10)

$ kubectl -n s11 exec dnsutils -- dig +noall +answer +stats example.com | grep -E 'IN|Query time|SERVER'
example.com.		30	IN	A	104.20.23.154
example.com.		30	IN	A	172.66.147.243
;; Query time: 1 msec
;; SERVER: 10.96.0.10#53(10.96.0.10)
```

## Troubleshooting DNS - real drill

I deployed a pod with a DNS misconfiguration ([`broken-dns-pod.yaml`](broken-dns-pod.yaml), `dnsPolicy: Default`), then followed the standard checklist:

```
$ kubectl apply -f broken-dns-pod.yaml
pod/broken-dns created

## Step 1: reproduce
$ kubectl -n s11 exec broken-dns -- nslookup web-clusterip.s11.svc.cluster.local
Server:		192.168.65.254
Address:	192.168.65.254#53

** server can't find web-clusterip.s11.svc.cluster.local: SERVFAIL

command terminated with exit code 1

## Step 2: is the problem the pod or cluster DNS? test from a known-good pod
$ kubectl -n s11 exec dnsutils -- nslookup kubernetes.default
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	kubernetes.default.svc.cluster.local
Address: 10.96.0.1


## Step 3: check the pod's resolv.conf and dnsPolicy
$ kubectl -n s11 exec broken-dns -- cat /etc/resolv.conf
nameserver 192.168.65.254
options ndots:0

$ kubectl -n s11 get pod broken-dns dnsutils -o custom-columns=POD:.metadata.name,DNS-POLICY:.spec.dnsPolicy
POD          DNS-POLICY
broken-dns   Default
dnsutils     ClusterFirst

## Step 4: CoreDNS health
$ kubectl -n kube-system get pods -l k8s-app=kube-dns
NAME                       READY   STATUS    RESTARTS   AGE
coredns-559f6c778d-9v66h   1/1     Running   0          63m
coredns-559f6c778d-jrrhj   1/1     Running   0          63m

$ kubectl -n kube-system get endpointslices -l kubernetes.io/service-name=kube-dns
NAME             ADDRESSTYPE   PORTS        ENDPOINTS               AGE
kube-dns-5k2lw   IPv4          53,53,9153   10.244.0.4,10.244.0.3   63m

$ kubectl -n s11 exec broken-dns -- dig +short @10.96.0.10 web-clusterip.s11.svc.cluster.local
10.96.213.135

## Step 5: fix
$ kubectl -n s11 delete pod broken-dns
pod "broken-dns" deleted from s11 namespace

$ diff broken-dns-pod.yaml fixed-dns-pod.yaml
9c9
<   dnsPolicy: Default
---
>   dnsPolicy: ClusterFirst

$ kubectl apply -f fixed-dns-pod.yaml
pod/broken-dns created

$ kubectl -n s11 exec broken-dns -- cat /etc/resolv.conf
search s11.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

$ kubectl -n s11 exec broken-dns -- nslookup web-clusterip.s11.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-clusterip.s11.svc.cluster.local
Address: 10.96.213.135


$ kubectl -n s11 delete pod broken-dns
pod "broken-dns" deleted from s11 namespace
```

**Root cause:** `dnsPolicy: Default` does not mean "the default policy". It means "inherit the node's DNS". The pod sent queries to Docker Desktop's
resolver `192.168.65.254`, which knows nothing about `cluster.local` (SERVFAIL), and it had no search domains. CoreDNS itself was healthy:
querying `@10.96.0.10` explicitly from the same pod worked. **Fix:** `dnsPolicy: ClusterFirst` ([`fixed-dns-pod.yaml`](fixed-dns-pod.yaml)).

### General DNS troubleshooting checklist

| Step | Command | Looking for |
|---|---|---|
| 1. Reproduce from the failing pod | `kubectl exec <pod> -- nslookup <svc>.<ns>.svc.cluster.local` | NXDOMAIN (wrong name/namespace) vs SERVFAIL/timeout (DNS path broken) |
| 2. Compare with a known-good pod | `kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/jessie-dnsutils:1.7 ...` then `nslookup kubernetes.default` | If this also fails, the problem is cluster DNS, not the pod |
| 3. Check the pod's resolver config | `kubectl exec <pod> -- cat /etc/resolv.conf`, `kubectl get pod -o jsonpath='{.spec.dnsPolicy}'` | `nameserver` = kube-dns IP, correct `search` list, `ndots` |
| 4. CoreDNS pods healthy? | `kubectl -n kube-system get pods -l k8s-app=kube-dns` | Running, Ready, no restarts |
| 5. kube-dns Service has endpoints? | `kubectl -n kube-system get endpointslices -l kubernetes.io/service-name=kube-dns` | CoreDNS pod IPs present |
| 6. CoreDNS logs / config | `kubectl -n kube-system logs -l k8s-app=kube-dns`, `kubectl -n kube-system get cm coredns -o yaml` | Errors, loop detected, bad upstream |
| 7. Does the target exist? | `kubectl get svc,endpointslices -n <ns>` | Typo in the name, Service in another namespace, Service with no endpoints |
| 8. Network policy / kube-proxy | `kubectl get networkpolicy -A`, kube-proxy pod logs | UDP/TCP 53 to kube-dns blocked |
| 9. Query a specific server | `dig @10.96.0.10 <name>` | Separates "resolver config" problems from "DNS server" problems (as in the drill) |
| 10. Metrics | `kubectl get --raw /api/v1/namespaces/kube-system/services/kube-dns:metrics/proxy/metrics` | request rate, errors, cache hit ratio |

NXDOMAIN for a name that does not exist (the expected answer for a typo), and metrics read through the API-server proxy:

```
$ kubectl -n s11 exec dnsutils -- nslookup does-not-exist.s11.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10#53

** server can't find does-not-exist.s11.svc.cluster.local: NXDOMAIN

command terminated with exit code 1

$ kubectl get --raw /api/v1/namespaces/kube-system/services/kube-dns:metrics/proxy/metrics | grep -E '^coredns_(dns_requests_total|cache_hits_total|cache_misses_total)' | head -8
coredns_cache_hits_total{server="dns://:53",type="success",view="",zones="."} 3
coredns_cache_misses_total{server="dns://:53",view="",zones="."} 2.717907e+06
coredns_dns_requests_total{family="1",proto="udp",server="dns://:53",type="A",view="",zone="."} 1.358819e+06
coredns_dns_requests_total{family="1",proto="udp",server="dns://:53",type="AAAA",view="",zone="."} 1.358781e+06
coredns_dns_requests_total{family="1",proto="udp",server="dns://:53",type="SRV",view="",zone="."} 309
coredns_dns_requests_total{family="1",proto="udp",server="dns://:53",type="other",view="",zone="."} 1
```

The very high `dns_requests_total` count (about 1.36 M A queries in about an hour) is **cluster-wide**. The cluster is shared with other workloads
(load tests in other namespaces), and with `ndots:5` every external lookup is multiplied by the search-list tries, so these counters do not come only from my tests.
`cache_hits` is tiny because this Corefile disables caching for `cluster.local`, so only external names can hit the cache.
