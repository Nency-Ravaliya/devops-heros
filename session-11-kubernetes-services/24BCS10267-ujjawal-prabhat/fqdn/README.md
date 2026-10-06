# Task 3 - FQDN & Service DNS in Kubernetes

**Ujjawal Prabhat - 24BCS10267 - Session 11**

## What is an FQDN?

A **Fully Qualified Domain Name** is the complete, unambiguous name of a host. It includes every label up to the DNS root
(the trailing dot), for example `web-clusterip.s11.svc.cluster.local.`. A short name like `web-clusterip` is *relative*: the resolver
has to complete it with a search domain.

## Service DNS naming convention

Every Service gets a DNS record from CoreDNS:

```
<service>.<namespace>.svc.<cluster-domain>
web-clusterip.s11.svc.cluster.local      -> A record = ClusterIP (10.96.213.135)
```

| Record | Format | Example (real, below) |
|---|---|---|
| Service (ClusterIP) | `<svc>.<ns>.svc.cluster.local` -> ClusterIP | `web-clusterip.s11.svc.cluster.local -> 10.96.213.135` |
| Headless service | same name -> **all ready pod IPs** | `web-headless.s11.svc.cluster.local -> 3 A records` |
| StatefulSet pod | `<pod>.<svc>.<ns>.svc.cluster.local` | `web-sts-0.web-headless.s11.svc.cluster.local` |
| Pod (by IP) | `<ip-with-dashes>.<ns>.pod.cluster.local` | `10-244-1-149.s11.pod.cluster.local` |
| SRV (named port) | `_<port>._<proto>.<svc>.<ns>.svc.cluster.local` | `_http._tcp.web-headless.s11.svc.cluster.local` |
| ExternalName | `<svc>.<ns>.svc.cluster.local` -> CNAME | `external-api... -> example.com` |
| Reverse (PTR) | `<reversed-ip>.in-addr.arpa` | `135.213.96.10.in-addr.arpa -> web-clusterip...` |

`cluster.local` is the default cluster domain (set by the kubelet `--cluster-domain` flag and the CoreDNS `kubernetes cluster.local` plugin).

## How a pod resolves names: `/etc/resolv.conf`

The kubelet writes this file into every pod with `dnsPolicy: ClusterFirst` (the default):

```
$ kubectl -n s11 exec dnsutils -- cat /etc/resolv.conf
search s11.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

$ kubectl -n s11 get pod dnsutils -o jsonpath='{.spec.dnsPolicy}{"\n"}'
ClusterFirst
```

- `nameserver 10.96.0.10` is the ClusterIP of the `kube-dns` Service, which is served by CoreDNS.
- `search s11.svc.cluster.local svc.cluster.local cluster.local`: the **first entry is the pod's own namespace**. That is why
  short names work only inside the same namespace.
- `options ndots:5`: any name with fewer than 5 dots is tried with each search suffix **before** being queried as-is.
  So `web-clusterip` is tried as `web-clusterip.s11.svc.cluster.local` first.
  Side effect: an external name like `example.com` (1 dot) first produces several NXDOMAIN lookups (`example.com.s11.svc.cluster.local`, ...).
  Writing a trailing dot (`example.com.`) or lowering `ndots` with `dnsConfig` avoids this.

## Namespace-based DNS: same name, four spellings

All four forms resolve to the same ClusterIP from inside namespace `s11`:

```
$ kubectl -n s11 exec dnsutils -- nslookup web-clusterip
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-clusterip.s11.svc.cluster.local
Address: 10.96.213.135


$ kubectl -n s11 exec dnsutils -- nslookup web-clusterip.s11
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-clusterip.s11.svc.cluster.local
Address: 10.96.213.135


$ kubectl -n s11 exec dnsutils -- nslookup web-clusterip.s11.svc
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-clusterip.s11.svc.cluster.local
Address: 10.96.213.135


$ kubectl -n s11 exec dnsutils -- nslookup web-clusterip.s11.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	web-clusterip.s11.svc.cluster.local
Address: 10.96.213.135
```

Cross-namespace: a short name only searches *my* namespace. `kube-dns` lives in `kube-system`, so it fails short and works with `.kube-system`:

```
$ kubectl -n s11 exec dnsutils -- nslookup kube-dns
Server:		10.96.0.10
Address:	10.96.0.10#53

** server can't find kube-dns: NXDOMAIN

command terminated with exit code 1

$ kubectl -n s11 exec dnsutils -- nslookup kube-dns.kube-system
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	kube-dns.kube-system.svc.cluster.local
Address: 10.96.0.10


$ kubectl -n s11 exec dnsutils -- nslookup kubernetes.default.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	kubernetes.default.svc.cluster.local
Address: 10.96.0.1


$ kubectl -n s11 exec dnsutils -- nslookup ingress-nginx-controller.ingress-nginx.svc.cluster.local
Server:		10.96.0.10
Address:	10.96.0.10#53

Name:	ingress-nginx-controller.ingress-nginx.svc.cluster.local
Address: 10.96.146.138
```

The `dig +search` question line shows the name the resolver actually sent:

```
$ kubectl -n s11 exec dnsutils -- dig +search +noall +answer +question web-clusterip
;web-clusterip.s11.svc.cluster.local. IN	A
web-clusterip.s11.svc.cluster.local. 30	IN A	10.96.213.135
```

Reverse lookup (PTR) of the ClusterIP, and the per-pod `pod.cluster.local` record:

```
$ kubectl -n s11 exec dnsutils -- dig +noall +answer -x 10.96.213.135
135.213.96.10.in-addr.arpa. 30	IN	PTR	web-clusterip.s11.svc.cluster.local.

$ kubectl -n s11 exec dnsutils -- dig +noall +answer 10-244-1-149.s11.pod.cluster.local
10-244-1-149.s11.pod.cluster.local. 30 IN A	10.244.1.149
```

## Pod-to-service communication across namespaces

From namespace **s11** (same namespace as the service), all forms work:

```
$ kubectl -n s11 exec curl -- sh -c 'curl -s web-clusterip:8080 | grep Hostname; curl -s web-clusterip.s11:8080 | grep Hostname; curl -s web-clusterip.s11.svc.cluster.local:8080 | grep Hostname'
Hostname: web-774ccbcbbc-l7b6l
Hostname: web-774ccbcbbc-854tp
Hostname: web-774ccbcbbc-s4trk
```

From namespace **s12** (a different namespace), the short name **fails** (curl exit 6 = could not resolve host), because the search list now starts with
`s12.svc.cluster.local`. Adding the namespace fixes it:

```
$ kubectl -n s12 exec nsclient -- cat /etc/resolv.conf
search s12.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5

$ kubectl -n s12 exec nsclient -- curl -s -m 3 web-clusterip:8080
command terminated with exit code 6

$ kubectl -n s12 exec nsclient -- sh -c 'curl -s web-clusterip.s11:8080 | grep Hostname'
Hostname: web-774ccbcbbc-854tp

$ kubectl -n s12 exec nsclient -- sh -c 'curl -s web-clusterip.s11.svc.cluster.local:8080 | grep Hostname'
Hostname: web-774ccbcbbc-854tp
```

## Rules of thumb

1. Same namespace: use the short name (`web-clusterip`). It keeps manifests portable between namespaces and environments.
2. Different namespace: use at least `<svc>.<ns>`, or the full `<svc>.<ns>.svc.cluster.local` in config files.
3. Service names are stable, and Service IPs and pod IPs are not (see the headless README: `web-sts-0` changed IP after a restart). Never hard-code IPs.
4. A NXDOMAIN for a name that looks right usually means a wrong namespace or a typo. Check `/etc/resolv.conf` and use the FQDN (see [`../coredns/README.md`](../coredns/README.md)).
