# 03 — LoadBalancer Service

LoadBalancer asks the underlying infrastructure to provision an external load balancer
and give the Service a real external IP.

![run](run.png)

## The external IP was actually assigned

```bash
kubectl get svc web-service-loadbalancer
```

```text
NAME                       TYPE           CLUSTER-IP   EXTERNAL-IP   PORT(S)        AGE
web-service-loadbalancer   LoadBalancer   10.96.4.14   172.19.0.5    80:30205/TCP   27s
```

`EXTERNAL-IP` shows `172.19.0.5` rather than `<pending>`, because my cluster runs a load
balancer provisioner. On a plain cluster with no cloud integration this column stays
`<pending>` forever — the Service is still created, but nothing ever assigns the address.

## All three Service types are layered

```bash
kubectl describe svc web-service-loadbalancer
```

```text
Type:                     LoadBalancer
IP:                       10.96.4.14
Port:                     http  80/TCP
TargetPort:               80/TCP
NodePort:                 http  30205/TCP
```

This is the key detail. One LoadBalancer Service has **all three** addresses at once:

- a ClusterIP (`10.96.4.14`) for in-cluster traffic,
- a NodePort (`30205`) on every node,
- an external IP (`172.19.0.5`) from the provisioner.

So the types build on each other: `ClusterIP → NodePort → LoadBalancer`.

## Traffic reaches all pods

```bash
for i in $(seq 1 8); do kubectl exec curl-client -- curl -s http://172.19.0.5; done
```

```text
Served by: web-app-loadbalancer-849576b9d7-9ctgs
Served by: web-app-loadbalancer-849576b9d7-6rsbr
Served by: web-app-loadbalancer-849576b9d7-6rsbr
Served by: web-app-loadbalancer-849576b9d7-6rsbr
Served by: web-app-loadbalancer-849576b9d7-9ctgs
Served by: web-app-loadbalancer-849576b9d7-9ctgs
Served by: web-app-loadbalancer-849576b9d7-9ctgs
Served by: web-app-loadbalancer-849576b9d7-9ctgs
```

## What I learned

- LoadBalancer is the standard way to expose a service in a cloud cluster, but each one
  usually costs a separate cloud load balancer — which gets expensive with many services.
- `<pending>` is not an error; it means no controller exists to fulfil the request.
- The third pod (`s6zzj`) did not appear in this sample of 8 requests. Distribution is random
  per connection, not strict round-robin, so a small sample does not always hit every pod.
