from datetime import datetime

import pytest

from app.exceptions import TaskNotFoundError
from app.models.task import TaskStatus
from app.schemas.task import TaskCreate
from app.services.task_service import TaskService
from tests.fakes import InMemoryTaskRepository


@pytest.fixture
def service() -> TaskService:
    return TaskService(InMemoryTaskRepository())


def make_task_data(**overrides) -> TaskCreate:
    data = {"title": "Review case file", "due_date": datetime(2026, 12, 1, 9, 0)}
    data.update(overrides)
    return TaskCreate(**data)


def test_create_task_assigns_id_and_defaults_status_to_todo(service):
    task = service.create_task(make_task_data())

    assert task.id == 1
    assert task.title == "Review case file"
    assert task.description is None
    assert task.status == TaskStatus.TODO


def test_get_task_returns_existing_task(service):
    created = service.create_task(make_task_data(description="Check documents"))

    assert service.get_task(created.id) is created


def test_get_task_raises_when_task_does_not_exist(service):
    with pytest.raises(TaskNotFoundError) as error:
        service.get_task(99)

    assert error.value.task_id == 99


def test_list_tasks_returns_tasks_ordered_by_due_date(service):
    later = service.create_task(make_task_data(title="Later", due_date=datetime(2026, 12, 5)))
    sooner = service.create_task(make_task_data(title="Sooner", due_date=datetime(2026, 12, 1)))

    assert service.list_tasks() == [sooner, later]


def test_update_status_changes_only_the_status(service):
    created = service.create_task(make_task_data())

    updated = service.update_status(created.id, TaskStatus.DONE)

    assert updated.status == TaskStatus.DONE
    assert updated.title == "Review case file"


def test_update_status_raises_when_task_does_not_exist(service):
    with pytest.raises(TaskNotFoundError):
        service.update_status(99, TaskStatus.DONE)


def test_delete_task_removes_it(service):
    created = service.create_task(make_task_data())

    service.delete_task(created.id)

    assert service.list_tasks() == []


def test_delete_task_raises_when_task_does_not_exist(service):
    with pytest.raises(TaskNotFoundError):
        service.delete_task(99)
