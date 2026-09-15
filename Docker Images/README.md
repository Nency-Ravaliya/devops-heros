# Docker Images Guide

This directory contains Dockerfile directives, image building procedures, tagging strategies, multi-stage build optimizations, image management, and Docker Hub registry workflows.

---

## Table of Contents

1. [Dockerfile Directives](#1-dockerfile-directives)
2. [Building & Tagging Images](#2-building--tagging-images)
3. [Image Management & Inspection](#3-image-management--inspection)
4. [Docker Hub & Registry Operations](#4-docker-hub--registry-operations)
5. [Multi-Stage Dockerfile Builds](#5-multi-stage-dockerfile-builds)
6. [Image Cleanup Operations](#6-image-cleanup-operations)

---

## 1. Dockerfile Directives

Understand core Dockerfile instructions used to define custom container image layers.

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
ENV PORT=3000
EXPOSE 3000
CMD ["npm", "start"]
```

---

## 2. Building & Tagging Images

Build container images from a `Dockerfile` and apply custom tags.

```bash
docker build -t my-app:v1.0 .
docker build -t my-app:latest -f Dockerfile.dev .
docker tag my-app:v1.0 username/my-app:v1.0
```

---

## 3. Image Management & Inspection

List locally cached images, inspect build history layers, and examine image metadata.

```bash
docker images
docker images -q
docker history my-app:v1.0
docker inspect my-app:v1.0
```

---

## 4. Docker Hub & Registry Operations

Authenticate with Docker Hub or custom registries to push and pull container images.

```bash
docker login
docker push username/my-app:v1.0
docker push username/my-app:latest
docker pull ubuntu:22.04
docker logout
```

---

## 5. Multi-Stage Dockerfile Builds

Optimize production image size by separating build environments from execution environments.

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine AS production
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## 6. Image Cleanup Operations

Remove dangling, unused, or specific container images from local cache.

```bash
docker rmi my-app:v1.0
docker rmi -f username/my-app:v1.0
docker rmi $(docker images -q)
docker rmi -f $(docker images -q)
docker image prune -a -f
```
