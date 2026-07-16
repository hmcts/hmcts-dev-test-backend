########################################################
# This is the build stage for the project
########################################################

FROM eclipse-temurin:21-jdk-alpine AS build

WORKDIR /app

# Copy wrapper and dependency descriptors first for layer cashing
COPY gradlew build.gradle ./
COPY gradle/ gradle/

# Download the dependencies
RUN ./gradlew dependencies --no-daemon --quiet || true

# Copy the source code
COPY src/ src/

# Build the executable Spring Boot jar for the runtime stage.
# Skip tests here so the image build stays fast/reliable; we will run them in CI instead.
# --no-daemon avoids leaving a Gradle process after this layer finishes.
RUN ./gradlew bootJar --no-daemon -x test -x integration -x functional -x smoke

########################################################
# This is the runtime stage for the project
########################################################

FROM eclipse-temurin:21-jre-alpine

# Create a non-root user/group with fixed IDs so ownership stays stable across builds and mounts.
# Override at build time, e.g.:
#   docker build --build-arg APP_UID=1000 --build-arg APP_GID=1000 --build-arg APP_USER=appuser --build-arg APP_GROUP=appgroup .
ARG APP_UID=1000
ARG APP_GID=1000
ARG APP_USER=appuser
ARG APP_GROUP=appgroup
RUN addgroup -S -g ${APP_GID} ${APP_GROUP} && adduser -S -u ${APP_UID} -G ${APP_GROUP} ${APP_USER}

WORKDIR /app

# Copy the built jar file from the build stage
COPY --from=build /app/build/libs/test-backend.jar app.jar

# Chown the jar file to the app user and group
RUN chown ${APP_USER}:${APP_GROUP} app.jar

USER ${APP_USER}

# Metadata only — publish the port with docker-compose `ports:` or `docker run -p (or -P for random port)`.
ARG SERVER_PORT=4000
EXPOSE ${SERVER_PORT}

ENTRYPOINT ["java", "-jar", "app.jar"]
