# Docker Networking & Volume Homework Tasks

This document contains full walkthroughs, command logs, and research for Docker Container Networking, Host Network, Bind Mounts, and Overlay Networks.

---

## Task 1: Docker Container Networking

### Objective
Create 3 containers (`Frontend`, `Backend`, `Database`), configure 3 separate Docker networks (`frontend-net`, `backend-net`, `db-net`), attach `Backend` to 2 networks, and test cross-container isolation and connectivity.

### Step 1: Create 3 Docker Networks
```bash
docker network create frontend-net
docker network create backend-net
docker network create db-net
```

### Step 2: Create Containers on Networks
```bash
# 1. Create Frontend container on frontend-net
docker run -d --name frontend-app --network frontend-net nginx:alpine

# 2. Create Backend container on backend-net
docker run -d --name backend-app --network backend-net alpine sleep 3600

# 3. Create Database container on db-net
docker run -d --name db-app --network db-net -e MYSQL_ROOT_PASSWORD=secret mysql:8.0
```

### Step 3: Connect Backend Container to `frontend-net` Network
```bash
docker network connect frontend-net backend-app
```
*(Now `backend-app` is connected to both `backend-net` and `frontend-net`)*

### Step 4: Verify Container Connectivity
```bash
# Test 1: Ping Frontend from Backend (SUCCESS expected - same network: frontend-net)
docker exec -it backend-app ping -c 2 frontend-app
```
*Output:*
```text
PING frontend-app (172.18.0.2): 56 data bytes
64 bytes from 172.18.0.2: seq=0 ttl=64 time=0.082 ms
64 bytes from 172.18.0.2: seq=1 ttl=64 time=0.091 ms
--- frontend-app ping statistics ---
2 packets transmitted, 2 packets received, 0% packet loss
```

```bash
# Test 2: Ping Database from Frontend (FAILURE expected - isolated networks)
docker exec -it frontend-app ping -c 2 db-app
```
*Output:*
```text
ping: bad address 'db-app'
```
*(Explanation: `frontend-app` is on `frontend-net` and `db-app` is on `db-net`. Docker embedded DNS cannot resolve `db-app` across disconnected networks, enforcing security network isolation.)*

---

## Task 2: Host Network Mode (`--net=host`)

### Objective
Run an Apache2 container using host network driver where container shares the host's networking namespace directly.

### Step 1: Pull and Run Apache Container on Host Network
```bash
docker pull httpd:2.4-alpine
docker run -d --name apache-host-app --net=host httpd:2.4-alpine
```

### Step 2: Access Apache Directly on Host Port 80
```bash
curl http://localhost:80
```
*Output:*
```html
<html><body><h1>It works!</h1></body></html>
```
*(Explanation: When using `--net=host`, port mapping like `-p 80:80` is not needed because the container binds directly to host port 80).*

---

## Task 3: Bind Mount Demonstration

### Objective
Mount a local directory containing `index.html` with `"Hello students"` into an Nginx container, edit the file on the host machine, and verify live changes without restarting the container.

### Step 1: Create Local Folder & File
```bash
mkdir -p bind_mount_demo
echo "<h1>Hello students</h1>" > bind_mount_demo/index.html
```

### Step 2: Bind Mount Folder to Nginx Container
```bash
docker run -d \
  --name nginx-bind-demo \
  -v $(pwd)/bind_mount_demo:/usr/share/nginx/html:ro \
  -p 8085:80 \
  nginx:alpine
```

### Step 3: Verify Initial Content
```bash
curl http://localhost:8085
```
*Output:*
```html
<h1>Hello students</h1>
```

### Step 4: Modify `index.html` on Local Host Machine
```bash
echo "<h1>Hello students - UPDATED LIVE WITHOUT RESTART!</h1>" > bind_mount_demo/index.html
```

### Step 5: Verify Changes Reflected Instantly
```bash
curl http://localhost:8085
```
*Output:*
```html
<h1>Hello students - UPDATED LIVE WITHOUT RESTART!</h1>
```
*(Observation: Changes made to the host file system were immediately visible in the container response without running `docker restart`).*

---

## Task 4: Docker Overlay Network Research Report

### 1. What is a Docker Overlay Network?
A Docker **Overlay Network** creates a distributed network across multiple physical or virtual Docker host daemon nodes. It enables containers running on different hosts to communicate with each other securely at Layer 2 without relying on host-specific routing configurations.

---

### 2. Primary Use Cases
- **Multi-Host Container Communication:** Connecting containers deployed across a cluster of servers (e.g. AWS EC2 instances, bare-metal servers).
- **Docker Swarm & Kubernetes Service Mesh:** Providing overlay IP addresses and routing for microservices deployed across worker nodes.
- **Secure Cross-Cloud Communication:** Encrypting container-to-container traffic automatically across public networks using IPsec tunnels.

---

### 3. How Overlay Networks Work Behind the Scenes
1. **VXLAN Encapsulation:** Overlay networks wrap standard Layer 2 Ethernet frames inside Layer 4 UDP datagrams (typically UDP port 4789).
2. **Control Plane (Gossip Protocol):** Docker Swarm manager nodes use gossip protocol to maintain state and propagate container IP addresses, MAC mapping, and endpoint routes to all node daemons.
3. **Data Plane:** When `containerA` on `Host1` sends a packet to `containerB` on `Host2`, the host kernel encapsulates the frame into a VXLAN packet and routes it over the underlying physical network directly to `Host2`, where it is decapsulated and delivered to `containerB`.

---

### 4. Commands to Create an Overlay Network
```bash
# Initialize Docker Swarm Mode (Required for Overlay driver)
docker swarm init

# Create an Overlay Network
docker network create -d overlay --attachable my-overlay-net
```
