> **Submission for `session6-7-docker`** — Piyush Bansal.
>
> Every image below was actually built and run with Docker, and every command's output is copied in verbatim.

# Session 6 & 7 — Docker Fundamental + Dockerfiles & Images Homework

**Environment:** Docker Desktop 4.87.0 (Docker Engine 29.7.2), macOS (Apple Silicon, linux/arm64 images).

## Contents

- [Session 6: Docker Fundamental — Hello World Applications](#session-6-docker-fundamental--hello-world-applications)
  - [A bug found (and fixed) in the course's starter Python app](#a-bug-found-and-fixed-in-the-courses-starter-python-app)
  - [Build & run — all six](#build--run--all-six)
  - [Verification transcript](#verification-transcript)
- [Session 7: Dockerfiles & Images](#session-7-dockerfiles--images)
  - [Task 1 — Run Multi-Stage Dockerfile](#task-1--run-multi-stage-dockerfile)
  - [Task 2 — Documentation](#task-2--documentation)
  - [Task 3 — Docker Application Deployment](#task-3--docker-application-deployment)

---

# Session 6: Docker Fundamental — Hello World Applications

Six simple Hello World web apps, each in its own folder with its own `Dockerfile`, each built and run, each
verified to actually display "Hello World" (via `curl` for server-rendered apps, and a real browser screenshot
for the client-rendered React app).

| Folder | Stack | Port |
|---|---|---|
| [`nodejs-app/`](./nodejs-app/) | Node.js (built-in `http` module) | 3000 |
| [`python-app/`](./python-app/) | Python 3 (`http.server`) | 5000 |
| [`java-app/`](./java-app/) | Java (`com.sun.net.httpserver`) | 8000 |
| [`Apache-app/`](./Apache-app/) | Apache HTTP Server (httpd) | 80 |
| [`React-app/`](./React-app/) | React (Vite), built + served via Nginx | 80 |
| [`nginx-app/`](./nginx-app/) | Nginx serving static HTML | 80 |

## A bug found (and fixed) in the course's starter Python app

The `python-app/` folder in this repo already had a starter `Dockerfile` and `app.py` from an earlier course
commit. Testing it surfaced three problems, so this submission replaces both files:

1. `RUN apt update && apt install -y pip3 python3` — `pip3` is not a valid apt package name on Debian/Ubuntu
   (it should be `python3-pip`), so the build fails.
2. The Dockerfile does `COPY requirements.txt .` but no `requirements.txt` exists in the folder — build fails.
3. `app.py` only did `print("Hello World from Docker!")` — that prints to stdout once and exits, it never
   serves a webpage, so it can't satisfy "verify Hello World is displayed on a webpage."

The version in this submission uses `python:3.12-slim` (which already has `python3`/`pip` built in, so no
`apt install` is needed), drops the phantom `requirements.txt`, and runs a real `http.server`-based HTTP
server so the app actually serves "Hello World from Python!" on port 5000.

## Build & run — all six

```bash
docker build -t hello-nodejs-app:latest  ./nodejs-app
docker build -t hello-python-app:latest  ./python-app
docker build -t hello-java-app:latest    ./java-app
docker build -t hello-apache-app:latest  ./Apache-app   # note: image tags must be lowercase
docker build -t hello-react-app:latest   ./React-app
docker build -t hello-nginx-app:latest   ./nginx-app

docker run -d --name hw-node   -p 3001:3000 hello-nodejs-app:latest
docker run -d --name hw-python -p 5001:5000 hello-python-app:latest
docker run -d --name hw-java   -p 8001:8000 hello-java-app:latest
docker run -d --name hw-apache -p 8081:80   hello-apache-app:latest
docker run -d --name hw-react  -p 8082:80   hello-react-app:latest
docker run -d --name hw-nginx  -p 8083:80   hello-nginx-app:latest
```

## Verification transcript

```console
$ docker ps --filter "name=hw-"
CONTAINER ID   IMAGE                     COMMAND                  CREATED          STATUS          PORTS                                         NAMES
5462c742f0bf   hello-nginx-app:latest    "/docker-entrypoint.…"   15 minutes ago   Up 15 minutes   0.0.0.0:8083->80/tcp, [::]:8083->80/tcp       hw-nginx
040db4c95524   hello-react-app:latest    "/docker-entrypoint.…"   15 minutes ago   Up 15 minutes   0.0.0.0:8082->80/tcp, [::]:8082->80/tcp       hw-react
476a5ee38cf8   hello-apache-app:latest   "httpd-foreground"       15 minutes ago   Up 15 minutes   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp       hw-apache
ea19e2790d65   hello-java-app:latest     "/__cacert_entrypoin…"   15 minutes ago   Up 15 minutes   0.0.0.0:8001->8000/tcp, [::]:8001->8000/tcp   hw-java
00734dcb8b3f   hello-python-app:latest   "python3 app.py"         15 minutes ago   Up 15 minutes   0.0.0.0:5001->5000/tcp, [::]:5001->5000/tcp   hw-python
d247e19eb739   hello-nodejs-app:latest   "docker-entrypoint.s…"   15 minutes ago   Up 15 minutes   0.0.0.0:3001->3000/tcp, [::]:3001->3000/tcp   hw-node

$ curl -s http://localhost:3001/
Hello World from Node.js!

$ curl -s http://localhost:5001/
Hello World from Python!

$ curl -s http://localhost:8001/
Hello World from Java!

$ curl -s http://localhost:8081/
<!DOCTYPE html>
<html>
<head><title>Apache Hello World</title></head>
<body>
  <h1>Hello World from Apache!</h1>
</body>
</html>

$ curl -s http://localhost:8083/
<!DOCTYPE html>
<html>
<head><title>Nginx Hello World</title></head>
<body>
  <h1>Hello World from Nginx!</h1>
</body>
</html>
```

### Browser screenshots — all six, actually rendered

`curl` proves the server responds, but the task asks to verify Hello World is **displayed on a webpage** — so
each app was also opened in a real browser (headless Chrome) and screenshotted, confirming the page genuinely
renders the text, not just that the HTTP response contains it:

| App | Screenshot |
|---|---|
| Node.js | [`evidence/nodejs-app.png`](./evidence/nodejs-app.png) |
| Python | [`evidence/python-app.png`](./evidence/python-app.png) |
| Java | [`evidence/java-app.png`](./evidence/java-app.png) |
| Apache | [`evidence/apache-app.png`](./evidence/apache-app.png) |
| Nginx | [`evidence/nginx-app.png`](./evidence/nginx-app.png) |
| React | [`React-app/evidence/react-app-browser.png`](./React-app/evidence/react-app-browser.png) (see below — the only one that *needs* a browser to prove anything, since it's client-rendered) |

### React needs a browser check, not just `curl`

React renders client-side, so `curl http://localhost:8082/` only returns the empty HTML shell (`<div
id="root"></div>` plus a script tag) — the "Hello World" text isn't there yet, it's injected by JavaScript
after the page loads in a real browser:

```console
$ curl -s http://localhost:8082/
<!doctype html>
<html lang="en">
  <head>
    ...
    <script type="module" crossorigin src="/assets/index-BZzo4mV3.js"></script>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>
```

So it was verified with a real headless-Chrome screenshot of the rendered page instead:
[`React-app/evidence/react-app-browser.png`](./React-app/evidence/react-app-browser.png) — confirms "Hello
World from React!" is genuinely displayed once the JS bundle runs. As an extra confirmation, the compiled
bundle itself was checked directly:

```console
$ docker exec hw-react sh -c "cat /usr/share/nginx/html/assets/index-*.js" | grep -o "Hello World from React!"
Hello World from React!
```

---

# Session 7: Dockerfiles & Images

## Task 1 — Run Multi-Stage Dockerfile

Uses the multi-stage Dockerfile at
[`session6-7-docker/multi-stage-dockerfile/`](./multi-stage-dockerfile/) (course-provided starter, from an
earlier commit).

### A bug found (and fixed) here too

The starter `server.js` listened on port **3000** and returned `"Hello World from Docker Multi-Stage
Build!"` (capitalized, with an exclamation mark) — but the task requires port **8080** and the exact text
`"Hello World from Docker multi-stage build"`. Fixed both in `server.js` and the corresponding `EXPOSE` line
in the `Dockerfile`.

### Build & run

```console
$ docker build -t multistage-app:latest ./multi-stage-dockerfile
$ docker run -d --name multistage-container -p 8080:8080 multistage-app:latest

$ curl -s http://localhost:8080/
Hello World from Docker multi-stage build

$ docker ps --filter name=multistage-container
CONTAINER ID   IMAGE                   COMMAND                  CREATED         STATUS         PORTS                                         NAMES
6fc2e6c0fef3   multistage-app:latest   "docker-entrypoint.s…"   3 seconds ago   Up 3 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp   multistage-container
```

Confirms: the app displays exactly **"Hello World from Docker multi-stage build"**, `docker ps` shows the
container running, and it's reachable on port `8080` — all three checks the task asks for.

Browser screenshot: [`evidence/multistage-app.png`](./evidence/multistage-app.png).

## Task 2 — Documentation

- **Name:** Piyush Bansal
- **Screenshot/output showing the app running successfully:** [`evidence/multistage-app.png`](./evidence/multistage-app.png)
  (browser) and the `curl` output above (`Hello World from Docker multi-stage build`)
- **Screenshot/output of `docker ps` on port 8080:** see the `docker ps` output above

## Task 3 — Docker Application Deployment

At least 3 different app types deployed via Docker — satisfied by the Session 6 Hello World apps above:
**Node.js**, **Python**, and **Java** (plus Apache, React, and Nginx as extras).

---

# Files in this folder

| Path | Purpose |
|---|---|
| `nodejs-app/` | Node.js Hello World app + Dockerfile |
| `python-app/` | Python Hello World app + Dockerfile (fixed from the buggy starter) |
| `java-app/` | Java Hello World app + Dockerfile |
| `Apache-app/` | Apache Hello World static page + Dockerfile |
| `React-app/` | React Hello World app (Vite, multi-stage build served via Nginx) + browser screenshot |
| `nginx-app/` | Nginx Hello World static page + Dockerfile |
| `multi-stage-dockerfile/` | Course-provided multi-stage build (Session 7 Task 1) |
| `evidence/` | Browser screenshots of all six Hello World apps + the multi-stage build app |
| `README.md` | This file |
