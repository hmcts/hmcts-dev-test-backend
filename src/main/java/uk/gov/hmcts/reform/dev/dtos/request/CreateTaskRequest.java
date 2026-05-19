package uk.gov.hmcts.reform.dev.dtos.request;

import lombok.*;
import uk.gov.hmcts.reform.dev.models.TaskStatus;

import java.time.LocalDateTime;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CreateTaskRequest {

    private String title;
    private String description;
    private TaskStatus status;
    private LocalDateTime dueDate;
}