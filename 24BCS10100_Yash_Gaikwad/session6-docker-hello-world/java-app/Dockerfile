# ---- stage 1: compile with the JDK ----
FROM eclipse-temurin:17-jdk-alpine AS build
WORKDIR /src
COPY Main.java .
RUN javac -d /out Main.java

# ---- stage 2: run on the much smaller JRE ----
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=build /out .

EXPOSE 8080

CMD ["java", "-cp", "/app", "Main"]
