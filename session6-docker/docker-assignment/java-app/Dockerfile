FROM eclipse-temurin:17-jdk

WORKDIR /app

COPY App.java .
RUN javac App.java

EXPOSE 8080

CMD ["java", "App"]