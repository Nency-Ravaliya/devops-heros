# Docker Multi-Stage Build Homework Submission

## Student Details
- **Name:** Raghav Rathi
- **Enrollment Number:** 24bcs10033
- **Course:** DevOps Engineering & Containerization

---

## Task 1: Run Multi-Stage Dockerfile & Execution Steps

### 1. Build Multi-Stage Docker Image
```bash
cd docker_multistage
docker build -t multistage-hello-world .
```

### 2. Run Container on Port 8080
```bash
docker run -d -p 8080:8080 --name multistage-app multistage-hello-world
```

### 3. Verify Container Status with `docker ps`
```bash
docker ps
```
*Terminal Output:*
```text
CONTAINER ID   IMAGE                    COMMAND                  CREATED          STATUS          PORTS                    NAMES
a8f91b2c3d4e   multistage-hello-world   "docker-entrypoint.s…"   10 seconds ago   Up 9 seconds    0.0.0.0:8080->8080/tcp   multistage-app
```

---

## Task 2: Verification of Application Response

### HTTP Verification (`curl http://localhost:8080`)
```bash
curl http://localhost:8080
```
*Output Response:*
```html
<!DOCTYPE html>
<html>
  <head>
    <title>Multi-Stage Docker Build</title>
  </head>
  <body>
    <div class="card">
      <h1>Hello World from Docker multi-stage build</h1>
      <p>Optimized Lightweight Production Container</p>
      <div class="badge">Running on Port 8080</div>
    </div>
  </body>
</html>
```

---

## Task 3: Multi-Stage Build Concept & Image Size Optimization

### Why use Multi-Stage Builds?
1. **Size Reduction:** Build tools (compilers, build caches, devDependencies) are discarded in early stages, resulting in dramatically smaller production images (e.g. 50MB runtime vs 1GB build environment).
2. **Security:** Runtime images omit build dependencies, compiler tools, and package managers, shrinking the attack surface.
3. **Layer Caching:** Re-building stages only invalidates layers that have changed, speeding up CI/CD build pipelines.
