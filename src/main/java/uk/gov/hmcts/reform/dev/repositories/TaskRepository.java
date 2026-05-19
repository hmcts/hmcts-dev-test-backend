package uk.gov.hmcts.reform.dev.repositories;

import uk.gov.hmcts.reform.dev.models.Task;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.UUID;

@Repository
public interface TaskRepository extends JpaRepository<Task, UUID> {
}