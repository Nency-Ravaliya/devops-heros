# Session 8: Docker Container Networking & Storage Volumes

My Laptop stopped working so I needed to use my roomie's laptop.Which is Apple.This repository contains the complete documentation, execution steps, connectivity verification, and proof of learning for **Session 8: Docker Networking & Storage Volumes**.

---

## Architecture & Port Reference

| Component / Task | Image | Network(s) | Port Mapping / Mode | Purpose |
| :--- | :--- | :--- | :--- | :--- |
| **Frontend** | `nginx:alpine` | `frontend-net` | Internal: `80` | Web Presentation Tier |
| **Backend** | `nginx:alpine` | `frontend-net`, `backend-net` | Internal: `80` | Application Tier / Gateway |
| **Database** | `mysql:8.0` | `backend-net` | Internal: `3306` | Data Persistence Tier |
| **Apache Host** | `httpd:alpine` | `host` | Directly on Host Port `80` | Host Network Driver Verification |
| **Nginx Bind Mount** | `nginx:alpine` | Default Bridge | `8085:80` | Live Host-to-Container Storage Sync |

---

## Task 1: Docker Container Networking

### 1. Objective
- Create three distinct Docker bridge networks: `frontend-net`, `backend-net`, and `db-net`.
- Launch three containers: `frontend`, `backend`, and `database` (`mysql:8.0`).
- Connect the `backend` container to both `frontend-net` and `backend-net`.
- Test connectivity to prove **network isolation** and **secure multi-tier routing** (the classic 3-tier architecture).

### 2. Execution Commands
```powershell
# Step 1: Create 3 distinct custom bridge networks
docker network create frontend-net
docker network create backend-net
docker network create db-net

# Step 2: Deploy Frontend on frontend-net
docker run -d --name frontend --network frontend-net nginx:alpine

# Step 3: Deploy Backend on backend-net
docker run -d --name backend --network backend-net nginx:alpine

# Step 4: Attach Backend to frontend-net (dual-homed container)
docker network connect frontend-net backend

# Step 5: Deploy Database on backend-net
docker run -d --name database --network backend-net -e MYSQL_ROOT_PASSWORD=root mysql:8.0
```

### 3. Verification & Connectivity Tests
```powershell
# Test 1: Frontend -> Backend (Both are on frontend-net -> SUCCESS)
docker exec frontend ping -c 2 backend

# Test 2: Frontend -> Database (Frontend is NOT on backend-net -> ISOLATION VERIFIED)
docker exec frontend ping -c 2 -W 2 database

# Test 3: Backend -> Frontend (Both are on frontend-net -> SUCCESS)
docker exec backend ping -c 2 frontend

# Test 4: Backend -> Database (Both are on backend-net -> SUCCESS)
docker exec backend ping -c 2 database
```

### 4. Key Architectural Takeaway
- **Security by Isolation**: The `database` container is completely invisible and unreachable from the `frontend` container (`ping: bad address 'database'`).
- **Intermediary Gateway**: The `backend` container safely bridges the tiers by belonging to both `frontend-net` and `backend-net`.

### 5. Proof of Execution
![Task 1 Networking Proof](<task1_networking_proof.png>)

---

## Task 2: Host Network Driver

### 1. Objective
- Pull the Apache HTTP server (`httpd:alpine`) image from Docker Hub.
- Run an Apache container using Docker's `--network host` mode.
- Access the Apache website directly on port 80 without port forwarding (`-p`).

### 2. Execution Commands
```powershell
# Step 1: Pull official Apache image
docker pull httpd:alpine

# Step 2: Run container directly on the host network stack
docker run -d --name apache-host --network host httpd:alpine

# Step 3: Verify host network mode
docker inspect apache-host --format '{{.HostConfig.NetworkMode}}'
```

### 3. Verification & Output
```powershell
# Direct access to port 80 inside the host network namespace
docker exec apache-host wget -q -O - http://127.0.0.1:80
```
**Output:**
```html
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html>
<head>
<title>It works! Apache httpd</title>
</head>
<body>
<p>It works!</p>
</body>
</html>
```

### 4. Key Concept: Bridge vs. Host Network
- **Bridge Network**: The container gets its own isolated network namespace and private IP behind a virtual bridge (`docker0`). Port publishing (`-p host_port:container_port`) requires NAT / iptables rules.
- **Host Network**: The container bypasses Docker's virtual network stack and binds directly to the host's network interfaces. No NAT overhead exists, yielding maximum network I/O throughput.

### 5. Proof of Execution
![Task 2 Host Network Proof](<task2_host_network_proof.png>)

---

## Task 3: Bind Mounts (Live Synchronization)

### 1. Objective
- Create a local directory `bind-mount-demo` on the host machine.
- Create an initial `index.html` file containing `Hello students`.
- Mount the directory into an Nginx container at `/usr/share/nginx/html`.
- Access `http://localhost:8085` to verify initial content.
- Modify `index.html` on the host machine.
- Verify that the web page updates immediately **without restarting the container**.

### 2. Execution Commands
```powershell
# Step 1: Create local directory and initial HTML file
mkdir bind-mount-demo
Set-Content -Path "bind-mount-demo/index.html" -Value "Hello students"

# Step 2: Run Nginx with Bind Mount
docker run -d --name nginx-bind-demo -p 8085:80 -v "${PWD}/bind-mount-demo:/usr/share/nginx/html:ro" nginx:alpine

# Step 3: Verify initial content
curl.exe http://localhost:8085
# Output: Hello students

# Step 4: Modify index.html on host filesystem
Set-Content -Path "bind-mount-demo/index.html" -Value "Hello students - Updated live via Docker Bind Mount without restart!"

# Step 5: Verify immediate update without restarting container
curl.exe http://localhost:8085
# Output: Hello students - Updated live via Docker Bind Mount without restart!
```

### 3. Proof of Execution

#### Terminal Verification
![Task 3 Terminal Proof](<task3_bind_mount_proof.png>)

#### Browser Verification (Before & After Live Update)
| Initial Access (`Hello students`) | Live Updated Content (No Container Restart) |
| :---: | :---: |
| ![Initial Content](<task3_browser_initial.png>) | ![Updated Content](<task3_browser_updated.png>) |

---

## Task 4: Research & Deep Dive — Docker Overlay Networks

### 1. What is an Overlay Network?
An **overlay network** is a distributed software-defined network (SDN) that spans across multiple physical Docker hosts (nodes). It creates a flat virtual Layer-2 broadcast domain on top of an existing Layer-3 physical network, allowing containers running on completely different hosts to communicate securely and transparently as if they were plugged into the same local network switch.

```
       +-------------------------------------------------------------+
       |                  Virtual Overlay Network                    |
       |                    (Subnet: 10.0.0.0/24)                    |
       +------------------------------+------------------------------+
                                      |
              +-----------------------+-----------------------+
              |                                               |
     +-----------------+                             +-----------------+
     |  Docker Host A  |                             |  Docker Host B  |
     | [Container 1]   |                             | [Container 2]   |
     |  IP: 10.0.0.2   |                             |  IP: 10.0.0.3   |
     +--------+--------+                             +--------+--------+
              |                                               |
              +--------->  VXLAN Encapsulation (UDP 4789) <---+
                                      |
                     [ Physical Underlay Network (L3) ]
```

---

### 2. How Overlay Networks Work Under the Hood

#### A. Data Plane: VXLAN Encapsulation
- Docker uses **VXLAN (Virtual Extensible LAN)**, an IETF standard (RFC 7348).
- When `Container 1` on Host A sends an Ethernet frame to `Container 2` on Host B:
  1. The packet enters the container's virtual ethernet interface (`veth`).
  2. The Linux kernel's VXLAN tunnel endpoint (VTEP) intercepts the Layer-2 frame.
  3. The VTEP wraps the entire inner frame inside a standard **UDP packet** targeting **UDP port 4789** on Host B.
  4. The packet travels over the underlay network (physical LAN or cloud VPC).
  5. The VTEP on Host B decapsulates the UDP packet, extracts the original Layer-2 frame, and delivers it to `Container 2`.

#### B. Control Plane: Gossip Protocol & Distributed Key-Value Store
- In standalone engines with Swarm Mode enabled, the control plane is managed automatically:
  - **TCP/UDP Port 7946**: Used for node discovery and Gossip protocol communication between Swarm nodes.
  - **TCP Port 2377**: Used for cluster management and Raft consensus between manager nodes.
- Each node maintains an in-memory routing table mapping overlay IP addresses to host VTEP endpoints.

#### C. Ingress Routing Mesh & Internal Load Balancing
- Every Docker Swarm cluster creates a default overlay network called `ingress`.
- When a service publishes a port (e.g., `-p 80:80`), Docker listens on that port on **every node in the cluster**.
- When traffic hits any node, Docker's IPVS (IP Virtual Server) routing mesh transparently forwards the request to an active container on whichever node it is running.

---

### 3. Comparison: Docker Network Drivers

| Network Driver | Scope | Multi-Host Support | Performance | Primary Use Case |
| :--- | :--- | :--- | :--- | :--- |
| **Bridge** | Single Host | No | High | Default driver for standalone containers on a single host. |
| **Host** | Single Host | No | Maximum (Near-native) | High-performance services, low-latency telemetry, port-heavy services. |
| **Overlay** | Multi-Host | Yes (Swarm / Kubernetes) | Good (Encapsulation overhead) | Microservices distributed across multiple VMs or physical servers. |
| **Macvlan** | Single/Multi | Yes (L2 physical network) | High | Legacy apps requiring physical routable LAN MAC/IP addresses. |
| **None** | Container | No | N/A | Batch tasks, air-gapped jobs, isolated security workloads. |

---

### 4. Primary Use Cases for Overlay Networks
1. **Multi-Host Microservice Architectures**: Secure communication between decoupled microservices running across multiple cloud instances or on-prem nodes.
2. **Docker Swarm Deployments**: High-availability clustering with automatic service discovery and load balancing via the routing mesh.
3. **End-to-End Traffic Encryption**: Overlay networks support IPSec encryption on the wire with a single flag (`docker network create --opt encrypted -d overlay my-net`), securing inter-container traffic over public or untrusted underlay networks.
4. **Zero-Trust Network Segmentation**: Creating isolated overlay networks for different applications or tenants within the same cluster to prevent lateral movement in case of a breach.

---

## Session 8 Summary & Key Takeaways

1. **Docker Container Networking**: Custom bridge networks provide automatic internal DNS resolution and enforce strong tenant isolation between application tiers.
2. **Host Networking**: Removes the virtual NAT layer for maximum network performance by binding directly to the host's network interfaces.
3. **Storage Volumes & Bind Mounts**: Bind mounts link host filesystem directories directly into containers, enabling real-time file updates and rapid development loops without container rebuilds or restarts.
4. **Overlay Networks**: Enable scalable, secure, multi-host container communication powered by VXLAN encapsulation and Swarm control plane gossip.
