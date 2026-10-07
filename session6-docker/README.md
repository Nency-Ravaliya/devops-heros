# Session 6 - Docker Fundamentals

**Name:** Shivansh Singh

## Docker Applications

This assignment contains Docker configurations for four simple web applications.

### 1. Apache

* Docker image: `httpd:alpine`
* Port: `80`
* HTML page served using Apache.

### 2. Node.js

* Docker image: `node:18-alpine`
* Port: `3000`
* Simple HTTP server created using Node.js.

### 3. Python

* Docker image: `python:3.10-alpine`
* Port: `8000`
* Simple HTTP server using Python's built-in HTTP server.

### 4. Java

* Docker image: `eclipse-temurin:17-jdk-alpine`
* Port: `8080`
* Simple HTTP server created using Java.

## Dockerfile Concepts Used

* `FROM` - selects the base image
* `WORKDIR` - sets the working directory
* `COPY` - copies application files
* `RUN` - executes build commands
* `EXPOSE` - documents the application port
* `CMD` - starts the application

## Folder Structure

```text
docker_assignment/
├── apache/
│   ├── Dockerfile
│   └── index.html
├── java/
│   ├── Dockerfile
│   └── Server.java
├── node/
│   ├── Dockerfile
│   └── server.js
└── python/
    ├── Dockerfile
    └── index.html
```

## Conclusion

This assignment helped me understand how Dockerfiles are created for different programming environments and how applications can be packaged into Docker containers.
