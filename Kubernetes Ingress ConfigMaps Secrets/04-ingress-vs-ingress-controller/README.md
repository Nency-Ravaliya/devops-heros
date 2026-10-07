# Ingress vs Ingress Controller

## What is an Ingress?

An **Ingress** is a Kubernetes **API object** (`networking.k8s.io/v1`, kind `Ingress`). It is just a set of **routing rules**: which external **host** and **path** should go to which **Service:port**, plus optional TLS settings. On its own it does nothing. It's a piece of configuration stored in etcd.

```yaml
rules:
  - host: demo.local
    http:
      paths:
        - path: /shop
          backend: { service: { name: shop, port: { number: 80 } } }
```

## What is an Ingress Controller?

An **Ingress Controller** is a **running application** (Pods + a Service) that:
1. **watches** the API server for Ingress, Service and EndpointSlice objects,
2. **translates** the rules into its own proxy configuration (e.g. an `nginx.conf`), and
3. **actually receives the HTTP/HTTPS traffic** and proxies it to the backend Pod IPs.

Kubernetes does **not** ship one. You install one. In my cluster, `minikube addons enable ingress` installed **ingress-nginx**:

```text
$ kubectl get ingressclass
NAME    CONTROLLER             PARAMETERS   AGE
nginx   k8s.io/ingress-nginx   <none>       ...

$ kubectl -n ingress-nginx get svc ingress-nginx-controller
NAME                       TYPE       CLUSTER-IP       PORT(S)
ingress-nginx-controller   NodePort   10.107.245.208   80:30088/TCP,443:32417/TCP
```

## Difference

| | Ingress | Ingress Controller |
|---|---|---|
| What it is | A YAML resource (rules) | A Deployment/DaemonSet of reverse-proxy Pods |
| Who creates it | App developers, per application | Cluster admins, once per cluster (or per class) |
| Handles traffic? | ❌ No | ✅ Yes: it is the L7 load balancer |
| Lives in | The app's namespace | Usually its own namespace (`ingress-nginx`) |
| Examples | `demo-ingress`, `host-ingress` in this folder | ingress-nginx, Traefik, HAProxy, Kong, Contour, AWS Load Balancer Controller, GKE Ingress |
| Linked by | `spec.ingressClassName: nginx` | `IngressClass` object `nginx` → `controller: k8s.io/ingress-nginx` |
| Without the other | Ingress stays with an empty ADDRESS; nothing routes | Controller runs but only serves a 404 default backend |

**Analogy:** the Ingress is the *routing table written on paper*, and the controller is the *router that reads it and moves the packets*.

## Why both are required

- **Separation of concerns:** developers declare *what* routing they want in a portable, standard object. The platform team chooses *how* it is implemented (nginx on bare metal, an AWS ALB in EKS, Traefik with Let's Encrypt…), and the same Ingress YAML works with any of them.
- **One entry point for many Services:** without Ingress, every public Service needs its own `LoadBalancer` (one cloud LB, one IP and one bill each). With Ingress, **one** controller Service (one LB) fans out to many Services by host and path.
- **L7 features in one place:** TLS termination, path rewrites, redirects, auth, rate limiting and canary routing are done by the controller, configured through Ingress fields and annotations.

## Examples (from my hands-on)

| Request | Ingress rule | Result |
|---|---|---|
| `Host: demo.local` `/shop` | path-based `/shop(/\|$)(.*)` → `shop:80` (rewrite to `/`) | `SHOP service` |
| `Host: demo.local` `/blog/some/page` | path-based → `blog:80` | `BLOG service` |
| `Host: shop.demo.local` `/` | host-based → `shop:80` | `SHOP service` |
| `Host: blog.demo.local` `/` | host-based → `blog:80` | `BLOG service` |
| `Host: unknown.local` | no rule | `404` from the controller's default backend |

Traffic path: `client → controller Service (NodePort 30088 / LoadBalancer) → ingress-nginx Pod (reads Host + path) → Pod IP of shop/blog directly`. ingress-nginx sends traffic straight to the Pod endpoints from the EndpointSlices, not through the Service's ClusterIP. That's why its access log shows upstream Pod IPs like `10.244.0.99:8080`.
