# 🏗️ Multi-Stage Dockerfile & Container Running Guide

This guide documents the building, running, testing, and process inspection (`docker ps`) of the **Multi-Stage Node.js Application**.

---

## 📸 Terminal Execution & `docker ps` Screenshot

![Multi-Stage Docker PS Screenshot](./multi_stage_ps.png)

---

## 📜 1. Multi-Stage `Dockerfile` Explanation

Multi-stage builds separate the **build stage** (compiling code, installing dev dependencies) from the **production stage** (lightweight runtime with minimal size).

```dockerfile
# -------------------------
# Stage 1: Build Stage
# -------------------------
FROM node:24-alpine AS builder

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# -------------------------
# Stage 2: Production Stage
# -------------------------
FROM node:24-alpine AS production

WORKDIR /app

COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev

COPY --from=builder /app/server.js ./

EXPOSE 3000

CMD ["npm", "start"]
```

---

## 🛠️ 2. Build & Execution Commands

### Step 1: Build the Multi-Stage Image
```bash
docker build -t multi-stage-node-app .
```

### Step 2: Run the Application Container (Bare Minimum)
```bash
docker run -it -d -p 800:3000 --name multi-stage multi-stage-node-app:latest
```

---

## 🧪 3. Verification & Endpoint Testing (`curl`)

Test the bare minimum application running on host port `800`:

```bash
$ curl http://localhost:800
<h1>Hello World from Docker Multi-Stage Build!</h1>
```

---

## 📊 4. Running Process Inspection (`docker ps`)

```bash
$ docker ps

CONTAINER ID   IMAGE                         COMMAND                  CREATED         STATUS         PORTS                     NAMES
3031a7837def   multi-stage-node-app:latest   "docker-entrypoint.s..."   5 seconds ago   Up 4 seconds   0.0.0.0:800->3000/tcp     multi-stage
84cd61ad1b84   nginx                         "/docker-entrypoint..."   24 minutes ago  Up 24 minutes  0.0.0.0:8085->80/tcp      mynginx
2819c587cdcb   node-web-app                  "docker-entrypoint.s..."   1 hour ago      Up 1 hour      0.0.0.0:3000->3000/tcp    my-node-app
```
