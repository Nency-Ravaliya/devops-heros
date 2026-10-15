# Session 6 & 7: Docker Fundamentals & Image Building

## Overview
This directory contains containerized applications, Dockerfiles, multi-stage builds, and docker configuration files for Sessions 6 and 7.

---

## Included Applications & Projects

1. **Python Flask Application** (`python-app/`)
   - `Dockerfile`, `app.py`, `requirements.txt`
   - Light-weight Python web application containerization.

2. **Node.js Express Server** (`nodejs-app/`)
   - `Dockerfile`, `server.js`, `package.json`
   - Express backend service running in Node environment.

3. **Multi-Stage Docker Build** (`multi-stage-dockerfile/`)
   - `Dockerfile`, `server.js`, `docker_multistage.md`
   - Optimized production image using multi-stage build pattern.

4. **React Single Page App** (`React-app/`)
   - `Dockerfile`, Vite configuration, and frontend source code.

5. **Java Application** (`java-app/`)
   - Containerized Java application with JDK/JRE runtime.

6. **Nginx & Apache Web Servers** (`nginx-app/`, `Apache-app/`)
   - Custom web server image configurations.

---

## Quick Start Commands

```bash
# Build & Run Python App
cd python-app
docker build -t python-demo .
docker run -p 5000:5000 python-demo

# Multi-Stage Build Optimization
cd multi-stage-dockerfile
docker build -t multi-stage-demo .
```
