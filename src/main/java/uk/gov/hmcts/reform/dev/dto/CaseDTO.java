package uk.gov.hmcts.reform.dev.dto;

import java.time.LocalDateTime;
import java.util.UUID;

import lombok.Getter;
import lombok.Setter;
import lombok.NoArgsConstructor;
import lombok.AllArgsConstructor;

@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
public class CaseDTO {
    private UUID id;
    private String caseNumber;
    private String description;
    private String status;
    private LocalDateTime createdDate;
}