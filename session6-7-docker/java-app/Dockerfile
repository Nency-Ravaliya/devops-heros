FROM eclipse-temurin:17-jdk AS builder
WORKDIR /app
COPY HelloWorld.java .
RUN javac HelloWorld.java

FROM eclipse-temurin:17-jre
WORKDIR /app
COPY --from=builder /app/HelloWorld*.class ./

EXPOSE 8000

CMD ["java", "HelloWorld"]
