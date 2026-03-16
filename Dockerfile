# ---------- مرحلة البناء ----------
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /build

# نسخ ملفات المشروع
COPY pom.xml .
COPY java ./src/java
COPY resources ./src/resources

# بناء المشروع بدون تشغيل الاختبارات
RUN mvn clean package -DskipTests

# ---------- مرحلة التشغيل ----------
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# نسخ ملف WAR النهائي من مرحلة البناء
COPY --from=builder /build/target/dukascopy-api-websocket-1.0.war app.war

# فتح البورتات المطلوبة
EXPOSE 7080
EXPOSE 7081

# بدء التطبيق
CMD ["java","-jar","app.war","--dukascopy.credential-username=DEMO2dwYGQ","--dukascopy.credential-password=dwYGQ"]
