package uk.gov.hmcts.reform.dev.models;

import java.time.LocalDateTime;
import java.util.UUID;

import org.hibernate.annotations.CreationTimestamp;

import com.fasterxml.jackson.annotation.JsonProperty;

import groovyjarjarantlr4.v4.runtime.misc.NotNull;
import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;
import lombok.Setter;
import lombok.Getter;
import lombok.AccessLevel;

@Getter
@Setter
@Entity
@Table(name = "cases")
public class Case {
    @Setter(AccessLevel.NONE)
    @JsonProperty(access = JsonProperty.Access.READ_ONLY)
    @Id
    @GeneratedValue
    @Column(name = "id", columnDefinition = "BINARY(16)", nullable = false, updatable = false)
    private UUID id;

    @NotNull
    @Column(name = "case_number", nullable = false, length = 255)
    @JsonProperty("case_number")
    private String caseNumber;

    @Column(name = "description", length = 255)
    private String description;

    @NotNull
    @Column(name = "status", nullable = false, length = 100)
    private String status;

    @Setter(AccessLevel.NONE)
    @JsonProperty(access = JsonProperty.Access.READ_ONLY)
    @CreationTimestamp
    @Column(name = "created_date", nullable = false, length = 100)
    private LocalDateTime createdDate;

    public Case(UUID id, String caseNumber, String description, String status, LocalDateTime createdDate) {
        this.id = id;
        this.caseNumber = caseNumber;
        this.description = description;
        this.status = status;
        this.createdDate = createdDate;
    }
    
    public Case() {
        this.status = "NEW";
        this.createdDate = LocalDateTime.now();
    }
}
