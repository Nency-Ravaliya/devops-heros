# Docker Networking & Volumes Homework

**Name:** Durga Prasad  
**Enrollment Number:** 10012  

---

## Task 1: 3-Tier Container Networking (Custom Bridge Networks)

### Architecture Overview
- **`net-frontend`**: Network for frontend web server.
- **`net-db`**: Isolated database network.
- **`backend-container`**: Dual-homed container connected to both `net-frontend` and `net-db`.

### Execution Commands
```bash
docker network create net-frontend
docker network create net-db

docker run -d --name db-container --network net-db -e MYSQL_ROOT_PASSWORD=secret mysql:8.0
docker run -d --name frontend-container --network net-frontend nginx:alpine
docker run -d --name backend-container --network net-frontend nginx:alpine
docker network connect net-db backend-container
```

### Verification & Network Isolation Test
1. **Backend -> DB Connectivity Test (Passed)**:
   ```bash
   docker exec backend-container ping -c 2 db-container
   ```
   *Output:*
   ```text
   PING db-container (172.23.0.2): 56 data bytes
   64 bytes from 172.23.0.2: seq=0 ttl=64 time=0.067 ms
   64 bytes from 172.23.0.2: seq=1 ttl=64 time=0.052 ms
   --- db-container ping statistics ---
   2 packets transmitted, 2 packets received, 0% packet loss
   ```

2. **Frontend -> DB Isolation Test (Successfully Isolated)**:
   ```bash
   docker exec frontend-container ping -c 2 db-container
   ```
   *Output:*
   ```text
   ping: bad address 'db-container'
   ```

---

## Task 2: Host Network Mode

In Host Networking mode (`--network host`), the container shares the host system's IP address and network stack directly without port mapping overhead.

### Execution & Verification
```bash
docker run -d --name apache-host-app --network host httpd:2.4-alpine
curl http://127.0.0.1
```
*Output:*
```html
<html><body><h1>It works!</h1></body></html>
```

---

## Task 3: Bind Mount Live Reload

Bind mounts link a local host directory directly to a container path, enabling real-time content updates without rebuilding or restarting containers.

### Execution & Live Update Test
```bash
# 1. Create local file with initial content
mkdir -p live-mount
echo "<h1>Hello students</h1>" > live-mount/index.html

# 2. Run container with bind mount
docker run -d --name live-reload-app -v $(pwd)/live-mount:/usr/share/nginx/html -p 8087:80 nginx:alpine

# 3. Verify initial response
curl http://127.0.0.1:8087
# Output: <h1>Hello Students</h1>

# 4. Modify host file dynamically
echo "<h1>Hello students - Updated Live!</h1>" > live-mount/index.html

# 5. Verify live update without restarting container
curl http://127.0.0.1:8087
# Output: <h1>Hello students - Updated Live!</h1>
```

---

## Task 4: Docker Overlay Network Research

### What is an Overlay Network?
An **Overlay Network** is a distributed network driver in Docker that enables communication between containers running across **multiple physical or virtual Docker hosts** (nodes in a Docker Swarm cluster).

### Key Features & Architecture
1. **Multi-Host Communication**: Allows containers on Host A to talk seamlessly to containers on Host B using internal container IP addresses.
2. **VXLAN Encapsulation**: Uses Virtual Extensible LAN (VXLAN) encapsulation (UDP port 4789) to route container traffic over host network infrastructure securely.
3. **Built-in Encryption**: Supports IPsec encryption out of the box for secure cross-host container data transfer.
4. **Service Discovery & Load Balancing**: Integrated with Docker Swarm DNS for automatic service discovery and ingress routing.
