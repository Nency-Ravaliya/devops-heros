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

If the Node image is already available from Session 6, the same build can use
`--build-arg NODE_IMAGE=student-node:assignment`. The default remains node:24-alpine.

The host port is 8080 and the application listens on container port 3000.
The page must contain `Hello World from Docker multi-stage build`.
The Node, Python, and Java folders are independent deployments; build and run
each as in Session 6. Verification output is in `evidence/`.

## Verification

The multi-stage image built using the locally available Node image and returned the required page on localhost:8080. Node, Python and Java deployments were also checked.

The default Node base comes from Docker Hub. For the recorded build, NODE_IMAGE was set to the previously built student-node:assignment image to avoid another registry lookup.

Command output: [evidence/](evidence/).
