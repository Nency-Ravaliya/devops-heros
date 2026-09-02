# Docker Homework — Hello World Applications

Six Hello World web applications, each in its own folder with a Dockerfile.

| Folder        | Stack                  | Container port | Suggested host port |
|---------------|------------------------|----------------|---------------------|
| `nodejs-app`  | Node.js 20 + Express   | 3000           | 3000                |
| `python-app`  | Python 3.11 + Flask    | 5000           | 5001                |
| `java-app`    | Java 17 (JDK HttpServer), multi-stage Maven build | 8080 | 8080 |
| `Apache-app`  | Apache HTTP Server 2.4 | 80             | 8081                |
| `React-app`   | React 18 + Vite, multi-stage build served by Nginx | 80 | 8082          |
| `nginx-app`   | Nginx 1.27             | 80             | 8083                |

## Build and run

Run each block from inside its folder.

```bash
# nodejs-app
cd nodejs-app
docker build -t hello-nodejs .
docker run -d --name hello-nodejs -p 3000:3000 hello-nodejs
# open http://localhost:3000

# python-app
cd python-app
docker build -t hello-python .
docker run -d --name hello-python -p 5001:5000 hello-python
# open http://localhost:5001

# java-app
cd java-app
docker build -t hello-java .
docker run -d --name hello-java -p 8080:8080 hello-java
# open http://localhost:8080

# Apache-app
cd Apache-app
docker build -t hello-apache .
docker run -d --name hello-apache -p 8081:80 hello-apache
# open http://localhost:8081

# React-app
cd React-app
docker build -t hello-react .
docker run -d --name hello-react -p 8082:80 hello-react
# open http://localhost:8082

# nginx-app
cd nginx-app
docker build -t hello-nginx .
docker run -d --name hello-nginx -p 8083:80 hello-nginx
# open http://localhost:8083
```

Each URL displays a **Hello World** page.

## Notes

- `python-app` is mapped to host port **5001** because macOS uses port 5000 for the
  AirPlay Receiver (AirTunes), which returns HTTP 403 and would mask the app.
  Inside the container the app still listens on 5000.
- `java-app` and `React-app` use multi-stage builds so the build tooling
  (Maven / npm) is not shipped in the final image.

## Verification status

All six images were built and run with Docker (Docker Engine 29.7.2, linux/arm64),
and every application was confirmed to serve **Hello World** over HTTP.

### Images built

```
hello-apache:latest  105MB
hello-java:latest  446MB
hello-nginx:latest  75.9MB
hello-nodejs:latest  210MB
hello-python:latest  248MB
hello-react:latest  76.1MB
```

### Running containers (`docker ps`)

```
NAMES          IMAGE          STATUS          PORTS
hello-nginx    hello-nginx    Up 47 seconds   0.0.0.0:8083->80/tcp, [::]:8083->80/tcp
hello-react    hello-react    Up 47 seconds   0.0.0.0:8082->80/tcp, [::]:8082->80/tcp
hello-apache   hello-apache   Up 47 seconds   0.0.0.0:8081->80/tcp, [::]:8081->80/tcp
hello-python   hello-python   Up 48 seconds   0.0.0.0:5001->5000/tcp, [::]:5001->5000/tcp
hello-nodejs   hello-nodejs   Up 48 seconds   0.0.0.0:3000->3000/tcp, [::]:3000->3000/tcp
hello-java     hello-java     Up 48 seconds   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

Note `hello-java` on `0.0.0.0:8080->8080/tcp`.

### HTTP verification

```
Node.js   http://localhost:3000  -> HTTP 200  Hello World: OK
Python    http://localhost:5001  -> HTTP 200  Hello World: OK
Java      http://localhost:8080  -> HTTP 200  Hello World: OK
Apache    http://localhost:8081  -> HTTP 200  Hello World: OK
React     http://localhost:8082  -> HTTP 200  Hello World: OK
Nginx     http://localhost:8083  -> HTTP 200  Hello World: OK
```

React serves a single-page app: `index.html` loads the hashed JS bundle, and the
rendered "Hello World" text lives in that bundle (verified by fetching
`/assets/index-*.js` and finding the string).

### Note on base images

The java-app runtime stage originally used `eclipse-temurin:17-jre-alpine`.
That tag is published **amd64-only**, so the build failed on Apple Silicon with
`no match for platform in manifest`. It now uses the multi-arch
`eclipse-temurin:17-jre`, which works on both arm64 and amd64.
