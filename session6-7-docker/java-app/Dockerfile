# ---- Build stage: compile and package with Maven ----
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build

# Resolve dependencies first so this layer is cached when only source changes
COPY pom.xml .
RUN mvn -B dependency:go-offline

COPY src ./src
RUN mvn -B clean package

# ---- Runtime stage: JRE only, no build tooling in the final image ----
FROM eclipse-temurin:17-jre

WORKDIR /app
COPY --from=build /build/target/hello-world.jar app.jar

EXPOSE 8080

CMD ["java", "-jar", "app.jar"]
