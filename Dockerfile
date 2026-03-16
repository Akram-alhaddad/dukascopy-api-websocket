# --------------------------
# مرحلة البناء (Maven)
# --------------------------
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /build

# نسخ ملفات المشروع
COPY pom.xml .
RUN mvn dependency:go-offline -B

COPY src ./src

# بناء المشروع بدون اختبارات
RUN mvn clean package -DskipTests

# --------------------------
# مرحلة التشغيل
# --------------------------
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# نسخ الملف الناتج من مرحلة البناء
COPY --from=builder /build/target/dukascopy-api-websocket-1.0.war app.war

EXPOSE 7080
EXPOSE 7081

# أمر التشغيل النهائي
CMD ["java","-jar","app.war","--dukascopy.credential-username=DEMO2dwYGQ","--dukascopy.credential-password=dwYGQ"]
