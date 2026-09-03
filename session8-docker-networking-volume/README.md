# Session 8 - Docker Networking and Volumes Homework

## Task 1: Docker container networking

Implemented in `docker-compose.yml` with:
- 3 containers: `frontend`, `backend`, `database`
- 3 custom networks:
  - `frontend_net`
  - `backend_net`
  - `admin_net`
- backend is attached to 2 networks (`frontend_net`, `backend_net`)

### Run and verify
```bash
cd session8-docker-networking-volume
docker compose up -d
docker compose ps
docker network ls
docker inspect session8-docker-networking-volume-backend-1
```

### Connectivity checks
```bash
docker exec -it session8-docker-networking-volume-frontend-1 ping -c 3 backend
docker exec -it session8-docker-networking-volume-backend-1 ping -c 3 database
```

---

## Task 2: Host network Apache container

```bash
docker pull httpd:2.4
docker run -d --name apache-host --network host httpd:2.4
curl http://localhost:80
```

---

## Task 3: Bind mount with Nginx

Create local folder and file:
```bash
mkdir -p bind-mount
echo "Hello students" > bind-mount/index.html
```

Run Nginx with bind mount:
```bash
docker run -d --name nginx-bind -p 8090:80 \
  -v "$(pwd)/bind-mount:/usr/share/nginx/html:ro" \
  nginx:alpine
```

Verify:
```bash
curl http://localhost:8090
```

Modify file without restart:
```bash
echo "Hello students - updated content" > bind-mount/index.html
curl http://localhost:8090
```

---

## Task 4: Overlay network notes

- Overlay networks connect containers across multiple Docker hosts.
- Typically used with Docker Swarm services.
- Docker creates VXLAN-based tunnels between nodes.
- Service discovery happens using internal DNS.
- Good for microservices spread across multiple servers.

Example:
```bash
docker network create -d overlay app_overlay
```

---

## Resources
- https://docs.docker.com/engine/network/drivers/
