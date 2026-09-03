# Dockerfiles & Images — Multi-Stage Build Homework

**Name:** _\<Your Name\>_
**Enrollment No.:** _\<Your Enrollment No.\>_

## Task 1: Run the Multi-Stage Dockerfile

The multi-stage [`Dockerfile`](Dockerfile) in this folder:
- **Stage 1 (`builder`)** installs all dependencies (including dev) and copies in the app source.
- **Stage 2 (`production`)** copies only `package*.json` and `server.js` from the builder stage, reinstalls with `npm install --omit=dev` (no dev dependencies in the final image), and runs the app — keeping the final image smaller than a single-stage build.

Build & run:
```bash
docker build -t multi-stage-hello .
docker run -d -p 8080:8080 --name multi-stage-hello multi-stage-hello
```

Access the app: open `http://localhost:8080` → should display **"Hello World from Docker multi-stage build"**.

Verify the container:
```bash
docker ps
```
Should show `multi-stage-hello` `Up ...` with `0.0.0.0:8080->8080/tcp`.

## Task 2: Documentation
This file. Screenshot placeholders below — replace with real output once you run the commands above (Docker isn't available on the machine this was prepared on, so these weren't captured live here):

- **Screenshot/output of the app running (`http://localhost:8080`):** _\<paste here\>_
- **Screenshot/output of `docker ps` showing the container on port 8080:** _\<paste here\>_

## Task 3: Docker Application Deployment
At least 3 different app types were deployed using Docker as part of the
"Docker Fundamental" homework in [`../HELLO_WORLD_APPS.md`](../HELLO_WORLD_APPS.md):
Node.js ([`../nodejs-app/`](../nodejs-app/)), Python ([`../python-app/`](../python-app/)),
and Java ([`../java-app/`](../java-app/)) — plus Apache, React and Nginx.

## Honesty note
Docker isn't installed in the environment this homework was prepared in
(verified: `command -v docker` finds nothing), so `docker build`/`docker run`
were not executed and the screenshots above are left as placeholders. The
`server.js`/`Dockerfile` in this folder were updated so the app listens on
port 8080 (as this task requires) and returns the exact expected text — the
commands above are ready to run as-is to produce the real output/screenshots
for submission.
