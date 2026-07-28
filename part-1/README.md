# How to run part 1 — Database Wiring & Containerisation

This folder contains the Part 1 Docker setup for the backend service.

## Prerequisites

- Docker installed and working.
- `docker compose` available.
- A `.env` file in this folder with the required service values. See sample from `.env.sample`

## Setup

1. Copy the sample env file:

   ```bash
   cd part-1
   cp .env.sample .env
   ```

2. Edit `part-1/.env` and set the database and app ports, plus the database credentials:

   ```env
   SERVER_PORT=4000
   DB_PORT=5432

   DB_NAME=<insert_db_name>
   DB_USER_NAME=<insert_db_user_name>
   DB_PASSWORD=<insert_db_password>
   ```

## Build and run

From the repository root:

```bash
cd part-1
docker compose build
docker compose up
```

If you want to start in detached mode:

```bash
docker compose up -d
```

## What this does

- Builds the app image using the parent repository as the build context.
- Starts a PostgreSQL container.
- Starts the app container and exposes it on the host port defined by `SERVER_PORT`.
- Uses the `.env` file to supply `DB_PORT`, `DB_NAME`, `DB_USER_NAME`, and `DB_PASSWORD`.

## Health check

The app exposes a health endpoint at:

```text
http://localhost:${SERVER_PORT}/health
```

Docker Compose will use this endpoint for the app health check.

## Notes

- The `docker-compose.yaml` file in `part-1` is configured to build from `..` so the Gradle wrapper and project sources are available.
- Keep `.env` out of Git; the repository root already ignores it via `.gitignore`.
