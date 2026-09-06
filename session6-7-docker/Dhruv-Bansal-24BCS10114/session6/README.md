# Session 6 - Docker fundamentals

**Dhruv Bansal - 24BCS10114**

This is a deliberately small Python HTTP service. The Dockerfile uses a pinned major Python image, a non-root user, and a port exposed only by the runtime command.

```bash
docker build -t dhruv-session6-python ./hello-python
docker run --rm --name session6-demo -p 8080:8080 dhruv-session6-python
curl http://localhost:8080
```

Useful inspection commands are `docker ps`, `docker logs session6-demo`, and `docker inspect session6-demo`. The container is removed automatically by `--rm` after it stops.
