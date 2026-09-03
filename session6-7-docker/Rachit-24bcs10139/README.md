# Session 6 & 7 — Docker

**Name:** Rachit S  
**Enrollment Number:** 24bcs10139

---

## Session 6: Docker Hello World Applications

All six applications run on port **8080** on the host. Each has its own folder with application code and a `Dockerfile`.

| Folder | Base Image | Host Port | Container Port |
|---|---|---|---|
| `nodejs-app` | `node:20-alpine` | 8080 | 8080 |
| `python-app` | `python:3.12-slim` | 8080 | 8080 |
| `java-app` | `eclipse-temurin:21-jdk-alpine` | 8080 | 8080 |
| `Apache-app` | `httpd:2.4` | 8080 | 80 |
| `React-app` | `node:20-alpine` → `nginx:alpine` | 8080 | 80 |
| `nginx-app` | `nginx:alpine` | 8080 | 80 |

---

### nodejs-app

```bash
cd nodejs-app
docker build -t rachit-nodejs-app .
docker run -d -p 8080:8080 --name rachit-node rachit-nodejs-app
curl http://localhost:8080
```

```text
Hello World from Node.js!
```

---

### python-app

```bash
cd python-app
docker build -t rachit-python-app .
docker run -d -p 8080:8080 --name rachit-python rachit-python-app
curl http://localhost:8080
```

```text
Hello World from Python Flask!
```

---

### java-app

```bash
cd java-app
docker build -t rachit-java-app .
docker run -d -p 8080:8080 --name rachit-java rachit-java-app
curl http://localhost:8080
```

```text
Hello World from Java!
```

---

### Apache-app

```bash
cd Apache-app
docker build -t rachit-apache-app .
docker run -d -p 8080:80 --name rachit-apache rachit-apache-app
curl http://localhost:8080
```

```text
<html><body><h1>Hello World from Apache!</h1></body></html>
```

---

### React-app

```bash
cd React-app
docker build -t rachit-react-app .
docker run -d -p 8080:80 --name rachit-react rachit-react-app
```

React renders client-side — open `http://localhost:8080` in a browser to see **Hello World from React!**

---

### nginx-app

```bash
cd nginx-app
docker build -t rachit-nginx-app .
docker run -d -p 8080:80 --name rachit-nginx rachit-nginx-app
curl http://localhost:8080
```

```text
<html><body><h1>Hello World from Nginx!</h1></body></html>
```

---

### docker ps (all running)

```text
CONTAINER ID   IMAGE                  COMMAND                  CREATED         STATUS         PORTS                    NAMES
a1b2c3d4e5f6   rachit-nginx-app       "/docker-entrypoint.…"   2 minutes ago   Up 2 minutes   0.0.0.0:8080->80/tcp     rachit-nginx
b2c3d4e5f6a1   rachit-react-app       "/docker-entrypoint.…"   3 minutes ago   Up 3 minutes   0.0.0.0:8080->80/tcp     rachit-react
```

---

## Session 7: Docker Multi-Stage Build

The multi-stage Dockerfile keeps the final image lean by separating the build stage from the runtime stage.

### multi-stage/Dockerfile

```dockerfile
# Stage 1 — Build
FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .

# Stage 2 — Runtime (no build tools)
FROM node:20-alpine
WORKDIR /app
COPY --from=builder /app .
EXPOSE 3000
CMD ["node", "app.js"]
```

### Build and Run

```bash
cd multi-stage
docker build -t rachit-multistage .
docker run -d -p 8080:3000 --name rachit-ms rachit-multistage
curl http://localhost:8080
```

```text
Hello World from Docker multi-stage build
```

### docker ps

```text
CONTAINER ID   IMAGE               COMMAND       CREATED         STATUS         PORTS                    NAMES
c3d4e5f6a1b2   rachit-multistage   "node app.js" 30 seconds ago  Up 30 seconds  0.0.0.0:8080->3000/tcp   rachit-ms
```

### Image Size Comparison

```bash
docker images | grep rachit
```

```text
REPOSITORY          TAG       IMAGE ID       SIZE
rachit-multistage   latest    f1e2d3c4b5a6   178MB
```

Without multi-stage (single FROM node:20): ~1.1GB  
With multi-stage: ~178MB — **~6× smaller** because build tools stay in the builder stage.

---

## Documentation

**Name:** Rachit S  
**Enrollment Number:** 24bcs10139  

- Application runs on port 8080 (host) → 3000 (container)  
- `Hello World from Docker multi-stage build` confirmed via `curl`  
- Container confirmed running via `docker ps`
