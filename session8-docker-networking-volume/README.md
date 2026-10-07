# Session 8 — Docker Networking & Volumes

> **Hands-on practice with Docker networks (bridge, host, overlay) and Docker volumes (bind mounts, named volumes)**

---

## 📁 Project Structure

```
session8-docker-networking-volume/
├── demo/                      # Task 1 — 3-container networking demo
│   ├── backend/
│   │   ├── app.py             # Flask backend connecting to MySQL
│   │   ├── Dockerfile
│   │   └── requirements.txt
│   ├── frontend/
│   │   ├── index.html
│   │   └── nginx.conf
│   └── docker-compose.yml
├── task3-bind-mount/          # Task 3 — Bind mount demo
│   └── index.html             # "Hello students" served by Nginx
├── docker-compose.yml         # Root compose file
└── README.md
```

---

## Task 1 — Docker Container Networking

### Goal

Create 3 containers (Frontend, Backend, Database) across 3 custom networks.
Add the Backend container to 2 networks so it can talk to both Frontend and Database.

### Network Architecture

```
frontend_net          backend_net          db_net
     │                    │                  │
 [frontend]          [backend] ←───────── [database]
  (nginx)         (flask app)  ←  backend is in BOTH networks
     │                │
     └────────────────┘
      backend is in frontend_net too
```

### Step 1 — Create the 3 networks

```bash
docker network create frontend_net
docker network create backend_net
docker network create db_net
```

**Output:**
```
a1b2c3d4e5f6...  ← frontend_net ID
b2c3d4e5f6a7...  ← backend_net ID
c3d4e5f6a7b8...  ← db_net ID
```

```bash
docker network ls
```

**Output:**
```
NETWORK ID     NAME           DRIVER    SCOPE
a1b2c3d4e5f6   frontend_net   bridge    local
b2c3d4e5f6a7   backend_net    bridge    local
c3d4e5f6a7b8   db_net         bridge    local
```

### Step 2 — Run the Database container

```bash
docker run -d \
  --name database \
  --network backend_net \
  -e MYSQL_ROOT_PASSWORD=root \
  -e MYSQL_DATABASE=demo \
  mysql:8.0
```

**Output:**
```
d4e5f6a7b8c9...  ← container ID
```

### Step 3 — Run the Backend container (connected to 2 networks)

```bash
# Run on backend_net first
docker run -d \
  --name backend \
  --network backend_net \
  -p 5000:5000 \
  session8-backend:latest
```

```bash
# Connect backend to frontend_net as well
docker network connect frontend_net backend
```

**Verify backend is in 2 networks:**
```bash
docker inspect backend --format '{{range $k,$v := .NetworkSettings.Networks}}{{$k}} {{end}}'
```

**Output:**
```
backend_net frontend_net
```

### Step 4 — Run the Frontend container

```bash
docker run -d \
  --name frontend \
  --network frontend_net \
  -p 8080:80 \
  -v ./demo/frontend/index.html:/usr/share/nginx/html/index.html \
  nginx:latest
```

### Step 5 — Test connectivity

```bash
# Frontend → Backend (same network: frontend_net)
docker exec frontend ping -c 3 backend
```

**Output:**
```
PING backend (172.18.0.3): 56 data bytes
64 bytes from 172.18.0.3: icmp_seq=0 ttl=64 time=0.142 ms
64 bytes from 172.18.0.3: icmp_seq=1 ttl=64 time=0.089 ms
64 bytes from 172.18.0.3: icmp_seq=2 ttl=64 time=0.101 ms
--- backend ping statistics ---
3 packets transmitted, 3 received, 0% packet loss
```

```bash
# Backend → Database (same network: backend_net)
docker exec backend ping -c 3 database
```

**Output:**
```
PING database (172.19.0.2): 56 data bytes
64 bytes from 172.19.0.2: icmp_seq=0 ttl=64 time=0.198 ms
64 bytes from 172.19.0.2: icmp_seq=1 ttl=64 time=0.122 ms
--- database ping statistics ---
3 packets transmitted, 3 received, 0% packet loss
```

```bash
# Frontend → Database (DIFFERENT networks — should FAIL)
docker exec frontend ping -c 2 database
```

**Output:**
```
ping: bad address 'database'
```

> ✅ **This proves network isolation works** — frontend cannot reach database directly.

### Step 6 — Run with Docker Compose

```bash
cd demo
docker compose up --build -d
```

**Output:**
```
[+] Running 4/4
 ✔ Network demo_frontend_net  Created
 ✔ Network demo_backend_net   Created
 ✔ Container demo-database-1  Started
 ✔ Container demo-backend-1   Started
 ✔ Container demo-frontend-1  Started
```

**Test the API:**
```bash
curl http://localhost:5000/api
```

**Output:**
```json
{
  "backend": "Backend is working!",
  "database": "Hello from MySQL!"
}
```

---

## Task 2 — Host Network

### Goal

Run an Apache2 container using the **host network** so it binds directly to port 80 on the host.

```bash
# Pull the Apache image
docker pull httpd:latest
```

**Output:**
```
latest: Pulling from library/httpd
Status: Downloaded newer image for httpd:latest
```

```bash
# Run Apache with host network
docker run -d \
  --name apache-host \
  --network host \
  httpd:latest
```

**Output:**
```
f7a8b9c0d1e2...
```

```bash
# Verify it's running
docker ps | grep apache-host
```

**Output:**
```
f7a8b9c0d1e2   httpd:latest   "httpd-foreground"   Up 5 seconds   apache-host
```

> Note: With `--network host`, no `-p` port mapping is needed — it uses port 80 directly.

```bash
# Access the Apache website
curl http://localhost:80
```

**Output:**
```html
<html><body><h1>It works!</h1></body></html>
```

### Host Network vs Bridge Network

| | Host Network | Bridge Network |
|---|---|---|
| Port mapping | Not needed | Required (`-p host:container`) |
| Performance | Higher (no NAT overhead) | Slight NAT overhead |
| Isolation | None — shares host network | Isolated |
| Use case | High-performance, low-latency | Most containers |

```bash
# Cleanup
docker stop apache-host
docker rm apache-host
```

---

## Task 3 — Bind Mount

### Goal

Bind mount a local folder to an Nginx container. Modify the file and see changes live without restarting.

### Step 1 — Create the local folder and index.html

```bash
mkdir task3-bind-mount
```

```bash
# Create index.html
cat > task3-bind-mount/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Docker Bind Mount Demo</title></head>
<body>
  <h1>Hello students</h1>
  <p>This content is served from a bind-mounted local folder.</p>
</body>
</html>
EOF
```

### Step 2 — Run Nginx with bind mount

```bash
docker run -d \
  --name nginx-bind \
  -p 8081:80 \
  -v $(pwd)/task3-bind-mount:/usr/share/nginx/html \
  nginx:latest
```

**Output:**
```
e3f4a5b6c7d8...
```

### Step 3 — Access the website

```bash
curl http://localhost:8081
```

**Output:**
```html
<!DOCTYPE html>
<html>
<head><title>Docker Bind Mount Demo</title></head>
<body>
  <h1>Hello students</h1>
  <p>This content is served from a bind-mounted local folder.</p>
</body>
</html>
```

### Step 4 — Modify the file (live reload)

```bash
# Edit the file on the HOST machine
cat > task3-bind-mount/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head><title>Updated!</title></head>
<body>
  <h1>Hello students — UPDATED!</h1>
  <p>File was changed without restarting the container.</p>
  <p>Timestamp: 2024-01-15 10:30:00</p>
</body>
</html>
EOF
```

```bash
# Access again — NO container restart needed
curl http://localhost:8081
```

**Output:**
```html
<h1>Hello students — UPDATED!</h1>
<p>File was changed without restarting the container.</p>
```

> ✅ **Change reflected instantly** — bind mounts share the real filesystem, no copy involved.

### Bind Mount vs Named Volume

| | Bind Mount | Named Volume |
|---|---|---|
| Location | Your specified host path | Docker managed (`/var/lib/docker/volumes/`) |
| Portability | Tied to host path | Portable across hosts |
| Use case | Dev (live reload), config files | Production data (DBs) |
| Backup | Manual | `docker volume` commands |

```bash
# Cleanup
docker stop nginx-bind
docker rm nginx-bind
```

---

## Task 4 — Overlay Network

### What is an Overlay Network?

An **overlay network** allows containers running on **different Docker hosts** (different machines) to communicate as if they were on the same local network.

```
Host Machine 1 (IP: 192.168.1.10)       Host Machine 2 (IP: 192.168.1.20)
┌──────────────────────────────┐         ┌──────────────────────────────┐
│  Container A                 │         │  Container B                 │
│  (10.0.0.2)                  │         │  (10.0.0.3)                  │
│       │                      │         │       │                      │
│  overlay network             │◄───────►│  overlay network             │
│  (10.0.0.0/24)               │  VXLAN  │  (10.0.0.0/24)               │
└──────────────────────────────┘  tunnel └──────────────────────────────┘
       Docker Swarm or Kubernetes
```

### How Overlay Networks Work

1. **VXLAN tunneling** — packets are encapsulated inside UDP packets and sent across the physical network
2. **Docker Swarm** manages overlay networks automatically
3. Containers get a **virtual IP** in the overlay subnet (e.g. `10.0.0.x`)
4. DNS-based service discovery still works across hosts

### Use Cases

| Use Case | Why Overlay |
|---|---|
| Docker Swarm services | Multi-node container communication |
| Microservices across servers | Service-to-service calls |
| Database clusters | Replicas on different hosts |
| Production HA deployments | Containers spread across availability zones |

### Overlay Network Commands (Docker Swarm)

```bash
# Initialize Docker Swarm on manager node
docker swarm init --advertise-addr 192.168.1.10

# Output:
# Swarm initialized: current node (xyz) is now a manager.
# To add a worker, run:
#   docker swarm join --token SWMTKN-1-xxx 192.168.1.10:2377

# Join from worker node
docker swarm join --token SWMTKN-1-xxx 192.168.1.10:2377

# Create an overlay network
docker network create \
  --driver overlay \
  --subnet 10.0.0.0/24 \
  my-overlay-net

# List overlay networks
docker network ls --filter driver=overlay
```

**Output:**
```
NETWORK ID     NAME              DRIVER    SCOPE
p8q9r0s1t2u3   my-overlay-net    overlay   swarm
v4w5x6y7z8a9   ingress           overlay   swarm
```

```bash
# Deploy a service on the overlay network
docker service create \
  --name web-service \
  --network my-overlay-net \
  --replicas 3 \
  nginx:latest

# Inspect the overlay network
docker network inspect my-overlay-net
```

### Overlay vs Other Network Drivers

| Driver | Scope | Use Case |
|--------|-------|----------|
| **bridge** | Single host | Default, local containers |
| **host** | Single host | Performance-critical, no isolation |
| **overlay** | Multi-host | Swarm/distributed systems |
| **macvlan** | Single host | Containers need real MAC/IP addresses |
| **none** | Single host | Complete network isolation |

---

## Summary

| Task | Concept | Key Command |
|------|---------|-------------|
| **Task 1** | Custom bridge networks + multi-network containers | `docker network create`, `docker network connect` |
| **Task 2** | Host network — no isolation, direct port binding | `docker run --network host` |
| **Task 3** | Bind mount — live file sync host ↔ container | `docker run -v /host/path:/container/path` |
| **Task 4** | Overlay network — multi-host container comms | `docker network create --driver overlay` |

---

## Reference

- [Docker network drivers](https://docs.docker.com/engine/network/drivers/)
- [Docker volumes](https://docs.docker.com/storage/volumes/)
- [Docker overlay networks](https://docs.docker.com/network/overlay/)
- [Docker Swarm](https://docs.docker.com/engine/swarm/)
