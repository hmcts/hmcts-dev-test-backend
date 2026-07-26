package uk.gov.hmcts.reform.dev.repositories;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.data.jpa.test.autoconfigure.DataJpaTest;
import uk.gov.hmcts.reform.dev.models.Task;
import uk.gov.hmcts.reform.dev.models.TaskStatus;

import java.time.LocalDateTime;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;

@DataJpaTest
class TaskRepositoryTest {

    @Autowired
    private TaskRepository taskRepository;

    private Task newTask(String title, TaskStatus status) {
        return new Task(null, title, "some description", status,
                        LocalDateTime.of(2026, 7, 10, 9, 0));
    }

    @Test
    void savesTaskAndAssignsGeneratedId() {
        Task saved = taskRepository.save(newTask("Review case", TaskStatus.PENDING));

        assertThat(saved.getId()).isNotNull();
        assertThat(taskRepository.findById(saved.getId()))
            .get()
            .satisfies(found -> {
                assertThat(found.getTitle()).isEqualTo("Review case");
                assertThat(found.getStatus()).isEqualTo(TaskStatus.PENDING);
                assertThat(found.getDescription()).isEqualTo("some description");
            });
    }

    @Test
    void persistsNullDescriptionAsOptionalField() {
        Task task = newTask("No description task", TaskStatus.PENDING);
        task.setDescription(null);

        Task saved = taskRepository.save(task);

        assertThat(taskRepository.findById(saved.getId()))
            .get()
            .satisfies(found -> assertThat(found.getDescription()).isNull());
    }

    @Test
    void findByIdReturnsEmptyWhenTaskDoesNotExist() {
        Optional<Task> result = taskRepository.findById(999L);

        assertThat(result).isEmpty();
    }

    @Test
    void deleteRemovesTheTask() {
        Task saved = taskRepository.save(newTask("Temporary", TaskStatus.PENDING));

        taskRepository.deleteById(saved.getId());

        assertThat(taskRepository.findById(saved.getId())).isEmpty();
    }
}
