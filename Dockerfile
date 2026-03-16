# ============================
# مرحلة البناء (Build)
# ============================
FROM maven:3.9.9-eclipse-temurin-17 AS builder
WORKDIR /build

# نسخ ملفات المشروع (pom.xml أولاً)
COPY pom.xml .
COPY src ./src

# بناء التطبيق مباشرة (دون go-offline)
RUN mvn clean package -DskipTests

# ============================
# مرحلة التشغيل (Runtime)
# ============================
FROM eclipse-temurin:17-jre-jammy
WORKDIR /app

COPY --from=builder /build/target/*.war app.war
EXPOSE 8080

ENV SERVER_PORT=${PORT:-8080} \
    DUKE_USERNAME=${DUKASCOPY_USER} \
    DUKE_PASSWORD=${DUKASCOPY_PASS} \
    DB_URL=${DATABASE_URL}

CMD java -jar app.war \
    --server.port=$SERVER_PORT \
    --dukascopy.username=$DUKE_USERNAME \
    --dukascopy.password=$DUKE_PASSWORD \
    --spring.datasource.url=$DB_URL
