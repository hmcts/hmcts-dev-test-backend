FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /project

COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle ./
COPY config ./config

RUN ./gradlew --no-daemon --console=plain dependencies --configuration runtimeClasspath > /dev/null 2>&1 || true

COPY src ./src

RUN ./gradlew --no-daemon --console=plain assemble

FROM eclipse-temurin:21-jre-alpine AS runtime

RUN addgroup -g 1001 -S appgroup \
    && adduser -u 1001 -S appuser -G appgroup

WORKDIR /opt/app

COPY --from=build --chown=appuser:appgroup /project/build/libs/test-backend.jar ./test-backend.jar

USER appuser

EXPOSE 4000

ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75.0"

HEALTHCHECK --interval=15s --timeout=5s --start-period=60s --retries=5 \
    CMD wget --quiet --tries=1 --spider http://localhost:4000/health/readiness || exit 1

ENTRYPOINT ["java", "-jar", "/opt/app/test-backend.jar"]
