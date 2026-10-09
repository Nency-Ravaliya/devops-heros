# Docker Networking & Volume Homework Tasks

This document contains step-by-step implementations, commands, outputs, and architectural research for the Docker Networking and Volume assignments.

---

## Task 1: Docker Container Networking (Multi-Network Topology)

### Architecture
```
[ frontend ] (on frontend-net)
     |
[ backend  ] (connected to BOTH frontend-net and backend-db-net)
     |
[ database ] (on backend-db-net)
```
- `frontend` can communicate with `backend`.
- `backend` can communicate with `database`.
- `frontend` CANNOT directly reach `database` (network segregation/security).

---

### Step-by-Step Implementation

#### 1. Create 3 Separate User-Defined Bridge Networks
```bash
docker network create --driver bridge frontend-net
docker network create --driver bridge backend-db-net
docker network create --driver bridge isolated-net
docker network ls
```
*Output:*
```text
NETWORK ID     NAME             DRIVER    SCOPE
5a14c9f13b20   backend-db-net   bridge    local
8f28b49e6c11   frontend-net     bridge    local
0d48a12e87c2   isolated-net     bridge    local
```

#### 2. Launch the 3 Containers
```bash
# Frontend container attached to frontend-net
docker run -d --name frontend --network frontend-net nginx:alpine

# Backend container attached initially to frontend-net
docker run -d --name backend --network frontend-net alpine sleep 3600

# Database container attached to backend-db-net
docker run -d --name database --network backend-db-net -e MYSQL_ROOT_PASSWORD=secret mysql:8.0
```

#### 3. Connect the Backend Container to the Second Network (`backend-db-net`)
```bash
docker network connect backend-db-net backend
```

#### 4. Verify Network Connectivity

**Test A: Frontend to Backend (Expected: Success)**
```bash
docker exec -it frontend ping -c 2 backend
```
*Output:*
```text
PING backend (172.19.0.3): 56 data bytes
64 bytes from 172.19.0.3: seq=0 ttl=64 time=0.088 ms
64 bytes from 172.19.0.3: seq=1 ttl=64 time=0.076 ms
--- backend ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```

**Test B: Backend to Database (Expected: Success)**
```bash
docker exec -it backend ping -c 2 database
```
*Output:*
```text
PING database (172.20.0.2): 56 data bytes
64 bytes from 172.20.0.2: seq=0 ttl=64 time=0.091 ms
64 bytes from 172.20.0.2: seq=1 ttl=64 time=0.082 ms
--- database ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```

**Test C: Frontend to Database (Expected: Fails / Isolated)**
```bash
docker exec -it frontend ping -c 2 -W 2 database
```
*Output:*
```text
ping: bad address 'database'
```
*(Confirms that the database is isolated from the frontend tier via network segmentation).*

---

## Task 2: Host Network (`--net host`)

Using the host network driver removes network isolation between the container and the Docker host. The container does not get its own IP address allocated; instead, it binds directly to the host's interfaces.

### 1. Pull the Apache Image
```bash
docker pull httpd:alpine
```

### 2. Run Apache Container with Host Networking
```bash
docker run -d --name apache-host-net --net host httpd:alpine
```

### 3. Verify Direct Access on Port 80
Since `--net host` is used, no `-p 80:80` port publishing is required. Apache directly binds to host port 80:
```bash
curl -i http://localhost:80
```
*Output:*
```http
HTTP/1.1 200 OK
Date: Sun, 06 Sep 2026 20:34:20 GMT
Server: Apache/2.4.58 (Unix)
Content-Type: text/html

<html><body><h1>It works!</h1></body></html>
```

---

## Task 3: Bind Mount Live Synchronization

A bind mount maps a directory or file on the host filesystem directly into a container directory. Changes made on the host are immediately reflected inside the container without rebuilding the image or restarting the container.

### 1. Create Local Folder and `index.html`
```bash
mkdir -p bind-mount-demo
cat << 'EOF' > bind-mount-demo/index.html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>Bind Mount Demo</title>
</head>
<body>
  <h1>Hello students</h1>
</body>
</html>
EOF
```

### 2. Run Nginx Container with Bind Mount
```bash
docker run -d --name nginx-bind-demo -p 8086:80 \
  -v "$(pwd)/bind-mount-demo:/usr/share/nginx/html:ro" \
  nginx:alpine
```

### 3. Verify Initial Content
```bash
curl -s http://localhost:8086 | grep "Hello"
```
*Output:*
```html
  <h1>Hello students</h1>
```

### 4. Modify `index.html` on the Host Machine
```bash
sed -i 's/Hello students/Hello students - Updated live via bind mount!/g' bind-mount-demo/index.html
```

### 5. Verify Content Updated Immediately (Without Container Restart)
```bash
curl -s http://localhost:8086 | grep "Hello"
```
*Output:*
```html
  <h1>Hello students - Updated live via bind mount!</h1>
```
*(Key takeaway: The container serves the modified host file instantly without any rebuild or restart).*

---

## Task 4: Research - Docker Overlay Network

### 1. What is an Overlay Network?
An **Overlay Network** creates a distributed virtual network spanning across multiple physical Docker hosts (nodes). Containers running on different hosts can communicate seamlessly with each other as if they were residing on the same local Layer 2 broadcast domain.

### 2. Core Use Cases
- **Docker Swarm Clusters**: Allows multi-container services across swarm manager and worker nodes to communicate securely.
- **Kubernetes Pod Networking**: CNI plugins (Flannel, Calico, Cilium) use overlay networks (such as VXLAN) to route traffic between pods scheduled on separate nodes.
- **Microservices Routing**: Enables service discovery and internal load balancing without exposing individual internal microservice ports to public host interfaces.

### 3. How Overlay Networks Work Across Multiple Hosts
```
 +-------------------------+                  +-------------------------+
 |       Host Node 1       |                  |       Host Node 2       |
 |  +-------------------+  |                  |  +-------------------+  |
 |  |    Container A    |  |                  |  |    Container B    |  |
 |  |   (10.0.0.2)      |  |                  |  |   (10.0.0.3)      |  |
 |  +---------+---------+  |                  |  +---------+---------+  |
 |            |            |                  |            |            |
 |      [VXLAN Tunnel]     |                  |      [VXLAN Tunnel]     |
 |            |            |                  |            |            |
 |         (eth0)          |                  |         (eth0)          |
 +------------+------------+                  +------------+------------+
              |                                            |
              +============ Physical Network ==============+
                            (Port 4789 UDP)
```

1. **VXLAN Encapsulation**: Docker uses **VXLAN (Virtual Extensible LAN)** technology. When Container A on Node 1 sends an IP packet to Container B on Node 2, the Docker daemon encapsulates the container Layer 2 frame inside a Layer 4 UDP packet on the host.
2. **Standard Ports Used**:
   - **TCP port 2377**: Cluster management communication.
   - **TCP & UDP port 7946**: Node-to-node gossip network and service discovery (control plane).
   - **UDP port 4789**: VXLAN overlay data traffic (data plane).
3. **Decapsulation**: When the UDP packet arrives at Node 2 via port 4789, Node 2 strips the outer IP/UDP headers and delivers the original packet directly to Container B.
4. **Built-in Encryption (IPsec)**: Docker overlay networks support optional AES encryption (`--opt encrypted`), securing cross-host container traffic automatically.
