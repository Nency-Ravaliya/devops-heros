# Session 6 — Docker Fundamentals

**Name:** Snehangshu Roy
**Enrollment No:** 24BCS10155
**Task:** Hello World web applications built and run with Docker

Six web applications, each in its own folder with its own `Dockerfile`, each built into an
image, run as a container, and verified over HTTP. All output below is real terminal output.

---

## Folder structure

```
docker-fundamentals-snehangshu/
├── nodejs-app/      Dockerfile, package.json, server.js
├── python-app/      Dockerfile, app.py
├── java-app/        Dockerfile, HelloServer.java
├── Apache-app/      Dockerfile, index.html
├── React-app/       Dockerfile, package.json, vite.config.js, index.html, src/
├── nginx-app/       Dockerfile, index.html
└── README.md
```

## Port map

| App | Image | Host port | Container port |
|---|---|---|---|
| Node.js | `hello-node:1.0` | 3000 | 3000 |
| Python | `hello-python:1.0` | 5000 | 5000 |
| Java | `hello-java:1.0` | 8080 | 8080 |
| Apache | `hello-apache:1.0` | 8081 | 80 |
| Nginx | `hello-nginx:1.0` | 8082 | 80 |
| React | `hello-react:1.0` | 3001 | 80 |

---

## 1. Node.js application

### `nodejs-app/Dockerfile`

```dockerfile
FROM node:20-alpine
WORKDIR /app
COPY package.json ./
RUN npm install --omit=dev
COPY server.js ./
EXPOSE 3000
CMD ["node", "server.js"]
```

The app uses Node's built-in `http` module, so it has no runtime dependencies — but
`package.json` is still copied **before** the source. That ordering matters: Docker caches
each layer, so as long as `package.json` is unchanged the `npm install` layer is reused and
only the last `COPY` re-runs when the code changes.

### Build and run

```bash
docker build -t hello-node:1.0 ./nodejs-app
docker run -d --name hello-node -p 3000:3000 hello-node:1.0
```

```
#8 0.754 up to date, audited 1 package in 331ms
#8 0.754 found 0 vulnerabilities
#8 DONE 0.8s

#9 [5/5] COPY server.js ./
#9 DONE 0.1s

#10 exporting to image
#10 naming to docker.io/library/hello-node:1.0 done
#10 DONE 0.4s
```

### Verify

```bash
curl http://localhost:3000/
```

```html
<!doctype html>
<html>
  <head><title>Node.js on Docker</title></head>
  <body>
    <h1>Hello World from Node.js!</h1>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
    <p>Served by Node v20.20.2 in container e482380b5f23</p>
  </body>
</html>
```

```bash
docker logs hello-node
```

```
Node.js app listening on port 3000
```

The page prints the container's own hostname (`e482380b5f23`) — which is the container ID.
That is the proof it is being served from inside the container and not from the host.

---

## 2. Python application

### `python-app/Dockerfile`

```dockerfile
FROM python:3.12-slim
WORKDIR /app
COPY app.py ./
EXPOSE 5000
CMD ["python", "app.py"]
```

`app.py` uses `http.server` from the standard library, so there is no `requirements.txt` and
no `pip install` step.

### Build and run

```bash
docker build -t hello-python:1.0 ./python-app
docker run -d --name hello-python -p 5000:5000 hello-python:1.0
curl http://localhost:5000/
```

```html
<!doctype html>
<html>
  <head><title>Python on Docker</title></head>
  <body>
    <h1>Hello World from Python!</h1>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
    <p>Served by Python in container c3f659a15d5d</p>
  </body>
</html>
```

---

## 3. Java application

### `java-app/Dockerfile`

```dockerfile
FROM eclipse-temurin:21-jdk-alpine
WORKDIR /app
COPY HelloServer.java ./
RUN javac HelloServer.java
EXPOSE 8080
CMD ["java", "HelloServer"]
```

`HelloServer.java` uses `com.sun.net.httpserver.HttpServer` from the JDK, so no Maven or
Gradle is needed. The compile happens **at image build time**, so the container starts
straight into a compiled class.

### Build and run

```bash
docker build -t hello-java:1.0 ./java-app
docker run -d --name hello-java -p 8080:8080 hello-java:1.0
curl http://localhost:8080/
```

```html
<!doctype html>
<html>
  <head><title>Java on Docker</title></head>
  <body>
    <h1>Hello World from Java!</h1>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
    <p>Served by Java 21.0.12 in container adf8499c87fd</p>
  </body>
</html>
```

```bash
docker logs hello-java
```

```
Java app listening on port 8080
```

Note this image is **552 MB** — by far the largest, because it ships a whole JDK just to run
a compiled class. That is exactly the problem multi-stage builds solve (Session 7).

---

## 4. Apache application

### `Apache-app/Dockerfile`

```dockerfile
FROM httpd:2.4-alpine
COPY index.html /usr/local/apache2/htdocs/index.html
EXPOSE 80
```

No `CMD` is needed — the official `httpd` image already starts Apache in the foreground.
The whole "application" is a static file dropped into Apache's document root at
`/usr/local/apache2/htdocs`.

### Build and run

```bash
docker build -t hello-apache:1.0 ./Apache-app
docker run -d --name hello-apache -p 8081:80 hello-apache:1.0
curl http://localhost:8081/
```

```html
<!doctype html>
<html>
  <head><title>Apache on Docker</title></head>
  <body>
    <h1>Hello World from Apache HTTP Server!</h1>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
    <p>Served by httpd from a Docker container.</p>
  </body>
</html>
```

Here the container listens on **80** but is published on host port **8081** (`-p 8081:80`),
because the nginx app also wants port 80 inside its container. This is the point of port
publishing: the port inside the container is fixed by the software, the port on the host is
your choice.

---

## 5. Nginx application

### `nginx-app/Dockerfile`

```dockerfile
FROM nginx:1.27-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

Same idea as Apache, but nginx's document root is `/usr/share/nginx/html`.

### Build and run

```bash
docker build -t hello-nginx:1.0 ./nginx-app
docker run -d --name hello-nginx -p 8082:80 hello-nginx:1.0
curl http://localhost:8082/
```

```html
<!doctype html>
<html>
  <head><title>Nginx on Docker</title></head>
  <body>
    <h1>Hello World from Nginx!</h1>
    <p>Name: Snehangshu Roy | Enrollment: 24BCS10155</p>
    <p>Served by nginx from a Docker container.</p>
  </body>
</html>
```

---

## 6. React application

This is the interesting one, because a React app is **built** by Node but **served** as
static files — so the Dockerfile uses two stages.

### `React-app/Dockerfile`

```dockerfile
# ---- Stage 1: build the React bundle ----
FROM node:20-alpine AS build
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

# ---- Stage 2: serve the static bundle with nginx ----
FROM nginx:1.27-alpine
COPY --from=build /app/dist /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

`nginx.conf` adds `try_files $uri $uri/ /index.html;` so client-side routes still resolve to
the SPA entry point instead of returning 404.

### Build and run

```bash
docker build -t hello-react:1.0 ./React-app
docker run -d --name hello-react -p 3001:80 hello-react:1.0
```

```
#12 1.478 ✓ built in 741ms
#12 DONE 1.5s

#13 [stage-1 2/3] COPY --from=build /app/dist /usr/share/nginx/html
#13 DONE 0.0s

#14 [stage-1 3/3] COPY nginx.conf /etc/nginx/conf.d/default.conf
#14 DONE 0.0s

#15 naming to docker.io/library/hello-react:1.0 done
#15 DONE 0.3s
```

### Verify

```bash
curl http://localhost:3001/
```

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>React on Docker</title>
    <script type="module" crossorigin src="/assets/index-D7gX08nC.js"></script>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
```

React renders into `<div id="root">` **in the browser**, so the HTML itself is just the
shell — the heading lives inside the compiled JavaScript bundle. Verified directly:

```bash
curl -s http://localhost:3001/assets/index-D7gX08nC.js | grep -o "Hello World from React!"
curl -s http://localhost:3001/assets/index-D7gX08nC.js | grep -o "24BCS10155"
```

```
Hello World from React!
24BCS10155
```

So the built bundle really does contain the Hello World component, and the browser renders
"**Hello World from React!**" on the page.

The payoff of the two stages: the final image is **73.8 MB** (nginx + static files). The
`node:20-alpine` build stage with `node_modules` never ships — it is thrown away after the
bundle is copied out.

---

## All containers running

```bash
docker ps
```

```
NAMES          IMAGE              STATUS              PORTS
hello-react    hello-react:1.0    Up 6 seconds        0.0.0.0:3001->80/tcp, [::]:3001->80/tcp
hello-nginx    hello-nginx:1.0    Up 23 seconds       0.0.0.0:8082->80/tcp, [::]:8082->80/tcp
hello-apache   hello-apache:1.0   Up 32 seconds       0.0.0.0:8081->80/tcp, [::]:8081->80/tcp
hello-java     hello-java:1.0     Up 40 seconds       0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
hello-python   hello-python:1.0   Up About a minute   0.0.0.0:5000->5000/tcp, [::]:5000->5000/tcp
hello-node     hello-node:1.0     Up About a minute   0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp
```

## All images built

```bash
docker images
```

```
REPOSITORY     TAG       SIZE
hello-react    1.0       73.8MB
hello-nginx    1.0       73.6MB
hello-apache   1.0       96.1MB
hello-java     1.0       552MB
hello-python   1.0       188MB
hello-node     1.0       193MB
```

### What the sizes tell us

| Image | Size | Why |
|---|---|---|
| `hello-nginx` | 73.6 MB | Alpine + nginx only |
| `hello-react` | 73.8 MB | Same nginx base + a ~200 KB JS bundle — the Node toolchain was discarded by the multi-stage build |
| `hello-apache` | 96.1 MB | Alpine + httpd |
| `hello-python` | 188 MB | `python:3.12-slim` is Debian-based, not Alpine |
| `hello-node` | 193 MB | Node runtime is large even on Alpine |
| `hello-java` | 552 MB | A full **JDK** (compiler included) shipped to production |

The two nginx-based images are the smallest, and `hello-java` is 7× larger than them. The
lesson: **choose the smallest base that can run your app, and do not ship build tools to
production.**

---

## Commands used

```bash
# build
docker build -t <image>:<tag> <path>

# run detached with a published port
docker run -d --name <name> -p <hostPort>:<containerPort> <image>:<tag>

# inspect
docker ps                 # running containers
docker ps -a              # including stopped
docker images             # local images
docker logs <name>        # container stdout/stderr
docker exec -it <name> sh # shell inside the container

# clean up
docker stop <name> && docker rm <name>
docker rmi <image>:<tag>
```

---

## Summary

| Application | Folder | Dockerfile | Image built | Container running | Hello World verified |
|---|---|---|---|---|---|
| Node.js | `nodejs-app/` | Yes | Yes | Yes | Yes |
| Python | `python-app/` | Yes | Yes | Yes | Yes |
| Java | `java-app/` | Yes | Yes | Yes | Yes |
| Apache | `Apache-app/` | Yes | Yes | Yes | Yes |
| React | `React-app/` | Yes | Yes | Yes | Yes |
| Nginx | `nginx-app/` | Yes | Yes | Yes | Yes |
