# ============================
# مرحلة البناء (Build)
# ============================
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /build

# نسخ كل ملفات المشروع
COPY . .

# تحميل التبعيات وبناء المشروع بدون تشغيل الاختبارات
RUN mvn clean package -DskipTests

# ============================
# مرحلة التشغيل (Runtime)
# ============================
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# نسخ ملف WAR النهائي من مرحلة البناء
COPY --from=builder /build/target/dukascopy-api-websocket-1.0.war app.war

# فتح البورتات المطلوبة
EXPOSE 7080
EXPOSE 7081

# أمر تشغيل المشروع مع متغيرات Dukascopy من ملف .env
CMD ["sh","-c","java -jar app.war --dukascopy.credential-username=$DUKASCOPY_USER --dukascopy.credential-password=$DUKASCOPY_PASS"]
