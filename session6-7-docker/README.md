# Docker Fundamentals Homework: Hello World Applications

This directory contains containerized "Hello World" web applications for 6 distinct application frameworks and web servers.

## Folder & Application Structure

| Application Folder | Technology Stack | Exposed Port | Image Base |
| :--- | :--- | :--- | :--- |
| `nodejs-app/` | Node.js HTTP Server | 3000 | `node:18-alpine` |
| `python-app/` | Python `http.server` | 5000 | `python:3.10-alpine` |
| `java-app/` | Java Native `HttpServer` | 8080 | `openjdk:17-alpine` |
| `apache-app/` | Apache HTTP Server (`httpd`) | 80 | `httpd:2.4-alpine` |
| `react-app/` | React Static Web App | 80 | `nginx:alpine` |
| `nginx-app/` | Nginx Web Server | 80 | `nginx:alpine` |

---

## Build and Run Instructions

### 1. Node.js Application (`nodejs-app`)
```bash
cd nodejs-app
docker build -t nodejs-hello-world .
docker run -d -p 3000:3000 --name node-container nodejs-hello-world
curl http://localhost:3000
# Output: <h1>Hello World from Node.js Application!</h1>
```

---

### 2. Python Application (`python-app`)
```bash
cd python-app
docker build -t python-hello-world .
docker run -d -p 5000:5000 --name python-container python-hello-world
curl http://localhost:5000
# Output: <h1>Hello World from Python Application!</h1>
```

---

### 3. Java Application (`java-app`)
```bash
cd java-app
docker build -t java-hello-world .
docker run -d -p 8080:8080 --name java-container java-hello-world
curl http://localhost:8080
# Output: <h1>Hello World from Java Application!</h1>
```

---

### 4. Apache Web Server (`apache-app`)
```bash
cd apache-app
docker build -t apache-hello-world .
docker run -d -p 8081:80 --name apache-container apache-hello-world
curl http://localhost:8081
# Output: <h1>Hello World from Apache Web Server!</h1>
```

---

### 5. React Application (`react-app`)
```bash
cd react-app
docker build -t react-hello-world .
docker run -d -p 8082:80 --name react-container react-hello-world
curl http://localhost:8082
# Output: <h1>Hello World from React Application!</h1>
```

---

### 6. Nginx Web Server (`nginx-app`)
```bash
cd nginx-app
docker build -t nginx-hello-world .
docker run -d -p 8083:80 --name nginx-container nginx-hello-world
curl http://localhost:8083
# Output: <h1>Hello World from Nginx Web Server!</h1>
```

---

## Verification & Cleanup

To list running containers:
```bash
docker ps
```

To stop and clean up containers:
```bash
docker stop node-container python-container java-container apache-container react-container nginx-container
docker rm node-container python-container java-container apache-container react-container nginx-container
```
