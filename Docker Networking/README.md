# Docker Networking & Volumes Guide

This directory contains Docker networking drivers, container port publishing, custom network creation, persistent volume storage, and multi-container orchestration with Docker Compose.

---

## Table of Contents

1. [Docker Network Drivers](#1-docker-network-drivers)
2. [Port Forwarding & Publishing](#2-port-forwarding--publishing)
3. [Docker Network Management](#3-docker-network-management)
4. [Docker Volumes & Persistent Storage](#4-docker-volumes--persistent-storage)
5. [Docker Compose Orchestration](#5-docker-compose-orchestration)

---

## 1. Docker Network Drivers

Docker provides multiple network drivers to handle container-to-container and container-to-host communications:

- **bridge**: Default network driver for isolated container communication on the same host.
- **host**: Removes network isolation between the container and the Docker host.
- **none**: Disables all networking for the container.
- **overlay**: Connects multiple Docker daemons across Swarm cluster nodes.

---

## 2. Port Forwarding & Publishing

Expose container internal ports to the host interface for external accessibility.

```bash
docker run -d --name webapp -p 8080:80 nginx
docker run -d --name api -p 127.0.0.1:3000:3000 my-api
docker run -d --name random-web -P nginx
docker port webapp
```

---

## 3. Docker Network Management

Create, list, inspect, connect, and delete user-defined Docker networks.

```bash
docker network ls
docker network create --driver bridge my-custom-network
docker network inspect my-custom-network
docker run -d --name db --network my-custom-network postgres
docker network connect my-custom-network webapp
docker network disconnect my-custom-network webapp
docker network rm my-custom-network
docker network prune
```

---

## 4. Docker Volumes & Persistent Storage

Persist data beyond container lifecycle using named volumes and host bind mounts.

```bash
docker volume create my-data
docker volume ls
docker volume inspect my-data
docker run -d --name db-server -v my-data:/var/lib/postgresql/data postgres
docker run -d --name dev-app -v $(pwd):/app node:18-alpine
docker volume rm my-data
docker volume prune
```

---

## 5. Docker Compose Orchestration

Define and run multi-container applications using a `docker-compose.yml` specification.

### Example `docker-compose.yml`

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "8000:8000"
    networks:
      - app-net
    depends_on:
      - redis
  redis:
    image: redis:alpine
    networks:
      - app-net

networks:
  app-net:
    driver: bridge
```

### Docker Compose Commands

```bash
docker-compose up -d
docker-compose ps
docker-compose logs -f
docker-compose exec web sh
docker-compose down
docker-compose down -v
```
