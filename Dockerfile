FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app

# RUN apk add --no-cache bash - Debug for any issues.

# Copy Gradle wrapper and configuration files first (for caching)
COPY gradle/ gradle/
COPY gradlew build.gradle ./

# Copy source code
COPY src/ src/

# Make wrapper executable and build the bootJar
RUN chmod +x gradlew && ./gradlew bootJar --no-daemon --stacktrace

# ==========================================
# Stage 2: Runtime image
# ==========================================
FROM eclipse-temurin:21-jre-alpine AS runner
WORKDIR /app

# Create non-root user
RUN addgroup -S appgroup && adduser -S appuser -G appgroup

# Copy the built JAR from the builder stage
COPY --from=builder /app/build/libs/test-backend.jar app.jar

# Ownership and security
RUN chown -R appuser:appgroup /app
USER appuser

EXPOSE 4000

ENTRYPOINT ["java", "-jar", "app.jar"]
