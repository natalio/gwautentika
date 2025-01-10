FROM openjdk:17-alpine
EXPOSE 8082
ADD target/*.jar autentika-0.0.1.jar
ENTRYPOINT ["java","-jar", "autentika-0.0.1.jar"]
