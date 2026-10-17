# Session 7: Docker multi-stage build

Name: PENTA GUNA SAI KUMAR
Enrollment: 24BCS10070

I read `session6-7-docker/multi-stage-dockerfile` in the cloned course repository.
My version uses the built-in Node HTTP server and validates syntax in the build stage.
The runtime stage copies only the application file. In this tiny example the size
saving is small; compiled applications benefit more by leaving build tools behind.

```bash
docker build -t student-multistage ./multi-stage
docker run -d --rm --name student-multistage -p 127.0.0.1:8080:3000 student-multistage
curl http://127.0.0.1:8080
docker ps --filter name=student-multistage
docker stop student-multistage
```

The host port is 8080 and the application listens on container port 3000.
The page must contain `Hello World from Docker multi-stage build`.
The Node, Python, and Java folders are independent deployments; build and run
each as in Session 6. Verification output is in `evidence/`.

## Verification

The Python deployment built and returned Hello World.

Multi-stage Node, Node deployment and Java deployment need registry access.

Command output: [evidence/](evidence/).
