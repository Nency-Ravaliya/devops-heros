# Task 4 - Ingress vs Ingress Controller

**Ujjawal Prabhat - 24BCS10267 - Session 12**

## Short answer

- An **Ingress** is a Kubernetes **API object** (`networking.k8s.io/v1`, kind `Ingress`). It is a set of *routing rules*:
  "requests for host X and path Y go to Service Z on port P", plus optional TLS. On its own it does nothing. It is just data in etcd.
- An **Ingress Controller** is the **software running in the cluster** (a Deployment/DaemonSet with a reverse proxy: NGINX, Traefik,
  HAProxy, Envoy/Contour, AWS ALB controller, ...). It **watches** Ingress objects, Services and EndpointSlices, **turns them into proxy
  configuration**, and actually receives and forwards the HTTP traffic.
- The **IngressClass** connects the two: an Ingress sets `ingressClassName: nginx`, and the IngressClass `nginx` says
  `controller: k8s.io/ingress-nginx`, so only that controller handles it.

Kubernetes ships the Ingress **API** but **no controller**. A cluster with no controller accepts Ingress objects and nothing happens.
(Troubleshooting case 2 shows the same thing for an Ingress whose class has no controller.)

| | Ingress | Ingress Controller |
|---|---|---|
| What | API resource (YAML rules) | Running pods (reverse proxy + control loop) |
| Provided by | Kubernetes core API | You install it (Helm/manifests) or the cloud provides it |
| Namespaced | Yes (lives next to its Services) | Usually its own namespace (`ingress-nginx`) and serves all namespaces |
| Contains | hosts, paths, pathType, backends, TLS secret refs, annotations | the proxy (nginx), the watcher, the default backend, admission webhook |
| Handles traffic? | No | Yes: L7 routing, TLS termination, rewrites, load balancing |
| Exposed by | n/a | A Service (LoadBalancer/NodePort) or hostPorts, the cluster's single entry point |
| How many | Many, one per app/team | Usually one or a few (selected by IngressClass) |
| Analogy | Routing table / config file | The router / web server that reads it |

## Seeing both in my cluster

```
$ kubectl api-resources | grep -iE '^(ingresses|ingressclasses) '
ingressclasses                                         networking.k8s.io/v1              false        IngressClass
ingresses                           ing                networking.k8s.io/v1              true         Ingress

$ kubectl get ingressclass nginx -o yaml | sed -n '/^spec/,$p;/annotations/,/^  [a-z]/p' | head -12
  annotations:
    kubectl.kubernetes.io/last-applied-configuration: |
      {"apiVersion":"networking.k8s.io/v1","kind":"IngressClass","metadata":{"annotations":{},"labels":{"app.kubernetes.io/component":"controller","app.kubernetes.io/instance":"ingress-nginx","app.kubernetes.io/name":"ingress-nginx","app.kubernetes.io/part-of":"ingress-nginx","app.kubernetes.io/version":"1.12.1"},"name":"nginx"},"spec":{"controller":"k8s.io/ingress-nginx"}}
  creationTimestamp: "2026-10-06T10:48:52Z"
spec:
  controller: k8s.io/ingress-nginx

$ kubectl -n ingress-nginx get deploy,pods,svc -o wide
NAME                                       READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES                                                                                                                     SELECTOR
deployment.apps/ingress-nginx-controller   1/1     1            1           74m   controller   registry.k8s.io/ingress-nginx/controller:v1.12.1@sha256:9724476b928967173d501040631b23ba07f47073999e80e34b120e8db5f234d5   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx

NAME                                            READY   STATUS      RESTARTS      AGE   IP           NODE                         NOMINATED NODE   READINESS GATES
pod/ingress-nginx-admission-create-49x7g        0/1     Completed   0             74m   10.244.1.4   devops-heros-worker2         <none>           <none>
pod/ingress-nginx-admission-patch-5xggt         0/1     Completed   2 (73m ago)   74m   10.244.1.3   devops-heros-worker2         <none>           <none>
pod/ingress-nginx-controller-7c467b649f-4q7rm   1/1     Running     0             74m   10.244.0.5   devops-heros-control-plane   <none>           <none>

NAME                                         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)                      AGE   SELECTOR
service/ingress-nginx-controller             LoadBalancer   10.96.146.138   172.18.0.5    80:31625/TCP,443:32701/TCP   74m   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
service/ingress-nginx-controller-admission   ClusterIP      10.96.228.163   <none>        443/TCP                      74m   app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx

$ kubectl -n ingress-nginx get deploy ingress-nginx-controller -o jsonpath='{.spec.template.spec.containers[0].image}{"\n"}{.spec.template.spec.containers[0].args}{"\n"}'
registry.k8s.io/ingress-nginx/controller:v1.12.1@sha256:9724476b928967173d501040631b23ba07f47073999e80e34b120e8db5f234d5
["/nginx-ingress-controller","--election-id=ingress-nginx-leader","--controller-class=k8s.io/ingress-nginx","--ingress-class=nginx","--configmap=$(POD_NAMESPACE)/ingress-nginx-controller","--validating-webhook=:8443","--validating-webhook-certificate=/usr/local/certificates/cert","--validating-webhook-key=/usr/local/certificates/key","--watch-ingress-without-class=true","--publish-status-address=localhost"]

$ kubectl -n ingress-nginx get deploy ingress-nginx-controller -o jsonpath='{.spec.template.spec.nodeSelector}{"\n"}{.spec.template.spec.containers[0].ports}{"\n"}'
{"kubernetes.io/os":"linux"}
[{"containerPort":80,"hostPort":80,"name":"http","protocol":"TCP"},{"containerPort":443,"hostPort":443,"name":"https","protocol":"TCP"},{"containerPort":8443,"name":"webhook","protocol":"TCP"}]
```

Things to notice:
- `ingresses` and `ingressclasses` are just API resources.
- The controller is an ordinary Deployment running the `ingress-nginx/controller` image, with `--controller-class=k8s.io/ingress-nginx` and
  `--ingress-class=nginx`, which match the IngressClass. In the kind flavour it binds **hostPort 80/443** on the control-plane node,
  and kind maps them to my Mac's `8081/8443`.
- `--watch-ingress-without-class=true`: this controller also takes Ingresses that set no class at all.

## The controller turning my Ingress objects into nginx config

```
$ kubectl -n ingress-nginx exec deploy/ingress-nginx-controller -- sh -c "grep -c 'server_name' /etc/nginx/nginx.conf; grep -n 'server_name .*24bcs10267' /etc/nginx/nginx.conf"
11
349:		server_name a.24bcs10267.local ;
462:		server_name apps.24bcs10267.local ;
768:		server_name b.24bcs10267.local ;

$ kubectl -n ingress-nginx exec deploy/ingress-nginx-controller -- sh -c "awk '/## start server apps.24bcs10267.local/,/## end server apps.24bcs10267.local/' /etc/nginx/nginx.conf | grep -E 'server_name|location|rewrite|set \$proxy_upstream_name|set \$service_name' "
		server_name apps.24bcs10267.local ;
		location ~* "^/b(/|$)(.*)" {
			set $location_path  "/b(/|${literal_dollar})(.*)";
			rewrite_by_lua_file /etc/nginx/lua/nginx/ngx_rewrite.lua;
			rewrite "(?i)/b(/|$)(.*)" /$2 break;
		location ~* "^/a(/|$)(.*)" {
			set $location_path  "/a(/|${literal_dollar})(.*)";
			rewrite_by_lua_file /etc/nginx/lua/nginx/ngx_rewrite.lua;
			rewrite "(?i)/a(/|$)(.*)" /$2 break;
		location ~* "^/" {
			set $location_path  "/";
			rewrite_by_lua_file /etc/nginx/lua/nginx/ngx_rewrite.lua;
			rewrite "(?i)/" /$2 break;
```

My three hostnames from the Task 3 Ingresses became `server_name` blocks in the generated `/etc/nginx/nginx.conf`. The path rules became
`location` blocks with the `rewrite "/a(/|$)(.*)" /$2` from my annotation. The controller regenerates and reloads this file
whenever an Ingress, Service or EndpointSlice changes. That is the controller's whole job.

## Request flow

```
curl -H "Host: apps.24bcs10267.local" localhost:8081/b/orders/42
  -> Mac :8081 --(kind extraPortMapping)--> control-plane node :80 (hostPort)
  -> ingress-nginx-controller pod (nginx)          <- Ingress Controller (data plane)
       server_name apps.24bcs10267.local
       location ~* ^/b(/|$)(.*)  -> rewrite to /orders/42
       upstream s12-app-b-80 = EndpointSlice IPs of Service app-b
  -> app-b pod 10.244.2.124:80 receives "GET /orders/42"
Ingress object "path-routing" in namespace s12  <- only the rules the controller read
```
