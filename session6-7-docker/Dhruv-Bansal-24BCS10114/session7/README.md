# Session 7 - Dockerfiles and images

**Dhruv Bansal - 24BCS10114**

The multi-stage Dockerfile isolates dependency installation in a build stage and copies only runtime files into the final image.

```bash
docker build -t dhruv-session7-node ./multi-stage-node
docker run --rm -p 8081:8081 dhruv-session7-node
curl http://localhost:8081
docker history dhruv-session7-node
```

`docker history` makes the layer structure visible. The final stage does not contain npm's cache or development dependency installation tools.
