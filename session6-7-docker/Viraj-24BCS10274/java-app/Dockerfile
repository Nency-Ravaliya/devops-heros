FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /src
COPY HelloServer.java .
RUN javac HelloServer.java

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /src/HelloServer.class .
EXPOSE 8080
CMD ["java", "HelloServer"]
