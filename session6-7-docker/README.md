# Session 6-7 - Docker Assignment

**Name:** Anshal Kumar
**Enrollment No:** 83

All images below were actually built and run with Docker locally; verification output (docker images,
docker ps, curl responses) is captured in [`verification/`](verification/).

## Task: Hello World Applications (6 stacks)

| Folder | Stack | Image | Port mapping used | Verified response |
|---|---|---|---|---|
| [`node-app/`](node-app/) | Node.js (Express) | `hello-node` | `3001:3000` | `Hello World from Docker!` |
| [`python-app/`](python-app/) | Python (`http.server`) | `hello-python` | `5001:5000` | `Hello World from Docker (Python)!` |
| [`java-app/`](java-app/) | Java (`com.sun.net.httpserver`) | `hello-java` | `8001:8000` | `Hello World from Docker (Java)!` |
| [`apache-app/`](apache-app/) | Apache HTTP Server (`httpd`) | `hello-apache` | `8002:80` | `Hello World from Docker (Apache HTTP Server)!` |
| [`react-app/`](react-app/) | React (CDN build, served by nginx) | `hello-react` | `8003:80` | `Hello World from Docker (React)!` |
| [`nginx-web/`](nginx-web/) | Nginx (static HTML) | `hello-nginx` | `8004:80` | `Hello World from Nginx + Docker!` |

Build + run pattern used for each (example: Node):
```bash
docker build -t hello-node ./node-app
docker run -d --name hello-node-c -p 3001:3000 hello-node
curl http://localhost:3001
```

Each app was built into an image, run as a container, and verified with `curl` to confirm the "Hello
World" page actually renders. Full command transcript: [`verification/curl-verification.txt`](verification/curl-verification.txt).

Notes on choices made while filling in the missing folders (`java-app`, `apache-app`, `react-app` didn't
exist yet):
- **java-app**: no official lightweight "hello world" web framework ships with a base JDK image, so a tiny
  `com.sun.net.httpserver.HttpServer` (built into the JDK, no dependencies) serves the page. Multi-stage
  build: compiled with `eclipse-temurin:17-jdk`, run on the smaller `eclipse-temurin:17-jre`.
- **apache-app**: official `httpd:2.4-alpine` image with a static `index.html` dropped into
  `htdocs/`.
- **react-app**: a minimal React app using the React/ReactDOM UMD builds (no local Node/npm build step
  needed), served as a static file by `nginx:alpine`. The `<div id="root">` ships with the same "Hello
  World" markup already in the HTML so it renders correctly even before React hydrates it client-side.
- **python-app**: originally just printed to stdout and exited; changed to serve the same "Hello World"
  text over HTTP with Python's built-in `http.server` module so it behaves like the other web apps
  (buildable, runnable, curl-able), and added the missing `requirements.txt` (Dockerfile referenced it but
  it didn't exist, which failed the build).

---

## Task: Multi-Stage Dockerfile

[`multi-stage-dockerfile/`](multi-stage-dockerfile/) - `FROM node:24-alpine AS builder` installs deps,
`FROM node:24-alpine AS production` copies only the built app + prod deps into a clean final stage.

```bash
docker build -t hello-multistage ./multi-stage-dockerfile
docker run -d --name hello-multistage-c -p 8080:3000 hello-multistage
curl http://localhost:8080
```
```
<h1>Hello World from Docker Multi-Stage Build!</h1>
```
Confirmed running on port **8080** (host) via `docker ps`:
```
hello-multistage-c   hello-multistage   Up 2 minutes   0.0.0.0:8080->3000/tcp
```
(Container listens on 3000 internally; published to host port 8080 as required.)

Full `docker images` / `docker ps` output: [`verification/docker-ps-output.txt`](verification/docker-ps-output.txt).

---

## Task: Docker Application Deployment (min. 3 types)

Node.js, Python and Java apps above satisfy this - each built into its own image, run as its own
container, and reachable on its own port at the same time (see the combined `docker ps` output in
[`verification/docker-ps-output.txt`](verification/docker-ps-output.txt), captured while all 7 containers
were running simultaneously).

---

## Reference

- [`docker.md`](docker.md) - Docker cleanup command reference (stop/remove containers & images, `docker system prune`).
- [`docker-advance-cmd.pdf`](docker-advance-cmd.pdf), [`docker-basic-cmd.pdf`](docker-basic-cmd.pdf), [`docker-interview-qa.pdf`](docker-interview-qa.pdf) - cheat sheets used.
