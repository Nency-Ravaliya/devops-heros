# Docker Fundamental — Hello World Applications Homework

Task: build a simple "Hello World" web app for each of Node.js, Python, Java,
Apache, React and Nginx, each in its own folder with a Dockerfile.

| Folder | Stack | Base image | Port | Serves |
|---|---|---|---|---|
| [`nodejs-app/`](nodejs-app/) | Node.js (Express) | `node:24-alpine` | 3000 | `<h1>Hello World from Node.js + Docker!</h1>` |
| [`python-app/`](python-app/) | Python (Flask) | `python:3.11-slim` | 5000 | `<h1>Hello World from Python + Docker!</h1>` |
| [`java-app/`](java-app/) | Java (`com.sun.net.httpserver`, no external deps) | `eclipse-temurin:21-jdk-alpine` | 8080 | `<h1>Hello World from Java + Docker!</h1>` |
| [`Apache-app/`](Apache-app/) | Apache HTTP Server | `httpd:latest` | 80 | `<h1>Hello World from Apache + Docker!</h1>` |
| [`React-app/`](React-app/) | React (served as a static page via nginx; React/ReactDOM loaded from a CDN so no local `npm install`/build step is required) | `nginx:alpine` | 80 | `<h1>Hello World from React + Docker!</h1>` (rendered by React into `#root`) |
| [`nginx-app/`](nginx-app/) | Nginx static site | `nginx:latest` | 80 | `<h1>Hello World from Nginx + Docker!</h1>` |

There's also a pre-existing `node-app/` and `nginx-web/` from earlier practice —
kept as-is; `nodejs-app/` and `nginx-app/` above are the ones matching this
homework's exact required folder names. `python-app/` was fixed as part of
this homework: it previously only did `print("Hello World from Docker!")`
with no web server and referenced a missing `requirements.txt`, so it
couldn't have satisfied "displayed on a webpage" or even built successfully
(`apt install -y pip3` isn't a real Debian package name). It now runs a
small Flask server on port 5000, with a `requirements.txt` added.

### Build & run each one
```bash
cd <folder-name>
docker build -t <folder-name> .
docker run -p <port>:<port> <folder-name>
# then open http://localhost:<port>
```

### Honesty note on verification
Docker isn't installed on the machine this homework was done on (checked:
`command -v docker` finds nothing), so `docker build`/`docker run` were **not
executed** here and no live screenshots were captured. Every Dockerfile and
app file was written to be minimal and correct (standard base images,
matching `EXPOSE`, no untested external dependencies beyond what the base
image or `requirements.txt`/`package.json` declares), and the commands above
are exactly what's needed to build, run and verify each one — please run
them locally (or in CI) to get the actual "Hello World on a webpage"
confirmation and screenshots for submission.
