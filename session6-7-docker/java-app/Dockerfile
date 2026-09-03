FROM eclipse-temurin:21-jdk-alpine AS builder

WORKDIR /app
COPY src ./src
RUN javac -d out src/main/java/com/example/App.java

FROM eclipse-temurin:21-jre-alpine

WORKDIR /app
COPY --from=builder /app/out ./out

EXPOSE 8080

CMD ["java", "-cp", "out", "com.example.App"]
