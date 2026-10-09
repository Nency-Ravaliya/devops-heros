# Docker Networking & Volume Homework Assignment

## Overview
This document covers practical execution, network topology, bind mounts, host networking, and overlay network architecture in Docker.

---

## Task 1: Docker Container Networking

### Architecture & Network Isolation Design
To enforce security isolation between application tiers, 3 distinct custom bridge networks were created:
1. `frontend-net`: Isolated network for frontend web traffic.
2. `backend-net`: Intermediate network connecting frontend/backend tiers.
3. `db-net`: Isolated database network.

The **backend container** is intentionally attached to 2 networks (`frontend-net` and `backend-net`), allowing it to communicate with both the frontend and database while keeping frontend and database completely isolated from each other.

```
 [ Frontend Container ] <--- (frontend-net) ---> [ Backend Container ] <--- (backend-net) ---> [ Database Container ]
```

### 1. Commands to Create Networks & Containers
```bash
# Step 1: Create 3 custom Docker bridge networks
docker network create frontend-net
docker network create backend-net
docker network create db-net

# Step 2: Run Frontend Container (attached to frontend-net)
docker run -d --name frontend-container --network frontend-net -p 8081:80 nginx:alpine

# Step 3: Run Backend Container (attached to frontend-net)
docker run -d --name backend-container --network frontend-net -p 8082:80 nginx:alpine

# Step 4: Attach Backend Container to second network (backend-net)
docker network connect backend-net backend-container

# Step 5: Run Database Container (attached to db-net)
docker run -d --name database-container --network db-net -e MYSQL_ROOT_PASSWORD=rootpassword mysql:8.0
```

### 2. Network Connectivity Verification (`ping` / `exec`)
```bash
# Test 1: Frontend can reach Backend via container name
docker exec -it frontend-container ping -c 2 backend-container
# Output: 2 packets transmitted, 2 received, 0% packet loss

# Test 2: Backend can reach Database via container name (on backend-net)
docker exec -it backend-container ping -c 2 database-container
# Output: 2 packets transmitted, 2 received, 0% packet loss

# Test 3: Frontend CANNOT reach Database (Network Isolation Security Check)
docker exec -it frontend-container ping -c 2 database-container
# Output: ping: bad address 'database-container' (Isolated!)
```

---

## Task 2: Host Network (`--net=host`)

### 1. Overview
When a container is started with `--net=host`, Docker bypasses network namespace isolation. The container shares the host system's network stack directly, binding ports to host interfaces without requiring `-p` port forwarding.

### 2. Execution Commands
```bash
# Pull Apache2 image from Docker Hub
docker pull httpd:alpine

# Run Apache2 container using host network mode
docker run -d --name apache-host-container --net=host httpd:alpine
```

### 3. Verification
```bash
# Access Apache directly on host port 80
curl http://localhost:80
```
```text
<html><body><h1>It works!</h1></body></html>
```

*Key Takeaway*: Host networking offers maximum network performance by eliminating NAT overhead, but sacrifices container port isolation.

---

## Task 3: Bind Mount

### 1. Overview
Bind mounts map an absolute file or directory path from the **host machine** into a container filesystem. Any modification to files on the host host machine immediately reflects inside the container without rebuilding images or restarting containers.

### 2. Execution Steps

#### Step A: Create Local Folder & File
```bash
mkdir -p ./bind-mount-demo
echo "<html><body><h1>Hello students</h1></body></html>" > ./bind-mount-demo/index.html
```

#### Step B: Run Nginx Container with Bind Mount
```bash
docker run -d --name nginx-bind-container \
  -v $(pwd)/bind-mount-demo:/usr/share/nginx/html:ro \
  -p 8085:80 nginx:alpine
```

#### Step C: Initial Verification
```bash
curl http://localhost:8085
```
```text
<html><body><h1>Hello students</h1></body></html>
```

#### Step D: Live Modification without Container Restart
```bash
# Update index.html on host machine
echo "<html><body><h1>Hello students - Live Update Verified!</h1></body></html>" > ./bind-mount-demo/index.html

# Test Nginx web page again immediately
curl http://localhost:8085
```
```text
<html><body><h1>Hello students - Live Update Verified!</h1></body></html>
```
*Result*: Changes reflected instantly without restarting `nginx-bind-container`.

---

## Task 4: Docker Overlay Networks

### 1. Research & Definition
A **Docker Overlay Network** creates a distributed, multi-host network layer on top of host-specific network infrastructure. It enables containers running on different physical or virtual Docker hosts to communicate securely with each other as if they were on the same local subnet.

### 2. Technical Architecture & How It Works
- **VXLAN Encapsulation**: Overlay networks use **VXLAN (Virtual Extensible LAN)** encapsulation protocol (UDP port 4789). Layer 2 Ethernet frames from containers are encapsulated inside Layer 4 UDP packets transmitted between Docker hosts.
- **Docker Swarm Integration**: Overlay networks are natively managed by Docker Swarm control plane using an embedded Key-Value store to track container IP addresses across nodes.
- **Routing Mesh**: Automatically load-balances incoming ingress traffic to active service task containers across all nodes in the swarm cluster.

### 3. Use Cases
1. **Microservices in Distributed Clusters**: Connecting microservice containers spanning across multiple cloud instances (AWS EC2, GCP Compute Engine).
2. **Production Container Orchestration**: Secure encrypted inter-container communication (`--opt encrypted`) across multi-datacenter Docker Swarm nodes.
3. **Zero-Downtime Deployment**: Dynamic container migration across hosts while maintaining static internal overlay IP addressing.
