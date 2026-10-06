# Session 6 and 7 — Docker Hello World

Student: Viraj Bhanage, roll 24BCS10274  
Enrollment number: `24BCS10274`

## Applications

| Folder | Stack | Page text |
|---|---|---|
| `nodejs-app` | Node.js + Express | Hello World |
| `python-app` | Python HTTP server | Hello World |
| `java-app` | Java `HttpServer` | Hello World |
| `Apache-app` | Apache `httpd` | Hello World |
| `React-app` | React + Vite, multi-stage Nginx | Hello World |
| `nginx-app` | Nginx | Hello World |
| `multi-stage-app` | Node multi-stage build on port 8080 | Hello World from Docker multi-stage build |

Docker Desktop was started and every image was built and run on this machine. The pages responded with Hello World. The multi-stage app on port 8080 returned `Hello World from Docker multi-stage build`, and `docker ps` showed `0.0.0.0:8080->8080/tcp`.

Evidence: [evidence/README.md](evidence/README.md) and [evidence/running-output.txt](evidence/running-output.txt).

The containers were stopped after the capture. Run `./build-and-run.sh` again if the form still wants browser screenshots, and save those pictures in `screenshots/`.

## What a multi-stage build is doing

`multi-stage-app/Dockerfile` uses a `build` stage and a final `node:22-alpine` stage. The final image copies only `package.json` and `server.js`. The build tools and any extra files stay behind in the discarded stage. The container listens on port 8080, which is the port the homework asks you to prove with `docker ps`.
