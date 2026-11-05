class AppError(Exception):
    """Base class for errors the API turns into a JSON error response."""

    status_code: int = 500

    def __init__(self, message: str) -> None:
        super().__init__(message)
        self.message = message


class TaskNotFoundError(AppError):
    """Raised when a task with the given ID does not exist."""

    status_code = 404

    def __init__(self, task_id: int) -> None:
        super().__init__(f"Task with id {task_id} was not found")
        self.task_id = task_id
