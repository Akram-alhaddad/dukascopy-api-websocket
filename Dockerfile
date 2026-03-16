FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /build
COPY . .

RUN mvn clean package -DskipTests


FROM openjdk:17-jdk-slim

WORKDIR /app

COPY --from=build /build/target/dukascopy-api-websocket-1.0.war app.war

EXPOSE 7080
EXPOSE 7081

CMD ["java","-jar","app.war","--dukascopy.credential-username=DEMO2dwYGQ","--dukascopy.credential-password=dwYGQ"]
