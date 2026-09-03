# Session 6-7 - Docker Homework Answers

## Folder structure completed
- `node-app/`
- `python-app/`
- `java-app/`
- `apache-app/`
- `react-app/`
- `nginx-web/`
- `multi-stage-dockerfile/`

---

## Task: Hello World applications

### 1) Node.js app
```bash
cd session6-7-docker/node-app
docker build -t hello-node .
docker run -d --name hello-node -p 3000:3000 hello-node
curl http://localhost:3000
```

### 2) Python app
```bash
cd session6-7-docker/python-app
docker build -t hello-python .
docker run -d --name hello-python -p 5000:5000 hello-python
curl http://localhost:5000
```

### 3) Java app
```bash
cd session6-7-docker/java-app
docker build -t hello-java .
docker run -d --name hello-java -p 8082:8080 hello-java
curl http://localhost:8082
```

### 4) Apache app
```bash
cd session6-7-docker/apache-app
docker build -t hello-apache .
docker run -d --name hello-apache -p 8083:80 hello-apache
curl http://localhost:8083
```

### 5) React app
```bash
cd session6-7-docker/react-app
docker build -t hello-react .
docker run -d --name hello-react -p 8084:80 hello-react
curl http://localhost:8084
```

### 6) Nginx app
```bash
cd session6-7-docker/nginx-web
docker build -t hello-nginx .
docker run -d --name hello-nginx -p 8085:80 hello-nginx
curl http://localhost:8085
```

---

## Multi-stage build task

```bash
cd session6-7-docker/multi-stage-dockerfile
docker build -t hello-multistage .
docker run -d --name hello-multistage -p 8080:8080 hello-multistage
curl http://localhost:8080
docker ps
```

Expected web output:
`Hello World from Docker multi-stage build`

---

## Deploy at least 3 apps
Done using Node.js, Python, and Java apps above.
