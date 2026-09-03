FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY HelloDocker.java .

RUN javac HelloDocker.java

EXPOSE 8080

CMD ["java", "HelloDocker"]
