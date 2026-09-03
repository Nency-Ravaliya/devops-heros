FROM eclipse-temurin:21-jdk

WORKDIR /app

COPY Main.java ./

EXPOSE 8080

# Java 11+ can run a single source file directly - it compiles in memory, so no
# javac step and no .class files. HttpServer comes from the JDK itself, so this
# app has no external dependencies at all.
CMD ["java", "Main.java"]
