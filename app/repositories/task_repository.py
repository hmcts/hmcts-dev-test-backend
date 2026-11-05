from sqlalchemy import select
from sqlalchemy.orm import Session

from app.models.task import Task
from app.repositories.base import BaseRepository


class TaskRepository(BaseRepository[Task]):
    """Stores tasks in the database using SQLAlchemy."""

    def __init__(self, session: Session) -> None:
        self._session = session

    def add(self, entity: Task) -> Task:
        self._session.add(entity)
        self._session.commit()
        self._session.refresh(entity)
        return entity

    def get(self, entity_id: int) -> Task | None:
        return self._session.get(Task, entity_id)

    def list_all(self) -> list[Task]:
        statement = select(Task).order_by(Task.due_date, Task.id)
        return list(self._session.scalars(statement))

    def save(self, entity: Task) -> Task:
        self._session.commit()
        self._session.refresh(entity)
        return entity

    def delete(self, entity: Task) -> None:
        self._session.delete(entity)
        self._session.commit()
