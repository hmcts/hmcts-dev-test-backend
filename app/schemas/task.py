from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field, field_validator

from app.models.task import TaskStatus


class TaskCreate(BaseModel):
    """Request body for creating a task."""

    title: str = Field(..., min_length=1, max_length=255, examples=["Review case file 1234"])
    description: str | None = Field(default=None, max_length=2000)
    status: TaskStatus = TaskStatus.TODO
    due_date: datetime = Field(..., examples=["2026-11-20T14:00:00"])

    @field_validator("title")
    @classmethod
    def title_must_not_be_blank(cls, value: str) -> str:
        value = value.strip()
        if not value:
            raise ValueError("Title must not be blank")
        return value

    @field_validator("description")
    @classmethod
    def empty_description_becomes_none(cls, value: str | None) -> str | None:
        if value is None:
            return None
        value = value.strip()
        return value or None


class TaskStatusUpdate(BaseModel):
    """Request body for updating only the status of a task."""

    status: TaskStatus


class TaskResponse(BaseModel):
    """A task as returned by the API."""

    model_config = ConfigDict(from_attributes=True)

    id: int
    title: str
    description: str | None
    status: TaskStatus
    due_date: datetime
    created_at: datetime
