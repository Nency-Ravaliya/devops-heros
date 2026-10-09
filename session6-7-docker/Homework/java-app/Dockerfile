FROM eclipse-temurin:17-jdk-focal

# set working directory
WORKDIR /app

# copy source
COPY HelloWorld.java /app/

# compile
RUN javac HelloWorld.java

# expose port used by the app
EXPOSE 8080

# run the application
CMD ["java", "HelloWorld"]