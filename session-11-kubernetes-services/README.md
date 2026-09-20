# Session 11: Kubernetes Networking & Services

**Name:** Durga Prasad  
**Enrollment Number:** 10012

---

## Task 1: Kubernetes Port Architecture & Clarification Drill

Demystify the 4 Kubernetes ports and how a packet travels from browser to container.

**Commands:**
```bash
kubectl explain pod.spec.containers.ports.containerPort
kubectl explain service.spec.ports
```

**Port Flow Architecture:**
```
Client Browser ──► [nodePort: 30080] (Host IP, any node)
                        │
                        ▼
                   [port: 8080] (Service Virtual IP / ClusterIP)
                        │
                        ▼
                   [targetPort: 80] (Pod Network)
                        │
                        ▼
                   [containerPort: 80] (Container process / Nginx)
```

| Port | Defined In | Scope | Purpose |
|---|---|---|---|
| `containerPort` | PodSpec | Container | Port app listens on (informational — does NOT open a firewall rule) |
| `targetPort` | ServiceSpec | Pod network | Port on the pod the Service routes traffic TO |
| `port` | ServiceSpec | ClusterIP (internal) | Port exposed by the Service internally within the cluster |
| `nodePort` | ServiceSpec | Every Node's external IP | Static high port (30000–32767) for external access |

**Screenshot:** `![Port Architecture](./screenshots/01-port-architecture.png)`

---

## Task 2: Type 1 — ClusterIP Service (Default Internal Networking)

Deploy a 3-replica backend and expose it internally via ClusterIP. Only reachable inside the cluster.

**Directory:** `01-clusterip/`

**Commands:**
```bash
kubectl apply -f 01-clusterip/app-deployment.yaml
kubectl apply -f 01-clusterip/service.yaml
kubectl get pods -l app=web-clusterip -o wide
kubectl get svc web-service-clusterip
kubectl get endpoints web-service-clusterip
kubectl apply -f 01-clusterip/client-pod.yaml
kubectl wait --for=condition=ready pod/curl-client --timeout=60s
kubectl exec -it curl-client -- curl -s http://web-service-clusterip:8080 | grep -i "<title>"
kubectl exec -it curl-client -- curl -s http://web-service-clusterip.default.svc.cluster.local:8080 | grep -i "<title>"
```

**Output:**
```
NAME                                 READY   STATUS    IP            NODE
web-app-clusterip-66865d4855-gxvv9   1/1     Running   10.244.0.13   minikube
web-app-clusterip-66865d4855-r5msq   1/1     Running   10.244.0.14   minikube
web-app-clusterip-66865d4855-zfx8q   1/1     Running   10.244.0.12   minikube

NAME                   TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)    AGE
web-service-clusterip  ClusterIP   10.99.80.229   <none>        8080/TCP   55s

NAME                   ENDPOINTS
web-service-clusterip  10.244.0.12:80,10.244.0.13:80,10.244.0.14:80

# Internal curl (via short name):
<title>Welcome to nginx!</title>

# Internal curl (via FQDN):
<title>Welcome to nginx!</title>
```

**Screenshots:**  
`![ClusterIP Service and Endpoints](./screenshots/02-1-clusterip-svc-endpoints.png)`  
`![ClusterIP Curl Test](./screenshots/02-2-clusterip-curl.png)`

---

## Task 3: Type 2 — NodePort Service (Host-Level External Ingress)

Expose a web app externally via a static port on every cluster node.

**Directory:** `02-nodeport/`

**Commands:**
```bash
kubectl apply -f 02-nodeport/app-deployment.yaml
kubectl apply -f 02-nodeport/service.yaml
kubectl get svc web-service-nodeport
MINIKUBE_IP=$(minikube ip)
curl -I http://${MINIKUBE_IP}:30080
minikube service web-service-nodeport --url
```

**Output:**
```
NAME                  TYPE       CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
web-service-nodeport  NodePort   10.101.108.100  <none>        80:30080/TCP   17s

HTTP/1.1 200 OK
Server: nginx/1.25.3
Content-Type: text/html

http://127.0.0.1:60012  ← minikube service tunnel URL
```

**Screenshots:**  
`![NodePort Service](./screenshots/03-1-nodeport-svc.png)`  
`![NodePort Curl 200 OK](./screenshots/03-2-nodeport-curl.png)`

---

## Task 4: Type 3 — LoadBalancer Service (Cloud-Native Ingress Simulation)

Simulate cloud provider IP allocation using `minikube tunnel`.

**Directory:** `03-loadbalancer/`

**Commands:**
```bash
kubectl apply -f 03-loadbalancer/app-deployment.yaml
kubectl apply -f 03-loadbalancer/service.yaml
kubectl get svc web-service-loadbalancer   # shows <pending>
# In separate terminal:
minikube tunnel
# Back in main terminal:
kubectl get svc web-service-loadbalancer   # shows EXTERNAL-IP
EXTERNAL_IP=$(kubectl get svc web-service-loadbalancer -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
curl -s http://${EXTERNAL_IP}:80 | grep -i "<title>"
```

**Output:**
```
# Before tunnel:
NAME                     TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)        AGE
web-service-loadbalancer LoadBalancer   10.96.207.28   <pending>     80:31362/TCP   17s

# After minikube tunnel:
NAME                     TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)      AGE
web-service-loadbalancer LoadBalancer   10.96.207.28   127.0.0.1    80:31362/TCP  2m

<title>Welcome to nginx!</title>
```

**Screenshots:**  
`![LoadBalancer Pending then Assigned](./screenshots/04-1-loadbalancer-pending.png)`  
`![LoadBalancer Browser](./screenshots/04-2-loadbalancer-browser.png)`

---

## Task 5: Type 4 — ExternalName Service (CoreDNS CNAME Alias Redirection)

Create a Service that acts as an internal DNS alias pointing to an external domain — no selectors, no endpoints.

**Directory:** `04-externalname/`

**Commands:**
```bash
kubectl apply -f 04-externalname/service.yaml
kubectl apply -f 04-externalname/client-pod.yaml
kubectl wait --for=condition=ready pod/dns-test-client --timeout=60s
kubectl get svc external-database-service
kubectl exec -it dns-test-client -- nslookup external-database-service
```

**Output:**
```
NAME                       TYPE           CLUSTER-IP   EXTERNAL-IP        PORT(S)   AGE
external-database-service  ExternalName   <none>       nencyravaliya.me   <none>    17s

# nslookup output:
Server:    10.96.0.10
Address 1: 10.96.0.10 kube-dns.kube-system.svc.cluster.local

Name:      external-database-service
Address 1: <resolved IP of nencyravaliya.me>
canonical name = nencyravaliya.me   ← CNAME returned by CoreDNS
```

**Screenshots:**  
`![ExternalName Service](./screenshots/05-1-externalname-svc.png)`  
`![ExternalName nslookup CNAME](./screenshots/05-2-externalname-nslookup.png)`

---

## Task 6: Type 5 — Headless Service (`clusterIP: None` & Stateful Workloads)

Deploy a headless service paired with a StatefulSet. CoreDNS returns individual Pod IPs instead of a VIP.

**Directory:** `05-headless/`

**Commands:**
```bash
kubectl apply -f 05-headless/service.yaml
kubectl apply -f 05-headless/app-statefulset.yaml
kubectl apply -f 05-headless/client-pod.yaml
kubectl rollout status statefulset/web-stateful --timeout=120s
kubectl get svc web-service-headless
kubectl exec -it headless-dns-client -- nslookup web-service-headless
kubectl exec -it headless-dns-client -- nslookup web-stateful-0.web-service-headless.default.svc.cluster.local
kubectl exec -it headless-dns-client -- curl -s http://web-stateful-0.web-service-headless:80 | grep -i "<title>"
```

**Output:**
```
NAME                 TYPE        CLUSTER-IP   EXTERNAL-IP   PORT(S)   AGE
web-service-headless ClusterIP   None         <none>        80/TCP    1m

# nslookup returns ALL individual pod IPs:
Server:    10.96.0.10
Name:      web-service-headless
Address 1: 10.244.0.22 web-stateful-0.web-service-headless.default.svc.cluster.local
Address 2: 10.244.0.23 web-stateful-1.web-service-headless.default.svc.cluster.local
Address 3: 10.244.0.24 web-stateful-2.web-service-headless.default.svc.cluster.local

<title>Welcome to nginx!</title>  ← Direct pod FQDN curl succeeds
```

**Screenshots:**  
`![Headless Service 3 A Records](./screenshots/06-1-headless-nslookup.png)`  
`![Headless Pod FQDN Curl](./screenshots/06-2-headless-curl.png)`

---

## Task 7: Services Without Selectors (Manual Endpoints Mapping)

Create a Service without a label selector and manually bind it to an external IP.

**Commands:**
```bash
# Create Service without selector
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: external-legacy-db
spec:
  ports:
    - protocol: TCP
      port: 3306
      targetPort: 3306
EOF

kubectl get endpoints external-legacy-db  # Shows <none>

# Manually create Endpoints object
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Endpoints
metadata:
  name: external-legacy-db
subsets:
  - addresses:
      - ip: 192.168.1.150
    ports:
      - port: 3306
EOF

kubectl get endpoints external-legacy-db  # Now shows IP
```

**Output:**
```
# Before:
NAME                 ENDPOINTS   AGE
external-legacy-db   <none>      10s

# After:
NAME                 ENDPOINTS            AGE
external-legacy-db   192.168.1.150:3306   20s
```

**Screenshots:**  
`![Empty Endpoints](./screenshots/07-1-empty-endpoints.png)`  
`![Manual Endpoints Bound](./screenshots/07-2-manual-endpoints.png)`

---

## Task 8: FQDN & CoreDNS Deep Dive Architecture Analysis

Investigate DNS configuration inside pods and the impact of `ndots:5`.

**Commands:**
```bash
kubectl get pods -n kube-system -l k8s-app=kube-dns -o wide
kubectl exec -it curl-client -- cat /etc/resolv.conf
kubectl exec -it curl-client -- nslookup web-service-clusterip
kubectl exec -it curl-client -- nslookup api.github.com
```

**Output:**
```
# CoreDNS pods:
NAME                       READY   STATUS    NODE
coredns-7db6d8ff4d-abc12   1/1     Running   minikube

# /etc/resolv.conf inside pod:
nameserver 10.96.0.10
search default.svc.cluster.local svc.cluster.local cluster.local
options ndots:5

# nslookup short name auto-expands:
Name: web-service-clusterip.default.svc.cluster.local
Address: 10.99.80.229
```

**FQDN Structure:**
```
<service-name>.<namespace>.svc.cluster.local
     web-service-clusterip.default.svc.cluster.local
```

**`ndots:5` Latency Implication:**  
For any query with fewer than 5 dots (like `api.stripe.com` = 2 dots), CoreDNS first appends all search suffixes before trying the external domain. This causes **5 extra DNS queries** before reaching the internet. Fix: use trailing dot (`api.stripe.com.`) or set `ndots:1` in dnsConfig.

**Screenshots:**  
`![resolv.conf](./screenshots/08-1-resolv-conf.png)`  
`![DNS FQDN Resolution](./screenshots/08-2-dns-fqdn.png)`

---

## Task 9: Pod Identity & Lifecycle Invariance — Deployment vs. StatefulSet

Prove that Deployments spawn new random identities while StatefulSets recreate identical ordinal pods.

**Commands:**
```bash
kubectl apply -f 01-clusterip/app-deployment.yaml
kubectl apply -f 05-headless/service.yaml
kubectl apply -f 05-headless/app-statefulset.yaml
kubectl get pods -l app=web-clusterip
kubectl get pods -l app=web-headless

# Delete Deployment pod
DEPLOY_POD=$(kubectl get pods -l app=web-clusterip -o jsonpath='{.items[0].metadata.name}')
echo "Deleting Stateless Deployment Pod: ${DEPLOY_POD}"
kubectl delete pod "${DEPLOY_POD}"
kubectl get pods -l app=web-clusterip   # New random hash

# Delete StatefulSet pod
kubectl delete pod web-stateful-0
kubectl get pods -l app=web-headless    # web-stateful-0 recreated identically
```

**Expected Behavior:**
```
# Stateless Deployment (before):  web-app-clusterip-66865d4855-gxvv9
# Stateless Deployment (after):   web-app-clusterip-66865d4855-NEW12  ← NEW random hash

# Stateful StatefulSet (before):  web-stateful-0
# Stateful StatefulSet (after):   web-stateful-0  ← SAME ordinal identity
```

**Screenshots:**  
`![Initial Pod Names](./screenshots/09-1-pod-names-before.png)`  
`![After Deletion New Identities](./screenshots/09-2-pod-names-after.png)`

---

## Task 10: Master Architectural Matrix — Deployment vs. StatefulSet vs. DaemonSet

| Architectural Metric | Deployment | StatefulSet | DaemonSet |
|---|---|---|---|
| **Primary Workload Type** | Stateless microservices, Web APIs | Clustered databases, Distributed queues | Node-level infrastructure agents |
| **Pod Naming Scheme** | Random hash (`<deploy>-<rs-hash>-<random>`) | Deterministic ordinal (`<name>-0, 1, 2`) | Node-bound hash |
| **Pod Identity Persistence** | Ephemeral (new identity on death) | Invariant (same identity, hostname, IP) | Bound to individual worker node |
| **Startup / Shutdown Order** | Parallel, non-ordered | Strictly sequential (`0→1→2`, reversed on termination) | Parallel across all eligible nodes |
| **Storage Mechanism** | Shared volume or ephemeral `emptyDir` | Dedicated PV per ordinal via `volumeClaimTemplates` | `HostPath` mounts or node-local storage |
| **Associated Service Type** | `ClusterIP` / `NodePort` / `LoadBalancer` | **Headless Service** (`clusterIP: None`) mandatory | None or local `ClusterIP` |
| **Scaling Behavior** | Arbitrary scale across healthy nodes | Ordinal scale (adds/removes at tail) | Auto-scales when nodes join/leave cluster |
| **Production Examples** | Nginx, Flask API, Go services, Node.js | Kafka, MongoDB, Cassandra, PostgreSQL | Fluentd, Prometheus Node Exporter, Cilium, Falco |

**Screenshot:** `![Architectural Matrix](./screenshots/10-1-architectural-matrix.png)`

---

## Task 11: Production Cost Optimization & Service Selection Decision Tree

### Cloud Cost Anti-Pattern vs. Best Practice

```
ANTI-PATTERN ($25/mo per LoadBalancer service):
Microservice A ──► AWS NLB 1 ($25/mo) ──► ClusterIP A
Microservice B ──► AWS NLB 2 ($25/mo) ──► ClusterIP B
Microservice C ──► AWS NLB 3 ($25/mo) ──► ClusterIP C
Total for 50 services = $1,250 / month

BEST PRACTICE (1 unified entry point):
Public Internet ──► 1 Unified AWS Load Balancer ($25/mo)
                              │
                              ▼
                   [ NGINX Ingress Controller ]
                   (Layer 7 Host & Path Routing)
                      │           │           │
                      ▼           ▼           ▼
                 ClusterIP A ClusterIP B ClusterIP C
Total for 50 services = $25 / month  (Savings: $1,225/mo)
```

### Service Selection Decision Tree

```
Need to expose outside cluster?
│
├── NO ──► Need direct pod-to-pod DNS (Kafka/DB)?
│           ├── YES ──► HEADLESS SERVICE (clusterIP: None)
│           └── NO  ──► CLUSTERIP (default)
│
└── YES ──► Connecting to external 3rd-party domain?
             ├── YES ──► EXTERNALNAME
             └── NO  ──► Public Cloud (AWS/GCP/Azure)?
                          ├── YES (HTTP/HTTPS) ──► 1 INGRESS via LOADBALANCER
                          │                        apps as internal CLUSTERIP
                          ├── YES (TCP/UDP)    ──► LOADBALANCER directly
                          └── NO (On-Prem/Dev) ──► NODEPORT
```

**Screenshot:** `![Service Decision Tree](./screenshots/11-1-service-decision-tree.png)`

---

## Task 12: Minikube Docker-Driver Port Binding & Tunnel Gotcha Analysis

### Root Cause: Why `<Node-IP>:<NodePort>` Fails on Docker Driver

When Minikube uses the Docker driver (`--driver=docker`), it runs inside an **isolated Docker container**. The node IP (`192.168.49.2`) belongs to an internal Docker bridge network that the host OS cannot directly route to without a proxy.

**Commands:**
```bash
kubectl get svc web-service-nodeport

# Attempt direct curl — demonstrates failure on Docker driver:
NODE_IP=$(minikube ip)
echo "Testing direct connection to ${NODE_IP}:30080..."
curl --connect-timeout 2 -s http://${NODE_IP}:30080 || echo "Connection Failed as expected!"

# WORKAROUND 1: Dynamic local proxy
minikube service web-service-nodeport --url
# Returns: http://127.0.0.1:60012 → curl this URL

# WORKAROUND 2: Continuous L3 routing tunnel
minikube tunnel
curl -I http://localhost:30080
```

**Output:**
```
NAME                  TYPE       CLUSTER-IP      PORT(S)
web-service-nodeport  NodePort   10.101.108.100  80:30080/TCP

Testing direct connection to 192.168.49.2:30080...
Connection Failed as expected!

http://127.0.0.1:60012    ← minikube service tunnel
HTTP/1.1 200 OK           ← tunnel works!
```

**Screenshots:**  
`![Direct Connection Failure](./screenshots/12-1-direct-connection-fail.png)`  
`![Minikube Service URL 200 OK](./screenshots/12-2-minikube-service-url.png)`
