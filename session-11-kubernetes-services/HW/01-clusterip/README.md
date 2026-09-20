# 01 — ClusterIP Service

**Cluster:** docker-desktop (Kubernetes v1.36.1)

ClusterIP is the default Service type. It gives the Service a stable virtual IP that is
reachable **only from inside the cluster** — there is no external access.

![run](run.png)

## Applied

```bash
kubectl apply -f app-deployment.yaml -f service.yaml -f client-pod.yaml
```

```text
deployment.apps/web-app-clusterip created
service/web-service-clusterip created
pod/curl-client created
```

## Resources created

```bash
kubectl get deployment,pods -l app=web-clusterip
```

```text
NAME                                READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/web-app-clusterip   3/3     3            3           18s

NAME                                     READY   STATUS    RESTARTS   AGE
pod/web-app-clusterip-86f7fc5489-2m457   1/1     Running   0          18s
pod/web-app-clusterip-86f7fc5489-knwhx   1/1     Running   0          18s
pod/web-app-clusterip-86f7fc5489-rcbf5   1/1     Running   0          18s
```

```bash
kubectl get svc web-service-clusterip
```

```text
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
web-service-clusterip   ClusterIP   10.96.228.250   <none>        8080/TCP   18s
```

Note `EXTERNAL-IP` is `<none>` — that is the defining property of ClusterIP.

## Endpoints — the Service found its pods

```bash
kubectl get endpoints web-service-clusterip
```

```text
NAME                    ENDPOINTS                                   AGE
web-service-clusterip   10.244.0.7:80,10.244.0.8:80,10.244.0.9:80   18s
```

All 3 pod IPs are registered. The Service matched them using `selector: app: web-clusterip`.
An empty `ENDPOINTS` column here would mean the selector does not match any pod labels.

## Accessing the Service from inside the cluster

![test](test.png)

```bash
kubectl exec curl-client -- curl -s http://web-service-clusterip:8080
```

```text
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
...
<h1>Welcome to nginx!</h1>
```

The Service name alone works as a hostname because CoreDNS resolves it automatically.

## DNS resolution

```bash
kubectl exec curl-client -- nslookup web-service-clusterip.default.svc.cluster.local
```

```text
Address:	10.96.0.10:53

Name:	web-service-clusterip.default.svc.cluster.local
Address: 10.96.228.250
```

The fully qualified name `<service>.<namespace>.svc.cluster.local` resolves to the
Service's ClusterIP — which matches the `CLUSTER-IP` column above.

## Proving load balancing across all 3 pods

Each pod was given a unique index page so the responses can be told apart:

```bash
for p in $(kubectl get pods -l app=web-clusterip -o jsonpath='{.items[*].metadata.name}'); do
  kubectl exec "$p" -- sh -c "echo 'Served by: $p' > /usr/share/nginx/html/index.html"
done
```

Then 8 requests were sent through the Service:

```bash
for i in $(seq 1 8); do kubectl exec curl-client -- curl -s http://web-service-clusterip:8080; done
```

```text
Served by: web-app-clusterip-86f7fc5489-knwhx
Served by: web-app-clusterip-86f7fc5489-rcbf5
Served by: web-app-clusterip-86f7fc5489-rcbf5
Served by: web-app-clusterip-86f7fc5489-rcbf5
Served by: web-app-clusterip-86f7fc5489-2m457
Served by: web-app-clusterip-86f7fc5489-knwhx
Served by: web-app-clusterip-86f7fc5489-rcbf5
Served by: web-app-clusterip-86f7fc5489-rcbf5
```

All three pods answered. The distribution is random rather than strict round-robin,
because kube-proxy in iptables mode picks a backend at random per connection.

## What I learned

- `port: 8080` is the Service port, `targetPort: 80` is the container port — they do not have to match.
- The Service is only reachable in-cluster, which is why a client pod was needed to test it.
- Endpoints are the link between a Service and its pods; they are populated by label selector, not by name.
