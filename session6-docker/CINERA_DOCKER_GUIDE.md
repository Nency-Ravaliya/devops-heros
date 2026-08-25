# 🍿 CINERA (Netflix Clone) - Complete Docker Mastery Guide & Notes

Welcome to the **Complete Docker & Containerization Guide** built around a real-world production application: **CINERA** (a full-stack Netflix clone).

This guide walks you through every core concept, command, and production pattern taught in DevOps Session 6, using **CINERA** as our hands-on example.

---

## 📂 1. CINERA Application Architecture

Imagine CINERA has the following standard project structure:

```text
cinera/
├── client/                  # Frontend (React + Vite)
│   ├── src/
│   ├── package.json
│   ├── nginx.conf           # Custom Nginx config for production React routing
│   └── Dockerfile           # Multi-stage production Dockerfile
├── server/                  # Backend (Express Node.js API)
│   ├── src/
│   │   └── server.js
│   ├── package.json
│   └── Dockerfile           # Backend Dockerfile
├── docker-compose.yml       # Multi-container orchestration (Client, Server, DB, Redis)
└── .env                     # Environment variables
```

---

## 🧠 2. Core Docker Concepts Explained

| Concept | Explanation | CINERA Example |
| :--- | :--- | :--- |
| **Docker Engine** | The underlying client-server app running Docker. | The background engine on your server managing CINERA. |
| **Docker Image** | A read-only blueprint containing OS, code, runtime & dependencies. | `cinera-server:v1.0` or `cinera-client:v1.0`. |
| **Container** | A running, isolated process instance of an image. | A running instance of `cinera-server` handling API requests. |
| **Volume** | Persistent storage independent of container lifecycle. | Storing CINERA's user movies & database data on disk. |
| **Network** | Isolated Virtual Bridge network allowing container communication. | Allows `cinera-client` to talk to `cinera-server` & `db`. |

---

## 🛠️ 3. Core Docker Commands Reference (Cheat Sheet)

### A. Image Management Commands

* **Build an image**:
  ```bash
  docker build -t cinera-server:latest ./server
  ```
  * `-t cinera-server:latest`: Tags the image with name and version.
  * `./server`: Path to the build context containing the `Dockerfile`.

* **List local images**:
  ```bash
  docker images
  ```

* **Remove an image**:
  ```bash
  docker rmi cinera-server:latest
  ```

* **Tag an image for Docker Hub**:
  ```bash
  docker tag cinera-server:latest yourusername/cinera-server:v1.0
  ```

* **Push an image to Docker Hub**:
  ```bash
  docker push yourusername/cinera-server:v1.0
  ```

---

### B. Container Lifecycle & Execution Commands

* **Run a container in background (detached mode)**:
  ```bash
  docker run -d -p 5000:5000 --name cinera-backend cinera-server:latest
  ```
  * `-d`: Detached mode (runs in background).
  * `-p 5000:5000`: Port forwarding (`HostPort:ContainerPort`).
  * `--name cinera-backend`: Gives a human-readable container name.

* **List running containers**:
  ```bash
  docker ps
  ```

* **List ALL containers (including stopped ones)**:
  ```bash
  docker ps -a
  ```

* **Stop a running container**:
  ```bash
  docker stop cinera-backend
  ```

* **Start a stopped container**:
  ```bash
  docker start cinera-backend
  ```

* **Remove a container**:
  ```bash
  docker rm cinera-backend
  ```

* **Force stop and remove a container**:
  ```bash
  docker rm -f cinera-backend
  ```

---

### C. Inspection, Debugging & Monitoring Commands

* **View container logs (live tailing)**:
  ```bash
  docker logs -f cinera-backend
  ```
  * `-f`: Follow / stream live logs.

* **Execute an interactive terminal inside a running container**:
  ```bash
  docker exec -it cinera-backend sh
  ```
  * `-it`: Interactive pseudo-TTY (gives you a terminal shell inside the container).

* **Inspect full container metadata (IP address, mounts, environment)**:
  ```bash
  docker inspect cinera-backend
  ```

* **Monitor resource usage (CPU, Memory, Network I/O)**:
  ```bash
  docker stats
  ```

* **Clean up unused containers, networks, and dangling images**:
  ```bash
  docker system prune -f
  ```

---

## 🐳 4. Writing Production-Ready Dockerfiles for CINERA

### A. CINERA Backend (`server/Dockerfile`) - Express API

```dockerfile
# 1. Use an official lightweight Node.js base image
FROM node:20-alpine

# 2. Set the working directory inside the container
WORKDIR /app

# 3. Copy dependency definitions first (Optimizes Docker build caching)
COPY package*.json ./

# 4. Install production dependencies only
RUN npm ci --only=production

# 5. Copy remaining application source code
COPY . .

# 6. Expose the port Express listens on
EXPOSE 5000

# 7. Use non-root user for security
USER node

# 8. Start the Express server
CMD ["node", "src/server.js"]
```

---

### B. CINERA Frontend (`client/Dockerfile`) - Multi-Stage Build (React + Nginx)

In production, React source code is built into static HTML/JS/CSS files, which are served using Nginx for maximum performance.

```dockerfile
# ==========================================
# STAGE 1: Build React Application
# ==========================================
FROM node:20-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm ci

COPY . .
RUN npm run build   # Produces output in /app/dist

# ==========================================
# STAGE 2: Serve Production Assets with Nginx
# ==========================================
FROM nginx:alpine

# Copy custom Nginx config for client-side routing (React Router)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy static build output from Stage 1 into Nginx web root
COPY --from=builder /app/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
```

---

## 🐙 5. Orchestrating CINERA with Docker Compose

Docker Compose manages multi-container applications with a single configuration file (`docker-compose.yml`).

### CINERA `docker-compose.yml`

```yaml
version: '3.8'

services:
  # 1. Database Service (MongoDB or PostgreSQL)
  cinera-db:
    image: mongo:latest
    container_name: cinera-db
    restart: always
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: secretpassword
    volumes:
      - mongo-data:/data/db
    networks:
      - cinera-network

  # 2. Redis Cache Service (For streaming session/video caching)
  cinera-redis:
    image: redis:alpine
    container_name: cinera-redis
    restart: always
    ports:
      - "6379:6379"
    networks:
      - cinera-network

  # 3. Express Backend Service
  cinera-server:
    build:
      context: ./server
      dockerfile: Dockerfile
    container_name: cinera-server
    restart: always
    ports:
      - "5000:5000"
    environment:
      PORT: 5000
      MONGO_URI: mongodb://admin:secretpassword@cinera-db:27017/cinera?authSource=admin
      REDIS_HOST: cinera-redis
    depends_on:
      - cinera-db
      - cinera-redis
    networks:
      - cinera-network

  # 4. React Frontend Service
  cinera-client:
    build:
      context: ./client
      dockerfile: Dockerfile
    container_name: cinera-client
    restart: always
    ports:
      - "80:80"
    depends_on:
      - cinera-server
    networks:
      - cinera-network

# Persistent Volumes
volumes:
  mongo-data:

# Custom Isolated Network
networks:
  cinera-network:
    driver: bridge
```

---

### Docker Compose Commands

* **Start the full CINERA stack in background**:
  ```bash
  docker compose up -d
  ```
* **Rebuild images and start containers**:
  ```bash
  docker compose up --build -d
  ```
* **Check status of all stack services**:
  ```bash
  docker compose ps
  ```
* **View logs for all services**:
  ```bash
  docker compose logs -f
  ```
* **Stop and remove all services, networks, and volumes**:
  ```bash
  docker compose down -v
  ```

---

## 🌐 6. Networks & Storage (Volumes) Deep-Dive

### Networking
Containers on the same user-defined network (`cinera-network`) can communicate using service names as domain names.
* Inside `cinera-server`, you connect to the database using `mongodb://cinera-db:27017` instead of an IP address. Docker's internal DNS handles IP resolution automatically!

### Volumes
1. **Named Volumes** (`mongo-data:/data/db`): Managed by Docker. Data persists even when containers are deleted/recreated.
2. **Bind Mounts** (`-v $(pwd)/server:/app`): Mounts a folder from your host system directly into the container. Used during development for live code reloading (hot-reloading).

---

## 🔒 7. Production Best Practices Checklist

1. **Use `.dockerignore`**: Exclude `node_modules`, `.git`, `.env`, and build logs from the build context to speed up builds and keep images small.
2. **Use Multi-Stage Builds**: Keeps production image size tiny (e.g., React build reduces from ~1GB to ~25MB with Nginx).
3. **Use Minimal Base Images**: Choose `-alpine` variants for smaller security attack surface.
4. **Never Store Secrets in Dockerfiles**: Pass sensitive keys using environment variables (`.env` or Docker secrets).
5. **Run as Non-Root User**: Use `USER node` to prevent security escalation.
