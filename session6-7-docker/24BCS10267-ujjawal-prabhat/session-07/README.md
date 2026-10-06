# Session 07 - Dockerfiles & Images (Multi-Stage Builds)

| | |
|---|---|
| **Student** | Ujjawal Prabhat |
| **Enrollment No.** | 24BCS10267 |
| **Session** | 07 - Dockerfiles & Images |

## Task checklist

- [x] **Task 1** - Build the course `multi-stage-dockerfile` example, run it on host port **8080**, check the page with `curl`, and show it in `docker ps`
- [x] **Task 2** - This README, with name, enrollment number and real command output
- [x] **Task 3** - Deploy 3 app types (Node.js, Python, Java) with multi-stage builds, and compare `docker images` sizes for single-stage vs multi-stage (done for all three)

Environment: Docker Desktop on macOS (Apple Silicon), Docker Engine `29.7.2 linux/arm64`. All output below is real and copied from the terminal (terminal captures are used instead of screenshots).

```
session6-7-docker/24BCS10267-ujjawal-prabhat/session-07/
├── README.md
├── nodejs-app/  Dockerfile (multi-stage), Dockerfile.single, package.json, tsconfig.json, src/server.ts
├── python-app/  Dockerfile (multi-stage), Dockerfile.single, requirements.txt, app.py
└── java-app/    Dockerfile (multi-stage), Dockerfile.single, pom.xml, src/main/java/com/ujjawal/HelloServer.java
```

---

## Task 1 - Course multi-stage example on port 8080

I built the course's `session6-7-docker/multi-stage-dockerfile` in place and did **not** modify it. Its Dockerfile has a `builder` stage (`npm install` + `COPY . .`) and a `production` stage that copies only `package*.json` and `server.js` and runs `npm install --omit=dev`.

First I checked that host port 8080 was free:

```
$ lsof -nP -iTCP:8080 -sTCP:LISTEN
(nothing listening on 8080)
```

```bash
# from session6-7-docker/
docker build -t 24bcs10267/multistage-hello:1.0 multi-stage-dockerfile
docker run -d --name s07-multistage -p 8080:3000 24bcs10267/multistage-hello:1.0
```

Build (key steps, `--progress=plain`):

```
#4 [builder 1/5] FROM docker.io/library/node:24-alpine@sha256:ebfe2f90462722a7a4de65e91990e97fe0d401c70e0e762c5b53302f905ec1c1
#6 [builder 2/5] WORKDIR /app
#7 [builder 3/5] COPY package*.json ./
#8 [builder 4/5] RUN npm install
#8 3.184 added 68 packages, and audited 69 packages in 3s
#9 [builder 5/5] COPY . .
#10 [production 3/5] COPY --from=builder /app/package*.json ./
#11 [production 4/5] RUN npm install --omit=dev
#11 1.435 added 68 packages, and audited 69 packages in 1s
#12 [production 5/5] COPY --from=builder /app/server.js ./
#13 naming to docker.io/24bcs10267/multistage-hello:1.0 done
```

Running container (port 8080 on the host maps to 3000 in the container):

```
$ docker ps --filter name=s07-
NAMES            IMAGE                             STATUS         PORTS
s07-java         24bcs10267/s07-java:multi         Up 4 seconds   0.0.0.0:9013->8080/tcp, [::]:9013->8080/tcp
s07-python       24bcs10267/s07-python:multi       Up 4 seconds   0.0.0.0:9012->5000/tcp, [::]:9012->5000/tcp
s07-nodejs       24bcs10267/s07-nodejs:multi       Up 4 seconds   0.0.0.0:9011->3000/tcp, [::]:9011->3000/tcp
s07-multistage   24bcs10267/multistage-hello:1.0   Up 4 seconds   0.0.0.0:8080->3000/tcp, [::]:8080->3000/tcp
```

Checking the page:

```
$ curl -s http://localhost:8080
<h1>Hello World from Docker Multi-Stage Build!</h1>

$ curl -sI http://localhost:8080 | head -5
HTTP/1.1 200 OK
X-Powered-By: Express
Content-Type: text/html; charset=utf-8
Content-Length: 51
ETag: W/"33-gCAsBJJtlso/BVPWoV3U/pWC3Ak"

$ docker logs s07-multistage

> docker-hello-world@1.0.0 start
> node server.js

Server running on port 3000
```

> Note: the assignment text says "Hello World from Docker multi-stage build". The course's `server.js` actually returns `Hello World from Docker Multi-Stage Build!` (different capitalisation, with a `!`). The output above is what the unmodified course app really serves.

Note on the course example: its two stages are the same base image (`node:24-alpine`), and both run `npm install` with the same single runtime dependency (`express`). So the multi-stage split does not save any space here (the image is 249 MB, about the same as the 255 MB single-stage `node:24-alpine` + Express image I built in Session 06). Multi-stage only helps when the build stage has something the runtime doesn't need, such as a compiler, dev dependencies or build tools. Task 3 shows that case.

---

## Task 3 - Node.js, Python and Java with multi-stage builds

Each app has a multi-stage `Dockerfile` (the one that gets deployed) and a `Dockerfile.single` that is used **only** for the size comparison.

| App | Single-stage (`Dockerfile.single`) | Multi-stage (`Dockerfile`) |
|---|---|---|
| **Node.js** (TypeScript) | `node:24`: `npm install` (TypeScript + @types) → `tsc` → run. The compiler stays in the image. | `node:24` build stage compiles TS to `dist/`. The runtime is `node:24-alpine` with **only** `dist/server.js`. No `node_modules` is needed (zero runtime deps). Runs as user `node`. |
| **Python** (Flask + Gunicorn) | `python:3.12` (full Debian with gcc and similar): `pip install` → run. | `python:3.12` stage builds a virtualenv in `/venv`. The runtime is `python:3.12-slim` with only `/venv` + `app.py`. Runs as user `appuser`. |
| **Java** (Maven, JDK 21) | `maven:3.9-eclipse-temurin-21`: `mvn package` → `java -jar target/app.jar`. Maven, the full JDK and `~/.m2` all ship. | Maven + JDK stage builds `app.jar`. The runtime is `eclipse-temurin:21-jre-alpine` with only the 3.3 KB jar. Runs as user `app`. |

### Build commands

```bash
cd session6-7-docker/24BCS10267-ujjawal-prabhat/session-07
for a in nodejs python java; do
  docker build -t 24bcs10267/s07-$a:multi  -f $a-app/Dockerfile        $a-app
  docker build -t 24bcs10267/s07-$a:single -f $a-app/Dockerfile.single $a-app
done
```

Multi-stage build steps (key lines):

```
# nodejs
#8 [build 1/6] FROM docker.io/library/node:24@sha256:22f6fe5f...
#11 [build 4/6] RUN npm install
#11 3.335 added 3 packages, and audited 4 packages in 3s
#13 [build 6/6] RUN npm run build
#5 [stage-1 1/3] FROM docker.io/library/node:24-alpine@sha256:ebfe2f90...
#14 [stage-1 3/3] COPY --from=build /app/dist ./dist
#15 naming to docker.io/24bcs10267/s07-nodejs:multi done

# python
#7 [build 1/4] FROM docker.io/library/python:3.12@sha256:2b832804...
#8 [build 2/4] RUN python -m venv /venv
#10 [build 4/4] RUN pip install --no-cache-dir -r requirements.txt
#5 [stage-1 1/5] FROM docker.io/library/python:3.12-slim@sha256:ddb0207a...
#11 [stage-1 2/5] COPY --from=build /venv /venv
#13 [stage-1 4/5] COPY app.py .
#15 naming to docker.io/24bcs10267/s07-python:multi done

# java
#7 [build 1/6] FROM docker.io/library/maven:3.9-eclipse-temurin-21@sha256:99e61abc...
#12 [build 4/6] RUN mvn -q dependency:go-offline
#14 [build 6/6] RUN mvn -q package -DskipTests
#8 [stage-1 1/4] FROM docker.io/library/eclipse-temurin:21-jre-alpine@sha256:51ab5e33...
#16 [stage-1 3/4] COPY --from=build /src/target/app.jar app.jar
#18 naming to docker.io/24bcs10267/s07-java:multi done
```

### Deploy (multi-stage images)

```bash
docker run -d --name s07-nodejs -p 9011:3000 24bcs10267/s07-nodejs:multi
docker run -d --name s07-python -p 9012:5000 24bcs10267/s07-python:multi
docker run -d --name s07-java   -p 9013:8080 24bcs10267/s07-java:multi
```

(`docker ps` for these containers is shown in Task 1 above.)

```
$ curl -s http://localhost:9011
<h1>Hello World from Node.js (TypeScript, multi-stage build)!</h1>
$ curl -s http://localhost:9012
<h1>Hello World from Python (Flask + Gunicorn, multi-stage build)!</h1>
$ curl -s http://localhost:9013
<h1>Hello World from Java (Maven, multi-stage build)!</h1>

$ docker logs s07-nodejs
Node app listening on port 3000
$ docker logs s07-python
[2026-10-06 11:09:35 +0000] [1] [INFO] Starting gunicorn 23.0.0
[2026-10-06 11:09:35 +0000] [1] [INFO] Listening at: http://0.0.0.0:5000 (1)
[2026-10-06 11:09:35 +0000] [1] [INFO] Using worker: sync
[2026-10-06 11:09:35 +0000] [7] [INFO] Booting worker with pid: 7
[2026-10-06 11:09:35 +0000] [8] [INFO] Booting worker with pid: 8
$ docker logs s07-java
Java app listening on port 8080

# all three multi-stage images run as a non-root user
$ docker exec s07-nodejs whoami; docker exec s07-python whoami; docker exec s07-java whoami
node
appuser
app
```

### Size comparison: single-stage vs multi-stage

```
$ docker images --format 'table {{.Repository}}\t{{.Tag}}\t{{.Size}}' | grep -E 'REPOSITORY|24bcs10267/(s07|multistage)'
REPOSITORY                                         TAG                 SIZE
24bcs10267/s07-java                                multi               286MB
24bcs10267/s07-java                                single              926MB
24bcs10267/s07-python                              single              1.63GB
24bcs10267/s07-python                              multi               230MB
24bcs10267/s07-nodejs                              single              1.71GB
24bcs10267/s07-nodejs                              multi               237MB
24bcs10267/multistage-hello                        1.0                 249MB
```

`docker image inspect --format '{{.Size}}'` gives the compressed content size, which is roughly what gets pushed to or pulled from a registry:

```
s07-nodejs:single      417158900
s07-nodejs:multi       62064049
s07-python:single      406237666
s07-python:multi       49624779
s07-java:single        278480297
s07-java:multi         73422329
multistage-hello:1.0   63999599
```

| App | Single-stage (disk) | Multi-stage (disk) | Reduction | Single (compressed) | Multi (compressed) |
|---|---|---|---|---|---|
| Node.js | 1.71 GB | 237 MB | **~86%** | 417 MB | 62 MB |
| Python | 1.63 GB | 230 MB | **~86%** | 406 MB | 50 MB |
| Java | 926 MB | 286 MB | **~69%** | 278 MB | 73 MB |

Docker Desktop uses the containerd image store here. `docker images` reports the unpacked size on disk, and `inspect .Size` reports the compressed layer size, which is why the two columns differ.

### Why the multi-stage images are smaller: what each image contains

```
# Node single-stage still ships the TypeScript compiler
$ docker run --rm 24bcs10267/s07-nodejs:single sh -c 'ls node_modules; du -sh node_modules'
@types
typescript
undici-types
26M	node_modules

# Node multi-stage has only the compiled JS
$ docker run --rm 24bcs10267/s07-nodejs:multi sh -c 'ls -R /app; ls /app/node_modules 2>&1'
/app:
dist

/app/dist:
server.js
ls: /app/node_modules: No such file or directory

# Java single-stage ships Maven, javac and a 48 MB Maven cache
$ docker run --rm 24bcs10267/s07-java:single sh -c 'which mvn javac; du -sh /root/.m2'
/usr/bin/mvn
/opt/java/openjdk/bin/javac
48M	/root/.m2

# Java multi-stage has a JRE only (no mvn, no javac) and the 3.3 KB jar
$ docker run --rm 24bcs10267/s07-java:multi sh -c 'which mvn javac; java -version 2>&1 | head -1; ls -la /app'
openjdk version "21.0.12.1" 2026-08-18 LTS
total 12
drwxr-xr-x 1 root root 4096 Oct  6 11:09 .
drwxr-xr-x 1 root root 4096 Oct  6 11:09 ..
-rw-r--r-- 1 root root 3345 Oct  6 11:09 app.jar

# Python single-stage includes a C compiler, multi-stage (slim) does not
$ docker run --rm 24bcs10267/s07-python:single sh -c 'which gcc; echo gcc-present=$?'
/usr/bin/gcc
gcc-present=0
$ docker run --rm 24bcs10267/s07-python:multi sh -c 'which gcc; echo gcc-present=$?'
gcc-present=1
```

### Takeaways

- A multi-stage build uses several `FROM` stages. Only the **last** stage becomes the image, and `COPY --from=<stage>` brings over just the build outputs (the jar, `dist/`, the virtualenv).
- Smaller images pull and deploy faster and have a smaller attack surface. Compilers, package managers and dev dependencies are not present in production.
- The build stage can use a large, convenient image (`maven`, `node`, `python`), while the runtime uses a minimal one (`*-alpine`, `*-slim`, a JRE instead of a JDK).
- Copying the dependency manifests (`package.json`, `pom.xml`, `requirements.txt`) before the source code keeps the dependency layers cached across code changes.

## Cleanup

```bash
docker rm -f s07-multistage s07-nodejs s07-python s07-java
```
