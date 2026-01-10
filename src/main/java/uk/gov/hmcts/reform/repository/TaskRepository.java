package uk.gov.hmcts.reform.dev.repository;

import org.springframework.data.jpa.repository.JpaRepository;
import uk.gov.hmcts.reform.dev.models.Task;

public interface TaskRepository extends JpaRepository<Task, Long> {
    // Basic CRUD methods inherited
}