package uk.gov.hmcts.reform.dev.dtos.response;

import lombok.AllArgsConstructor;
import lombok.Getter;
import java.util.UUID;
import java.time.LocalDateTime;
import uk.gov.hmcts.reform.dev.models.TaskStatus;

@Getter
@AllArgsConstructor
public class TaskResponse {
    private UUID id;
    private String title;
    private String description;
    private TaskStatus status;
    private LocalDateTime dueDate;
}