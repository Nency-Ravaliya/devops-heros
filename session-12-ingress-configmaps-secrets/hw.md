## Screenshots

### Configmap

![Screenshot 1](screenshots/Screenshot%202026-09-17%20230445.png)

![Screenshot 2](screenshots/Screenshot%202026-09-17%20230613.png)

### Secret
![Screenshot 3](screenshots/Screenshot%202026-09-17%20231008.png)

### Ingress

![Screenshot 4](screenshots/Screenshot%202026-09-17%20231356.png)

![Screenshot 5](screenshots/Screenshot%202026-09-17%20231413.png)

### Demo

![Screenshot 8](screenshots/Screenshot%202026-09-17%20232447.png)

![Screenshot 9](screenshots/Screenshot%202026-09-17%20232503.png)

![Screenshot 10](screenshots/Screenshot%202026-09-17%20232603.png)

![Screenshot 6](screenshots/Screenshot%202026-09-17%20232332.png)

![Screenshot 7](screenshots/Screenshot%202026-09-17%20232401.png)

# Ingress vs. Ingress Controller

The difference between an **Ingress** and an **Ingress Controller** is the difference between a **configuration file (the rules)** and the **software execution engine (the proxy)** that enforces those rules.

Creating an Ingress resource without an Ingress Controller does nothing—the traffic rules will simply sit idle in `etcd`.

---

## High-Level Analogy

* **Ingress:** A traffic law or flight itinerary written on paper (e.g., *"Vehicles bound for `/api` take Exit 4"*).
* **Ingress Controller:** The traffic officer, router, or airport staff actively directing the cars and passengers according to that paper.

---

## 1. Core Definitions

### What is an Ingress?
An **Ingress** is a standard Kubernetes API resource (`networking.k8s.io/v1`) that defines how external HTTP/HTTPS traffic should route to internal services.

* It is purely declarative metadata (**data/rules only**).
* Defines hostnames (e.g., `api.example.com`), URL paths (e.g., `/users`, `/checkout`), and TLS certificates.
* Does not process packets or listen on network sockets by itself.

### What is an Ingress Controller?
An **Ingress Controller** is an active, running application (typically a Pod or DaemonSet/Deployment backed by a Layer 7 proxy like NGINX, HAProxy, Envoy, or Traefik).

* It monitors the Kubernetes API server for the creation, modification, or deletion of Ingress resources.
* It dynamically translates those Ingress rules into its own proxy configuration (e.g., rewriting `nginx.conf` or updating Envoy routes) and reloads without dropping connections.
* It accepts incoming external traffic (via a `LoadBalancer` or `NodePort` Service) and proxies requests directly to Pod endpoints.

---

## 2. Comparison Table

| Attribute | Ingress | Ingress Controller |
|---|---|---|
| **What is it?** | Kubernetes API object / YAML manifest | Running application (reverse proxy + controller loop) |
| **Cluster Presence** | Built into Kubernetes core API specifications | **Not installed by default**; must be deployed separately |
| **Role** | Stores routing rules and TLS specifications | Reads rules, opens ports, handles TLS termination, and routes traffic |
| **Resource Kind** | `kind: Ingress` | `kind: Deployment` or `DaemonSet` running a proxy |
| **Examples** | A `.yaml` file with routing rules | Ingress-NGINX, Traefik, HAProxy, AWS ALB Controller, Emissary-ingress |
| **Failure Impact** | Deleting it drops the routing rules for that specific domain/path | Crashing it breaks all external Layer 7 ingress traffic cluster-wide |





