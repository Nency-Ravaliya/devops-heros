# CoreDNS

## What is CoreDNS?

CoreDNS is a flexible DNS server written in Go and built from a chain of **plugins**. It is a CNCF graduated project and has been the **default cluster DNS since Kubernetes 1.13**, replacing kube-dns. In my cluster it runs as:

- **Deployment** `coredns` in `kube-system` (image `registry.k8s.io/coredns/coredns:v1.14.6`)
- **Service** `kube-dns` with ClusterIP `10.96.0.10`, ports 53/UDP, 53/TCP and 9153 (Prometheus metrics). The Service keeps the old name `kube-dns` for compatibility.
- **ConfigMap** `coredns`, which holds the `Corefile`

## Why Kubernetes uses CoreDNS

- **Service discovery by name:** Pods and Service IPs change, names don't.
- **Watches the API server:** the `kubernetes` plugin updates records the moment a Service or EndpointSlice changes, with no zone files to edit.
- **Plugin architecture:** caching, forwarding, metrics, health, rewrite, hosts and stub domains are all configurable in one small file.
- **Single binary, low memory, multi-threaded.** kube-dns needed three containers (kubedns, dnsmasq, sidecar).

## How service discovery works

```
 Pod                      CoreDNS (10.96.0.10)                    API server
  |  A? web-clusterip.default.svc.cluster.local                     |
  |------------------------>|  kubernetes plugin (in-memory cache    |
  |                         |  fed by WATCH on Services/EndpointSlices)
  |<------------------------|  10.102.13.85                          |
  |  connect 10.102.13.85:80 ---> kube-proxy iptables ---> Pod IP     |
```

1. kubelet writes `/etc/resolv.conf` into each Pod: `nameserver 10.96.0.10`, `search <ns>.svc.cluster.local svc.cluster.local cluster.local`, `ndots:5`.
2. CoreDNS keeps a live cache of every Service and EndpointSlice through a WATCH on the API server.
3. Normal Service → ClusterIP. Headless → Pod IPs. ExternalName → CNAME. StatefulSet Pods → their own A records.

## How a DNS query is resolved

For `curl http://web-clusterip` in namespace `default`:

1. `web-clusterip` has 0 dots (< `ndots:5`), so the resolver tries the search list in order:
   1. `web-clusterip.default.svc.cluster.local` → **NOERROR, 10.102.13.85**, and stops here.
   2. (`web-clusterip.svc.cluster.local`, `web-clusterip.cluster.local`, then `web-clusterip.` would only be tried if the previous one failed.)
2. CoreDNS walks its plugin chain: `errors` → `health`/`ready` → `kubernetes` (answers authoritatively for `cluster.local`) → `cache` → `forward`.
3. For names outside `cluster.local` (e.g. `kubernetes.io`), `kubernetes` falls through and `forward . /etc/resolv.conf` sends the query to the **node's upstream DNS** (Docker Desktop's `192.168.65.254` on my machine). The answer is cached for 30s.

## CoreDNS configuration (my Corefile)

```
.:53 {
    log                               # log every query (minikube enables it; I used it below)
    errors                            # log errors to stdout
    health { lameduck 5s }            # :8080/health for the liveness probe
    ready                             # :8181/ready for the readiness probe
    kubernetes cluster.local in-addr.arpa ip6.arpa {
       pods insecure                  # answer <ip-dashed>.<ns>.pod.cluster.local
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153                  # metrics: coredns_dns_requests_total, ...
    hosts {                           # static entries (minikube adds host.minikube.internal)
       192.168.65.254 host.minikube.internal
       fallthrough
    }
    forward . /etc/resolv.conf { max_concurrent 1000 }   # upstream for everything else
    cache 30 { ... }                  # cache answers for 30s
    loop                              # detect forwarding loops and stop
    reload                            # pick up ConfigMap changes automatically
    loadbalance                       # round-robin the order of A records
}
```

Common customizations (edit with `kubectl -n kube-system edit configmap coredns`, and `reload` applies them):
- **Stub domain:** `corp.internal:53 { forward . 10.0.0.53 }` sends a private zone to a company DNS server.
- **Custom upstream:** `forward . 8.8.8.8 1.1.1.1`.
- **Rewrite:** `rewrite name old.svc.cluster.local new.svc.cluster.local`.

## How to troubleshoot DNS issues

| Step | Command | Looking for |
|---|---|---|
| 1. Is CoreDNS running? | `kubectl -n kube-system get pods -l k8s-app=kube-dns` | Running and Ready; no CrashLoopBackOff (often the `loop` plugin detecting a loop) |
| 2. Does the Service have endpoints? | `kubectl -n kube-system get endpointslices -l kubernetes.io/service-name=kube-dns` | CoreDNS Pod IPs, not `<unset>` |
| 3. Pod's resolver config | `kubectl exec <pod> -- cat /etc/resolv.conf` | `nameserver 10.96.0.10`, correct search list. A `dnsPolicy`/`dnsConfig` override can break it |
| 4. Test from a debug Pod | `kubectl run dnsutils --image=registry.k8s.io/e2e-test-images/agnhost:2.53 -- sleep infinity` then `nslookup kubernetes.default` | `kubernetes.default` must resolve. If it does but your Service doesn't → wrong name or namespace |
| 5. CoreDNS logs | `kubectl -n kube-system logs deploy/coredns` | `SERVFAIL`, `i/o timeout` to the upstream, `plugin/loop` errors |
| 6. Does the Service exist / have endpoints? | `kubectl get svc,endpointslices -n <ns>` | DNS resolving but connection failing = a Service/selector problem, not DNS |
| 7. Bypass DNS | `curl http://<ClusterIP>` | If the IP works and the name doesn't, it's definitely DNS |
| 8. Network policy | `kubectl get networkpolicy -A` | Egress to `kube-system` port 53 UDP/TCP must be allowed |
| 9. Upstream / external names | `dig @10.96.0.10 google.com` | Fails while cluster names work → node's `/etc/resolv.conf` or `forward` target |

### Hands-on: I broke DNS and fixed it

I scaled CoreDNS to 0 replicas:

- **Symptom:** `nslookup web-clusterip` → `connection refused` to `10.96.0.10`, and `curl http://web-clusterip` → exit 6 (*could not resolve host*).
- **Investigation:** `curl http://10.102.13.85` (the ClusterIP) **still worked**, so the Service and Pods were fine and the problem was only name resolution. `get pods -l k8s-app=kube-dns` showed no Pods, and the `kube-dns` EndpointSlice had `<unset>` endpoints.
- **Root cause:** the DNS Service had no backends.
- **Fix:** `kubectl -n kube-system scale deploy coredns --replicas=1`.
- **Verify:** the EndpointSlice showed the new CoreDNS Pod IP `10.244.0.88`, and both `nslookup` and `curl` by name worked again.

## Hands-on output

```text
$ kubectl -n kube-system get deploy,pods,svc -l k8s-app=kube-dns -o wide
NAME                      READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                    SELECTOR
deployment.apps/coredns   1/1     1            1           24m   coredns      registry.k8s.io/coredns/coredns:v1.14.6   k8s-app=kube-dns

NAME                           READY   STATUS    RESTARTS   AGE   IP            NODE       NOMINATED NODE   READINESS GATES
pod/coredns-559f6c778d-v49qj   1/1     Running   0          61s   10.244.0.85   minikube   <none>           <none>

NAME               TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE   SELECTOR
service/kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   24m   k8s-app=kube-dns

$ kubectl -n kube-system get endpointslices -l kubernetes.io/service-name=kube-dns
NAME             ADDRESSTYPE   PORTS        ENDPOINTS     AGE
kube-dns-6wnzv   IPv4          53,53,9153   10.244.0.85   24m

$ kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}'
.:53 {
    log
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
    hosts {
       192.168.65.254 host.minikube.internal
       fallthrough
    }
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

$ kubectl exec dns -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

$ kubectl exec dns -- dig web-clusterip.default.svc.cluster.local

; <<>> DiG 9.18.24 <<>> web-clusterip.default.svc.cluster.local
;; global options: +cmd
;; Got answer:
;; WARNING: .local is reserved for Multicast DNS
;; You are currently testing what happens when an mDNS query is leaked to DNS
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 58969
;; flags: qr aa rd; QUERY: 1, ANSWER: 1, AUTHORITY: 0, ADDITIONAL: 1
;; WARNING: recursion requested but not available

;; OPT PSEUDOSECTION:
; EDNS: version: 0, flags:; udp: 1232
; COOKIE: 3be3a2db162c8232 (echoed)
;; QUESTION SECTION:
;web-clusterip.default.svc.cluster.local. IN A

;; ANSWER SECTION:
web-clusterip.default.svc.cluster.local. 30 IN A 10.102.13.85

;; Query time: 0 msec
;; SERVER: 10.96.0.10#53(10.96.0.10) (UDP)
;; WHEN: Wed Oct 07 19:04:04 UTC 2026
;; MSG SIZE  rcvd: 135


$ kubectl -n kube-system logs deploy/coredns --tail=6
[INFO] 10.244.0.79:35291 - 36583 "PTR IN 85.13.102.10.in-addr.arpa. udp 66 false 1232" NOERROR qr,aa,rd 121 0.000196914s
[INFO] 10.244.0.87:56426 - 39270 "AAAA IN web-clusterip.default.team-b.svc.cluster.local. udp 64 false 512" NXDOMAIN qr,aa,rd 157 0.000243026s
[INFO] 10.244.0.87:56426 - 38997 "A IN web-clusterip.default.team-b.svc.cluster.local. udp 64 false 512" NXDOMAIN qr,aa,rd 157 0.000297824s
[INFO] 10.244.0.87:39410 - 55573 "AAAA IN web-clusterip.default.svc.cluster.local. udp 57 false 512" NOERROR qr,aa,rd 150 0.000131914s
[INFO] 10.244.0.87:39410 - 55318 "A IN web-clusterip.default.svc.cluster.local. udp 57 false 512" NOERROR qr,aa,rd 112 0.000157843s
[INFO] 10.244.0.79:58716 - 58969 "A IN web-clusterip.default.svc.cluster.local. udp 80 false 1232" NOERROR qr,aa,rd 112 0.000156754s

# --- external names are forwarded upstream (forward . /etc/resolv.conf) ---
$ kubectl exec dns -- dig +noall +answer +stats kubernetes.io | grep -E 'IN|Query time|SERVER'
kubernetes.io.		30	IN	A	3.33.186.135
kubernetes.io.		30	IN	A	15.197.167.90
;; Query time: 56 msec
;; SERVER: 10.96.0.10#53(10.96.0.10) (UDP)

# ===== Troubleshooting: simulate a DNS outage by scaling CoreDNS to 0 =====
$ kubectl -n kube-system scale deploy coredns --replicas=0
deployment.apps/coredns scaled

$ kubectl exec dns -- nslookup -timeout=2 -retry=1 web-clusterip || true
;; communications error to 10.96.0.10#53: connection refused
;; no servers could be reached


command terminated with exit code 1

$ kubectl exec dns -- curl -s --max-time 5 http://web-clusterip || true
command terminated with exit code 6

$ kubectl exec dns -- curl -s --max-time 5 http://10.102.13.85
hello from web-86bb596c4d-nknrw

$ kubectl -n kube-system get pods -l k8s-app=kube-dns
No resources found in kube-system namespace.

$ kubectl -n kube-system get endpointslices -l kubernetes.io/service-name=kube-dns
NAME             ADDRESSTYPE   PORTS     ENDPOINTS   AGE
kube-dns-6wnzv   IPv4          <unset>   <unset>     24m

# root cause: kube-dns Service has no endpoints -> fix: bring CoreDNS back
$ kubectl -n kube-system scale deploy coredns --replicas=1 && kubectl -n kube-system rollout status deploy coredns --timeout=120s
deployment.apps/coredns scaled
Waiting for deployment "coredns" rollout to finish: 0 of 1 updated replicas are available...
deployment "coredns" successfully rolled out

$ kubectl -n kube-system get endpointslices -l kubernetes.io/service-name=kube-dns
NAME             ADDRESSTYPE   PORTS        ENDPOINTS     AGE
kube-dns-6wnzv   IPv4          53,53,9153   10.244.0.88   24m

$ kubectl exec dns -- nslookup web-clusterip
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-clusterip.default.svc.cluster.local
Address: 10.102.13.85


$ kubectl exec dns -- curl -s http://web-clusterip
hello from web-86bb596c4d-nknrw
```
