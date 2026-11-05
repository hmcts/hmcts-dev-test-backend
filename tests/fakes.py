from datetime import datetime

from app.models.task import Task
from app.repositories.base import BaseRepository


class InMemoryTaskRepository(BaseRepository[Task]):
    """Keeps tasks in a dictionary so the service can be tested without a database."""

    def __init__(self) -> None:
        self._tasks: dict[int, Task] = {}
        self._next_id = 1

    def add(self, entity: Task) -> Task:
        entity.id = self._next_id
        entity.created_at = datetime.now()
        self._tasks[entity.id] = entity
        self._next_id += 1
        return entity

    def get(self, entity_id: int) -> Task | None:
        return self._tasks.get(entity_id)

    def list_all(self) -> list[Task]:
        return sorted(self._tasks.values(), key=lambda task: (task.due_date, task.id))

    def save(self, entity: Task) -> Task:
        self._tasks[entity.id] = entity
        return entity

    def delete(self, entity: Task) -> None:
        del self._tasks[entity.id]
