# ============================
# مرحلة البناء (Build) باستخدام Java 11
# ============================
FROM maven:3.8-openjdk-11 AS builder
WORKDIR /build

# نسخ ملف POM أولاً للاستفادة من التخزين المؤقت للتبعيات
COPY pom.xml .
RUN mvn dependency:go-offline -B || true

# نسخ باقي الكود المصدري
COPY src ./src

# بناء التطبيق (إنشاء ملف WAR)
RUN mvn clean package -DskipTests

# ============================
# مرحلة التشغيل (Runtime) باستخدام Java 11
# ============================
FROM openjdk:11-jre-slim
WORKDIR /app

# نسخ ملف WAR الناتج من مرحلة البناء
COPY --from=builder /build/target/*.war app.war

# تعريف المنفذ (سيتم تجاوزه بواسطة Render عبر متغير PORT)
EXPOSE 8080

# متغيرات البيئة الافتراضية (يتم استبدالها بقيم من خدمة Render)
ENV SERVER_PORT=${PORT:-8080} \
    DUKE_USERNAME=${DUKASCOPY_USER} \
    DUKE_PASSWORD=${DUKASCOPY_PASS} \
    DB_URL=${DATABASE_URL}

# نقطة الدخول: تشغيل التطبيق مع تمرير المتغيرات
CMD java -jar app.war \
    --server.port=$SERVER_PORT \
    --dukascopy.credential-username=$DUKE_USERNAME \
    --dukascopy.credential-password=$DUKE_PASSWORD \
    --spring.datasource.url=$DB_URL
