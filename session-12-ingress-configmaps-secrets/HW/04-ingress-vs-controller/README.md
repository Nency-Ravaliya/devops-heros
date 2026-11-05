# Ingress vs Ingress Controller

**Name:** Smit Rupani  
**Enrollment:** 24bcs10256  

---

## 1. What is an Ingress?
An **Ingress** is a Kubernetes API object (`kind: Ingress`) that defines rules for external HTTP/HTTPS routing to internal Services.
- It is purely a **declarative specification / configuration data**.
- Creating an Ingress resource on its own **does nothing** unless an Ingress Controller is actively running to read and implement those rules.

## 2. What is an Ingress Controller?
An **Ingress Controller** is the actual software daemon/application (usually a reverse proxy like NGINX, Traefik, HAProxy, Envoy, or AWS ALB Controller) running in your cluster.
- It continuously monitors the Kubernetes API for new or updated `Ingress` resources.
- It dynamically updates its load-balancing configuration (e.g. `/etc/nginx/nginx.conf`) and reloads traffic routing without dropping connections.

## 3. Key Differences

| Feature | Ingress | Ingress Controller |
| :--- | :--- | :--- |
| **What it is** | Kubernetes API Resource (YAML definition). | An active running application / Pod (Reverse Proxy daemon). |
| **Role** | Specifies the desired routing rules (hosts, paths, TLS certs, backend services). | Reads the rules, provisions load balancer ports, proxies incoming requests. |
| **Built-in?** | Part of standard Kubernetes core APIs (`networking.k8s.io/v1`). | NOT bundled by default in plain k8s; must be installed explicitly. |
| **Analogy** | A blueprint or architectural rulebook. | The construction crew and traffic police that enforce the blueprint. |

## 4. Why Both Are Required
- An Ingress without a Controller is an ignored YAML file with no active listener.
- An Ingress Controller without Ingress resources has no routing rules to execute and returns 404 for all requests.
- Together, they decouple routing configuration from controller infrastructure, enabling multi-tenant routing and zero-downtime path updates.

## 5. Popular Ingress Controllers
1. **NGINX Ingress Controller:** Most popular community controller; high performance and rich annotation support.
2. **Traefik:** Dynamic cloud-native reverse proxy with automated Let's Encrypt SSL and intuitive dashboard.
3. **AWS Load Balancer Controller:** Automatically provisions AWS Application Load Balancers (ALB) and Network Load Balancers (NLB) in AWS EKS.
