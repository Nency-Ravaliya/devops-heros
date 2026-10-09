# Docker Fundamentals - Hello World Web Applications

This project fulfills the homework requirements by containerizing simple "Hello World" web applications across 6 different technologies and runtimes, maintaining the exact folder structure specified.

---

## Folder Structure

```text
session6-7-docker/
├── nodejs-app/
│   ├── package.json
│   ├── server.js
│   └── Dockerfile
├── python-app/
│   ├── app.py
│   └── Dockerfile
├── java-app/
│   ├── Main.java
│   └── Dockerfile
├── Apache-app/
│   ├── index.html
│   └── Dockerfile
├── React-app/
│   ├── index.html
│   └── Dockerfile
└── nginx-app/
    ├── index.html
    └── Dockerfile
```

---

## Applications Overview & Commands

| Application | Technology | Internal Port | Host Port | Build Command | Run Command |
|---|---|---|---|---|---|
| **`nodejs-app`** | Node.js Alpine | `3000` | `3001` | `docker build -t nodejs-hello ./nodejs-app` | `docker run -d -p 3001:3000 --name nodejs-container nodejs-hello` |
| **`python-app`** | Python Alpine | `5000` | `5001` | `docker build -t python-hello ./python-app` | `docker run -d -p 5001:5000 --name python-container python-hello` |
| **`java-app`** | Java 17 Temurin | `8080` | `8082` | `docker build -t java-hello ./java-app` | `docker run -d -p 8082:8080 --name java-container java-hello` |
| **`Apache-app`** | Apache (`httpd`) | `80` | `8083` | `docker build -t apache-hello ./Apache-app` | `docker run -d -p 8083:80 --name apache-container apache-hello` |
| **`React-app`** | React + Nginx | `80` | `8084` | `docker build -t react-hello ./React-app` | `docker run -d -p 8084:80 --name react-container react-hello` |
| **`nginx-app`** | Nginx Alpine | `80` | `8085` | `docker build -t nginx-hello ./nginx-app` | `docker run -d -p 8085:80 --name nginx-container nginx-hello` |

---

## Verification & Output Testing

Run all containers and verify each web endpoint using `curl`:

### 1. Node.js Web Application
```bash
docker build -t nodejs-hello ./nodejs-app
docker run -d -p 3001:3000 --name nodejs-container nodejs-hello
curl -s http://localhost:3001 | grep "Hello World"
```
*Output:*
```html
<h1>Hello World from Node.js Docker App!</h1>
```

---

### 2. Python Web Application
```bash
docker build -t python-hello ./python-app
docker run -d -p 5001:5000 --name python-container python-hello
curl -s http://localhost:5001 | grep "Hello World"
```
*Output:*
```html
<h1>Hello World from Python Docker App!</h1>
```

---

### 3. Java Web Application
```bash
docker build -t java-hello ./java-app
docker run -d -p 8082:8080 --name java-container java-hello
curl -s http://localhost:8082 | grep "Hello World"
```
*Output:*
```html
<h1>Hello World from Java Docker App!</h1>
```

---

### 4. Apache Web Server Application
```bash
docker build -t apache-hello ./Apache-app
docker run -d -p 8083:80 --name apache-container apache-hello
curl -s http://localhost:8083 | grep "Hello World"
```
*Output:*
```html
<h1>Hello World from Apache Web Server!</h1>
```

---

### 5. React Web Application
```bash
docker build -t react-hello ./React-app
docker run -d -p 8084:80 --name react-container react-hello
curl -s http://localhost:8084 | grep "Hello World"
```
*Output:*
```html
<h1>Hello World from React Docker App!</h1>
```

---

### 6. Nginx Web Server Application
```bash
docker build -t nginx-hello ./nginx-app
docker run -d -p 8085:80 --name nginx-container nginx-hello
curl -s http://localhost:8085 | grep "Hello World"
```
*Output:*
```html
<h1>Hello World from Nginx Web Server!</h1>
```

---

## Verify All Running Containers

```bash
docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}\t{{.Ports}}"
```
*Sample Output:*
```text
NAMES               IMAGE          STATUS         PORTS
nodejs-container    nodejs-hello   Up 2 minutes   0.0.0.0:3001->3000/tcp
python-container    python-hello   Up 2 minutes   0.0.0.0:5001->5000/tcp
java-container      java-hello     Up 2 minutes   0.0.0.0:8082->8080/tcp
apache-container    apache-hello   Up 2 minutes   0.0.0.0:8083->80/tcp
react-container     react-hello    Up 2 minutes   0.0.0.0:8084->80/tcp
nginx-container     nginx-hello    Up 2 minutes   0.0.0.0:8085->80/tcp
```
