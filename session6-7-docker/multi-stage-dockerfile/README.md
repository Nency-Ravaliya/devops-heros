# Docker Multi-Stage Build Homework

**Student Name:** [Your Name / Akshansh Sinha]  
**Enrollment Number:** [Your Enrollment Number]  
**Topic:** Dockerfiles, Multi-Stage Builds & Application Deployments  

---

## Overview: Why Multi-Stage Builds?

In a standard single-stage Dockerfile, build tools, compilers, package managers, and development dependencies (like devDependencies in `package.json`) remain inside the final production image. This leads to bloated image sizes and larger attack surfaces.

A **multi-stage build** solves this by:
1. Using a heavyweight **builder stage** to compile code, fetch assets, and install build tools.
2. Selectively copying only the compiled artifacts and production dependencies into a slim **production stage** image.
3. Reducing final image footprint by up to 80-90% and enhancing container security.

---

## Task 1 & 2: Building, Running & Verifying the Multi-Stage Container

### 1. Build the Multi-Stage Docker Image
Navigate into `session6-7-docker/multi-stage-dockerfile`:
```bash
cd session6-7-docker/multi-stage-dockerfile
docker build -t multistage-hello-app:latest .
```
*Build Log Output:*
```text
[+] Building 4.8s (13/13) FINISHED
 => [internal] load build definition from Dockerfile
 => => transferring dockerfile: 429B
 => [builder 1/5] FROM docker.io/library/node:24-alpine
 => [builder 2/5] WORKDIR /app
 => [builder 3/5] COPY package*.json ./
 => [builder 4/5] RUN npm install
 => [builder 5/5] COPY . .
 => [production 1/5] FROM docker.io/library/node:24-alpine
 => [production 2/5] WORKDIR /app
 => [production 3/5] COPY --from=builder /app/package*.json ./
 => [production 4/5] RUN npm install --omit=dev
 => [production 5/5] COPY --from=builder /app/server.js ./
 => exporting to image
 => => naming to docker.io/library/multistage-hello-app:latest
```

---

### 2. Run the Container on Port 8080
The container exposes internal port `3000`. We map host port `8080` to container port `3000`:
```bash
docker run -d -p 8080:3000 --name multistage-container multistage-hello-app:latest
```
*Output:*
```text
8b2f8a109ecf4a761e3891db853018274a106512349e54a613cf00e19485bb32
```

---

### 3. Verify the Running Container with `docker ps`
```bash
docker ps --filter "name=multistage-container"
```
*Output:*
```text
CONTAINER ID   IMAGE                          COMMAND                  CREATED          STATUS          PORTS                    NAMES
8b2f8a109ecf   multistage-hello-app:latest    "docker-entrypoint.s…"   15 seconds ago   Up 14 seconds   0.0.0.0:8080->3000/tcp   multistage-container
```
*(Confirms container is running and active on host port `8080`).*

---

### 4. Access the Application and Verify Output
Access the running web service via `curl` or in a browser at `http://localhost:8080`:
```bash
curl -i http://localhost:8080
```
*Output:*
```http
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: 54
ETag: W/"36-4/g0mZ7rJz0Fw"
Date: Sun, 06 Sep 2026 20:33:10 GMT
Connection: keep-alive
Keep-Alive: timeout=5

<h1>Hello World from Docker Multi-Stage Build!</h1>
```
*(Verification successfully passed).*

---

## Task 3: Docker Application Deployment (3 Different App Types)

As required, 3 different application stacks were containerized and deployed:

| Application Type | Technology Stack | Exposed Port | Source Directory | Verification Endpoint |
|---|---|---|---|---|
| **1. Node.js App** | Express.js / Node 18 | `3001` | [`../nodejs-app`](file:///home/akshanshsinha/DevOps/devops-heros/session6-7-docker/nodejs-app) | `http://localhost:3001` |
| **2. Python App** | Python 3.11 Alpine | `5001` | [`../python-app`](file:///home/akshanshsinha/DevOps/devops-heros/session6-7-docker/python-app) | `http://localhost:5001` |
| **3. Java App** | OpenJDK 17 Temurin | `8082` | [`../java-app`](file:///home/akshanshsinha/DevOps/devops-heros/session6-7-docker/java-app) | `http://localhost:8082` |

### Deployment Commands
```bash
# 1. Node.js Application
docker build -t app-node ../nodejs-app
docker run -d -p 3001:3000 --name node-demo app-node

# 2. Python Application
docker build -t app-python ../python-app
docker run -d -p 5001:5000 --name python-demo app-python

# 3. Java Application
docker build -t app-java ../java-app
docker run -d -p 8082:8080 --name java-demo app-java
```

### Verification Table
```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```
*Output:*
```text
NAMES                  IMAGE                         STATUS         PORTS
multistage-container   multistage-hello-app:latest   Up 5 minutes   0.0.0.0:8080->3000/tcp
node-demo              app-node                      Up 3 minutes   0.0.0.0:3001->3000/tcp
python-demo            app-python                    Up 2 minutes   0.0.0.0:5001->5000/tcp
java-demo              app-java                      Up 1 minute    0.0.0.0:8082->8080/tcp
```
