# Session 11 - Kubernetes Networking & Services

**Name:** Sourabh Srivastva
**Enrollment Number:** 24BCS10157

I applied the five service types from the session folders and tested how each one can be accessed.

```text
$ kubectl get svc

NAME                        TYPE           CLUSTER-IP       EXTERNAL-IP        PORT(S)        AGE
external-database-service   ExternalName   <none>           nencyravaliya.me   <none>         17s
kubernetes                  ClusterIP      10.96.0.1        <none>             443/TCP        31m
web-service-clusterip       ClusterIP      10.103.181.111   <none>             8080/TCP       18s
web-service-headless        ClusterIP      None             <none>             80/TCP         16s
web-service-loadbalancer    LoadBalancer   10.98.112.60     <pending>          80:30708/TCP   17s
web-service-nodeport        NodePort       10.107.134.211   <none>             80:30080/TCP   17s
```

The `CLUSTER-IP` column shows the main difference between the services. Normal ClusterIP, NodePort, and LoadBalancer services have a cluster IP, a headless service has `None`, and ExternalName does not have a cluster IP.

## 1. ClusterIP

```bash
kubectl apply -f 01-clusterip/app-deployment.yaml
kubectl apply -f 01-clusterip/service.yaml
kubectl apply -f 01-clusterip/client-pod.yaml
```

```text
$ kubectl get endpoints web-service-clusterip

Warning: v1 Endpoints is deprecated in v1.33+; use discovery.k8s.io/v1 EndpointSlice
NAME                    ENDPOINTS                                      AGE
web-service-clusterip   10.244.0.82:80,10.244.0.83:80,10.244.0.84:80   56s

$ kubectl exec curl-client -- curl -s http://web-service-clusterip:8080

<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
```

The Endpoints output showed the three pod IPs selected by the service. The service provides a stable name and IP while the actual pod IPs can change.

The service uses `port: 8080` while the Nginx containers listen on `targetPort: 80`. These two ports do not have to be the same.

The warning also shows that the older `Endpoints` API is deprecated in newer Kubernetes versions and `EndpointSlice` should be used instead.

## 2. NodePort

```text
$ kubectl get svc web-service-nodeport

NAME                   TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)        AGE
web-service-nodeport   NodePort   10.107.134.211   <none>        80:30080/TCP   2m27s

$ minikube service web-service-nodeport --url

http://127.0.0.1:59679

! Because you are using a Docker driver on windows, the terminal needs to be open to run it.
```

`80:30080/TCP` means the service uses port 80 internally and exposes port 30080 on the node.

With Minikube using the Docker driver on Windows, the node is running inside a container, so I could not directly access the NodePort using the node IP. `minikube service --url` created a local tunnel and gave me a localhost URL instead.

The tunnel has to remain running for the URL to work.

## 3. LoadBalancer

```text
$ kubectl get svc web-service-loadbalancer

NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
web-service-loadbalancer   LoadBalancer   10.98.112.60   <pending>     80:30708/TCP   4m22s
```

The `EXTERNAL-IP` remained `<pending>`. A LoadBalancer service normally asks the underlying cloud provider to create an external load balancer. Since this is a local Minikube cluster, there is no cloud provider to provide one.

Minikube can provide similar functionality using:

```bash
minikube tunnel
```

The service also has a NodePort (`30708`), showing that the LoadBalancer service builds on the NodePort functionality.

## 4. ExternalName

```text
$ kubectl get svc external-database-service

NAME                        TYPE           CLUSTER-IP   EXTERNAL-IP        PORT(S)   AGE
external-database-service   ExternalName   <none>       nencyravaliya.me   <none>    4m53s

$ kubectl exec dns-test-client -- nslookup external-database-service

Server:         10.96.0.10
Address:        10.96.0.10:53

** server can't find external-database-service.cluster.local: NXDOMAIN
** server can't find external-database-service.svc.cluster.local: NXDOMAIN

external-database-service.default.svc.cluster.local canonical name = nencyravaliya.me
```

ExternalName does not have a cluster IP, selector, or pods. It provides a DNS alias to an external address.

This allows an application to use the service name instead of depending directly on the external database hostname. If the external address changes, the service can be updated without changing the application configuration.

## 5. Headless Service

```text
$ kubectl get svc web-service-headless

NAME                   TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
web-service-headless   ClusterIP   None         <none>        80/TCP    5m27s

$ kubectl exec headless-dns-client -- nslookup web-service-headless

Server:         10.96.0.10
Address:        10.96.0.10:53

Name:   web-service-headless.default.svc.cluster.local
Address: 10.244.0.95
Name:   web-service-headless.default.svc.cluster.local
Address: 10.244.0.94
Name:   web-service-headless.default.svc.cluster.local
Address: 10.244.0.92

$ kubectl get pods -l app=web-headless -o wide

NAME             READY   STATUS    RESTARTS   AGE     IP            NODE
web-stateful-0   1/1     Running   0          5m27s   10.244.0.92   minikube
web-stateful-1   1/1     Running   0          5m26s   10.244.0.94   minikube
web-stateful-2   1/1     Running   0          5m26s   10.244.0.95   minikube
```

The `clusterIP: None` setting makes this a headless service. Instead of providing one virtual IP, DNS returns the IP addresses of the matching pods directly.

The three returned IPs matched the three StatefulSet pods. This is useful when clients need to communicate with individual pods instead of having traffic distributed through a single service IP.

The StatefulSet also provides stable pod names, so individual pods can be addressed using their predictable names.

---

## What I Learned

The main service types build on each other:

**ClusterIP → NodePort → LoadBalancer**

ClusterIP provides internal access, NodePort adds access through a port on the node, and LoadBalancer adds an external load balancer when the environment supports one.

Services select pods using **labels**, not pod names or IP addresses. If the selector does not match any pods, the service will have no endpoints.

I also learned the Kubernetes service DNS format:

`<service>.<namespace>.svc.cluster.local`

Within the same namespace, the shorter service name can be used because of the DNS search path configured inside the pod.

The `nslookup` output also showed the DNS search process. It first tried names with different suffixes, producing the `NXDOMAIN` messages, before resolving the complete service name successfully.
