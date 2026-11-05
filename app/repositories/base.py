from abc import ABC, abstractmethod
from typing import Generic, TypeVar

T = TypeVar("T")


class BaseRepository(ABC, Generic[T]):
    """Defines how entities are stored and retrieved, independent of the storage used."""

    @abstractmethod
    def add(self, entity: T) -> T:
        """Persist a new entity and return it with its generated ID."""

    @abstractmethod
    def get(self, entity_id: int) -> T | None:
        """Return the entity with the given ID, or None if it does not exist."""

    @abstractmethod
    def list_all(self) -> list[T]:
        """Return every entity."""

    @abstractmethod
    def save(self, entity: T) -> T:
        """Persist changes made to an existing entity."""

    @abstractmethod
    def delete(self, entity: T) -> None:
        """Remove the entity."""
