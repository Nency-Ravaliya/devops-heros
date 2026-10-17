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
