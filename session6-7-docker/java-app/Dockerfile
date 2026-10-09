FROM eclipse-temurin:17-alpine
WORKDIR /app
COPY Main.java .
RUN javac Main.java
EXPOSE 8082
CMD ["java", "Main"]
