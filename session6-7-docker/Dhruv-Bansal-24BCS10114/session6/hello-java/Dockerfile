FROM eclipse-temurin:21-jdk-alpine AS build
WORKDIR /src
COPY Hello.java ./Hello.java
RUN javac Hello.java

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /src/Hello.class ./Hello.class
RUN addgroup -S app && adduser -S app -G app
USER app
EXPOSE 8083
CMD ["java", "Hello"]
