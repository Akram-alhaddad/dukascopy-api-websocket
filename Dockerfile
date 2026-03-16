# ============================
# مرحلة البناء (Build)
# ============================
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /build

# نسخ ملفات المشروع (pom.xml والكود المصدري)
COPY pom.xml .
COPY src ./src

# تحميل التبعيات وبناء المشروع بدون تشغيل الاختبارات
RUN mvn clean package -DskipTests

# ============================
# مرحلة التشغيل (Runtime)
# ============================
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# نسخ ملف WAR الناتج من مرحلة البناء
COPY --from=builder /build/target/*.war app.war

# تعريض المنفذ (سيتم تجاوزه بواسطة Render عبر متغير PORT)
EXPOSE 8080

# متغيرات البيئة الافتراضية (يتم استبدالها بقيم من Render)
ENV DUKE_USERNAME=${DUKASCOPY_USER} \
    DUKE_PASSWORD=${DUKASCOPY_PASS} \
    DB_URL=${DATABASE_URL} \
    SERVER_PORT=${PORT:-8080}

# نقطة الدخول: تشغيل التطبيق مع تمرير المتغيرات
CMD java -jar app.war \
    --server.port=$SERVER_PORT \
    --dukascopy.username=$DUKE_USERNAME \
    --dukascopy.password=$DUKE_PASSWORD \
    --spring.datasource.url=$DB_URL
