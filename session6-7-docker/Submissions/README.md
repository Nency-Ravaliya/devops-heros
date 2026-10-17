# Docker Fundamental — Hello World Applications

Six simple **Hello World** web applications, each in its own folder with application code and a
`Dockerfile`, built and run with Docker, and verified.

## Folder Structure

```
session6-7-docker/
├── node-app/           # Node.js                   -> localhost:3001
├── python-app/         # Python + Flask             -> localhost:5001
├── Java-App/           # Java (JDK)                 -> localhost:8081
├── Apache-App/         # Apache httpd (Alpine)      -> localhost:8082
├── React-App/          # React + Vite (multi-stage) -> localhost:8083
├── nginx-App/          # Nginx                      -> localhost:8084
├── nginx-web/          # Nginx static               -> localhost:8085
├── multi-stage-dockerfile/  # Multi-stage Node.js   -> localhost:8080
├── docker-compose-app/ # Docker Compose example
└── submissions/        # Submission scripts and docs
```

## Build Commands

```bash
# Build all images
docker build -t hw-nodejs ./node-app
docker build -t hw-python ./python-app
docker build -t hw-java   ./Java-App
docker build -t hw-apache ./Apache-App
docker build -t hw-react  ./React-App
docker build -t hw-nginx  ./nginx-App
docker build -t hw-multistage ./multi-stage-dockerfile
```

## Run Commands

```bash
# Run all containers
docker run -d --name hw-nodejs -p 3001:3000 hw-nodejs
docker run -d --name hw-python -p 5001:5000 hw-python
docker run -d --name hw-java   -p 8081:8080 hw-java
docker run -d --name hw-apache -p 8082:80   hw-apache
docker run -d --name hw-react  -p 8083:80   hw-react
docker run -d --name hw-nginx  -p 8084:80   hw-nginx
docker run -d --name hw-multistage -p 8080:8080 hw-multistage
```

---

## 1. Node.js App — `node-app/`

```javascript
// server.js
const http = require('http');
const PORT = process.env.PORT || 3000;
const server = http.createServer((req, res) => {
  res.writeHead(200, { 'Content-Type': 'text/html' });
  res.end('<h1>Hello World from Node.js!</h1>');
});
server.listen(PORT, () => console.log(`Server on port ${PORT}`));
```

```dockerfile
FROM node:24-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 3000
CMD ["npm", "start"]
```

### Web Verification Screenshot
![Node.js Web App Verification](./SS/web-nodejs.png)

## 2. Python App — `python-app/`

```python
# app.py
from flask import Flask
app = Flask(__name__)

@app.route("/")
def hello():
    return "<h1>Hello World from Python!</h1>"

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000)
```

```dockerfile
FROM python:3.10-slim
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app.py ./
EXPOSE 5000
CMD ["python", "app.py"]
```

### Web Verification Screenshot
![Python Web App Verification](./SS/web-python.png)

## 3. Java App — `Java-App/`

```java
// Main.java
import com.sun.net.httpserver.HttpServer;
import java.net.InetSocketAddress;

public class Main {
    public static void main(String[] args) throws Exception {
        HttpServer server = HttpServer.create(new InetSocketAddress(8080), 0);
        server.createContext("/", exchange -> {
            String response = "<h1>Hello World from Java!</h1>";
            exchange.sendResponseHeaders(200, response.length());
            exchange.getResponseBody().write(response.getBytes());
            exchange.getResponseBody().close();
        });
        server.start();
    }
}
```

```dockerfile
# Build Stage
FROM eclipse-temurin:17-jdk-alpine AS builder
WORKDIR /app
COPY Main.java .
RUN javac Main.java

# Runtime Stage
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/*.class .
EXPOSE 8080
CMD ["java", "Main"]
```

### Web Verification Screenshot
![Java Web App Verification](./SS/web-java.png)

## 4. Apache App — `Apache-App/`

```dockerfile
FROM httpd:2.4.66-alpine3.22
COPY index.html /usr/local/apache2/htdocs/
EXPOSE 80
```

`index.html` contains `<h1>Hello World from Apache!</h1>`.

### Web Verification Screenshot
![Apache Web App Verification](./SS/web-apache.png)

## 5. React App — `React-App/`

A **multi-stage build**: stage 1 bundles the React app with Vite, stage 2 serves with Nginx.

```dockerfile
# Stage 1: Build React static assets
FROM node:18-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Stage 2: Serve static assets with Nginx
FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

### Web Verification Screenshot
![React Web App Verification](./SS/web-react.png)

## 6. Nginx App — `nginx-App/`

```dockerfile
FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
EXPOSE 80
```

### Web Verification Screenshot
![Nginx Web App Verification](./SS/web-nginx.png)

## 7. Multi-Stage Build — `multi-stage-dockerfile/`

A **multi-stage Node.js build** demonstrating optimized production containers.

```dockerfile
FROM node:18-alpine AS builder
WORKDIR /build
COPY server.js ./
RUN echo "Building lightweight production artifact..."

FROM node:18-alpine AS runner
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
WORKDIR /app
COPY --from=builder /build/server.js ./
ENV PORT=8080
USER appuser
EXPOSE 8080
CMD ["node", "server.js"]
```

### Terminal Demonstration Screenshot
![Multi-Stage Build Demonstration](./SS/Show-multistage.jpg)

---

## Verification Scripts

```bash
# Run all apps and verify
bash submissions/show-hello-world.sh

# Run multi-stage build
bash submissions/show-multistage.sh

# Run 3 app types (Node.js, Python, Java)
bash submissions/show-three-apps.sh
```

### Three Applications Multi-Stage Deployment Proof
![Three Applications Multi-Stage Deployment](./SS/Sow-three-apps-multistage.jpg)

## Cleanup Commands

```bash
# Stop all containers
docker stop $(docker ps -q)

# Remove all containers
docker rm -f $(docker ps -aq)

# Remove all images
docker rmi -f $(docker images -q)

# Full cleanup
docker system prune -a
```
