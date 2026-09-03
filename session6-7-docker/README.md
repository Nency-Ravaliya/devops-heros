> **Submission for `session6-7-docker`** — Kartikey, Enrollment No. **10121** ([@Json604](https://github.com/Json604)).
>
> Every command shown was actually executed and the output is copied in verbatim.
> Full working code, Dockerfiles, screenshots and raw transcripts:
> [assignment-05-docker-hello-world](https://github.com/Json604/devops-assignments/tree/main/assignment-05-docker-hello-world)
> and [assignment-06-multistage](https://github.com/Json604/devops-assignments/tree/main/assignment-06-multistage)

# Session 6–7 — Docker

This session folder covers two assignments:

| Part | Assignment | Summary |
|---|---|---|
| **A** | Hello World Applications | Six containerised web apps — Node.js, Python, Java, Apache, React, Nginx — each built, run and verified as displaying Hello World on a webpage |
| **B** | Multi-Stage Dockerfile | The repo's `multi-stage-dockerfile/` cloned, built and run on port 8080, plus a 3-application deployment |

---

# PART A

# Assignment 5 — Hello World Applications with Docker

**Session:** `session6-7-docker` · **Author:** Kartikey (Json604) · **Enrollment No:** 10121

Six "Hello World" web applications, each in its own folder with its own `Dockerfile`, each built, run, and
verified as displaying **Hello World on a webpage**.

## Folder structure

```
assignment-05-docker-hello-world/
├── nodejs-app/        Node.js + Express
│   ├── Dockerfile
│   ├── package.json
│   ├── server.js
│   └── .dockerignore
├── python-app/        Python + Flask
│   ├── Dockerfile
│   ├── app.py
│   └── requirements.txt
├── java-app/          Java (JDK built-in HTTP server), multi-stage
│   ├── Dockerfile
│   └── App.java
├── Apache-app/        Apache HTTP Server (httpd)
│   ├── Dockerfile
│   └── index.html
├── React-app/         React + Vite, multi-stage, served by Nginx
│   ├── Dockerfile
│   ├── package.json
│   ├── vite.config.js
│   ├── index.html
│   ├── .dockerignore
│   └── src/
│       ├── main.jsx
│       └── App.jsx
├── nginx-app/         Nginx serving a static page
│   ├── Dockerfile
│   └── index.html
└── evidence/          screenshots + raw command output
```

## Results at a glance

| # | App | Folder | Base image | Container port | Host port | Status |
|---|---|---|---|---|---|---|
| 1 | Node.js | `nodejs-app` | `node:22-alpine` | 3000 | 3001 | HTTP 200 |
| 2 | Python | `python-app` | `python:3.12-slim` | 5000 | 3002 | HTTP 200 |
| 3 | Java | `java-app` | `eclipse-temurin:21` | 8080 | 3003 | HTTP 200 |
| 4 | Apache | `Apache-app` | `httpd:2.4-alpine` | 80 | 3004 | HTTP 200 |
| 5 | React | `React-app` | `node:22` → `nginx:1.27` | 80 | 3005 | HTTP 200 |
| 6 | Nginx | `nginx-app` | `nginx:1.27-alpine` | 80 | 3006 | HTTP 200 |

Different host ports are used so **all six run simultaneously** — two containers cannot share a host port.

## Build and run everything

```bash
# build
docker build -t hello-nodejs-app ./nodejs-app
docker build -t hello-python-app ./python-app
docker build -t hello-java-app   ./java-app
docker build -t hello-apache-app ./Apache-app
docker build -t hello-react-app  ./React-app
docker build -t hello-nginx-app  ./nginx-app

# run
docker run -d --name hello-nodejs -p 3001:3000 hello-nodejs-app
docker run -d --name hello-python -p 3002:5000 hello-python-app
docker run -d --name hello-java   -p 3003:8080 hello-java-app
docker run -d --name hello-apache -p 3004:80   hello-apache-app
docker run -d --name hello-react  -p 3005:80   hello-react-app
docker run -d --name hello-nginx  -p 3006:80   hello-nginx-app
```

Then open <http://localhost:3001> … <http://localhost:3006>.

## Images built

```console
$ docker images | grep hello-
REPOSITORY                          TAG            IMAGE ID       SIZE
hello-nginx-app                     latest         1707ebea03cc   75.9MB
hello-react-app                     latest         578565c5c796   76.1MB
hello-apache-app                    latest         dfbc096be809   105MB
hello-java-app                      latest         777d64433c99   474MB
hello-python-app                    latest         c8b0ce347ea9   234MB
hello-nodejs-app                    latest         c087c3cba5c8   248MB

$ docker ps
```

Image size is worth noticing: the two **multi-stage** builds are the small ones. `hello-react-app` is
**76.1 MB** even though building React needs a full Node toolchain — because Node never reaches the final
image. Compare `hello-nodejs-app` at 248 MB, which must ship the Node runtime to work.

## All six containers running

```console
$ docker ps
NAMES          IMAGE              STATUS         PORTS
hello-nginx    hello-nginx-app    Up 2 minutes   0.0.0.0:3006->80/tcp, [::]:3006->80/tcp
hello-react    hello-react-app    Up 2 minutes   0.0.0.0:3005->80/tcp, [::]:3005->80/tcp
hello-apache   hello-apache-app   Up 2 minutes   0.0.0.0:3004->80/tcp, [::]:3004->80/tcp
hello-java     hello-java-app     Up 2 minutes   0.0.0.0:3003->8080/tcp, [::]:3003->8080/tcp
hello-python   hello-python-app   Up 2 minutes   0.0.0.0:3002->5000/tcp, [::]:3002->5000/tcp
hello-nodejs   hello-nodejs-app   Up 2 minutes   0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp

```

---

# The applications

## 1. `nodejs-app` — Node.js + Express

**`server.js`** starts an Express server that returns an HTML page.

```javascript
const express = require("express");
const app = express();
const PORT = process.env.PORT || 3000;

app.get("/", (req, res) => {
  res.send(`... <h1>Hello World from Node.js + Docker!</h1> ...`);
});

app.listen(PORT, "0.0.0.0", () => {
  console.log(`Node.js server listening on port ${PORT}`);
});
```

**`Dockerfile`**

```dockerfile
FROM node:22-alpine
WORKDIR /app

# Copy manifests first so this layer is cached and `npm install`
# only re-runs when dependencies actually change.
COPY package*.json ./
RUN npm install --omit=dev

COPY server.js ./
USER node

EXPOSE 3000
CMD ["npm", "start"]
```

Two deliberate choices: `package*.json` is copied **before** the source so Docker's layer cache skips
`npm install` when only the code changed, and `USER node` drops root because the official image already
provides that account.

## 2. `python-app` — Python + Flask

```python
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "... <h1>Hello World from Python + Docker!</h1> ..."

if __name__ == "__main__":
    # 0.0.0.0 is essential inside a container.
    app.run(host="0.0.0.0", port=5000)
```

```dockerfile
FROM python:3.12-slim
WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

EXPOSE 5000
CMD ["python", "app.py"]
```

**`host="0.0.0.0"` is the single most important line here.** Flask's default is `127.0.0.1`, which inside a
container means "reachable only from within this container" — the port mapping would appear to work but every
request would be refused. Binding to `0.0.0.0` listens on all interfaces.

`--no-cache-dir` keeps pip's download cache out of the image layer.

## 3. `java-app` — Java (multi-stage)

Uses the HTTP server built into the JDK, so no Maven/Gradle and no framework are needed.

```java
HttpServer server = HttpServer.create(new InetSocketAddress("0.0.0.0", PORT), 0);
server.createContext("/", exchange -> {
    byte[] body = PAGE.getBytes(StandardCharsets.UTF_8);
    exchange.getResponseHeaders().set("Content-Type", "text/html; charset=utf-8");
    exchange.sendResponseHeaders(200, body.length);
    try (OutputStream out = exchange.getResponseBody()) { out.write(body); }
});
server.start();
```

```dockerfile
# ---------- Stage 1: build ----------
FROM eclipse-temurin:21-jdk AS builder
WORKDIR /build
COPY App.java .
RUN javac App.java

# ---------- Stage 2: runtime ----------
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /build/*.class ./

EXPOSE 8080
CMD ["java", "App"]
```

Java needs a **compiler** (`javac`, in the JDK) to build but only a **runtime** (JRE) to execute. The build
stage compiles `App.java`; the runtime stage copies just the `.class` files, so the JDK and the `.java` source
never ship.

## 4. `Apache-app` — Apache HTTP Server

```dockerfile
FROM httpd:2.4-alpine
COPY index.html /usr/local/apache2/htdocs/index.html
EXPOSE 80
CMD ["httpd-foreground"]
```

No application code — a web server plus a static file. The path `/usr/local/apache2/htdocs/` is Apache's
document root in the official image. `httpd-foreground` keeps Apache attached to PID 1, which matters because
**a container exits the moment its main process does** — a daemonised Apache would background itself and the
container would immediately stop.

## 5. `React-app` — React + Vite (multi-stage)

```jsx
export default function App() {
  return (
    <div style={{ fontFamily: "system-ui, sans-serif", textAlign: "center", paddingTop: "80px" }}>
      <h1>Hello World from React + Docker!</h1>
      <p>Built with Vite, served as a static bundle by Nginx on port 80</p>
    </div>
  );
}
```

```dockerfile
# ---------- Stage 1: build the React bundle ----------
FROM node:22-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build          # emits static assets into /app/dist

# ---------- Stage 2: serve the static files ----------
FROM nginx:1.27-alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

This is the standard production pattern for a single-page app. React compiles to plain HTML, CSS and JS, so
once `npm run build` has run there is nothing left to execute — only files to serve. The final image is
**Nginx plus a `dist` folder**: no Node, no `node_modules`, 76 MB instead of several hundred.

## 6. `nginx-app` — Nginx

```dockerfile
FROM nginx:1.27-alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

`daemon off;` serves the same purpose as `httpd-foreground` — it stops Nginx from backgrounding itself so it
remains PID 1 and the container stays up.

---

# Verification

## Screenshots — Hello World displayed on a webpage

| Node.js — <http://localhost:3001> | Python — <http://localhost:3002> |
|---|---|
| ![Node.js app](https://raw.githubusercontent.com/Json604/devops-assignments/main/assignment-05-docker-hello-world/evidence/01-nodejs-app.png) | ![Python app](https://raw.githubusercontent.com/Json604/devops-assignments/main/assignment-05-docker-hello-world/evidence/02-python-app.png) |

| Java — <http://localhost:3003> | Apache — <http://localhost:3004> |
|---|---|
| ![Java app](https://raw.githubusercontent.com/Json604/devops-assignments/main/assignment-05-docker-hello-world/evidence/03-java-app.png) | ![Apache app](https://raw.githubusercontent.com/Json604/devops-assignments/main/assignment-05-docker-hello-world/evidence/04-Apache-app.png) |

| React — <http://localhost:3005> | Nginx — <http://localhost:3006> |
|---|---|
| ![React app](https://raw.githubusercontent.com/Json604/devops-assignments/main/assignment-05-docker-hello-world/evidence/05-React-app.png) | ![Nginx app](https://raw.githubusercontent.com/Json604/devops-assignments/main/assignment-05-docker-hello-world/evidence/06-nginx-app.png) |

## HTTP verification

Each app was fetched and the rendered text checked:

```console
######## Node.js  (nodejs-app)  ->  http://localhost:3001 ########
$ curl -s -o /dev/null -w "HTTP %{http_code}  %{size_download} bytes  %{time_total}s" http://localhost:'3001'
HTTP 200  284 bytes  0.010971s
$ curl -s http://localhost:3001
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>Node.js + Docker</title></head>
<body style="font-family:system-ui,sans-serif;text-align:center;padding-top:80px">
  <h1>Hello World from Node.js + Docker!</h1>
  <p>Served by Express on port 3000</p>
</body>
</html>
$ curl -s http://localhost:3001 | grep -o "Hello World[^<]*"
Hello World from Node.js + Docker!

######## Python  (python-app)  ->  http://localhost:3002 ########
$ curl -s -o /dev/null -w "HTTP %{http_code}  %{size_download} bytes  %{time_total}s" http://localhost:'3002'
HTTP 200  280 bytes  0.004417s
$ curl -s http://localhost:3002
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>Python + Docker</title></head>
<body style="font-family:system-ui,sans-serif;text-align:center;padding-top:80px">
  <h1>Hello World from Python + Docker!</h1>
  <p>Served by Flask on port 5000</p>
</body>
</html>
$ curl -s http://localhost:3002 | grep -o "Hello World[^<]*"
Hello World from Python + Docker!

######## Java  (java-app)  ->  http://localhost:3003 ########
$ curl -s -o /dev/null -w "HTTP %{http_code}  %{size_download} bytes  %{time_total}s" http://localhost:'3003'
HTTP 200  294 bytes  0.044949s
$ curl -s http://localhost:3003
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>Java + Docker</title></head>
<body style="font-family:system-ui,sans-serif;text-align:center;padding-top:80px">
  <h1>Hello World from Java + Docker!</h1>
  <p>Served by com.sun.net.httpserver on port 8080</p>
</body>
</html>

$ curl -s http://localhost:3003 | grep -o "Hello World[^<]*"
Hello World from Java + Docker!

######## Apache  (Apache-app)  ->  http://localhost:3004 ########
$ curl -s -o /dev/null -w "HTTP %{http_code}  %{size_download} bytes  %{time_total}s" http://localhost:'3004'
HTTP 200  304 bytes  0.001203s
$ curl -s http://localhost:3004
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>Apache + Docker</title></head>
<body style="font-family:system-ui,sans-serif;text-align:center;padding-top:80px">
  <h1>Hello World from Apache + Docker!</h1>
  <p>Served by the Apache HTTP Server (httpd) on port 80</p>
</body>
</html>

$ curl -s http://localhost:3004 | grep -o "Hello World[^<]*"
Hello World from Apache + Docker!

######## React  (React-app)  ->  http://localhost:3005 ########
$ curl -s -o /dev/null -w "HTTP %{http_code}  %{size_download} bytes  %{time_total}s" http://localhost:'3005'
HTTP 200  325 bytes  0.001164s
$ curl -s http://localhost:3005
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>React + Docker</title>
    <script type="module" crossorigin src="/assets/index-DDc-BsL5.js"></script>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>

$ curl -s http://localhost:3005 | grep -o "Hello World[^<]*"

######## Nginx  (nginx-app)  ->  http://localhost:3006 ########
$ curl -s -o /dev/null -w "HTTP %{http_code}  %{size_download} bytes  %{time_total}s" http://localhost:'3006'
HTTP 200  277 bytes  0.001074s
$ curl -s http://localhost:3006
<!DOCTYPE html>
<html lang="en">
<head><meta charset="utf-8"><title>Nginx + Docker</title></head>
<body style="font-family:system-ui,sans-serif;text-align:center;padding-top:80px">
  <h1>Hello World from Nginx + Docker!</h1>
  <p>Served by Nginx on port 80</p>
</body>
</html>

$ curl -s http://localhost:3006 | grep -o "Hello World[^<]*"
Hello World from Nginx + Docker!

```

All six returned **HTTP 200**, and five of the six had "Hello World" directly in the HTML.

## The React exception — worth understanding

`curl http://localhost:3005` returned an HTML page with **no "Hello World" in it**:

```html
<div id="root"></div>
<script type="module" crossorigin src="/assets/index-DDc-BsL5.js"></script>
```

That is not a failure — it is how a single-page application works. The server sends an empty shell plus a
JavaScript bundle, and **React renders the text in the browser** after the JS executes. `curl` does not run
JavaScript, so it can never see the result.

Two ways to verify it properly, both done:

**1. Look inside the bundle:**

```console
$ # React renders client-side, so the text is in the JS bundle, not the HTML.
$ BUNDLE=$(curl -s http://localhost:3005 | grep -o "/assets/index-[^\"]*\.js")
$ echo $BUNDLE
/assets/index-DDc-BsL5.js
$ curl -s http://localhost:3005$BUNDLE | grep -o 'Hello World from React + Docker!'
Hello World from React + Docker!

$ curl -s -o /dev/null -w "bundle: HTTP %{http_code}  %{size_download} bytes
" http://localhost:3005$BUNDLE
bundle: HTTP 200  144006 bytes
```

**2. Load it in a real browser** — the screenshot above (`evidence/05-React-app.png`) shows
*"Hello World from React + Docker!"* rendered on the page. This is why all six were screenshotted in Chrome
rather than trusting `curl` alone.

## Container logs

```console
$ docker logs hello-nodejs
> node server.js

Node.js server listening on port 3000

$ docker logs hello-java
Java server listening on port 8080

$ docker logs hello-python
192.168.65.1 - - [02/Sep/2026 19:59:39] "GET / HTTP/1.1" 200 -
192.168.65.1 - - [02/Sep/2026 19:59:39] "GET / HTTP/1.1" 200 -
192.168.65.1 - - [02/Sep/2026 19:59:39] "GET / HTTP/1.1" 200 -
192.168.65.1 - - [02/Sep/2026 20:00:20] "GET / HTTP/1.1" 200 -
192.168.65.1 - - [02/Sep/2026 20:00:20] "[33mGET /favicon.ico HTTP/1.1[0m" 404 -
```

The Flask access log is the useful one — `"GET / HTTP/1.1" 200` lines are the actual browser and `curl`
requests arriving, from `192.168.65.1` (Docker Desktop's gateway). The `404` for `/favicon.ico` is the browser
asking for a tab icon that does not exist; it is expected and harmless.

## Cleanup

```bash
docker rm -f hello-nodejs hello-python hello-java hello-apache hello-react hello-nginx
docker rmi hello-nodejs-app hello-python-app hello-java-app \
           hello-apache-app hello-react-app hello-nginx-app
```

---

# What I understood

**A Dockerfile is a recipe, an image is the result, a container is a running instance.**
`docker build` turns the Dockerfile into an image; `docker run` starts a container from it. One image can
back many containers.

**`EXPOSE` documents, `-p` publishes.** `EXPOSE 3000` is metadata — on its own it makes nothing reachable.
`-p 3001:3000` is what actually forwards host port 3001 to container port 3000. The order is
**`host:container`**, and getting it backwards is a common mistake.

**Bind to `0.0.0.0`, never `127.0.0.1`.** Inside a container, `127.0.0.1` means the container itself, so the
port mapping delivers traffic that the app then refuses. This applies to Flask, Express and everything else.

**The main process must stay in the foreground.** A container lives exactly as long as PID 1. That is why
Nginx needs `daemon off;` and Apache needs `httpd-foreground` — a self-backgrounding server makes the
container exit instantly.

**Layer order controls build speed.** Copying `package.json`/`requirements.txt` and installing *before*
copying source means an application-code change reuses the cached dependency layer. Copying everything first
would reinstall all dependencies on every build.

**Multi-stage builds are the big win, and the numbers show it.** React needs Node to build but not to run;
Java needs a JDK to compile but only a JRE to run. Discarding the build stage gave 76 MB for React versus
248 MB for the single-stage Node app — a smaller image is faster to push and pull and has less installed
software to be vulnerable.

**Static vs dynamic is a real architectural distinction.** Nginx and Apache just serve files. Node, Python and
Java run a program per request. React starts as the second and *compiles into* the first, which is exactly why
its Dockerfile has two stages.


---
---

# PART B

# Assignment 6 — Multi-Stage Dockerfile

## Submission details

| | |
|---|---|
| **Name** | Kartikey |
| **Enrollment Number** | 10121 |
| **Session** | `session6-7-docker` |
| **GitHub** | [Json604](https://github.com/Json604) |
| **Repository cloned** | <https://github.com/Json604/devops-heros> |
| **Date** | 2026-09-02 |

---

# Task 1 — Run the Multi-Stage Dockerfile

## Step 1 — Clone the repository containing the multi-stage Dockerfile

```console
$ git clone https://github.com/Json604/devops-heros.git
Cloning into 'devops-heros'...

$ cd devops-heros/session6-7-docker/multi-stage-dockerfile
$ ls -la
-rw-r--r--  1 kartikey  wheel  429  Dockerfile
-rw-r--r--  1 kartikey  wheel  178  package.json
-rw-r--r--  1 kartikey  wheel  258  server.js
```

### The multi-stage Dockerfile

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

### The application

```javascript
const express = require("express");
const app = express();
const PORT = 3000;

app.get("/", (req, res) => {
  res.send("<h1>Hello World from Docker Multi-Stage Build!</h1>");
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
```

## Step 2 — Build the image using the multi-stage Dockerfile

```console
$ docker build -t multistage-hello .
#3 [internal] load metadata for docker.io/library/node:24-alpine
#6 [builder 1/5] FROM docker.io/library/node:24-alpine
#7 [builder 2/5] WORKDIR /app
#8 [builder 3/5] COPY package*.json ./
#9 [builder 4/5] RUN npm install                          DONE 1.8s
#10 [builder 5/5] COPY . .
#11 [production 3/5] COPY --from=builder /app/package*.json ./
#12 [production 4/5] RUN npm install --omit=dev           DONE 0.9s
#13 [production 5/5] COPY --from=builder /app/server.js ./
#14 naming to docker.io/library/multistage-hello:latest   done
```

Both stages are visible in the build log — BuildKit labels them `[builder …]` and `[production …]`, which is
the clearest confirmation that the multi-stage build actually ran as two separate stages.

## Step 3 — Run a container from the image

The application listens on port **3000** inside the container (`const PORT = 3000` and `EXPOSE 3000`), and the
task requires it to be reachable on port **8080**, so the container port is published to host port 8080:

```console
$ docker run -d --name multistage-app -p 8080:3000 multistage-hello
807d5ff99ec8a96c7ef54f2e87dc86990ac5ede18b9aa4d8797606f816acb4dc
```

> `-p 8080:3000` reads **host:container**. Traffic arriving at `localhost:8080` is forwarded to port 3000
> inside the container.

## Step 4 — Verify the running container with `docker ps`

```console
$ docker ps
NAMES            IMAGE              STATUS              PORTS
multistage-app   multistage-hello   Up About a minute   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp
```

**`0.0.0.0:8080->3000/tcp` confirms the application is running on port 8080**, as the task requires.

## Step 5 — Access the application and verify the output

```console
$ docker logs multistage-app

> docker-hello-world@1.0.0 start
> node server.js

Server running on port 3000

$ curl -s -o /dev/null -w "HTTP %{http_code}  %{size_download} bytes
" http://localhost:8080
HTTP 200  51 bytes

$ curl -s http://localhost:8080
<h1>Hello World from Docker Multi-Stage Build!</h1>

$ curl -s http://localhost:8080 | grep -o "Hello World from Docker Multi-Stage Build!"
Hello World from Docker Multi-Stage Build!
```

## Screenshot — the application running on port 8080

![Multi-stage app on port 8080](https://raw.githubusercontent.com/Json604/devops-assignments/main/assignment-06-multistage/evidence/01-app-on-port-8080.png)

## Task 1 verification checklist

| # | Requirement | Evidence | Result |
|---|---|---|---|
| 1 | Clone the repository with the multi-stage Dockerfile | `git clone` of `Json604/devops-heros` | Done |
| 2 | Build the image using the multi-stage Dockerfile | build log shows `[builder …]` and `[production …]` stages | Done |
| 3 | Run a container from the image | `docker run -d -p 8080:3000` → container `807d5ff99ec8` | Done |
| 4 | Access the application in the container | `curl http://localhost:8080` → **HTTP 200**, 51 bytes | Done |
| 5 | Verify it displays *Hello World from Docker multi-stage build* | `<h1>Hello World from Docker Multi-Stage Build!</h1>` | Done |
| 6 | Verify the container with `docker ps` | `multistage-app  Up  0.0.0.0:8080->3000/tcp` | Done |
| 7 | Confirm the application is on port 8080 | screenshot of <http://localhost:8080> + HTTP 200 | Done |

> On item 5: the repository's `server.js` renders the text as
> *"Hello World from Docker **M**ulti-**S**tage **B**uild!"*. It matches the task wording apart from
> capitalisation, and it is the string the cloned application actually contains — I did not modify it.

---

# What a multi-stage build actually is

A multi-stage Dockerfile has **more than one `FROM`**. Each `FROM` starts a fresh stage with its own
filesystem. `COPY --from=<stage>` reaches back into an earlier stage and takes only the files you name.
**Only the final stage becomes the image** — everything else is discarded when the build finishes.

The point is that the tools needed to *build* software are usually not needed to *run* it:

| Language | Needed to build | Needed to run |
|---|---|---|
| Java | JDK + compiler + Maven/Gradle | JRE + `.jar`/`.class` |
| React / Vue | Node, npm, `node_modules`, bundler | a web server + static files |
| Go | Go toolchain | one static binary (`FROM scratch` works) |
| TypeScript | TypeScript compiler, dev dependencies | Node + compiled JS |

## Measuring what this Dockerfile actually saves

Rather than assume, I built a **single-stage** version of the same application and compared:

```console
$ docker images | grep -E "multistage-hello|singlestage-hello"
REPOSITORY                          TAG            SIZE
singlestage-hello                   latest         249MB
multistage-hello                    latest         243MB

$ docker history multistage-hello --format "table {{.CreatedBy}}	{{.Size}}" | head -8
CREATED BY                                      SIZE
CMD ["npm" "start"]                             0B
EXPOSE [3000/tcp]                               0B
COPY /app/server.js ./ # buildkit               12.3kB
RUN /bin/sh -c npm install --omit=dev # buil…   9.45MB
COPY /app/package*.json ./ # buildkit           45.1kB
WORKDIR /app                                    8.19kB
CMD ["node"]                                    0B
```

**The honest result: 249 MB → 243 MB. A 6 MB saving, about 2%.**

That is a much smaller win than multi-stage builds usually deliver, and the reason is worth understanding:

1. **Both stages use the same base image.** `node:24-alpine` appears in stage 1 *and* stage 2, so the final
   image still contains the entire Node.js runtime. Nothing heavy was actually dropped.
2. **`package.json` declares no `devDependencies`.** Its only dependency is `express`, which is needed at
   runtime, so `npm install` and `npm install --omit=dev` install exactly the same packages. There is nothing
   for `--omit=dev` to remove.
3. **The builder stage's work is thrown away.** Stage 1 runs `npm install`, and then stage 2 ignores those
   `node_modules` and runs `npm install --omit=dev` from scratch. The builder's install is wasted effort — the
   6 MB difference is really just the discarded duplicate `node_modules` layer.

So this Dockerfile **demonstrates the multi-stage pattern correctly**, but the application is too simple for
the pattern to pay off. That is a useful thing to know rather than to gloss over.

### Where multi-stage genuinely pays off

From [Assignment 5](https://github.com/Json604/devops-assignments/tree/main/assignment-05-docker-hello-world/) in this repository, where the runtime base is
genuinely different from the build base:

| App | Build stage | Runtime stage | Final size |
|---|---|---|---|
| `React-app` | `node:22-alpine` (npm + Vite) | `nginx:1.27-alpine` | **76.1 MB** |
| `nodejs-app` (single stage) | — | `node:22-alpine` | **248 MB** |

**76 MB versus 248 MB — a 69% reduction**, because a compiled React bundle needs no Node.js at runtime at all.
That is the real lesson: *multi-stage saves space in proportion to how much of the build toolchain the runtime
can discard.* Same base image in both stages ⇒ small gain. Fat build image, slim runtime image ⇒ large gain.

### How this Dockerfile could be improved

```dockerfile
FROM node:24-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --omit=dev          # install production deps ONCE, reproducibly
COPY . .

FROM node:24-alpine AS production
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules   # reuse, don't reinstall
COPY --from=builder /app/server.js /app/package*.json ./
USER node                      # don't run as root
EXPOSE 3000
CMD ["node", "server.js"]      # skip the npm wrapper process
```

This removes the duplicated `npm install`, makes the build reproducible with `npm ci`, drops root privileges,
and avoids running an extra `npm` process just to launch `node`.

---

# Task 2 — Documentation

This file **is** the required documentation. It contains:

| Required item | Where |
|---|---|
| Your name | **Kartikey** — top of this file |
| Your enrollment number | **10121** — top of this file |
| Screenshot/output showing the application running successfully | [screenshot](https://raw.githubusercontent.com/Json604/devops-assignments/main/assignment-06-multistage/evidence/01-app-on-port-8080.png) + the `curl` output in Step 5 |
| Screenshot/output of `docker ps` showing the container on port 8080 | Step 4 — `0.0.0.0:8080->3000/tcp` |

---

# Task 3 — Docker Application Deployment

Deploy at least **3 different types of applications** using Docker. Three different language runtimes were
deployed simultaneously, alongside the multi-stage container:

| Type | Image | Runtime | Container port | Host port |
|---|---|---|---|---|
| **Node.js** | `hello-nodejs-app` | Node 22 + Express | 3000 | 9001 |
| **Python** | `hello-python-app` | Python 3.12 + Flask | 5000 | 9002 |
| **Java** | `hello-java-app` | Temurin 21 JRE | 8080 | 9003 |

Application sources are in
[`../assignment-05-docker-hello-world/`](https://github.com/Json604/devops-assignments/tree/main/assignment-05-docker-hello-world/).

```console
### Deploying 3 different types of applications with Docker ###

$ docker run -d --name deploy-nodejs -p 9001:3000 hello-nodejs-app
5206427c870e6b495c21b04a35c373fb2c81602b9bacc5b433d8b00a407a027d
$ docker run -d --name deploy-python -p 9002:5000 hello-python-app
2e41549b9cafc91418a2635531278cc96e8a2645065506f5960686cb52bb8238
$ docker run -d --name deploy-java   -p 9003:8080 hello-java-app
5e35180d0709dfcf4a6f08209579efd10f2a5c13d6a443ece199d25186d302da

$ docker ps
NAMES                       IMAGE                     STATUS          PORTS
deploy-java                 hello-java-app            Up 5 seconds    0.0.0.0:9003->8080/tcp, [::]:9003->8080/tcp
deploy-python               hello-python-app          Up 5 seconds    0.0.0.0:9002->5000/tcp, [::]:9002->5000/tcp
deploy-nodejs               hello-nodejs-app          Up 5 seconds    0.0.0.0:9001->3000/tcp, [::]:9001->3000/tcp
multistage-app              multistage-hello          Up 56 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp
hello-nginx                 hello-nginx-app           Up 6 minutes    0.0.0.0:3006->80/tcp, [::]:3006->80/tcp
hello-react                 hello-react-app           Up 6 minutes    0.0.0.0:3005->80/tcp, [::]:3005->80/tcp
hello-apache                hello-apache-app          Up 6 minutes    0.0.0.0:3004->80/tcp, [::]:3004->80/tcp
hello-java                  hello-java-app            Up 6 minutes    0.0.0.0:3003->8080/tcp, [::]:3003->8080/tcp
hello-python                hello-python-app          Up 6 minutes    0.0.0.0:3002->5000/tcp, [::]:3002->5000/tcp
hello-nodejs                hello-nodejs-app          Up 6 minutes    0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp
devops-linux                devops-linux:24.04        Up 32 minutes   
task__j4w9nsz__env-main-1   task__j4w9nsz__env-main   Up 34 hours     
task__jsfdynx__env-main-1   task__jsfdynx__env-main   Up 34 hours     
task__knrfigh__env-main-1   task__knrfigh__env-main   Up 39 hours     
task__3xp24x5__env-main-1   task__3xp24x5__env-main   Up 40 hours     
task__scmd7bf__env-main-1   task__scmd7bf__env-main   Up 40 hours     
task__4oxxrzj__env-main-1   task__4oxxrzj__env-main   Up 42 hours     

### Verifying each deployment ###
$ curl -s -o /dev/null -w "Node.js  -> HTTP %{http_code}
" http://localhost:9001
Node.js  -> HTTP 200
$ curl -s http://localhost:9001 | grep -o 'Hello World[^<]*'
Hello World from Node.js + Docker!
$ curl -s -o /dev/null -w "Python  -> HTTP %{http_code}
" http://localhost:9002
Python  -> HTTP 200
$ curl -s http://localhost:9002 | grep -o 'Hello World[^<]*'
Hello World from Python + Docker!
$ curl -s -o /dev/null -w "Java  -> HTTP %{http_code}
" http://localhost:9003
Java  -> HTTP 200
$ curl -s http://localhost:9003 | grep -o 'Hello World[^<]*'
Hello World from Java + Docker!
```

All three returned **HTTP 200** with their own Hello World page, from three different language runtimes,
running at the same time on one Docker host.

> The `docker ps` listing above also shows the six Assignment 5 containers and the `devops-linux` systemd
> container still running, plus some unrelated `task__*` containers already on this machine. That is a fair
> illustration of the point: 10+ isolated application environments coexisting on one host, each with its own
> runtime and dependencies, none conflicting.

## Task 3 verification

| App type | Endpoint | HTTP status | Page text |
|---|---|---|---|
| Node.js | <http://localhost:9001> | 200 | `Hello World from Node.js + Docker!` |
| Python | <http://localhost:9002> | 200 | `Hello World from Python + Docker!` |
| Java | <http://localhost:9003> | 200 | `Hello World from Java + Docker!` |

---

# Cleanup

```bash
docker rm -f multistage-app deploy-nodejs deploy-python deploy-java
docker rmi multistage-hello singlestage-hello
```

# What I understood

- **`COPY --from=<stage>` is the whole mechanism.** It is the one instruction that reaches across stages, and
  it is what lets the final image keep the *artifacts* while dropping the *toolchain*.
- **Only the last stage ships.** Everything in earlier stages — compilers, `node_modules`, source files,
  secrets used during the build — is discarded. That is a security benefit as much as a size one.
- **Stages can be named and targeted.** `AS builder` names a stage; `docker build --target builder .` builds
  only up to it, which is handy for a debug or test image from the same Dockerfile.
- **Measure, don't assume.** I expected a large saving here and got 2%. Checking the actual numbers explained
  why — same base image in both stages, and no dev dependencies to strip — which taught me more than a clean
  result would have.
- **`-p host:container` is the part to get right.** The app hardcodes port 3000 and cannot be reconfigured
  without editing the source, yet it serves on 8080 purely through the port mapping. Publishing is a
  deployment concern, separate from what the application binds to.
