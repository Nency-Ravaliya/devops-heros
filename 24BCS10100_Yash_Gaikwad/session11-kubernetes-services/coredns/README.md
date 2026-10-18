# CoreDNS in Kubernetes

Author: Yash Gaikwad (24BCS10100) | Session 11 - Kubernetes Services

---

## 1. What is CoreDNS?

CoreDNS is a DNS server written in Go (a CNCF graduated project). Its main design idea is that **everything is a plugin**: the server itself only receives DNS queries, and a configurable chain of plugins decides how each query is answered (look it up in Kubernetes, forward it upstream, cache it, log it, expose metrics, and so on). The configuration file that wires the plugins together is called the **Corefile**.

In Kubernetes, CoreDNS is the cluster DNS add-on. It is what turns a name like `backend.default.svc.cluster.local` into the ClusterIP of the `backend` Service.

## 2. Why Kubernetes uses CoreDNS

- It **replaced kube-dns**, the older DNS add-on made of three containers (kubedns, dnsmasq, sidecar). CoreDNS is a single process, simpler to run and more memory efficient.
- It became generally available as a kube-dns alternative in v1.11 and the **default cluster DNS since Kubernetes 1.13** (kubeadm).
- The plugin chain makes it flexible: the `kubernetes` plugin handles cluster names, `forward` handles everything else, and extras like `hosts`, `rewrite`, `log` or a stub zone can be added by editing a ConfigMap.
- For backward compatibility the Service is still called **`kube-dns`** and its Pods carry the label `k8s-app=kube-dns`, even though the Pods are CoreDNS. That naming is a common source of confusion when searching for it.

Where it lives:

| Object | Name | Namespace |
|---|---|---|
| Deployment (Pods) | `coredns` | `kube-system` |
| Service | `kube-dns` | `kube-system` |
| ConfigMap (the Corefile) | `coredns` | `kube-system` |
| Pod label | `k8s-app=kube-dns` | `kube-system` |

---

## 3. How service discovery works

1. The `kubernetes` plugin in CoreDNS **watches the Kubernetes API server** for Services, EndpointSlices and (depending on settings) Pods, using a ServiceAccount with a read-only ClusterRole.
2. It keeps that data in memory. There is no DNS zone file to maintain; records are generated from API objects at query time.
3. When I create, change or delete a Service, the API objects change, CoreDNS sees the watch event, and the DNS answers change automatically.
4. The kubelet configures each Pod's `/etc/resolv.conf` so that its nameserver is the ClusterIP of the `kube-dns` Service. Every Pod therefore asks CoreDNS without any application configuration.

The records it serves are the ones described in the FQDN notes (`../fqdn/README.md`): A/AAAA records for Services, SRV records for named ports, per-Pod names for headless Services, and CNAME for ExternalName Services.

---

## 4. How a DNS query is resolved, step by step

```
 Pod (resolv.conf: nameserver 10.96.0.10, search ..., ndots:5)
   |
   |  1. app calls  http://backend
   |  2. resolver expands with search list ->  backend.default.svc.cluster.local
   v
 kube-dns Service ClusterIP (10.96.0.10, UDP/TCP 53)
   |  3. kube-proxy rules DNAT to one of the CoreDNS Pods
   v
 CoreDNS Pod
   |  4a. name ends in cluster.local  -> kubernetes plugin answers from API data
   |  4b. any other name (example.com) -> forward plugin sends it to upstream DNS
   |  5. cache plugin stores the answer for the TTL
   v
 answer returned to the Pod
```

For an internal name:

1. The Pod's resolver tries the name with the search suffixes (`default.svc.cluster.local`, `svc.cluster.local`, `cluster.local`) because `ndots:5` makes it do that for names with fewer than 5 dots.
2. The query goes to the nameserver in `resolv.conf`, the `kube-dns` ClusterIP.
3. The kube-proxy rules on the node forward it to one of the CoreDNS Pods (the DNS Service is load balanced like any other Service).
4. The `kubernetes` plugin owns the `cluster.local` zone, finds the Service and returns its ClusterIP.

For an external name:

1. The suffixed attempts (`example.com.default.svc.cluster.local` ...) reach CoreDNS and get NXDOMAIN from the `kubernetes` plugin.
2. The final attempt, `example.com`, is not in `cluster.local`, so CoreDNS passes it on with the `forward` plugin to the upstream resolvers (by default the ones in the node's `/etc/resolv.conf`).
3. The answer comes back, the `cache` plugin remembers it, and the Pod receives it.

---

## 5. The Corefile explained

The Corefile is stored in the `coredns` ConfigMap. A typical kubeadm default (the exact contents vary a bit between Kubernetes versions and distributions, including minikube) looks like this:

```
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
    cache 30
    loop
    reload
    loadbalance
}
```

Line by line:

| Line | What it does |
|---|---|
| `.:53 {` | Server block: handle **every zone** (`.` is the root) on **port 53**. |
| `errors` | Log errors to standard output so they show up in `kubectl logs`. |
| `health { lameduck 5s }` | Exposes a liveness endpoint (HTTP `:8080/health`). `lameduck 5s` keeps answering for 5 seconds after a shutdown signal so in-flight queries can finish. |
| `ready` | Exposes a readiness endpoint (`:8181/ready`). It returns OK only once the plugins that support it (like `kubernetes`) are ready; the Pod's readiness probe uses it. |
| `kubernetes cluster.local in-addr.arpa ip6.arpa { ... }` | The core plugin. It is authoritative for the cluster domain `cluster.local` and for reverse lookups (`in-addr.arpa`, `ip6.arpa`), and answers from the Kubernetes API. |
| `pods insecure` | Answer Pod A records of the form `10-244-1-5.ns.pod.cluster.local` from the IP in the name **without checking** the Pod exists. (`verified` checks, `disabled` turns it off.) Kept for kube-dns compatibility. |
| `fallthrough in-addr.arpa ip6.arpa` | If the `kubernetes` plugin has no answer for a **reverse** lookup, pass the query to the next plugin instead of returning NXDOMAIN. Names under `cluster.local` do not fall through, so an unknown Service gets NXDOMAIN. |
| `ttl 30` | TTL in seconds placed on the records the plugin returns. |
| `prometheus :9153` | Exposes Prometheus metrics at port 9153 (`/metrics`). |
| `forward . /etc/resolv.conf` | Everything the `kubernetes` plugin did not handle is forwarded to the nameservers listed in the **CoreDNS Pod's** `/etc/resolv.conf`, which is inherited from the node (the CoreDNS Pod runs with `dnsPolicy: Default`). `max_concurrent 1000` limits in-flight upstream queries. |
| `cache 30` | Cache answers for up to 30 seconds. |
| `loop` | Detects simple forwarding loops (CoreDNS asking itself). If one is found CoreDNS stops, so the failure is obvious rather than silent. |
| `reload` | Watches the Corefile and reloads it automatically after the ConfigMap changes, without restarting the Pod. |
| `loadbalance` | Randomizes the order of records in an answer (round-robin DNS) so clients spread across multiple A records. |

The order in which plugins run is fixed when CoreDNS is compiled (in its `plugin.cfg`). It is **not** the order of lines in the Corefile, so moving a line up or down does not change which plugin goes first.

---

## 6. The ConfigMap and how to edit it

The Corefile lives in the ConfigMap `coredns` in namespace `kube-system`, under the key `Corefile`:

```bash
kubectl -n kube-system get configmap coredns -o yaml
kubectl -n kube-system edit configmap coredns
```

CoreDNS Pods mount this ConfigMap as a volume. With the `reload` plugin enabled the new config is picked up automatically after the volume refreshes (it can take a minute or two). To apply it immediately I can restart the Deployment:

```bash
kubectl -n kube-system rollout restart deployment coredns
kubectl -n kube-system rollout status deployment coredns
```

### Example: stub domain (send one domain to a company DNS server)

Add a second server block next to the `.:53` block inside the Corefile:

```
corp.example.com:53 {
    errors
    cache 30
    forward . 10.20.0.53
}
```

Now any query for `*.corp.example.com` goes to `10.20.0.53`, and everything else still follows the default block.

### Example: custom hosts entries

Add a `hosts` block inside `.:53 { ... }`. `fallthrough` is important; without it, names that are not listed would stop there instead of continuing to the other plugins.

```
hosts {
    192.168.49.1 host.lab.internal
    fallthrough
}
```

### Example: change the upstream resolvers

Replace `forward . /etc/resolv.conf` with explicit servers if the node's resolver is unsuitable:

```
forward . 8.8.8.8 1.1.1.1
```

### Example: turn on query logging while debugging

Add the `log` plugin to the block, then remove it afterwards because it is noisy:

```
.:53 {
    log
    errors
    ...
}
```

After any change I should check the logs of the CoreDNS Pods; a syntax error in the Corefile prevents the new config from loading.

---

## 7. Useful inspection commands

```bash
kubectl -n kube-system get deployment coredns
kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
kubectl -n kube-system get svc kube-dns
kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}'
kubectl -n kube-system logs -l k8s-app=kube-dns --tail=50
kubectl -n kube-system scale deployment coredns --replicas=3
```

---

## 8. Troubleshooting

Work from the bottom (is the DNS server running) to the top (is my Pod configured to use it).

### 8.1 CoreDNS Pods are not running

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide
kubectl -n kube-system describe pod -l k8s-app=kube-dns
kubectl -n kube-system get events --sort-by=.metadata.creationTimestamp
kubectl get nodes
```

Things to look for:

- `Pending`: no schedulable node, or on a fresh kubeadm cluster **no CNI plugin installed yet** (CoreDNS stays Pending/ContainerCreating until the Pod network exists).
- `ImagePullBackOff`: registry or network problem on the node.
- `Running` but `0/1 READY`: the readiness probe on `:8181/ready` is failing, usually because the `kubernetes` plugin cannot reach the API server.
- `CrashLoopBackOff`: see 8.7 and read the logs.

### 8.2 Check the CoreDNS logs

```bash
kubectl -n kube-system logs -l k8s-app=kube-dns --tail=100
kubectl -n kube-system logs <coredns-pod-name> --previous      # logs from the crashed container
```

Look for Corefile syntax errors, failures talking to the API server (RBAC or connectivity), upstream timeouts from `forward`, and loop messages. Adding the `log` plugin (section 6) shows each query.

### 8.3 Test with nslookup from a debug Pod

```bash
kubectl run dns-debug --rm -it --image=busybox:1.36 --restart=Never -- sh

# then inside the Pod:
nslookup kubernetes.default
nslookup kubernetes.default.svc.cluster.local
nslookup example.com
```

Interpreting the combinations:

- Internal works, external fails: cluster DNS is fine, the `forward` upstream is the problem (node resolver, egress firewall, NetworkPolicy to the outside).
- Internal fails, external works: the `kubernetes` plugin or its API access is the problem, or the Service really does not exist.
- Both fail: the Pod cannot reach CoreDNS at all (see 8.4 to 8.6).

To bypass the Service and ask one CoreDNS Pod directly:

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns -o wide     # note a Pod IP
kubectl run dns-debug --rm -it --image=busybox:1.36 --restart=Never -- nslookup kubernetes.default <coredns-pod-ip>
```

If querying the Pod IP works but the Service IP does not, the problem is the `kube-dns` Service or kube-proxy.

### 8.4 Check the kube-dns Service and Endpoints

```bash
kubectl -n kube-system get svc kube-dns -o wide
kubectl -n kube-system get endpointslices -l kubernetes.io/service-name=kube-dns
kubectl -n kube-system get endpoints kube-dns
kubectl -n kube-system get pods -l k8s-app=kube-dns --show-labels
```

The Service selector is `k8s-app=kube-dns` and it exposes port 53 (UDP and TCP) plus the metrics port. If the endpoints list is empty, no CoreDNS Pod is Ready or the labels were changed. The Service ClusterIP must match the `nameserver` value inside Pods.

### 8.5 Check resolv.conf and ndots inside the Pod

```bash
kubectl exec -it <pod> -- cat /etc/resolv.conf
kubectl get pod <pod> -o jsonpath='{.spec.dnsPolicy}'
```

- The `nameserver` should be the `kube-dns` ClusterIP and `search` should list the three cluster suffixes. If not, the Pod may use `dnsPolicy: Default` (inherits the node's DNS, so cluster names will not resolve) or `hostNetwork: true` without `ClusterFirstWithHostNet`.
- `ndots:5` can make external lookups slow because of the extra suffix attempts. Use trailing-dot names or set a lower `ndots` through `spec.dnsConfig`.

### 8.6 NetworkPolicy blocking port 53

If default-deny egress policies exist, Pods can no longer reach CoreDNS and every lookup times out.

```bash
kubectl get networkpolicy -A
kubectl -n <namespace> describe networkpolicy
```

An egress rule that allows DNS (UDP and TCP 53) to the CoreDNS Pods in `kube-system`:

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: allow-dns-egress
  namespace: demo
spec:
  podSelector: {}
  policyTypes:
  - Egress
  egress:
  - to:
    - namespaceSelector:
        matchLabels:
          kubernetes.io/metadata.name: kube-system
      podSelector:
        matchLabels:
          k8s-app: kube-dns
    ports:
    - protocol: UDP
      port: 53
    - protocol: TCP
      port: 53
```

Ingress policies in `kube-system` can also block queries into CoreDNS, so check both directions.

### 8.7 Loop detection and CrashLoopBackOff

The `loop` plugin sends itself a probe query and checks if it comes back. If CoreDNS forwards to an upstream that ultimately points back at CoreDNS, it detects the loop and **deliberately exits**, which the kubelet shows as `CrashLoopBackOff`. The log mentions that a forwarding loop was detected for the zone.

Typical cause: the node's `/etc/resolv.conf` contains a local stub resolver such as `127.0.0.53` (systemd-resolved) or the node's own address. Because the CoreDNS Pod inherits that file for `forward . /etc/resolv.conf`, it ends up forwarding to itself.

```bash
kubectl -n kube-system get pods -l k8s-app=kube-dns
kubectl -n kube-system logs <coredns-pod-name> --previous
kubectl -n kube-system get configmap coredns -o jsonpath='{.data.Corefile}'
```

Fixes (pick one):

1. Point the kubelet at the real upstream resolver file, for example `resolvConf: /run/systemd/resolve/resolv.conf` in the KubeletConfiguration on systemd-resolved hosts, then restart the kubelet and the CoreDNS Pods.
2. Edit the Corefile and replace `forward . /etc/resolv.conf` with explicit upstream servers, e.g. `forward . 8.8.8.8 1.1.1.1`.
3. Fix or disable the local DNS stub on the node so `/etc/resolv.conf` lists reachable external resolvers.

Removing the `loop` plugin only hides the problem and is not recommended.

### 8.8 Other checks worth remembering

- Restart CoreDNS after changing config if you do not want to wait for `reload`: `kubectl -n kube-system rollout restart deployment coredns`.
- Run at least two replicas so a single node failure does not take down cluster DNS.
- Check metrics (`:9153/metrics`), for example via `kubectl -n kube-system port-forward <pod> 9153:9153` then `curl localhost:9153/metrics`.
- Confirm the Service you are resolving exists and has endpoints: `kubectl get svc,endpointslices -n <namespace>`.

---

## Hands-on output (real)

Run in my Minikube cluster (Kubernetes v1.37.0). The `whoami-clusterip` Service and the `dns-client` Pod come from the [Service exercise](../README.md).

### 1. Where CoreDNS runs

_CoreDNS is a Deployment in kube-system (here with one replica) and its Pods carry the label k8s-app=kube-dns._

```console
$ kubectl get deployment coredns -n kube-system && kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   1/1     1            1           57m
NAME                       READY   STATUS    RESTARTS   AGE   IP             NODE       NOMINATED NODE   READINESS GATES
coredns-559f6c778d-bsdnf   1/1     Running   0          69s   10.244.0.155   minikube   <none>           <none>
```

_The Service that fronts CoreDNS keeps the historical name **kube-dns**. Its ClusterIP is the nameserver address every Pod is given._

```console
$ kubectl get svc kube-dns -n kube-system -o wide
NAME       TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)                  AGE   SELECTOR
kube-dns   ClusterIP   10.96.0.10   <none>        53/UDP,53/TCP,9153/TCP   57m   k8s-app=kube-dns
```

_The endpoints behind the Service are the CoreDNS Pods (port 53)._

```console
$ kubectl get endpointslices -n kube-system -l kubernetes.io/service-name=kube-dns
NAME             ADDRESSTYPE   PORTS        ENDPOINTS      AGE
kube-dns-hgzgp   IPv4          53,53,9153   10.244.0.155   56m
```

_The Pod really uses that ClusterIP as its DNS server (same address as above)._

```console
$ kubectl exec dns-client -- grep nameserver /etc/resolv.conf
nameserver 10.96.0.10
```

### 2. The configuration (Corefile)

_The Corefile lives in the ConfigMap `coredns` in kube-system. Plugins run in a chain for every query: `kubernetes` answers cluster.local names, `forward` sends everything else to the upstream resolver, `cache` keeps answers, `health`/`ready` expose probes, `prometheus` exposes metrics, `loop` and `reload` protect and refresh the configuration._

```console
$ kubectl get configmap coredns -n kube-system -o jsonpath="{.data.Corefile}"
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
```

### 3. How queries are resolved

_**Cluster name**: answered by the `kubernetes` plugin from the Service list (note the status NOERROR in the stats line and the very short query time)._

```console
$ kubectl exec dns-client -- dig whoami-clusterip.default.svc.cluster.local +noall +answer +stats

; <<>> DiG 9.11.3 <<>> whoami-clusterip.default.svc.cluster.local +noall +answer +stats
;; global options: +cmd
whoami-clusterip.default.svc.cluster.local. 30 IN A 10.99.227.182
;; Query time: 1 msec
;; SERVER: 10.96.0.10#53(10.96.0.10)
;; WHEN: Sun Oct 18 13:59:06 UTC 2026
;; MSG SIZE  rcvd: 141
```

_**External name**: not in cluster.local, so the `forward` plugin sends it to the upstream DNS and returns the answer._

```console
$ kubectl exec dns-client -- dig example.com +noall +answer +stats

; <<>> DiG 9.11.3 <<>> example.com +noall +answer +stats
;; global options: +cmd
example.com.		30	IN	A	172.66.147.243
example.com.		30	IN	A	104.20.23.154
;; Query time: 4 msec
;; SERVER: 10.96.0.10#53(10.96.0.10)
;; WHEN: Sun Oct 18 13:59:06 UTC 2026
;; MSG SIZE  rcvd: 106
```

_**Name that does not exist**: the `kubernetes` plugin answers authoritatively with NXDOMAIN._

```console
$ kubectl exec dns-client -- dig nosuchservice.default.svc.cluster.local +noall +comments | grep -E "status|flags"
;; ->>HEADER<<- opcode: QUERY, status: NXDOMAIN, id: 16006
;; flags: qr aa rd; QUERY: 1, ANSWER: 0, AUTHORITY: 1, ADDITIONAL: 1
; EDNS: version: 0, flags:; udp: 4096
```

_Why short names work: the resolver appends each search suffix in turn until one answers._

```console
$ kubectl exec dns-client -- sh -c "grep -E ^search /etc/resolv.conf; grep ndots /etc/resolv.conf"
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

### 4. Watching real queries (the `log` plugin)

The Corefile above already contains the `log` plugin (the line `log` at the top), which Minikube enables by default, so **every query is written to the CoreDNS log**. On clusters where `log` is off, adding that one line to the Corefile ConfigMap turns it on, and the `reload` plugin applies it without restarting CoreDNS. Here I read the real log lines that my own queries produced:

_**A short Service name.** The first search suffix (`default.svc.cluster.local`) already matches, so the `kubernetes` plugin answers right away: NOERROR (the A and AAAA lines are the two address families)._

```console
$ kubectl exec dns-client -- nslookup whoami-clusterip > /dev/null; sleep 1; kubectl logs -n kube-system -l k8s-app=kube-dns --since=10s | grep whoami-clusterip | cut -c1-165 | tail -n 4
[INFO] 10.244.0.147:49373 - 50796 "A IN whoami-clusterip.default.svc.cluster.local. udp 83 false 4096" NOERROR qr,aa,rd 118 0.00033373s
[INFO] 10.244.0.147:59323 - 64678 "A IN whoami-clusterip.default.svc.cluster.local. udp 60 false 512" NOERROR qr,aa,rd 118 0.000311526s
[INFO] 10.244.0.147:37230 - 49643 "AAAA IN whoami-clusterip.default.svc.cluster.local. udp 60 false 512" NOERROR qr,aa,rd 153 0.000257179s
```

_**An external name.** `example.com` has fewer than 5 dots (`ndots:5`), so the resolver first tries it with every search suffix. Those attempts end in NXDOMAIN (answered by the `kubernetes` plugin); only the last, absolute query `example.com.` is forwarded upstream and succeeds (the `ra` flag = answered by a recursive resolver). This is the hidden cost of `ndots:5`._

```console
$ kubectl exec dns-client -- nslookup example.com > /dev/null; sleep 1; kubectl logs -n kube-system -l k8s-app=kube-dns --since=10s | grep example.com | cut -c1-165 | tail -n 10
[INFO] 10.244.0.147:49996 - 33782 "A IN example.com. udp 52 false 4096" NOERROR qr,rd,ra 83 0.004465881s
[INFO] 10.244.0.147:59248 - 9736 "A IN example.com.default.svc.cluster.local. udp 55 false 512" NXDOMAIN qr,aa,rd 148 0.000304161s
[INFO] 10.244.0.147:36361 - 21293 "A IN example.com.svc.cluster.local. udp 47 false 512" NXDOMAIN qr,aa,rd 140 0.000218902s
[INFO] 10.244.0.147:52079 - 42561 "A IN example.com.cluster.local. udp 43 false 512" NXDOMAIN qr,aa,rd 136 0.000190727s
[INFO] 10.244.0.147:59308 - 34239 "A IN example.com. udp 29 false 512" NOERROR qr,aa,rd,ra 83 0.000179525s
[INFO] 10.244.0.147:40251 - 0 "AAAA IN example.com. udp 29 false 512" NOERROR qr,rd,ra 29 0.002817256s
```

_**A name that does not exist** in the cluster domain: the `kubernetes` plugin answers NXDOMAIN itself (flag `aa`, authoritative)._

```console
$ kubectl exec dns-client -- dig +short nosuchservice.default.svc.cluster.local; sleep 1; kubectl logs -n kube-system -l k8s-app=kube-dns --since=10s | grep nosuchservice | cut -c1-165 | tail -n 2
[INFO] 10.244.0.147:58902 - 16006 "A IN nosuchservice.default.svc.cluster.local. udp 80 false 4096" NXDOMAIN qr,aa,rd 150 0.000382256s
[INFO] 10.244.0.147:50090 - 8206 "A IN nosuchservice.default.svc.cluster.local. udp 80 false 4096" NXDOMAIN qr,aa,rd 150 0.000366565s
```

### 5. Troubleshooting a real DNS outage

I break DNS on purpose by scaling CoreDNS to zero, observe the symptoms, then repair it, following the checklist from the notes above.

_**Break it**: no CoreDNS Pods any more._

```console
$ kubectl scale deployment coredns -n kube-system --replicas=0 && sleep 8 && kubectl get pods -n kube-system -l k8s-app=kube-dns
deployment.apps/coredns scaled
No resources found in kube-system namespace.
```

_**Symptom**: the query times out ("no servers could be reached"): nothing answers on the DNS Service address._

```console
$ kubectl exec dns-client -- dig +time=2 +tries=1 whoami-clusterip.default.svc.cluster.local; echo "dig exit code: $?"

; <<>> DiG 9.11.3 <<>> +time=2 +tries=1 whoami-clusterip.default.svc.cluster.local
;; global options: +cmd
;; connection timed out; no servers could be reached
command terminated with exit code 9
dig exit code: 9
```

_The application-level symptom: a name that worked before fails to resolve (curl exit code 28 = operation timed out: the name lookup never got an answer)._

```console
$ kubectl exec dns-client -- curl -s -m 4 http://whoami-clusterip:8080; echo "curl exit code: $?"
command terminated with exit code 28
curl exit code: 28
```

_**Investigate**: the kube-dns Service has no endpoints, and the Deployment shows 0/0 replicas. Root cause: CoreDNS is not running._

```console
$ kubectl get endpointslices -n kube-system -l kubernetes.io/service-name=kube-dns; kubectl get deployment coredns -n kube-system
NAME             ADDRESSTYPE   PORTS     ENDPOINTS   AGE
kube-dns-hgzgp   IPv4          <unset>   <unset>     57m
NAME      READY   UP-TO-DATE   AVAILABLE   AGE
coredns   0/0     0            0           57m
```

_**Fix**: scale CoreDNS back to its original replica count._

```console
$ kubectl scale deployment coredns -n kube-system --replicas=1 && kubectl rollout status deployment/coredns -n kube-system --timeout=120s
deployment.apps/coredns scaled
Waiting for deployment "coredns" rollout to finish: 0 of 1 updated replicas are available...
deployment "coredns" successfully rolled out
```

_**Verify**: DNS answers again and the application works._

```console
$ kubectl exec dns-client -- dig +short whoami-clusterip.default.svc.cluster.local; kubectl exec dns-client -- curl -s http://whoami-clusterip:8080 | head -n 2
10.99.227.182
Hostname: whoami-784794f757-jk2hz
IP: 127.0.0.1
```

### Troubleshooting checklist (what I used)

1. From a Pod: `dig`/`nslookup` the Service name and an external name (which of the two fails?).
2. `cat /etc/resolv.conf` in the Pod: is the nameserver the kube-dns ClusterIP?
3. `kubectl get pods -n kube-system -l k8s-app=kube-dns` and `kubectl logs ...`: running? errors?
4. `kubectl get endpointslices -n kube-system -l kubernetes.io/service-name=kube-dns`: does the DNS Service have endpoints?
5. Read the Corefile ConfigMap; enable `log` temporarily to see queries.
6. If only **cluster** names fail: check the target Service and its endpoints. If only **external** names fail: check the `forward` upstream.
