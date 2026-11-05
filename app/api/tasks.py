from typing import Any

from fastapi import APIRouter, Depends, Response, status
from sqlalchemy.orm import Session

from app.database import get_session
from app.repositories.task_repository import TaskRepository
from app.schemas.task import TaskCreate, TaskResponse, TaskStatusUpdate
from app.services.task_service import TaskService

router = APIRouter(prefix="/tasks", tags=["Tasks"])

NOT_FOUND_RESPONSE: dict[int | str, dict[str, Any]] = {404: {"description": "Task not found"}}


def get_task_service(session: Session = Depends(get_session)) -> TaskService:
    """Build a TaskService backed by the database for the current request."""
    return TaskService(TaskRepository(session))


@router.post(
    "",
    response_model=TaskResponse,
    status_code=status.HTTP_201_CREATED,
    summary="Create a task",
)
def create_task(data: TaskCreate, service: TaskService = Depends(get_task_service)):
    return service.create_task(data)


@router.get("", response_model=list[TaskResponse], summary="Retrieve all tasks")
def list_tasks(service: TaskService = Depends(get_task_service)):
    return service.list_tasks()


@router.get(
    "/{task_id}",
    response_model=TaskResponse,
    responses=NOT_FOUND_RESPONSE,
    summary="Retrieve a task by ID",
)
def get_task(task_id: int, service: TaskService = Depends(get_task_service)):
    return service.get_task(task_id)


@router.patch(
    "/{task_id}/status",
    response_model=TaskResponse,
    responses=NOT_FOUND_RESPONSE,
    summary="Update the status of a task",
)
def update_task_status(
    task_id: int,
    data: TaskStatusUpdate,
    service: TaskService = Depends(get_task_service),
):
    return service.update_status(task_id, data.status)


@router.delete(
    "/{task_id}",
    status_code=status.HTTP_204_NO_CONTENT,
    responses=NOT_FOUND_RESPONSE,
    summary="Delete a task",
)
def delete_task(task_id: int, service: TaskService = Depends(get_task_service)):
    service.delete_task(task_id)
    return Response(status_code=status.HTTP_204_NO_CONTENT)
