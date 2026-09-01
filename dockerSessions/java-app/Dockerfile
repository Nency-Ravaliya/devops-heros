# -------------------------
# Stage 1: Build
# -------------------------

FROM maven:3.8.6-openjdk-11 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn clean package -DskipTests

# -------------------------
# Stage 2: Production
# -------------------------

FROM eclipse-temurin:11-jre-alpine
WORKDIR /app
COPY --from=builder app/target/todo_api-0.0.1-SNAPSHOT.jar app.jar
EXPOSE 8080
ENTRYPOINT [ "java", "-jar", "app.jar" ]