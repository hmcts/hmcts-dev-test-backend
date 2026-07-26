package uk.gov.hmcts.reform.dev.services;

import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.ArgumentCaptor;
import org.mockito.InjectMocks;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import uk.gov.hmcts.reform.dev.dto.CreateTaskRequest;
import uk.gov.hmcts.reform.dev.dto.TaskResponse;
import uk.gov.hmcts.reform.dev.exceptions.TaskNotFoundException;
import uk.gov.hmcts.reform.dev.models.Task;
import uk.gov.hmcts.reform.dev.models.TaskStatus;
import uk.gov.hmcts.reform.dev.repositories.TaskRepository;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.Assertions.assertThatThrownBy;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

@ExtendWith(MockitoExtension.class)
class TaskServiceTest {

    private static final LocalDateTime DUE = LocalDateTime.of(2026, 7, 10, 9, 0);

    @Mock
    private TaskRepository taskRepository;

    @InjectMocks
    private TaskService taskService;

    private Task existingTask(Long id, TaskStatus status) {
        return new Task(id, "Review case", "Check documents", status, DUE);
    }

    @Test
    void createTaskMapsRequestToEntityAndReturnsSavedTask() {
        CreateTaskRequest request =
            new CreateTaskRequest("Review case", "Check documents", TaskStatus.PENDING, DUE);
        when(taskRepository.save(any(Task.class))).thenReturn(existingTask(1L, TaskStatus.PENDING));

        TaskResponse response = taskService.createTask(request);

        ArgumentCaptor<Task> captor = ArgumentCaptor.forClass(Task.class);
        verify(taskRepository).save(captor.capture());
        Task persisted = captor.getValue();
        assertThat(persisted.getId()).isNull();
        assertThat(persisted.getTitle()).isEqualTo("Review case");
        assertThat(persisted.getStatus()).isEqualTo(TaskStatus.PENDING);
        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getTitle()).isEqualTo("Review case");
    }

    @Test
    void getTaskByIdReturnsMappedTaskWhenFound() {
        when(taskRepository.findById(1L)).thenReturn(Optional.of(existingTask(1L, TaskStatus.IN_PROGRESS)));

        TaskResponse response = taskService.getTaskById(1L);

        assertThat(response.getId()).isEqualTo(1L);
        assertThat(response.getStatus()).isEqualTo(TaskStatus.IN_PROGRESS);
    }

    @Test
    void getTaskByIdThrowsWhenMissing() {
        when(taskRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.getTaskById(99L))
            .isInstanceOf(TaskNotFoundException.class)
            .hasMessageContaining("99");
    }

    @Test
    void getAllTasksMapsEveryTask() {
        when(taskRepository.findAll()).thenReturn(List.of(
            existingTask(1L, TaskStatus.PENDING),
            existingTask(2L, TaskStatus.COMPLETED)
        ));

        List<TaskResponse> responses = taskService.getAllTasks();

        assertThat(responses).extracting(TaskResponse::getId).containsExactly(1L, 2L);
        assertThat(responses).extracting(TaskResponse::getStatus)
            .containsExactly(TaskStatus.PENDING, TaskStatus.COMPLETED);
    }

    @Test
    void getAllTasksReturnsEmptyListWhenNoTasks() {
        when(taskRepository.findAll()).thenReturn(List.of());

        assertThat(taskService.getAllTasks()).isEmpty();
    }

    @Test
    void updateStatusChangesStatusAndSaves() {
        Task task = existingTask(1L, TaskStatus.PENDING);
        when(taskRepository.findById(1L)).thenReturn(Optional.of(task));
        when(taskRepository.save(any(Task.class))).thenAnswer(invocation -> invocation.getArgument(0));

        TaskResponse response = taskService.updateStatus(1L, TaskStatus.COMPLETED);

        assertThat(task.getStatus()).isEqualTo(TaskStatus.COMPLETED);
        assertThat(response.getStatus()).isEqualTo(TaskStatus.COMPLETED);
        verify(taskRepository).save(task);
    }

    @Test
    void updateStatusThrowsWhenMissing() {
        when(taskRepository.findById(99L)).thenReturn(Optional.empty());

        assertThatThrownBy(() -> taskService.updateStatus(99L, TaskStatus.COMPLETED))
            .isInstanceOf(TaskNotFoundException.class);
        verify(taskRepository, never()).save(any(Task.class));
    }

    @Test
    void deleteTaskDeletesWhenItExists() {
        when(taskRepository.existsById(1L)).thenReturn(true);

        taskService.deleteTask(1L);

        verify(taskRepository).deleteById(1L);
    }

    @Test
    void deleteTaskThrowsWhenMissing() {
        when(taskRepository.existsById(99L)).thenReturn(false);

        assertThatThrownBy(() -> taskService.deleteTask(99L))
            .isInstanceOf(TaskNotFoundException.class);
        verify(taskRepository, never()).deleteById(any());
    }
}
