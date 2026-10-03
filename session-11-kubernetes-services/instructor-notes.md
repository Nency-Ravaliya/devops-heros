# Instructor Guide — Session 11: Kubernetes Networking & Services

* Class Pacing: 120 Minutes
* Environment: Minikube / Kind on macOS/Linux + VS Code Terminal Split
* Target Audience: 3rd & 4th Year BCA/MCA Students
* Core Narrative: Connecting Pods and the Outside World: Pod Networking, CoreDNS, Service Discovery, ClusterIP, NodePort, LoadBalancer, Selectors, and Port Mapping

---

## 1. Class Overview & Pacing (120 Minutes)

| Time | Topic | Core Focus | Code File / Lab |
| :--- | :--- | :--- | :--- |
| **00 – 15 min** | 1. Pod Networking Model | The 3 Fundamental Rules of K8s Networking; Ephemeral IPs. | Board diagram |
| **15 – 30 min** | 2. What is a Service? | The Corporate Reception Desk analogy; Decoupling Pod lifecycles. | Corporate analogy |
| **30 – 45 min** | 3. `port` vs `targetPort` vs `nodePort` | The Three Ports Triangle; Front Door vs Back Door. | Port mapping diagram |
| **45 – 60 min** | 4. ClusterIP in Action | Default internal virtual IP; Endpoints & EndpointSlices. | `service/clusterip.yaml` |
| **60 – 75 min** | 5. Kubernetes DNS & Service Discovery | CoreDNS, `/etc/resolv.conf`, `ndots:5`, and FQDN lookups. | `dns-test/curl-test-pod.yaml` |
| **75 – 90 min** | 6. External Access: NodePort | Opening ports on physical host machines (`30000–32767`). | `service/nodeport.yaml` |
| **90 – 100 min** | 7. External Access: LoadBalancer | Cloud provider integration (AWS NLB/ALB) and public IPs. | `service/loadbalancer.yaml` |
| **100 – 110 min** | 8. Service Selectors & Empty Endpoints | Triage label/selector mismatches and Headless Services. | `troubleshooting/empty-endpoints.yaml` |
| **110 – 120 min** | 9. Classroom Quiz & Memory Map | 10 Socratic review questions, memory aids, and key takeaways. | Rapid-Fire Q&A |

---

## 2. Topic 1: The Kubernetes Pod Networking Model (00 – 15 min)

### Concept Explanation:
Start class by explaining how networking in Kubernetes is fundamentally different from standard Docker host networking:

> "In plain Docker on your laptop, every container gets an IP like `172.17.0.2` on a private bridge. To let outside traffic reach it, Docker performs Network Address Translation (NAT) and port mapping (`-p 8080:80`). What happens when you have 1,000 pods across 20 physical servers? NAT and port conflicts become an unmanageable nightmare."

Kubernetes solves this with a clean, flat networking model governed by **The 3 Golden Rules**:
1. **All Pods can communicate with all other Pods without NAT** (across any node in the cluster).
2. **All Nodes can communicate with all Pods without NAT** (and vice versa).
3. **The IP that a Pod sees for itself is the exact same IP that every other Pod sees for it** (no port translation or IP masquerading).

### Relatable Fun Analogy: The Global Mobile Network
* Imagine every citizen in India gets their own direct mobile number with a SIM card.
* You don't call a hotel PBX operator and ask for extension 4; you dial their direct number.
* That is how Pod networking works: **Every Pod gets its own real IP address on the cluster network!**

### The Role of CNI (Container Network Interface):
* Kubernetes doesn't implement the network wires itself; it defines the CNI specification.
* Plugins like **Calico**, **Flannel**, **Cilium**, or **AWS VPC CNI** assign IP subnets to nodes and configure packet routing so Pod A on Node 1 can ping Pod B on Node 2 directly.

### The Problem: Ephemeral Pod IPs
Now ask students:
> "If every Pod has its own IP, why can't our frontend microservice just send requests directly to the backend Pod IP?"

Show what happens when a pod crashes or a rolling update occurs:
```text
Old Backend Pod: 10.244.1.15  --> Dies / Terminated
New Backend Pod: 10.244.2.42  --> Starts with a BRAND NEW IP!
```
* If the frontend hardcoded `http://10.244.1.15:5000`, the moment the backend pod restarts, **the frontend crashes with Connection Refused!**
* Pod IPs are temporary and ephemeral.
* We must **never** hardcode Pod IP addresses.

---

## 3. Topic 2: What is a Service? (The Corporate Reception Desk) (15 – 30 min)

### Concept Explanation:
A **Service** is an abstraction that defines a logical set of Pods and a policy by which to access them.
* A Service provides a **single, static, unchanging Virtual IP address (ClusterIP)** and a stable DNS name.
* Even if 50 pods behind the service are destroyed and recreated with new IPs, the Service IP and DNS name **never change**.

### Relatable Student Analogy: The Corporate Office Reception Desk
* Imagine you visit Google's corporate headquarters to submit an internship form to HR.
* There are 5 HR executives working in the building.
* Employees take lunch breaks, shift desks, go on vacation, and resign.
* You do not walk into the building shouting: *"Where is Rohan's personal desk today?"*
* You walk to the **Reception Desk (The Service)**!
* The receptionist sits at an unchanging desk (Static ClusterIP).
* The receptionist keeps a live clipboard listing who is currently sitting at their desk (The **Endpoints** list).
* When you hand your form to the receptionist, they hand it to whichever HR executive is available.
* In Kubernetes:
  * **The Reception Desk** = The **Service**
  * **The HR Staff** = The **Pods**
  * **The Live Clipboard** = The **Endpoints / EndpointSlices**

Draw this on the board:

```text
               Frontend Pods / External Users
                             |
                             v
               +---------------------------+
               |    KUBERNETES SERVICE     |
               | (ClusterIP: 10.96.0.100)  |  <-- Stable unchanging VIP
               +---------------------------+
                             |
        ---------------------+---------------------
        |                    |                    |
        v                    v                    v
  Backend Pod 1        Backend Pod 2        Backend Pod 3
 (10.244.0.15)        (10.244.0.22)        (10.244.0.38)
```

---

## 4. Topic 3: Port Mapping Mastery (`port` vs `targetPort` vs `nodePort`) (30 – 45 min)

### Concept Explanation:
Students frequently get confused by the three different port settings. Dissect them clearly using the **Three Ports Triangle**:

```text
External Internet / User Browser
       |
       | hits physical machine on high port (30000 - 32767)
       v
+--------------+
|   nodePort   |  (e.g. 30080 on the Worker Node IP)
+--------------+
       |
       | forwards internally inside cluster
       v
+--------------+
|     port     |  (Port exposed by the Service inside the cluster, e.g. 80)
+--------------+
       |
       | forwards into container process
       v
+--------------+
|  targetPort  |  (Port where the container app is actually listening, e.g. 5000)
+--------------+
```

### Trainer Script:
> *"Why do we have `port: 80` and `targetPort: 5000`?  
> Think about clean interface design:  
> Does your frontend developer want to remember that Flask listens on 5000, Spring Boot on 8080, and Go on 9000? NO!  
> They want standard HTTP port 80!  
> `port: 80` is the FRONT DOOR of the Service inside the cluster.  
> `targetPort: 5000` is the BACK DOOR where the container process is listening.  
> `targetPort` targets the container process!  
> If you swap these two numbers, your traffic hits an empty wall."*

---

## 5. Topic 4: ClusterIP in Action (45 – 60 min)

### Concept Explanation:
* **ClusterIP** is the default Service type.
* It allocates an internal IP address reachable **only from within the cluster**.
* Perfect for databases, caching layers, and internal microservice APIs.

### Hands-on Lab 1: Deploying a ClusterIP Service

Tell students:
> "Before we create a Service, we need something to receive the traffic! Let's deploy 3 backend pods running a Python HTTP server on port 5000 using `sessions/session-11-kubernetes-services/deployment/backend-deployment.yaml`."

#### Code File: `deployment/backend-deployment.yaml`
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: yatri-backend
  labels:
    app: yatri-backend
spec:
  replicas: 3
  selector:
    matchLabels:
      app: yatri-backend
  template:
    metadata:
      labels:
        app: yatri-backend
    spec:
      containers:
        - name: backend
          image: python:3.11-alpine3.19
          ports:
            - containerPort: 5000
```

Apply Backend Deployment:
```bash
kubectl apply -f deployment/backend-deployment.yaml
```

Wait until all 3 pods are in `Running` state:
```bash
kubectl get pods -l app=yatri-backend -o wide
```

Output:
```text
NAME                            READY   STATUS    RESTARTS   AGE   IP            NODE
yatri-backend-7f89d54b8-2k4l9   1/1     Running   0          25s   10.244.0.15   minikube
yatri-backend-7f89d54b8-8p2m1   1/1     Running   0          25s   10.244.0.22   minikube
yatri-backend-7f89d54b8-x9q4t   1/1     Running   0          25s   10.244.0.38   minikube
```

Now tell students:
> "Notice how each pod has a unique private IP address. If we hardcode these, our frontend breaks when pods reschedule. Let's create our ClusterIP Service!"

Tell students:
> "Open `sessions/session-11-kubernetes-services/service/clusterip.yaml`."

#### Code File: `service/clusterip.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: yatri-backend-service
  labels:
    app: yatri-backend
spec:
  type: ClusterIP
  selector:
    app: yatri-backend
  ports:
    - name: http
      port: 80
      targetPort: 5000
      protocol: TCP
```

#### YAML Breakdown:
* `spec.type: ClusterIP` -> Exposes the service on a cluster-internal IP.
* `spec.selector.app: yatri-backend` -> Finds all pods with label `app: yatri-backend`.
* `spec.ports[0].port: 80` -> Service listens on port 80.
* `spec.ports[0].targetPort: 5000` -> Forwards traffic to container port 5000.

#### Apply Command:
```bash
kubectl apply -f service/clusterip.yaml
```

#### Output:
```text
service/yatri-backend-service created
```

Inspect the Service:
```bash
kubectl get svc yatri-backend-service
```

Output:
```text
NAME                    TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)   AGE
yatri-backend-service   ClusterIP   10.96.145.82    <none>        80/TCP    18s
```

### Inspecting the Endpoints:
Tell students:
> "A Service is just a set of routing rules. Who tracks the actual pods? The **Endpoints** object!"

```bash
kubectl get endpoints yatri-backend-service
```

Output:
```text
NAME                    ENDPOINTS                                         AGE
yatri-backend-service   10.244.0.15:5000,10.244.0.22:5000,10.244.0.38:5000   45s
```

Explain:
* Notice how the Endpoints list automatically populated the exact IP addresses and container target ports (`5000`) of the three backend pods.
* If a pod crashes or fails its Readiness Probe, the **Endpoints Controller** instantly removes its IP from this list!

---

## 6. Topic 5: Kubernetes DNS & Service Discovery (60 – 75 min)

### Concept Explanation:
Ask students:
> "If our frontend microservice needs to talk to the backend, does it hardcode the ClusterIP `10.96.145.82`? What if someone deletes and recreates the service tomorrow? The ClusterIP might change! How do pods discover each other? By NAME!"

Kubernetes runs a cluster-internal DNS service called **CoreDNS**.

### The Fully Qualified Domain Name (FQDN):
Every Service automatically receives a DNS record in this format:
$$\text{service-name}.\text{namespace}.\text{svc}.\text{cluster}.\text{local}$$

* Within the **same namespace**: Simply call `http://yatri-backend-service:80`
* Across **different namespaces** (e.g. from `frontend` namespace to `backend` namespace): Call `http://yatri-backend-service.default.svc.cluster.local:80`

### The Magic Inside the Container: `/etc/resolv.conf`
When a pod starts, the kubelet injects DNS configuration into `/etc/resolv.conf`:
```text
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5
```

Explain `search` domains:
* When an app queries `yatri-backend-service`, the resolver appends `.default.svc.cluster.local`, and CoreDNS immediately resolves it to `10.96.145.82`!

### Hands-on Lab 2: Testing CoreDNS Resolution Live

#### Code File: `dns-test/curl-test-pod.yaml`
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: curl-test-pod
spec:
  containers:
    - name: curl-client
      image: curlimages/curl:8.5.0
      command: ["sh", "-c", "sleep 3600"]
```

Apply test pod:
```bash
kubectl apply -f dns-test/curl-test-pod.yaml
```

Wait until running:
```bash
kubectl get pod curl-test-pod
```

Test DNS lookup directly:
```bash
kubectl exec -it curl-test-pod -- nslookup yatri-backend-service
```

Output:
```text
Server:    10.96.0.10
Address:   10.96.0.10#53

Name:      yatri-backend-service.default.svc.cluster.local
Address:   10.96.145.82
```

Now curl the service by name:
```bash
kubectl exec -it curl-test-pod -- curl -s http://yatri-backend-service:80
```

Output:
```text
<!DOCTYPE HTML>
<html>
<head><title>Directory listing for /</title></head>
...
Backend v2.0.0 listening on 5000
```

Trainer Script:
> *"Look at that! We did not touch an IP address. We typed `http://yatri-backend-service`. CoreDNS resolved the name to the virtual ClusterIP, and `kube-proxy` load-balanced the request to one of the three backend pods. That is automated service discovery!"*

---

## 7. Topic 6: External Access via NodePort (75 – 90 min)

### Concept Explanation:
Ask students:
> "ClusterIP works great for internal communication between microservices. But how does a customer sitting at home on their laptop access our application from outside the cluster?"

The simplest primitive is a **NodePort Service**:
* Kubernetes allocates a static high port from the range **`30000–32767`**.
* Every single worker node in the cluster opens this port.
* Any traffic sent to `http://<Worker-Node-IP>:<NodePort>` is intercepted and forwarded to the service!

### Hands-on Lab 3: Deploying a NodePort Service

#### Code File: `service/nodeport.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: yatri-backend-nodeport
spec:
  type: NodePort
  selector:
    app: yatri-backend
  ports:
    - name: http
      port: 80
      targetPort: 5000
      nodePort: 30080
```

Apply Command:
```bash
kubectl apply -f service/nodeport.yaml
```

Output:
```text
service/yatri-backend-nodeport created
```

Inspect the service:
```bash
kubectl get svc yatri-backend-nodeport
```

Output:
```text
NAME                     TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
yatri-backend-nodeport   NodePort   10.96.210.44    <none>        80:30080/TCP   12s
```

Test access from the host machine:
```bash
curl http://localhost:30080
```

Output:
```text
Backend v2.0.0 listening on 5000
```

---

## 8. Topic 7: External Access via LoadBalancer (90 – 100 min)

### Concept Explanation:
Ask students:
> "Do you ever see an Amazon or Swiggy URL with port `:30080`? No! Users expect standard ports (`80` for HTTP, `443` for HTTPS). Furthermore, what happens if Worker Node 1 goes down? If users were calling Node 1's IP, they get an outage. We need a cloud-managed public load balancer."

* In managed cloud environments (AWS EKS, GCP GKE, Azure AKS), setting `type: LoadBalancer` tells Kubernetes to automatically provision an external cloud load balancer (e.g. AWS Network Load Balancer).
* The cloud load balancer receives a public IP / DNS name and distributes traffic across all cluster nodes on the assigned NodePort.

```text
Internet User
      |
      v
Cloud Load Balancer (AWS NLB - Public IP: 54.210.15.22)
      |
      +-----------------------+-----------------------+
      |                       |                       |
      v (Port 30080)          v (Port 30080)          v (Port 30080)
Worker Node 1           Worker Node 2           Worker Node 3
      |                       |                       |
      +-----------------------+-----------------------+
                              |
                              v
                   Service ClusterIP (10.96.x.x)
                              |
                              v
                   Target Pods (Port 5000)
```

#### Code File: `service/loadbalancer.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: yatri-backend-lb
  labels:
    app: yatri-backend
spec:
  type: LoadBalancer
  selector:
    app: yatri-backend
  ports:
    - name: http
      port: 80
      targetPort: 5000
      protocol: TCP
```

Apply Command:
```bash
kubectl apply -f service/loadbalancer.yaml
```

Output:
```text
service/yatri-backend-lb created
```

Inspect LoadBalancer state:
```bash
kubectl get svc yatri-backend-lb
```

Explain to students:
* On local Minikube, `EXTERNAL-IP` will show `<pending>` unless `minikube tunnel` is running.
* In AWS EKS, `EXTERNAL-IP` automatically populates with an AWS DNS name:
  `a1b2c3d4e5.us-east-1.elb.amazonaws.com`!

---

## 9. Topic 8: Service Selectors & The "Empty Endpoints" Trap (100 – 110 min)

### Concept Explanation:
Ask students:
> "In tech support tickets, 80% of service issues boil down to one thing: you curl the service, and the connection hangs or returns HTTP 503. Why? Because the Service has **zero endpoints**. Let's break it live!"

### Hands-on Lab 4: Deploying Broken Selector

#### Code File: `troubleshooting/empty-endpoints.yaml`
```yaml
apiVersion: v1
kind: Service
metadata:
  name: broken-backend-service
spec:
  type: ClusterIP
  selector:
    # BUG: Typo in label selector! Running pods have label app: yatri-backend
    app: wrong-backend-name
  ports:
    - port: 80
      targetPort: 5000
```

Apply Broken Service:
```bash
kubectl apply -f troubleshooting/empty-endpoints.yaml
```

Inspect Endpoints:
```bash
kubectl get endpoints broken-backend-service
```

Output:
```text
NAME                     ENDPOINTS   AGE
broken-backend-service   <none>      8s
```

Test Curl from Test Pod:
```bash
kubectl exec -it curl-test-pod -- curl --connect-timeout 3 http://broken-backend-service
```

Output:
```text
curl: (28) Failed to connect to broken-backend-service port 80: Connection timed out
```

### The 3-Step Triage Formula:
1. **Step 1:** Check `kubectl get endpoints <service-name>`.
   If it shows `<none>`, the Service has zero pods attached.
2. **Step 2:** Inspect the Service selector:
   ```bash
   kubectl describe svc broken-backend-service | grep Selector
   ```
   Output: `Selector: app=wrong-backend-name`
3. **Step 3:** Compare against actual running Pod labels:
   ```bash
   kubectl get pods --show-labels
   ```
   Output: `app=yatri-backend`
4. **Fix:** Update the Service selector to `app: yatri-backend`. The Endpoints list immediately populates!

Cleanup broken service:
```bash
kubectl delete -f troubleshooting/empty-endpoints.yaml
```

---

## 10. Topic 9: 10-Question Classroom Quiz & Review (110 – 120 min)

Ask students these 10 rapid-fire questions:

### Q1. Why shouldn't microservices connect to each other using Pod IP addresses?
> Because Pod IPs are dynamic and ephemeral. When pods restart or scale, their IPs change permanently.

### Q2. What is the default Service type in Kubernetes?
> `ClusterIP`.

### Q3. What is the difference between `port` and `targetPort`?
> `port` is the port exposed by the Service inside the cluster. `targetPort` is the port the application container is listening on.

### Q4. What component inside Kubernetes translates service names to ClusterIPs?
> CoreDNS.

### Q5. What is the valid port range for a `NodePort` service?
> Port `30000` to `32767`.

### Q6. What does `kubectl get endpoints <service>` display?
> The list of IP:Port addresses of healthy pods currently receiving traffic for that service.

### Q7. If `kubectl get endpoints` displays `<none>`, what is the most common root cause?
> A mismatch between the Service's `spec.selector` and the Pod's `metadata.labels`.

### Q8. What happens to traffic sent to a Service if a Pod fails its Readiness Probe?
> The Pod's IP is immediately removed from the Service Endpoints list, preventing traffic from reaching the unready container.

### Q9. What is the Fully Qualified Domain Name (FQDN) structure for a service?
> `<service-name>.<namespace>.svc.cluster.local`.

### Q10. What is the difference between `NodePort` and `LoadBalancer` services?
> `NodePort` exposes a static port on each worker node. `LoadBalancer` provisions an external cloud load balancer (e.g. AWS NLB) with a public IP routing to the cluster.

---

## 11. Final One-Minute Memory Map

```text
               KUBERNETES SERVICE DISCOVERY
                            |
        -----------------------------------------
        |                   |                   |
    ClusterIP            NodePort          LoadBalancer
  (Internal VIP)      (High Host Port)    (Public Cloud LB)
        |                   |                   |
   Internal Only       Host:30000+         Public Internet
        \                   |                  /
         \                  |                 /
          v                 v                v
                 CoreDNS (Name -> VIP)
                            |
                            v
               Endpoints (Live Healthy Pods)
```

Three golden rules to remember:
* `port` = Front Door of Service
* `targetPort` = Port on the Container
* `nodePort` = Port on the Physical Machine
