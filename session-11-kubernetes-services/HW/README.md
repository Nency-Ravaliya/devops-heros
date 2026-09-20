# Session 11 — Kubernetes Networking & Services

**Submitted by:** Antara Utane
**Cluster used:** Kubernetes v1.36.1, single node (`desktop-control-plane`), CoreDNS at `10.96.0.10`

All five Service types were deployed and tested on a live cluster. Every command output in
these notes was captured from that cluster — nothing is copied from the lab guide.

## Contents

| # | Service type | Notes |
|---|---|---|
| 01 | ClusterIP | [01-clusterip/](01-clusterip/) — internal-only VIP, load balanced across 3 pods |
| 02 | NodePort | [02-nodeport/](02-nodeport/) — port 30080 open on the node |
| 03 | LoadBalancer | [03-loadbalancer/](03-loadbalancer/) — real external IP assigned |
| 04 | ExternalName | [04-externalname/](04-externalname/) — CNAME alias, no proxying |
| 05 | Headless | [05-headless/](05-headless/) — `clusterIP: None` + StatefulSet, per-pod DNS |

## Summary of what each type does

| Type | Cluster IP | External access | Load balances | Main use |
|---|---|---|---|---|
| ClusterIP | yes | no | yes | internal service-to-service |
| NodePort | yes | node IP + port | yes | dev / on-prem exposure |
| LoadBalancer | yes | external IP | yes | production cloud exposure |
| ExternalName | **no** | n/a (DNS only) | no | alias an external host |
| Headless | **None** | no | **no** (client-side) | StatefulSets, databases |

## The three things that connected for me

**1. The types are layered, not parallel.** I assumed these were five separate options.
They are not. `kubectl describe` on the LoadBalancer Service showed it holding a ClusterIP,
a NodePort *and* an external IP simultaneously:

```text
Type:       LoadBalancer
IP:         10.96.4.14        <- ClusterIP layer
NodePort:   http  30205/TCP   <- NodePort layer
```

So LoadBalancer contains NodePort, which contains ClusterIP.

**2. Endpoints are the link between a Service and its pods.** A Service does not know about
pods by name — it matches labels and writes the results into an Endpoints object:

```text
web-service-clusterip   10.244.0.7:80,10.244.0.8:80,10.244.0.9:80
```

An empty `ENDPOINTS` column is the single most useful signal when a Service returns nothing:
it means the selector matches no pods, so the problem is the labels, not the network.

**3. Headless inverts the responsibility.** Normal Services hide the pods behind one VIP.
A headless Service returns all pod IPs and lets the client choose — which is the only way a
database replica can deliberately address its primary.

## Verifying load balancing honestly

A plain `curl` loop against nginx returns the same default page every time, which proves
nothing. To get real evidence I gave each pod a unique index page first:

```bash
for p in $(kubectl get pods -l app=web-clusterip -o jsonpath='{.items[*].metadata.name}'); do
  kubectl exec "$p" -- sh -c "echo 'Served by: $p' > /usr/share/nginx/html/index.html"
done
```

Then all three pod names appeared across 8 requests. The distribution was uneven
(`rcbf5` answered 4 of 8), because kube-proxy in iptables mode picks a backend at random
per connection rather than strict round-robin.

## One thing that did not work

The ExternalName HTTP request failed with curl exit code 6 even though the CNAME resolved
correctly. Details in [04-externalname/](04-externalname/). I kept it in rather than dropping
it, because it shows precisely what ExternalName does and does not guarantee: it aliases a
name, it does not make the destination reachable.
