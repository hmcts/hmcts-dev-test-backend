import pytest

VALID_TASK = {
    "title": "Review case file 1234",
    "description": "Check the evidence bundle",
    "due_date": "2026-12-01T09:00:00",
}


def create_task(client, **overrides) -> dict:
    response = client.post("/tasks", json={**VALID_TASK, **overrides})
    assert response.status_code == 201
    return response.json()


def test_create_task_returns_created_task(client):
    response = client.post("/tasks", json=VALID_TASK)

    assert response.status_code == 201
    body = response.json()
    assert body["id"] == 1
    assert body["title"] == "Review case file 1234"
    assert body["description"] == "Check the evidence bundle"
    assert body["status"] == "TODO"
    assert body["due_date"] == "2026-12-01T09:00:00"
    assert "created_at" in body


def test_create_task_without_description(client):
    task = create_task(client, description=None)

    assert task["description"] is None


@pytest.mark.parametrize(
    "payload",
    [
        {"due_date": "2026-12-01T09:00:00"},
        {"title": "   ", "due_date": "2026-12-01T09:00:00"},
        {"title": "No due date"},
        {"title": "Bad date", "due_date": "not-a-date"},
        {"title": "Bad status", "due_date": "2026-12-01T09:00:00", "status": "FINISHED"},
        {"title": "x" * 256, "due_date": "2026-12-01T09:00:00"},
    ],
    ids=["missing title", "blank title", "missing due date", "invalid date", "invalid status", "title too long"],
)
def test_create_task_rejects_invalid_input(client, payload):
    response = client.post("/tasks", json=payload)

    assert response.status_code == 422


def test_get_task_by_id(client):
    created = create_task(client)

    response = client.get(f"/tasks/{created['id']}")

    assert response.status_code == 200
    assert response.json() == created


def test_get_missing_task_returns_404(client):
    response = client.get("/tasks/99")

    assert response.status_code == 404
    assert response.json() == {"detail": "Task with id 99 was not found"}


def test_list_tasks(client):
    assert client.get("/tasks").json() == []

    create_task(client, title="Second", due_date="2026-12-05T09:00:00")
    create_task(client, title="First", due_date="2026-12-01T09:00:00")

    titles = [task["title"] for task in client.get("/tasks").json()]
    assert titles == ["First", "Second"]


def test_update_task_status(client):
    created = create_task(client)

    response = client.patch(f"/tasks/{created['id']}/status", json={"status": "IN_PROGRESS"})

    assert response.status_code == 200
    assert response.json()["status"] == "IN_PROGRESS"
    assert client.get(f"/tasks/{created['id']}").json()["status"] == "IN_PROGRESS"


def test_update_status_rejects_invalid_status(client):
    created = create_task(client)

    response = client.patch(f"/tasks/{created['id']}/status", json={"status": "FINISHED"})

    assert response.status_code == 422


def test_update_status_of_missing_task_returns_404(client):
    response = client.patch("/tasks/99/status", json={"status": "DONE"})

    assert response.status_code == 404


def test_delete_task(client):
    created = create_task(client)

    response = client.delete(f"/tasks/{created['id']}")

    assert response.status_code == 204
    assert client.get(f"/tasks/{created['id']}").status_code == 404


def test_delete_missing_task_returns_404(client):
    response = client.delete("/tasks/99")

    assert response.status_code == 404
