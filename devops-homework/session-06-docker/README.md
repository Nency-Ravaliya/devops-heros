# Session 6: Docker Hello World applications

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

Each required application has its own directory and Dockerfile. Node uses its
built-in HTTP module, Python uses `http.server`, Java uses `HttpServer`, React
builds with Vite, and Apache/Nginx serve static HTML.

From this session directory:

```bash
docker build -t student-node ./nodejs-app
docker run --rm -d --name student-node -p 127.0.0.1:18001:3000 student-node
curl http://127.0.0.1:18001
docker stop student-node
```

| Folder | Image name to build | Container port | Suggested host port |
|---|---|---|---|
| nodejs-app | student-node | 3000 | 18001 |
| python-app | student-python | 8000 | 18002 |
| java-app | student-java | 8080 | 18003 |
| Apache-app | student-apache | 80 | 18004 |
| React-app | student-react | 80 | 18005 |
| nginx-app | student-nginx | 80 | 18006 |

Repeat the same build/run/curl/stop pattern for every row. A Dockerfile describes
the image; `docker run` creates a container from it. `EXPOSE` documents a port,
while `-p` actually publishes it. See `evidence/` for executed checks.

## Verification

All six Docker images built. Node, Python, Java, Apache and Nginx returned Hello World; React served its HTML and compiled Hello World application.

React uses a lockfile and Vite 7.3.7. The audit service was intermittent, so a complete fresh audit result is not claimed.

Command output: [evidence/](evidence/).
