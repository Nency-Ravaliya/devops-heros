# Ingress vs Ingress Controller

Author: Yash Gaikwad (24BCS10100) | Session 12 - Ingress, ConfigMaps and Secrets

The part that confused me at first is that "Ingress" is *not* a piece of software. It is only a Kubernetes API object, a set of routing rules. Something else has to read those rules and do the actual routing, and that something is the Ingress Controller.

---

## 1. What is an Ingress?

An **Ingress** (`networking.k8s.io/v1`) is an API object that describes how HTTP and HTTPS traffic from outside the cluster should be routed to Services inside the cluster.

What it can express:

- **Layer 7 routing** (HTTP/HTTPS only): decisions are based on the request's host and path, not just IP and port.
- **Host based routing**: `shop.example.com` goes to one Service, `blog.example.com` to another.
- **Path based routing**: `/api` goes to the API Service, `/` goes to the frontend.
- **TLS termination**: a `tls` section references a Secret holding the certificate and key.
- **Class selection** with `spec.ingressClassName`, which says *which* controller should implement this Ingress.

What it cannot do on its own: forward a single packet. Creating an Ingress object just stores some YAML in etcd.

### Path types

| `pathType` | Behaviour |
|---|---|
| `Exact` | Matches only that exact path (`/app1` does not match `/app1/`) |
| `Prefix` | Matches on path segments: `/app1` matches `/app1`, `/app1/` and `/app1/x` but not `/app10` |
| `ImplementationSpecific` | Left to the controller / IngressClass |

---

## 2. What is an Ingress Controller?

An **Ingress Controller** is the running component (Pods) that **watches Ingress objects** through the API server and **configures a real reverse proxy / load balancer** to match them. It is the data plane that receives the traffic.

Kubernetes does not ship one by default. I have to install one. Common choices:

| Controller | Notes |
|---|---|
| ingress-nginx | NGINX based, the one used in most tutorials. The Kubernetes project announced its retirement in November 2025 and upstream maintenance (releases, bug fixes, security fixes) ended in March 2026, so for new long-lived setups prefer another controller or the Gateway API. It is still what the Minikube `ingress` addon installs, which is fine for learning |
| Traefik | Dynamic config, popular in smaller clusters and k3s |
| HAProxy Ingress | HAProxy based, high performance |
| AWS Load Balancer Controller | Creates AWS Application Load Balancers from Ingress objects |
| Istio / Contour / Kong / others | Proxy-based controllers that also support Ingress |
| **minikube `ingress` addon** | Deploys **ingress-nginx** into the `ingress-nginx` namespace |

Several controllers can run in the same cluster. `ingressClassName` is what keeps them from stepping on each other.

### IngressClass

An `IngressClass` object links an Ingress to a controller implementation by name:

```yaml
apiVersion: networking.k8s.io/v1
kind: IngressClass
metadata:
  name: nginx
  annotations:
    ingressclass.kubernetes.io/is-default-class: "true"   # optional: used when an Ingress sets no class
spec:
  controller: k8s.io/ingress-nginx
```

`spec.controller` is the string the controller identifies itself with (`k8s.io/ingress-nginx` for ingress-nginx). The old annotation `kubernetes.io/ingress.class` is deprecated in favour of `spec.ingressClassName`.

---

## 3. Ingress vs Ingress Controller

| | Ingress | Ingress Controller |
|---|---|---|
| What it is | Kubernetes **API resource** (YAML in etcd) | **Application** running as Pods (Deployment/DaemonSet) |
| Role | Declares the routing **rules** (what should happen) | Implements the rules (makes it happen) |
| Contains logic? | No, only configuration | Yes, runs NGINX/Traefik/HAProxy/etc. |
| Who creates it | The application team, one per app or per host | The cluster admin, usually installed once (Helm, manifest, addon) |
| Scope | Namespaced | Runs in its own namespace, watches Ingresses cluster-wide (or selected namespaces) |
| Exposed to the internet? | No | Yes, through a LoadBalancer or NodePort Service |
| Examples | `demo-ingress` | ingress-nginx, Traefik, AWS ALB controller |
| If it is missing | Controller has nothing to route | Rules are ignored, nothing is routed |

### Why both are required

- **Ingress without a controller does nothing.** `kubectl apply` succeeds, `kubectl get ingress` lists it, but the ADDRESS column stays empty and requests are never routed, because nobody is watching.
- **A controller without Ingress objects has no rules.** The proxy is running but only returns its default 404 page, because it has no hosts or paths to route.

The split also keeps things portable: the same Ingress YAML works with different controllers, and the controller is where the vendor-specific implementation lives. Vendor-specific extras go in annotations, which is also the weakness of the API.

---

## 4. How a request flows

```
Client (browser / curl)
   |  http://demo.local/app1
   v
DNS / hosts file:  demo.local -> controller's external address
   |
   v
Service of the controller (type LoadBalancer or NodePort)
   |
   v
Ingress Controller Pod (NGINX)   <-- config generated from Ingress objects
   |  matches Host: demo.local and path /app1
   v
Service  app1-svc  (ClusterIP)
   |  kube-proxy picks an endpoint
   v
Application Pod
```

The controller usually routes **straight to Pod IPs** taken from the Service's endpoints rather than sending traffic through the Service's ClusterIP, but the Service is still what the Ingress references and what defines the set of Pods. The controller Pods also write the external address back into the Ingress status, which is what fills the `ADDRESS` column.

---

## 5. Example: two apps behind one Ingress

### Backend apps

Two tiny echo servers so I can tell which one answered:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app1
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app1
  template:
    metadata:
      labels:
        app: app1
    spec:
      containers:
      - name: echo
        image: hashicorp/http-echo:1.0
        args: ["-text=hello from app1"]
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: app1-svc
spec:
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 5678
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app2
spec:
  replicas: 1
  selector:
    matchLabels:
      app: app2
  template:
    metadata:
      labels:
        app: app2
    spec:
      containers:
      - name: echo
        image: hashicorp/http-echo:1.0
        args: ["-text=hello from app2"]
        ports:
        - containerPort: 5678
---
apiVersion: v1
kind: Service
metadata:
  name: app2-svc
spec:
  selector:
    app: app2
  ports:
  - port: 80
    targetPort: 5678
```

### The Ingress (one host, two paths)

```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: demo-ingress
spec:
  ingressClassName: nginx
  rules:
  - host: demo.local
    http:
      paths:
      - path: /app1
        pathType: Prefix
        backend:
          service:
            name: app1-svc
            port:
              number: 80
      - path: /app2
        pathType: Prefix
        backend:
          service:
            name: app2-svc
            port:
              number: 80
```

### Adding TLS

```yaml
spec:
  ingressClassName: nginx
  tls:
  - hosts:
    - demo.local
    secretName: demo-tls
  rules:
  - host: demo.local
    # ...same rules as above
```

The Secret must be of type `kubernetes.io/tls` in the same namespace as the Ingress:

```bash
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout tls.key -out tls.crt -subj "/CN=demo.local/O=demo"
kubectl create secret tls demo-tls --cert=tls.crt --key=tls.key
```

### Optional default backend

Traffic that matches no rule can be sent to a fallback Service:

```yaml
spec:
  defaultBackend:
    service:
      name: app1-svc
      port:
        number: 80
```

---

## 6. Enabling an Ingress Controller on minikube

minikube bundles the ingress-nginx controller as an addon:

```bash
minikube addons enable ingress
kubectl get pods -n ingress-nginx
kubectl get ingressclass
kubectl get svc -n ingress-nginx
```

Then deploy the apps and the Ingress:

```bash
kubectl apply -f apps.yaml
kubectl apply -f demo-ingress.yaml
kubectl get ingress demo-ingress
kubectl describe ingress demo-ingress
```

Reaching it from my machine depends on the driver:

```bash
# Linux with a VM-style or direct node IP:
minikube ip
curl -H "Host: demo.local" http://$(minikube ip)/app1
curl -H "Host: demo.local" http://$(minikube ip)/app2

# Docker driver on Windows/macOS: the node IP is not directly reachable.
# Keep this running in a separate terminal and use 127.0.0.1 instead:
minikube tunnel
curl -H "Host: demo.local" http://127.0.0.1/app1
curl -H "Host: demo.local" http://127.0.0.1/app2
```

To use the real hostname in a browser, add a hosts-file line pointing `demo.local` at the address above (`/etc/hosts` on Linux/macOS, `C:\Windows\System32\drivers\etc\hosts` on Windows):

```
127.0.0.1  demo.local
```

Clean up:

```bash
kubectl delete ingress demo-ingress
kubectl delete -f apps.yaml
minikube addons disable ingress
```

---

## 7. Ingress vs Service type LoadBalancer

One way to expose HTTP apps without Ingress is to give every Service `type: LoadBalancer`.

```yaml
apiVersion: v1
kind: Service
metadata:
  name: app1-lb
spec:
  type: LoadBalancer
  selector:
    app: app1
  ports:
  - port: 80
    targetPort: 5678
```

| | One LoadBalancer Service per app | One Ingress + one controller |
|---|---|---|
| External IPs / cloud load balancers | One **per Service** | **One** for the controller, shared by all hosts and paths |
| Cost | Each cloud load balancer and public IP is billed | A single load balancer in front of the controller |
| Routing | L4 only, so one IP:port per app | L7 host and path rules, many apps on one IP |
| TLS | Each app handles its own certificates | Terminated centrally at the controller |
| Protocols | Any TCP/UDP | HTTP/HTTPS (other protocols need controller-specific settings) |
| Extras | None | Redirects, rewrites, rate limiting, auth via controller features |

So with ten web apps, Services of type LoadBalancer mean ten external load balancers on a cloud provider, while an Ingress means one. For non-HTTP traffic (databases, raw TCP) a LoadBalancer Service is still the right tool.

---

## 8. Gateway API: the successor

The Ingress API is stable but **feature-frozen**: no new features are being added, and its design pushes controller-specific behaviour into annotations. The **Gateway API** (`gateway.networking.k8s.io`) is its more expressive successor. It splits responsibilities into resources for different roles:

- `GatewayClass`: which implementation (like IngressClass), owned by the infrastructure provider.
- `Gateway`: the listener (ports, protocols, TLS), owned by the cluster operator.
- `HTTPRoute` (and `GRPCRoute`, `TCPRoute`, ...): the routing rules, owned by the application team.

It supports header matching, traffic splitting and cross-namespace routing in the spec itself instead of annotations. The same idea still applies there: the API objects only describe intent, and a controller implementation has to be installed to act on them.

---

## 9. Quick recap

- **Ingress** = the rules (an API object).
- **Ingress Controller** = the engine that reads the rules and routes traffic (Pods running a proxy).
- Both are needed: rules without an engine do nothing, an engine without rules has nothing to do.
- Flow: client, controller Service (LoadBalancer or NodePort), controller Pod, application Service, application Pod.
- On minikube: `minikube addons enable ingress`, then create Ingress objects with `ingressClassName: nginx`.
- One Ingress controller can front many apps, which is cheaper than a LoadBalancer Service per app.
