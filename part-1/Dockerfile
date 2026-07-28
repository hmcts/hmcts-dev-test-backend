# Build stage uses official Gradle image with Java 21 to match the project toolchain
FROM gradle:9.6.1-jdk21-corretto AS build
WORKDIR /home/gradle/app
COPY --chown=gradle:gradle . /home/gradle/app
RUN chmod +x ./gradlew && ./gradlew build --no-daemon

# Runtime stage uses a slim JRE image with a non-root user for security
FROM eclipse-temurin:21-jre-jammy
# Create a non-root user and switch to it
RUN groupadd --system appgroup && useradd --system --gid appgroup --uid 1000 --create-home hmctsuser
WORKDIR /app
COPY --from=build /home/gradle/app/build/libs/*.jar app.jar
RUN chown -R hmctsuser:appgroup /app
USER hmctsuser
EXPOSE 4000
ENTRYPOINT ["java", "-jar", "app.jar"]
