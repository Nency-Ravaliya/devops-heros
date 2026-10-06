# Session 11 - Kubernetes Networking & Services

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 11 - Networking & Services (Service types, workload comparisons, FQDN, CoreDNS) |

## Task checklist

- [x] **Task 1 - Five Service types**, each with YAML, deploy, `get svc`, `get endpointslices` and a connectivity test:
  - [x] [ClusterIP](01-clusterip/README.md): curl from a client pod, load-balancing across 3 pods, not reachable from the host
  - [x] [NodePort](02-nodeport/README.md): same port on all 3 node IPs, plus `localhost:30080` via the kind port mapping
  - [x] [LoadBalancer](03-loadbalancer/README.md): real `EXTERNAL-IP 172.18.0.6` via **cloud-provider-kind** (pending -> assigned)
  - [x] [ExternalName](04-externalname/README.md): CNAME to `example.com`, Host-header gotcha, cross-namespace alias
  - [x] [Headless](05-headless/README.md): `nslookup` returns per-pod IPs, StatefulSet per-pod DNS names, SRV records
- [x] **Task 2 - Comparisons** -> [`comparisons/README.md`](comparisons/README.md): Deployment vs ReplicaSet (real `ownerReferences`),
  Deployment vs DaemonSet vs StatefulSet (with a running DaemonSet and a StatefulSet with PVCs), ReplicaSet vs Service
- [x] **Task 3 - FQDN** -> [`fqdn/README.md`](fqdn/README.md): naming convention, `resolv.conf`, `ndots`, cross-namespace `nslookup` and curl
- [x] **Task 4 - CoreDNS** -> [`coredns/README.md`](coredns/README.md): what/why, the real Corefile explained plugin by plugin, resolution flow, a DNS troubleshooting drill

## Environment

- kind cluster `kind-devops-heros`: 1 control-plane + 2 workers, Kubernetes v1.37.0, arm64, CNI kindnet, CoreDNS 1.14.6
- My namespace: `s11` (plus `s12` for one cross-namespace DNS test)
- Test images: `traefik/whoami` (prints the pod hostname/IP), `curlimages/curl`, `registry.k8s.io/e2e-test-images/jessie-dnsutils` (dig/nslookup)
- LoadBalancer support: `cloud-provider-kind` 0.12.0 (Homebrew), run with default ingress and Gateway features **disabled** so it does not change the shared cluster

All command output in these READMEs is real. Long output is trimmed with `...`.

## Folder layout

```
24BCS10267-ujjawal-prabhat/
├── README.md
├── common/            web-deployment.yaml (3x whoami), client-pod.yaml (dnsutils + curl)
├── 01-clusterip/      service.yaml, README.md
├── 02-nodeport/       service.yaml, README.md
├── 03-loadbalancer/   service.yaml, README.md
├── 04-externalname/   service.yaml, README.md
├── 05-headless/       headless.yaml (Service + StatefulSet), README.md
├── comparisons/       daemonset.yaml, statefulset-with-storage.yaml, README.md
├── fqdn/              README.md
└── coredns/           broken-dns-pod.yaml, fixed-dns-pod.yaml, README.md
```

## Service types at a glance

| Type | ClusterIP? | Reachable from | DNS answer | Real value in my cluster |
|---|---|---|---|---|
| ClusterIP | yes | inside the cluster only | A -> VIP | `10.96.213.135:8080` |
| NodePort | yes | `<any-node-IP>:30000-32767` | A -> VIP | `:30080` on 172.18.0.2/.3/.4 and `localhost:30080` |
| LoadBalancer | yes (+ NodePort) | external LB IP | A -> VIP | `172.18.0.6:80` (Envoy by cloud-provider-kind) |
| ExternalName | **no** | (DNS only) | CNAME | `external-api -> example.com` |
| Headless | **no** (`None`) | inside the cluster, directly to pods | A -> every pod IP | 3 records, `web-sts-N.web-headless` |

## Cleanup

```bash
kubectl delete ns s11
# stop cloud-provider-kind (Ctrl-C). Its Envoy containers are removed when the LB services are deleted
```
