# LoadBalancer Service — Production Public Cloud Ingress

## 1. What is a LoadBalancer Service?
A `LoadBalancer` service is the standard way to expose internet-facing applications in managed cloud environments (AWS EKS, Google Cloud GKE, Azure AKS, DigitalOcean DOKS).

When you deploy a service with `type: LoadBalancer`:
1. Kubernetes automatically provisions an external cloud-managed load balancer (e.g., AWS Network Load Balancer / Classic ELB, GCP Network Load Balancer, Azure Public Load Balancer).
2. The cloud provider assigns a **public IP address** or a **public DNS domain name**.
3. Under the hood, Kubernetes automatically builds a `NodePort` and a `ClusterIP` to route traffic into the cluster.

---

## 2. Why Do We Need LoadBalancer? (The Problem It Solves)

### The Problem with NodePort:
* **Non-Standard High Ports:** End users cannot be expected to visit `http://shop.company.com:30080`. They expect standard HTTP (`80`) and HTTPS (`443`).
* **Single Point of Failure:** If clients connect to a specific worker node's IP directly, and that node dies, users get a connection timeout.
* **No Cloud-Level Traffic Balancing:** NodePort does not distribute traffic evenly across multiple availability zones.

### The Solution: Cloud Load Balancer
A managed Cloud Load Balancer acts as a single, resilient entry point with health checks and autoscaling across all cluster worker nodes.

```text
               Public Internet User
                        |
            Visits: http://my-shop.com:80
                        |
                        v
        +-----------------------------------+
        |      Cloud Provider Public LB     |
        |   (AWS NLB / GCP External LB)     |
        |   Public IP: 54.210.15.22:80      |
        +-----------------------------------+
                        |
        [Distributes traffic across worker nodes]
                        |
         +--------------+--------------+
         | (Port 31250)                | (Port 31250)
         v                             v
+-------------------+         +-------------------+
|   Worker Node 1   |         |   Worker Node 2   |
|   192.168.1.10    |         |   192.168.1.11    |
+-------------------+         +-------------------+
         \                             /
          \                           /
           v                         v
     +-------------------------------------+
     |   Service ClusterIP: 10.96.88.20    |
     +-------------------------------------+
                        |
         +--------------+--------------+
         |                             |
         v                             v
+------------------+          +------------------+
|   Backend Pod 1  |          |   Backend Pod 2  |
|   10.244.0.5:80  |          |   10.244.1.9:80  |
+------------------+          +------------------+
```

---

## 3. Real-World Analogy: The International Airport Gate
* **The Cloud Load Balancer** = The main international terminal entrance. Every traveler enters through the same glass doors on ground level.
* **The Worker Nodes** = Terminal shuttles routing passengers across different concourses.
* **The Pods** = The specific flight boarding gates.

---

## 4. Where is LoadBalancer Used in Production?
* **Public Customer Web Applications:** E-commerce frontends, SaaS user dashboards, public landing pages.
* **Public REST/GraphQL APIs:** Mobile app API gateways and public webhooks.
* **Ingress Controller Entrypoints:** In production architectures, teams rarely create a `LoadBalancer` for every single microservice (due to cloud costs). Instead, they create **one single LoadBalancer Service** pointing to an Ingress Controller (like NGINX Ingress), which routes all subdomains and paths internally.

---

## 5. Code Manifests & Field-by-Field Breakdown

### File: `app-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: web-app-loadbalancer
  labels:
    app: web-loadbalancer
spec:
  replicas: 3
  selector:
    matchLabels:
      app: web-loadbalancer
  template:
    metadata:
      labels:
        app: web-loadbalancer
    spec:
      containers:
        - name: web-server
          image: nginx:1.25-alpine
          ports:
            - containerPort: 80
          resources:
            requests:
              cpu: "50m"
              memory: "64Mi"
            limits:
              cpu: "100m"
              memory: "128Mi"
```

### File: `service.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: web-service-loadbalancer
  labels:
    app: web-loadbalancer
spec:
  type: LoadBalancer
  selector:
    app: web-loadbalancer
  ports:
    - name: http
      port: 80
      targetPort: 80
      protocol: TCP
```

### Key Field Explanations:
* `spec.type: LoadBalancer`: Instructs the cloud controller manager to provision a cloud load balancer.
* `spec.ports[0].port: 80`: Standard HTTP port exposed to public users.
* `spec.ports[0].targetPort: 80`: The container's listening port.

---

## 6. How to Run and Deploy

### Step 1: Apply the Deployment
```bash
kubectl apply -f 03-loadbalancer/app-deployment.yaml
```

Verify pods are running:
```bash
kubectl get pods -l app=web-loadbalancer
```

### Step 2: Apply the LoadBalancer Service
```bash
kubectl apply -f 03-loadbalancer/service.yaml
```

Inspect service creation:
```bash
kubectl get svc web-service-loadbalancer
```

---

## 7. How to Check Website Traffic on LoadBalancer

### In Production Cloud (AWS EKS, GCP GKE, Azure AKS):
In a real cloud cluster, `EXTERNAL-IP` will automatically populate within 1–2 minutes with a public IP or AWS ELB DNS name:
```text
NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP                                                              PORT(S)        AGE
web-service-loadbalancer   LoadBalancer   10.96.88.20    a1b2c3d4e5f6-123456789.us-east-1.elb.amazonaws.com                       80:31250/TCP   60s
```

Test access:
```bash
curl http://a1b2c3d4e5f6-123456789.us-east-1.elb.amazonaws.com
```

### In Local Development (Minikube / Docker Desktop):
On local Minikube, there is no real cloud provider. `EXTERNAL-IP` will stay in `<pending>` state unless you run the Minikube tunnel daemon.

**Option 1: Start Minikube Tunnel (in a separate terminal window)**
```bash
minikube tunnel
```
Once the tunnel starts, `kubectl get svc web-service-loadbalancer` will show a real local IP (e.g., `127.0.0.1` or `10.96.88.20`).
Open in browser:
```text
http://localhost
```

**Option 2: Direct Minikube Service Access**
```bash
minikube service web-service-loadbalancer
```

---

## 8. Cloud Cost Considerations & Production Best Practices

* **Cost Gotcha:** Every `LoadBalancer` service provisions a separate cloud infrastructure asset (e.g., ~$18–$25/month per AWS NLB/ALB). If you have 50 microservices, creating 50 LoadBalancer services will cost $1,000+/month just for load balancers!
* **Production Best Practice:** Create **1 LoadBalancer** for your **Ingress Controller**, and use Kubernetes Ingress rules (`/orders`, `/users`, `/payments`) or host headers (`api.company.com`, `app.company.com`) to route traffic to internal `ClusterIP` services for zero extra load balancer cost.

---

## 9. Cleanup
```bash
kubectl delete -f 03-loadbalancer/service.yaml
kubectl delete -f 03-loadbalancer/app-deployment.yaml
```
