# Session 06 - Docker Fundamentals

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 06 - Docker Fundamentals (Hello World apps in 6 stacks) |

## Task checklist

- [x] `nodejs-app` - Express "Hello World" + Dockerfile
- [x] `python-app` - Flask "Hello World" + Dockerfile
- [x] `java-app` - plain Java (`com.sun.net.httpserver`) built with Maven in a build stage, run on a JRE (multi-stage)
- [x] `Apache-app` - `httpd` image with a custom `index.html`
- [x] `React-app` - Vite + React build stage, served by nginx (multi-stage)
- [x] `nginx-app` - `nginx` image with a custom `index.html`
- [x] Built every image, ran every container, and used `curl` to check that each one serves "Hello World"

Environment: Docker Desktop on macOS (Apple Silicon), Docker Engine `29.7.2 linux/arm64`.
All the output below is real terminal output. Host ports 9001-9006 are used so they don't clash with other services on this machine.

## Folder layout

```
24BCS10267-ujjawal-prabhat/
├── nodejs-app/   Dockerfile, package.json, server.js
├── python-app/   Dockerfile, requirements.txt, app.py
├── java-app/     Dockerfile, pom.xml, src/main/java/com/ujjawal/HelloServer.java
├── Apache-app/   Dockerfile, index.html
├── React-app/    Dockerfile, package.json, vite.config.js, index.html, src/{main,App}.jsx
└── nginx-app/    Dockerfile, index.html
```

## What each Dockerfile does

| App | Base image(s) | Notes |
|---|---|---|
| nodejs-app | `node:24-alpine` | Copies `package.json` first so the `npm install` layer is cached, then copies `server.js`. Listens on 3000. |
| python-app | `python:3.12-slim` | `pip install --no-cache-dir` keeps the layer small. Flask binds `0.0.0.0:5000` so it can be reached from outside the container. |
| java-app | `maven:3.9-eclipse-temurin-21` → `eclipse-temurin:21-jre-alpine` | Stage 1 runs `mvn package` to build `app.jar`. Stage 2 copies only the jar onto a JRE image, so Maven and the JDK are not shipped. Listens on 8080. |
| Apache-app | `httpd:2.4-alpine` | Replaces `/usr/local/apache2/htdocs/index.html`. |
| React-app | `node:24-alpine` → `nginx:alpine` | Stage 1 runs `npm run build` (Vite) to produce `dist/`. Stage 2 serves `dist/` with nginx. Node and `node_modules` are not in the final image. |
| nginx-app | `nginx:alpine` | Replaces `/usr/share/nginx/html/index.html`. |

## Build

Run from this folder (image names must be lowercase):

```bash
docker build -t 24bcs10267/nodejs-app:1.0 nodejs-app
docker build -t 24bcs10267/python-app:1.0 python-app
docker build -t 24bcs10267/java-app:1.0   java-app
docker build -t 24bcs10267/apache-app:1.0 Apache-app
docker build -t 24bcs10267/react-app:1.0  React-app
docker build -t 24bcs10267/nginx-app:1.0  nginx-app
```

Key lines from the builds (`--progress=plain`, trimmed):

```
# python-app
#9 [4/5] RUN pip install --no-cache-dir -r requirements.txt
#9 7.245 Successfully installed blinker-1.9.0 click-8.5.0 flask-3.1.1 itsdangerous-2.2.0 jinja2-3.1.6 markupsafe-3.0.4 werkzeug-3.1.9
#10 [5/5] COPY app.py .
#11 naming to docker.io/24bcs10267/python-app:1.0 done

# java-app
#13 [build 4/6] RUN mvn -q dependency:go-offline
#13 DONE 68.6s
#15 [build 6/6] RUN mvn -q package -DskipTests
#15 DONE 1.4s
#16 [stage-1 3/3] COPY --from=build /src/target/app.jar app.jar
#17 naming to docker.io/24bcs10267/java-app:1.0 done

# React-app
#12 19.31 added 64 packages, and audited 65 packages in 19s
#14 [build 6/6] RUN npm run build
#14 0.367 vite v6.4.4 building for production...
#14 1.330 ✓ 28 modules transformed.
#14 1.405 dist/index.html                  0.34 kB │ gzip:  0.25 kB
#14 1.405 dist/assets/index-D-m5zvn1.js  224.08 kB │ gzip: 69.61 kB
#14 1.405 ✓ built in 1.02s
#15 [stage-1 2/2] COPY --from=build /app/dist /usr/share/nginx/html
#16 naming to docker.io/24bcs10267/react-app:1.0 done

# Apache-app
#7 [2/2] COPY index.html /usr/local/apache2/htdocs/index.html
#8 naming to docker.io/24bcs10267/apache-app:1.0 done

# nginx-app
#6 [2/2] COPY index.html /usr/share/nginx/html/index.html
#7 naming to docker.io/24bcs10267/nginx-app:1.0 done

# nodejs-app (layers were already cached from an earlier build of the same Dockerfile)
#7 [4/5] RUN npm install --omit=dev
#9 [5/5] COPY server.js .
#10 naming to docker.io/24bcs10267/nodejs-app:1.0 done
```

```
$ docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|24bcs10267'
REPOSITORY                                         TAG                 SIZE
24bcs10267/nginx-app                               1.0                 93MB
24bcs10267/react-app                               1.0                 93.3MB
24bcs10267/apache-app                              1.0                 115MB
24bcs10267/java-app                                1.0                 286MB
24bcs10267/python-app                              1.0                 223MB
24bcs10267/nodejs-app                              1.0                 255MB
```

The React image is only about 0.3 MB bigger than plain nginx. That is the payoff of the multi-stage build: about 64 npm packages are used in the build stage, and none of them end up in the final image.

## Run

```bash
docker run -d --name s06-nodejs -p 9001:3000 24bcs10267/nodejs-app:1.0
docker run -d --name s06-python -p 9002:5000 24bcs10267/python-app:1.0
docker run -d --name s06-java   -p 9003:8080 24bcs10267/java-app:1.0
docker run -d --name s06-apache -p 9004:80   24bcs10267/apache-app:1.0
docker run -d --name s06-react  -p 9005:80   24bcs10267/react-app:1.0
docker run -d --name s06-nginx  -p 9006:80   24bcs10267/nginx-app:1.0
```

```
$ docker ps --filter name=s06- --format 'table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}'
NAMES        IMAGE                       STATUS         PORTS
s06-nginx    24bcs10267/nginx-app:1.0    Up 4 seconds   0.0.0.0:9006->80/tcp, [::]:9006->80/tcp
s06-react    24bcs10267/react-app:1.0    Up 4 seconds   0.0.0.0:9005->80/tcp, [::]:9005->80/tcp
s06-apache   24bcs10267/apache-app:1.0   Up 4 seconds   0.0.0.0:9004->80/tcp, [::]:9004->80/tcp
s06-java     24bcs10267/java-app:1.0     Up 4 seconds   0.0.0.0:9003->8080/tcp, [::]:9003->8080/tcp
s06-python   24bcs10267/python-app:1.0   Up 5 seconds   0.0.0.0:9002->5000/tcp, [::]:9002->5000/tcp
s06-nodejs   24bcs10267/nodejs-app:1.0   Up 5 seconds   0.0.0.0:9001->3000/tcp, [::]:9001->3000/tcp
```

Container logs:

```
$ docker logs s06-nodejs
Node app listening on port 3000
$ docker logs s06-python
 * Serving Flask app 'app'
 * Debug mode: off
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
$ docker logs s06-java
Java app listening on port 8080
```

## Proof: `curl` each app

These terminal captures stand in for screenshots.

```
$ curl -s http://localhost:9001
<h1>Hello World from Node.js (Express) in Docker!</h1>

$ curl -s http://localhost:9002
<h1>Hello World from Python (Flask) in Docker!</h1>

$ curl -s http://localhost:9003
<h1>Hello World from Java in Docker!</h1>

$ curl -s http://localhost:9004
<!DOCTYPE html>
<html>
<head><title>Apache Hello</title></head>
<body>
  <h1>Hello World from Apache httpd in Docker!</h1>
  <p>Ujjawal Prabhat - 24BCS10267</p>
</body>
</html>

$ curl -s http://localhost:9005
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Hello World from React in Docker!</title>
    <script type="module" crossorigin src="/assets/index-D-m5zvn1.js"></script>
  </head>
  <body>
    <div id="root"></div>
  </body>
</html>

$ curl -s http://localhost:9006
<!DOCTYPE html>
<html>
<head><title>Nginx Hello</title></head>
<body>
  <h1>Hello World from Nginx in Docker!</h1>
  <p>Ujjawal Prabhat - 24BCS10267</p>
</body>
</html>
```

React renders the `<h1>` in the browser, so `curl` only gets the HTML shell. To check that the "Hello World" component is really served, look inside the JS bundle that nginx returns:

```
$ curl -s http://localhost:9005/assets/index-D-m5zvn1.js | grep -o 'Hello World from React in Docker!'
Hello World from React in Docker!
```

## Cleanup

```bash
docker rm -f s06-nodejs s06-python s06-java s06-apache s06-react s06-nginx
```
