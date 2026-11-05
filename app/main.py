from collections.abc import AsyncGenerator
from contextlib import asynccontextmanager

from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse

from app.api.tasks import router as tasks_router
from app.config import settings
from app.database import init_db
from app.exceptions import AppError


@asynccontextmanager
async def lifespan(_: FastAPI) -> AsyncGenerator[None, None]:
    init_db()
    yield


def create_app() -> FastAPI:
    app = FastAPI(
        title=settings.app_name,
        description="API for HMCTS caseworkers to create and manage their tasks.",
        version="1.0.0",
        lifespan=lifespan,
    )

    @app.exception_handler(AppError)
    async def handle_app_error(_: Request, exc: AppError) -> JSONResponse:
        return JSONResponse(status_code=exc.status_code, content={"detail": exc.message})

    @app.get("/", tags=["Health"], summary="Check the API is running")
    def root() -> dict[str, str]:
        return {"message": "HMCTS Task API is running"}

    app.include_router(tasks_router)
    return app


app = create_app()
