package uk.gov.hmcts.reform.dev.repositories;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import uk.gov.hmcts.reform.dev.models.Task;

/**
 * Data-access layer for {@link Task} entities. Spring Data JPA supplies the
 * standard CRUD operations (save, findById, findAll, deleteById, ...).
 */
@Repository
public interface TaskRepository extends JpaRepository<Task, Long> {
}
