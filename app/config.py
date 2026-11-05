import os


class Settings:
    """Application settings, read from environment variables with sensible defaults."""

    def __init__(self) -> None:
        self.database_url: str = os.getenv("DATABASE_URL", "sqlite:///./tasks.db")
        self.app_name: str = "HMCTS Task API"


settings = Settings()
