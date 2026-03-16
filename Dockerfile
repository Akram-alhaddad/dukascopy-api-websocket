# مرحلة البناء
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /build

COPY pom.xml .
COPY src ./src

# بناء المشروع بدون اختبار
RUN mvn clean package -DskipTests

# مرحلة التشغيل
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

COPY --from=builder /build/target/dukascopy-api-websocket-1.0.war app.war

EXPOSE 7080
EXPOSE 7081

CMD ["java","-jar","app.war","--dukascopy.credential-username=DEMO2dwYGQ","--dukascopy.credential-password=dwYGQ"]
