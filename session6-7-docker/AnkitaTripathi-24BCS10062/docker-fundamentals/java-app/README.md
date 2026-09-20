# Java Web App

Hello World web application built on the JDK's built-in `com.sun.net.httpserver`, compiled during the build with `javac`.

## Image

![Java container serving Hello World in the browser](image.png)

## Dockerfile

```dockerfile
FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY Main.java ./
RUN javac Main.java

EXPOSE 8080

CMD ["java", "Main"]
```

## Commands

Build the image from the Dockerfile:

```bash
docker build -t java-webapp .
```

Run the container and map host port `8080` to container port `8080`:

```bash
docker run -d --name java-container -p 8080:8080 java-webapp
```

### Terminal Output

![docker build, docker run, docker ps and curl for the Java app](commands.png)
