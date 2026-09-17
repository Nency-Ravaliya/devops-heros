# Session 7 — Dockerfiles & Images (Multi-Stage Build)

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Topic:** Docker multi-stage builds

All output below is real terminal output.

---

## Task 1 — Run the Multi-Stage Dockerfile

### 1.1 Clone the repository containing the multi-stage Dockerfile

```bash
git clone https://github.com/Nency-Ravaliya/devops-heros.git
cd devops-heros/session6-7-docker/multi-stage-dockerfile
```

The app is a small Express server (`server.js`) that responds with
`Hello World from Docker Multi-Stage Build!`.

### 1.2 The multi-stage Dockerfile

```dockerfile
# -------------------------
# Stage 1: Build
# -------------------------
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .

# -------------------------
# Stage 2: Production
# -------------------------
FROM node:24-alpine AS production
WORKDIR /app
COPY --from=builder /app/package*.json ./
RUN npm install --omit=dev
COPY --from=builder /app/server.js ./
EXPOSE 3000
CMD ["npm", "start"]
```

**How it works.** A multi-stage Dockerfile has more than one `FROM`. Each `FROM` starts a
fresh stage with its own filesystem, and **only the last stage becomes the final image**.
Earlier stages exist purely to produce artifacts, which the final stage pulls in with
`COPY --from=<stage>`. Everything else in those stages — compilers, dev dependencies,
caches, source files — is discarded.

Here `builder` installs **all** dependencies and holds the full source. The `production`
stage then starts clean and takes only `package*.json` and `server.js`, reinstalling with
`--omit=dev` so devDependencies never reach production.

### 1.3 Build the image

```bash
docker build -t multistage-hello:1.0 .
```

The build runs both stages and tags only the final one.

### 1.4 Run a container from the image on port 8080

The app listens on **3000** inside the container, so it is published to **8080** on the host:

```bash
docker run -d --name multistage-hello -p 8080:3000 multistage-hello:1.0
```

```
3647398de5f9d312f7e028237897625615c791d9e87fc456151c75f1b3aafb0a
```

### 1.5 Verify the running container with `docker ps` — on port 8080

```bash
docker ps
```

```
CONTAINER ID   IMAGE                  STATUS         PORTS                                         NAMES
3647398de5f9   multistage-hello:1.0   Up 5 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   multistage-hello
```

`0.0.0.0:8080->3000/tcp` confirms the container is published on **host port 8080**.

### 1.6 Access the application and verify the output

```bash
curl http://localhost:8080/
```

```
<h1>Hello World from Docker Multi-Stage Build!</h1>
```

**Verified** — the application displays `Hello World from Docker multi-stage build`.

```bash
curl -I http://localhost:8080/
```

```
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: 51
ETag: W/"33-gCAsBJJtlso/BVPWoV3U/pWC3Ak"
Date: Thu, 17 Sep 2026 20:42:27 GMT
```

`X-Powered-By: Express` confirms the Express server from the final stage is the one serving.

```bash
docker logs multistage-hello
```

```
> docker-hello-world@1.0.0 start
> node server.js
```

### 1.7 What actually ended up in the final image

```bash
docker exec multistage-hello ls -la /app
```

```
total 52
drwxr-xr-x    1 root     root          4096 Sep 17 20:41 .
drwxr-xr-x    1 root     root          4096 Sep 17 20:42 ..
drwxr-xr-x   67 root     root          4096 Sep 17 20:41 node_modules
-rw-r--r--    1 root     root         31935 Sep 17 20:41 package-lock.json
-rwxr-xr-x    1 root     root           188 Sep 17 20:37 package.json
-rwxr-xr-x    1 root     root           269 Sep 17 20:37 server.js
```

Only the runtime files are present. The `builder` stage's working copy of the whole source
tree never shipped — the final stage explicitly copied `server.js` and the manifests and
nothing else.

```bash
docker history multistage-hello:1.0
```

```
CREATED BY                                      SIZE
CMD ["npm" "start"]                             0B
EXPOSE [3000/tcp]                               0B
COPY /app/server.js ./ # buildkit               12.3kB
RUN /bin/sh -c npm install --omit=dev # buil…   9.45MB
COPY /app/package*.json ./ # buildkit           45.1kB
WORKDIR /app                                    8.19kB
CMD ["node"]                                    0B
ENTRYPOINT ["docker-entrypoint.sh"]             0B
COPY docker-entrypoint.sh /usr/local/bin/ # …   20.5kB
```

`docker history` shows the layers of the **final image only** — the builder stage's layers
are not part of it. Above the base image there are just three meaningful layers totalling
about 9.5 MB.

### 1.8 Size comparison against a single-stage build

To measure the benefit, I wrote the equivalent single-stage Dockerfile
(`Dockerfile.single-stage`) and built both:

```dockerfile
FROM node:24-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

```bash
docker images
```

```
REPOSITORY            TAG         SIZE
multistage-hello      1.0         247MB
singlestage-hello     1.0         253MB
```

**Honest reading of this result:** the saving here is only **6 MB (≈2.4%)**. That is small,
and it is worth saying why rather than overstating the result: this app has *one* runtime
dependency (Express), *no* devDependencies and *no* compile step, so there is barely
anything for the builder stage to throw away. Most of the 247 MB is the `node:24-alpine`
base image, which both builds share.

Multi-stage pays off when the build stage produces something genuinely heavy that the
runtime does not need. From my Session 6 work, the React app is the clear case:

| Build style | What ships | Size |
|---|---|---|
| React, multi-stage (`node` builds → `nginx` serves) | nginx + a ~200 KB static bundle | **73.8 MB** |
| Java, single-stage (full JDK in the final image) | JDK + compiler + compiled class | **552 MB** |

The React image is 7× smaller than the Java one because the entire Node toolchain and
`node_modules` were left behind in the discarded build stage. That is the pattern:
**the bigger the gap between build-time and run-time needs, the bigger the win.**

### Why multi-stage builds matter

| Benefit | Explanation |
|---|---|
| **Smaller images** | Compilers, SDKs, dev dependencies and caches never reach production |
| **Faster deploys** | Less to push and pull on every release |
| **Smaller attack surface** | No `gcc`, `npm`, `git` or build secrets sitting in the running container for an attacker to use |
| **Cleaner separation** | Build environment and runtime environment are declared independently in one file |
| **One reproducible file** | No separate build script — `docker build` produces the same artifact everywhere |

---

## Task 2 — Documentation

- **Name:** Snehangshu Roy
- **Enrollment Number:** 24BCS10155

### Output showing the application running successfully

```bash
curl http://localhost:8080/
```

```
<h1>Hello World from Docker Multi-Stage Build!</h1>
```

### Output of `docker ps` showing the running container on port 8080

```bash
docker ps
```

```
CONTAINER ID   IMAGE                  STATUS         PORTS                                         NAMES
3647398de5f9   multistage-hello:1.0   Up 5 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp   multistage-hello
```

---

## Task 3 — Docker Application Deployment (3+ application types)

Three different application types, each with its own Dockerfile, built and deployed as
containers. The sources are in the `three-apps/` folder here (same apps as my Session 6
submission).

```bash
docker ps
```

```
NAMES          IMAGE              STATUS         PORTS
hello-java     hello-java:1.0     Up 3 minutes   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
hello-python   hello-python:1.0   Up 4 minutes   0.0.0.0:5000->5000/tcp, [::]:5000->5000/tcp
hello-node     hello-node:1.0     Up 4 minutes   0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp
```

### 1. Node.js

```bash
curl http://localhost:3000/
```

```
    <h1>Hello World from Node.js!</h1>
    <p>Served by Node v20.20.2 in container e482380b5f23</p>
```

### 2. Python

```bash
curl http://localhost:5000/
```

```
    <h1>Hello World from Python!</h1>
    <p>Served by Python in container c3f659a15d5d</p>
```

### 3. Java

```bash
docker exec hello-java wget -qO- http://localhost:8080/
```

```
    <h1>Hello World from Java!</h1>
    <p>Served by Java 21.0.12 in container adf8499c87fd</p>
```

(Queried inside the container because host port 8080 was handed to the multi-stage
container for Task 1 — two containers cannot publish the same host port at once. The
container ID `adf8499c87fd` in the response matches the running Java container.)

### The three Dockerfiles

**Node.js** — `three-apps/nodejs-app/Dockerfile`

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY server.js ./
EXPOSE 3000
CMD ["node", "server.js"]
```

**Python** — `three-apps/python-app/Dockerfile`

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app.py ./
EXPOSE 5000
CMD ["python", "app.py"]
```

**Java** — `three-apps/java-app/Dockerfile`

```dockerfile
FROM eclipse-temurin:21-jdk-alpine
WORKDIR /app
COPY HelloServer.java ./
RUN javac HelloServer.java
EXPOSE 8080
CMD ["java", "HelloServer"]
```

---

## Commands used

```bash
# build both variants
docker build -t multistage-hello:1.0 .
docker build -f Dockerfile.single-stage -t singlestage-hello:1.0 .

# run on port 8080
docker run -d --name multistage-hello -p 8080:3000 multistage-hello:1.0

# verify
docker ps
curl http://localhost:8080/
docker logs multistage-hello
docker images
docker history multistage-hello:1.0
docker exec multistage-hello ls -la /app

# target one stage only (useful for debugging a build)
docker build --target builder -t debug-builder .
```

---

## Summary

| Task | Status |
|---|---|
| Task 1 — Cloned the repo, built the multi-stage image, ran the container, accessed the app, verified the Hello World output and confirmed port 8080 with `docker ps` | Done |
| Task 2 — Documentation with name, enrollment number and both required outputs | Done |
| Task 3 — Three application types (Node.js, Python, Java) built and deployed with Docker | Done |
