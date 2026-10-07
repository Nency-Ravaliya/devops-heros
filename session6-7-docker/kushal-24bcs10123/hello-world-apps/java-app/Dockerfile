# Stage 1: compile with the full JDK
FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /build
COPY src/HelloServer.java .
RUN javac HelloServer.java && jar cfe hello.jar HelloServer *.class

# Stage 2: run on the much smaller JRE image
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /build/hello.jar .
ENV PORT=8080
EXPOSE 8080
CMD ["java", "-jar", "hello.jar"]
