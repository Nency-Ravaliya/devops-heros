# Docker Images

**Name:** Shivansh Singh  
**Enrollment Number:** 24BCS10050

## Objective

The objective of this assignment is to understand Docker images and Dockerfiles by creating simple applications using Node.js, Python, Java and Nginx.

## Applications

### Node.js
- Base image: `node:18-alpine`
- Port: `3000`
- Dockerfile installs the required Node environment and runs the server.

### Python
- Base image: `python:3.10-alpine`
- Runs a simple Python application inside a container.

### Java
- Base image: `eclipse-temurin:17-jdk-alpine`
- Compiles and runs a simple Java program.

### Nginx
- Base image: `nginx:alpine`
- Serves a simple HTML Hello World page.

## Important Docker Commands

```bash
docker build -t node-app ./node
docker build -t python-app ./python
docker build -t java-app ./java
docker build -t nginx-app ./nginx