# ============================
# مرحلة البناء (Build)
# ============================
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /build

# نسخ ملفات المشروع (pom.xml أولاً لتحسين التخزين المؤقت للتبعيات)
COPY pom.xml .
RUN mvn dependency:go-offline -B

# نسخ باقي الكود المصدري
COPY src ./src

# بناء التطبيق (إنشاء ملف WAR)
RUN mvn clean package -DskipTests

# ============================
# مرحلة التشغيل (Runtime)
# ============================
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

# نسخ ملف WAR الناتج من مرحلة البناء (باستخدام wildcard لمرونة الاسم)
COPY --from=builder /build/target/*.war app.war

# تعريف المنافذ التي قد يستخدمها التطبيق (سيتم تجاوزها بواسطة Render)
EXPOSE 8080

# متغيرات البيئة الافتراضية (يتم استبدالها بقيم من خدمة Render)
ENV SERVER_PORT=${PORT:-8080} \
    DUKE_USERNAME=${DUKASCOPY_USER} \
    DUKE_PASSWORD=${DUKASCOPY_PASS} \
    DB_URL=${DATABASE_URL}

# نقطة الدخول: تشغيل التطبيق مع تمرير المتغيرات
CMD java -jar app.war \
    --server.port=$SERVER_PORT \
    --dukascopy.username=$DUKE_USERNAME \
    --dukascopy.password=$DUKE_PASSWORD \
    --spring.datasource.url=$DB_URL
