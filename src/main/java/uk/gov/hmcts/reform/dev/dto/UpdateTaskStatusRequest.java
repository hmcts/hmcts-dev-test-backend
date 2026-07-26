package uk.gov.hmcts.reform.dev.dto;

import jakarta.validation.constraints.NotNull;
import uk.gov.hmcts.reform.dev.models.TaskStatus;

/**
 * Payload for updating the status of an existing task.
 */
public class UpdateTaskStatusRequest {

    @NotNull(message = "status is required")
    private TaskStatus status;

    public UpdateTaskStatusRequest() {
    }

    public UpdateTaskStatusRequest(TaskStatus status) {
        this.status = status;
    }

    public TaskStatus getStatus() {
        return status;
    }

    public void setStatus(TaskStatus status) {
        this.status = status;
    }
}
