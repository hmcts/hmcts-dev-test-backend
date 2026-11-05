from app.exceptions import TaskNotFoundError
from app.models.task import Task, TaskStatus
from app.repositories.base import BaseRepository
from app.schemas.task import TaskCreate


class TaskService:
    """Business logic for managing caseworker tasks."""

    def __init__(self, repository: BaseRepository[Task]) -> None:
        self._repository = repository

    def create_task(self, data: TaskCreate) -> Task:
        task = Task(
            title=data.title,
            description=data.description,
            status=data.status,
            due_date=data.due_date,
        )
        return self._repository.add(task)

    def get_task(self, task_id: int) -> Task:
        task = self._repository.get(task_id)
        if task is None:
            raise TaskNotFoundError(task_id)
        return task

    def list_tasks(self) -> list[Task]:
        return self._repository.list_all()

    def update_status(self, task_id: int, status: TaskStatus) -> Task:
        task = self.get_task(task_id)
        task.status = status
        return self._repository.save(task)

    def delete_task(self, task_id: int) -> None:
        task = self.get_task(task_id)
        self._repository.delete(task)
