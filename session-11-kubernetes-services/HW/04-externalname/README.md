# 04 — ExternalName Service

ExternalName is the odd one out. It creates **no proxy, no endpoints and no cluster IP** —
it only makes CoreDNS return a CNAME pointing at an external domain.

![run](run.png)

## Nothing is allocated

```bash
kubectl get svc external-database-service
```

```text
NAME                        TYPE           CLUSTER-IP   EXTERNAL-IP        PORT(S)   AGE
external-database-service   ExternalName   <none>       nencyravaliya.me   <none>    0s
```

Both `CLUSTER-IP` and `PORT(S)` are empty. Every other Service type fills at least one of
these. There is no selector and no endpoint list, because no traffic is ever proxied.

## The CNAME redirect

```bash
kubectl exec dns-test-client -- nslookup external-database-service.default.svc.cluster.local
```

```text
Server:		10.96.0.10
Address:	10.96.0.10:53

external-database-service.default.svc.cluster.local	canonical name = nencyravaliya.me
```

CoreDNS answers the in-cluster name with `canonical name = nencyravaliya.me`.
The pod then resolves *that* name and connects to it directly — kube-proxy is never involved.

## An honest result: the HTTP call failed

```bash
kubectl exec dns-test-client -- curl -s http://external-database-service
```

```text
command terminated with exit code 6
```

curl exit code 6 means "could not resolve host". The CNAME step worked — that is proven by
the nslookup above — but the target domain had no address record this pod could resolve,
so the request never completed.

This is worth recording rather than hiding, because it demonstrates the limitation exactly:
**ExternalName only aliases a name. It does not verify or guarantee that the destination
is reachable.** A Service that looks perfectly healthy in `kubectl get svc` can still fail
at connection time.

## When this is used

Pointing in-cluster workloads at something outside the cluster without hardcoding the real
hostname — a managed database, a third-party API. Application code says
`external-database-service`, and the real target can be swapped by editing the Service alone.

## What I learned

- ExternalName is a DNS-layer feature, not a networking one.
- It cannot do port remapping, since it never touches traffic.
- A `type: ExternalName` Service with no working target still shows as created and healthy,
  which makes it easy to misdiagnose.
