# Build Stage
FROM openjdk:17-slim AS builder
WORKDIR /app
COPY Main.java .
RUN javac Main.java

# Runtime Stage
FROM openjdk:17-slim
WORKDIR /app
COPY --from=builder /app/*.class .
EXPOSE 8080
CMD ["java", "Main"]
