# Stage 1: compile with the full JDK, which carries javac and the whole
# development toolchain.
FROM eclipse-temurin:21-jdk AS builder

WORKDIR /app
COPY Main.java ./
RUN javac Main.java

# Stage 2: run on the JRE, which has no compiler. Only the compiled .class
# file crosses over - the JDK and the source never reach the shipped image.
# This is where the size saving comes from: a JRE on Alpine is a fraction of
# a Debian-based JDK.
FROM eclipse-temurin:21-jre-alpine AS production

WORKDIR /app
COPY --from=builder /app/Main.class ./

EXPOSE 8080
CMD ["java", "Main"]
