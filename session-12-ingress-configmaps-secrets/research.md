# Kubernetes Ingress and Ingress Controller — My Understanding

While working with Kubernetes Services, I understood that Services are useful for exposing applications, but they can become inconvenient when we have multiple applications that need to be accessed from outside the cluster. Instead of creating a separate NodePort or LoadBalancer for every application, Kubernetes provides **Ingress** for handling HTTP and HTTPS traffic through routing rules.

## What is Ingress?

In my understanding, an **Ingress is basically a set of routing rules** that tells Kubernetes where incoming HTTP/HTTPS requests should go.

For example, suppose I have a frontend and a backend:

* `/` → frontend service
* `/api/` → backend service

Instead of exposing both Services separately, I can put these rules into one Ingress. When a request comes in, the Ingress uses the hostname and/or URL path to decide which Service should receive it.

So I think of Ingress as a **routing configuration or traffic rule**, rather than the actual server handling the request.

Ingress can also be used for things such as host-based routing, path-based routing, TLS termination, and exposing multiple Services through a common entry point. Kubernetes describes Ingress as an API object for managing external access to Services, mainly for HTTP and HTTPS traffic.

For example:

```text
                    Outside the cluster
                           |
                           v
                    Ingress
                   /        \
                  /          \
             /api/             /
                |              |
                v              v
          Backend Service   Frontend Service
                |              |
                v              v
             Backend Pods   Frontend Pods
```

This makes more sense to me than thinking of Ingress as another type of Service. **Ingress is not a Service type**. It defines how HTTP/HTTPS traffic should be routed to Services.

---

## What is an Ingress Controller?


Creating an Ingress object by itself does **not actually make the application accessible**. There has to be an **Ingress Controller** running in the cluster to implement those rules.

The way I understand the difference now is:

**Ingress = the rules**

**Ingress Controller = the component that actually implements those rules**

For example, if my Ingress says:

```text
/api → backend-service
/    → frontend-service
```

the Ingress Controller reads those rules and configures the actual proxy/load-balancing system to route requests accordingly.

In the case of the Ingress-NGINX controller, it watches Kubernetes resources such as Ingresses, Services, Endpoints, Secrets and ConfigMaps and builds the NGINX configuration from them.

So the overall flow I understand is:

```text
Client
  |
  | HTTP request
  v
Ingress Controller
  |
  | reads Ingress rules
  v
Ingress routing
  |
  +------ / -------> Frontend Service ---> Frontend Pods
  |
  +---- /api/ -----> Backend Service ----> Backend Pods
```

---

## How Ingress worked in my Minikube setup

In my Kubernetes setup, I enabled the NGINX Ingress controller using:

```bash
minikube addons enable ingress
```

Then I could check that the controller was running with:

```bash
kubectl get pods -n ingress-nginx
```

The important thing I learned from this was that enabling the controller and creating an Ingress are **two different things**.

The controller provides the actual machinery for processing the traffic, while the Ingress resource provides the rules that I want that machinery to follow.

---

## Path-Based Routing

One of the most useful things I understood from the Ingress exercise was **path-based routing**.

For example, I had a setup similar to:

```text
yatri.local/
        |
        +---- /api/ ------> yatri-backend-service
        |
        +---- / -----------> yatri-frontend-service
```

So when I sent:

```text
http://yatri.local/
```

the request was routed to the frontend.

When I sent:

```text
http://yatri.local/api/
```

the request was routed to the backend.

This means I can expose multiple parts of an application through a single hostname instead of giving every Service its own external address.

---

## Host-Based Routing

Ingress can also use the hostname to decide where traffic goes.

For example:

```text
shop.example.com  → frontend-service
api.example.com   → backend-service
```

The important point is that the request's **Host** and **path** can both be used as matching rules. Kubernetes requires the host/path rules to match before routing the request to the specified backend Service.

So I see Ingress as being similar to a traffic receptionist:

```text
                    Incoming Request
                           |
                           v
                    "Where should
                     this go?"
                           |
              +------------+------------+
              |                         |
         Host/path =                 Host/path =
         frontend                   backend
              |                         |
              v                         v
       Frontend Service          Backend Service
```

---

## Ingress vs Service


A **Service** provides a stable way of accessing a set of Pods. It uses selectors to identify the Pods behind it.

An **Ingress** sits at the HTTP/HTTPS routing level and decides **which Service should receive an incoming request**.

So I would think of it like this:

```text
Ingress
   |
   | decides where traffic goes
   v
Service
   |
   | finds the appropriate Pods
   v
Pods
```

A NodePort or LoadBalancer Service can expose an application directly, while Ingress allows multiple HTTP/HTTPS applications to share a common entry point and routing layer.

---

## TLS and HTTPS

Ingress can also handle TLS.

Instead of each individual application having to deal with external HTTPS traffic separately, an Ingress controller can terminate TLS and then route the request to the appropriate Service.

A typical setup would look like:

```text
Client
  |
 HTTPS
  |
  v
Ingress Controller
  |
 TLS termination
  |
  v
Service
  |
  v
Pods
```

The exact TLS behaviour depends on the particular Ingress Controller being used, so the controller's documentation still needs to be checked for implementation-specific details.

