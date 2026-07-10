package uk.gov.hmcts.reform.dev.dto;

import uk.gov.hmcts.reform.dev.models.Task;
import uk.gov.hmcts.reform.dev.models.TaskStatus;

import java.time.LocalDateTime;

/**
 * View of a task returned by the API.
 */
public class TaskResponse {

    private Long id;
    private String title;
    private String description;
    private TaskStatus status;
    private LocalDateTime dueDateTime;

    public TaskResponse() {
    }

    public TaskResponse(Long id, String title, String description, TaskStatus status, LocalDateTime dueDateTime) {
        this.id = id;
        this.title = title;
        this.description = description;
        this.status = status;
        this.dueDateTime = dueDateTime;
    }

    /**
     * Maps a persisted {@link Task} entity to its API representation.
     */
    public static TaskResponse from(Task task) {
        return new TaskResponse(
            task.getId(),
            task.getTitle(),
            task.getDescription(),
            task.getStatus(),
            task.getDueDateTime()
        );
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getTitle() {
        return title;
    }

    public void setTitle(String title) {
        this.title = title;
    }

    public String getDescription() {
        return description;
    }

    public void setDescription(String description) {
        this.description = description;
    }

    public TaskStatus getStatus() {
        return status;
    }

    public void setStatus(TaskStatus status) {
        this.status = status;
    }

    public LocalDateTime getDueDateTime() {
        return dueDateTime;
    }

    public void setDueDateTime(LocalDateTime dueDateTime) {
        this.dueDateTime = dueDateTime;
    }
}
