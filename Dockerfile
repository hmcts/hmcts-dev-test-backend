# syntax=docker/dockerfile:1.7

# ---------- Build ----------
FROM eclipse-temurin:21-jdk-jammy AS build

WORKDIR /workspace

# Build scripts first so dependency resolution is cached.
COPY gradlew ./
COPY gradle ./gradle
COPY build.gradle settings.gradle ./
RUN sed -i 's/\r$//' ./gradlew \
  && chmod +x ./gradlew \
  && (./gradlew --no-daemon --quiet dependencies || true)

COPY config ./config
COPY src ./src

# Tests and static analysis run in CI.
RUN ./gradlew --no-daemon clean bootJar

# ---------- Runtime ----------
FROM eclipse-temurin:21-jre-jammy AS runtime

# curl is used by the health check.
RUN apt-get update \
  && apt-get install -y --no-install-recommends curl \
  && rm -rf /var/lib/apt/lists/*

# Fixed UID/GID for runAsUser policies and volume mounts.
RUN groupadd --system --gid 10001 app \
  && useradd --system --uid 10001 --gid app --home-dir /app --shell /usr/sbin/nologin app

WORKDIR /app

COPY --from=build --chown=10001:10001 /workspace/build/libs/test-backend.jar /app/app.jar

USER 10001:10001

# Heap sized from the container limit rather than a fixed -Xmx.
ENV SERVER_PORT=4000 \
    JAVA_OPTS="-XX:MaxRAMPercentage=75.0 -XX:+ExitOnOutOfMemoryError"

EXPOSE 4000

HEALTHCHECK --interval=15s --timeout=5s --start-period=90s --retries=5 \
  CMD curl -fsS "http://127.0.0.1:${SERVER_PORT}/health/readiness" || exit 1

# exec keeps the JVM as PID 1 so it receives SIGTERM for graceful shutdown.
ENTRYPOINT ["/bin/sh", "-c", "exec java $JAVA_OPTS -jar /app/app.jar"]
