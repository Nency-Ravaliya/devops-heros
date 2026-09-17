FROM eclipse-temurin:11-jdk-alpine AS builder
WORKDIR /app
COPY Main.java .
RUN javac Main.java

FROM eclipse-temurin:11-jre-alpine
WORKDIR /app
COPY --from=builder /app/Main.class .
COPY --from=builder /app/Main\$MyHandler.class .
EXPOSE 4003
CMD ["java", "Main"]
