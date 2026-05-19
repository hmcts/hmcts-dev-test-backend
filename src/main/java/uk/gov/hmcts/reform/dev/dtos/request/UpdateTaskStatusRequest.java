package uk.gov.hmcts.reform.dev.dtos.request;

import lombok.*;
import uk.gov.hmcts.reform.dev.models.TaskStatus;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class UpdateTaskStatusRequest {

    private TaskStatus status;
}