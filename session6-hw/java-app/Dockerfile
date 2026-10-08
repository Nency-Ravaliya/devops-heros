FROM eclipse-temurin:17-jdk-alpine

WORKDIR /app

COPY HelloServer.java .

RUN javac HelloServer.java

EXPOSE 8080

CMD ["java", "HelloServer"]