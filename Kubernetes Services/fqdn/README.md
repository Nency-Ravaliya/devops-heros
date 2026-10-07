# FQDN & Kubernetes Service DNS

## What is an FQDN?

A **Fully Qualified Domain Name** is the complete, unambiguous name of a host, all the way up to the DNS root. For example `www.example.com.`, where the trailing dot is the root. A name that is *not* fully qualified (like `web-clusterip`) is a **relative** name. The resolver completes it using the **search domains** in `/etc/resolv.conf`.

## Kubernetes Service DNS

Every Pod's `/etc/resolv.conf` points at the cluster DNS Service (CoreDNS, `kube-dns` at `10.96.0.10`):

```
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

- `nameserver 10.96.0.10`: all lookups go to CoreDNS.
- `search ...`: suffixes appended to relative names. The first one contains **the Pod's own namespace** (`default`), so short names resolve to Services in the same namespace.
- `ndots:5`: a name with fewer than 5 dots is first tried with each search suffix before being tried as-is.

## DNS naming convention

| Record | Format | Example from my cluster | Resolves to |
|---|---|---|---|
| Service (ClusterIP) | `<service>.<namespace>.svc.<cluster-domain>` | `web-clusterip.default.svc.cluster.local` | ClusterIP `10.102.13.85` |
| Headless Service | same | `db-headless.default.svc.cluster.local` | All Pod IPs (`.80`, `.81`, `.82`) |
| StatefulSet Pod | `<pod>.<headless-svc>.<namespace>.svc.<cluster-domain>` | `db-2.db-headless.default.svc.cluster.local` | `10.244.0.82` |
| Pod (by IP) | `<ip-with-dashes>.<namespace>.pod.<cluster-domain>` | `10-244-0-19.default.pod.cluster.local` | `10.244.0.19` |
| ExternalName | same as Service | `external-api.default.svc.cluster.local` | `CNAME example.com.` |
| SRV (named port) | `_<port-name>._<proto>.<service>.<ns>.svc.<cluster-domain>` | `_http._tcp.web-clusterip.default.svc.cluster.local` | `0 100 80 web-clusterip…` |
| Reverse (PTR) | `<reversed-ip>.in-addr.arpa` | `85.13.102.10.in-addr.arpa` | `web-clusterip.default.svc.cluster.local.` |

`cluster.local` is the default cluster domain (set by kubelet's `--cluster-domain`).

## Namespace-based DNS

To demonstrate this I created a second namespace with a Service: [team-b-api.yaml](team-b-api.yaml) (`api` in namespace `team-b`).

| From a Pod in `default`, I query… | Result | Why |
|---|---|---|
| `web-clusterip` | ✅ | Search domain `default.svc.cluster.local` matches |
| `api` | ❌ `SERVFAIL` | Tried `api.default.svc…`, `api.svc…`, `api.cluster.local` (all NXDOMAIN). The bare `api.` then went upstream and failed |
| `api.team-b` | ✅ | `api.team-b` + search `svc.cluster.local` → `api.team-b.svc.cluster.local` |
| `api.team-b.svc` | ✅ | + `cluster.local` |
| `api.team-b.svc.cluster.local` | ✅ | Fully qualified |

**Rule:** within the same namespace use `<service>`. Across namespaces use at least `<service>.<namespace>`. In config files, prefer the full `<service>.<namespace>.svc.cluster.local` because it is unambiguous and skips the search-list round-trips.

## Pod-to-Service communication

1. The app calls `http://api.team-b`.
2. The libc resolver appends search suffixes and asks CoreDNS (`10.96.0.10`).
3. CoreDNS's `kubernetes` plugin watches Services through the API server and answers `api.team-b.svc.cluster.local → 10.100.133.28`.
4. The app connects to the ClusterIP. kube-proxy's iptables rules DNAT it to a Ready Pod in `team-b`.

The last command below shows the reverse direction too: a Pod in `team-b` reaching `web-clusterip.default`.

## Hands-on output

```text
$ kubectl apply -f fqdn/team-b-api.yaml
namespace/team-b unchanged
deployment.apps/api unchanged
service/api unchanged

$ kubectl exec dns -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

$ kubectl get svc -A -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,TYPE:.spec.type,CLUSTER-IP:.spec.clusterIP | grep -v ingress
NAMESPACE       NAME                                 TYPE           CLUSTER-IP
default         db-headless                          ClusterIP      None
default         external-api                         ExternalName   <none>
default         kubernetes                           ClusterIP      10.96.0.1
default         web-clusterip                        ClusterIP      10.102.13.85
default         web-loadbalancer                     LoadBalancer   10.105.46.105
default         web-nodeport                         NodePort       10.109.189.251
kube-system     kube-dns                             ClusterIP      10.96.0.10
kube-system     metrics-server                       ClusterIP      10.111.217.175
team-b          api                                  ClusterIP      10.107.104.143

# --- same namespace: the short name works ---
$ kubectl exec dns -- curl -s http://web-clusterip
hello from web-86bb596c4d-72lwl

# --- other namespace: the short name FAILS, you need <svc>.<namespace> ---
$ kubectl exec dns -- nslookup -timeout=2 api || true
Server:		10.96.0.10
Address:	10.96.0.10#53

** server can't find api: SERVFAIL

command terminated with exit code 1

$ kubectl exec dns -- curl -s http://api.team-b
api in team-b

$ kubectl exec dns -- curl -s http://api.team-b.svc
api in team-b

$ kubectl exec dns -- curl -s http://api.team-b.svc.cluster.local
api in team-b

# --- FQDN examples resolved by CoreDNS ---
$ kubectl exec dns -- dig +noall +answer api.team-b.svc.cluster.local
api.team-b.svc.cluster.local. 30 IN	A	10.107.104.143

$ kubectl exec dns -- dig +noall +answer kubernetes.default.svc.cluster.local
kubernetes.default.svc.cluster.local. 30 IN A	10.96.0.1

$ kubectl exec dns -- dig +noall +answer kube-dns.kube-system.svc.cluster.local
kube-dns.kube-system.svc.cluster.local.	30 IN A	10.96.0.10

$ kubectl exec dns -- dig +noall +answer db-headless.default.svc.cluster.local
db-headless.default.svc.cluster.local. 30 IN A	10.244.0.80
db-headless.default.svc.cluster.local. 30 IN A	10.244.0.83
db-headless.default.svc.cluster.local. 30 IN A	10.244.0.82

$ kubectl exec dns -- dig +noall +answer db-2.db-headless.default.svc.cluster.local
db-2.db-headless.default.svc.cluster.local. 30 IN A 10.244.0.82

$ kubectl exec dns -- dig +noall +answer external-api.default.svc.cluster.local
external-api.default.svc.cluster.local.	30 IN CNAME example.com.
example.com.		30	IN	A	104.20.23.154
example.com.		30	IN	A	172.66.147.243

$ kubectl get pod curl -o jsonpath='{.status.podIP}'; echo
10.244.0.19

$ kubectl exec dns -- dig +noall +answer 10-244-0-19.default.pod.cluster.local
10-244-0-19.default.pod.cluster.local. 30 IN A	10.244.0.19

$ kubectl exec dns -- dig +noall +answer SRV _http._tcp.web-clusterip.default.svc.cluster.local
_http._tcp.web-clusterip.default.svc.cluster.local. 30 IN SRV 0 100 80 web-clusterip.default.svc.cluster.local.

$ kubectl exec dns -- dig +noall +answer -x 10.102.13.85
85.13.102.10.in-addr.arpa. 30	IN	PTR	web-clusterip.default.svc.cluster.local.

# --- Pod-to-Service from a Pod in team-b back to default ---
$ kubectl -n team-b run tmp --rm -i --restart=Never --image=curlimages/curl:8.10.1 -- sh -c 'cat /etc/resolv.conf | head -1; curl -s http://web-clusterip.default'
All commands and output from this session will be recorded in container logs, including credentials and sensitive information passed through the command prompt.
If you don't see a command prompt, try pressing enter.
hello from web-86bb596c4d-72lwl
pod "tmp" deleted from team-b namespace
```
