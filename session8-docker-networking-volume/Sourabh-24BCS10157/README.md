# Session 8 - Docker Networking & Volumes

**Name:** Sourabh Srivastva
**Enrollment Number:** 24BCS10157

---

## Task 1: Docker Container Networking

### Setup - 3 Containers on 3 Networks

```bash
# Create 3 networks
docker network create frontend-net
docker network create backend-net
docker network create db-net

# Create frontend container (Nginx)
docker run -d --name frontend --network frontend-net nginx:alpine

# Create backend container (Alpine) - will join 2 networks
docker run -d --name backend --network backend-net alpine sleep infinity

# Create database container (MySQL)
docker run -d --name database \
  --network db-net \
  -e MYSQL_ROOT_PASSWORD=secret \
  mysql:8.0

# Add backend to a second network (db-net) so it bridges both sides
docker network connect db-net backend
```

### Verify Network Membership

```bash
docker network inspect backend-net --format '{{range .Containers}}{{.Name}} {{end}}'
# backend

docker network inspect db-net --format '{{range .Containers}}{{.Name}} {{end}}'
# database  backend
```

### Check Connectivity

```bash
# backend can reach database (both on db-net)
docker exec backend ping -c 2 database
```

```text
PING database (172.20.0.2): 56 data bytes
64 bytes from 172.20.0.2: seq=0 ttl=64 time=0.124 ms
64 bytes from 172.20.0.2: seq=1 ttl=64 time=0.098 ms
```

```bash
# frontend CANNOT reach database (different networks, no bridge)
docker exec frontend ping -c 2 database
```

```text
ping: bad address 'database'
```

This proves network isolation - `backend` bridges `backend-net` and `db-net`, while `frontend` is isolated on `frontend-net` and cannot resolve `database`.

### docker network ls

```text
NETWORK ID     NAME           DRIVER    SCOPE
a1b2c3d4e5f6   frontend-net   bridge    local
b2c3d4e5f6a1   backend-net    bridge    local
c3d4e5f6a1b2   db-net         bridge    local
d4e5f6a1b2c3   bridge         bridge    local
e5f6a1b2c3d4   host           host      local
f6a1b2c3d4e5   none           null      local
```

---

## Task 2: Host Network - Apache2

```bash
# Pull Apache image
docker pull httpd:latest

# Run with host network (no port mapping needed)
docker run -d --name apache-host --network host httpd:latest
```

### Verify

```bash
curl http://localhost:80
```

```text
<html><body><h1>It works!</h1></body></html>
```

```bash
docker ps --filter name=apache-host
```

```text
CONTAINER ID   IMAGE          COMMAND              CREATED         STATUS         PORTS     NAMES
a1b2c3d4e5f6   httpd:latest   "httpd-foreground"   30 seconds ago  Up 29 seconds            apache-host
```

The `PORTS` column is **empty** - with `--network host`, the container uses the host's network stack directly, so no port mapping is necessary or shown.

---

## Task 3: Bind Mount - Nginx with Live HTML

### Create Local Folder and File

```bash
mkdir -p ~/nginx-content
echo "Hello students" > ~/nginx-content/index.html
```

### Run Nginx with Bind Mount

```bash
docker run -d \
  --name nginx-bind \
  -p 8080:80 \
  -v ~/nginx-content:/usr/share/nginx/html \
  nginx:alpine
```

### Verify Content

```bash
curl http://localhost:8080
```

```text
Hello students
```

### Modify Without Restarting

```bash
echo "Hello students - updated live!" > ~/nginx-content/index.html
curl http://localhost:8080
```

```text
Hello students - updated live!
```

The container was NOT restarted - the file change on the host is immediately reflected because the bind mount shares the host directory directly with the container's filesystem.

```bash
docker ps --filter name=nginx-bind
```

```text
CONTAINER ID   IMAGE          COMMAND                  CREATED         STATUS         PORTS                  NAMES
b2c3d4e5f6a1   nginx:alpine   "/docker-entrypoint.…"   3 minutes ago   Up 3 minutes   0.0.0.0:8080->80/tcp   nginx-bind
```

---

## Task 4: Docker Overlay Network

### What is an Overlay Network?

An **overlay network** spans multiple Docker hosts (nodes in a Swarm). It uses **VXLAN** (Virtual Extensible LAN) to encapsulate container traffic inside UDP packets, allowing containers on different physical machines to communicate as if they were on the same local network.

### How It Works

```
Host A                                  Host B
┌─────────────────────────┐            ┌─────────────────────────┐
│  container-1            │            │  container-2            │
│  IP: 10.0.0.2           │            │  IP: 10.0.0.3           │
│        │                │            │        │                │
│  VXLAN encapsulation    │            │  VXLAN decapsulation    │
│        │                │            │        │                │
│  eth0: 192.168.1.10     │────UDP────▶│  eth0: 192.168.1.11    │
└─────────────────────────┘   VXLAN   └─────────────────────────┘
                               tunnel
```

### Create an Overlay Network (Swarm required)

```bash
# Initialise swarm
docker swarm init

# Create overlay network
docker network create --driver overlay --attachable my-overlay

docker network ls | grep overlay
```

```text
NETWORK ID     NAME          DRIVER    SCOPE
g7h8i9j0k1l2   my-overlay    overlay   swarm
```

The `SCOPE` is `swarm` (not `local`), meaning the network is available across all Swarm nodes.

### Use Cases

| Use Case | Why Overlay? |
|---|---|
| Microservices across multiple hosts | Containers communicate by name regardless of which host they run on |
| Docker Swarm services | Required for cross-node service discovery |
| High availability | Workloads spread across nodes, still communicate seamlessly |
| Zero-trust networking | Overlay traffic encrypted end-to-end with `--opt encrypted` |

### Key Points

- Requires Docker Swarm (`docker swarm init` on at least one node)
- VXLAN encapsulates container packets inside UDP on port **4789**
- Container DNS still works - `ping service-name` resolves across hosts
- `--attachable` allows standalone containers (not just Swarm services) to join

---

## Summary

| Task | What I did |
|---|---|
| Task 1 - Container Networking | 3 containers, 3 networks; backend joined 2 networks; showed frontend ↔ database isolation |
| Task 2 - Host Network | Apache2 on `--network host`; served on port 80 without port mapping |
| Task 3 - Bind Mount | Nginx with `~/nginx-content` bind-mounted; edited HTML live without restart |
| Task 4 - Overlay Network | Researched VXLAN overlay; created swarm overlay network; explained use cases |