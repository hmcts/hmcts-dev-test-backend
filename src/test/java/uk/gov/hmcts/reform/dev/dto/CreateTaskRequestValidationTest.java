package uk.gov.hmcts.reform.dev.dto;

import jakarta.validation.ConstraintViolation;
import jakarta.validation.Validation;
import jakarta.validation.Validator;
import jakarta.validation.ValidatorFactory;
import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.Test;
import uk.gov.hmcts.reform.dev.models.TaskStatus;

import java.time.LocalDateTime;
import java.util.Set;

import static org.assertj.core.api.Assertions.assertThat;

class CreateTaskRequestValidationTest {

    private static ValidatorFactory factory;
    private static Validator validator;

    @BeforeAll
    static void setUp() {
        factory = Validation.buildDefaultValidatorFactory();
        validator = factory.getValidator();
    }

    @AfterAll
    static void tearDown() {
        factory.close();
    }

    private CreateTaskRequest validRequest() {
        return new CreateTaskRequest(
            "Review case file",
            "Optional detail",
            TaskStatus.PENDING,
            LocalDateTime.of(2026, 7, 10, 9, 0)
        );
    }

    private Set<String> violatedFields(CreateTaskRequest request) {
        return validator.validate(request).stream()
            .map(violation -> violation.getPropertyPath().toString())
            .collect(java.util.stream.Collectors.toSet());
    }

    @Test
    void validRequestHasNoViolations() {
        Set<ConstraintViolation<CreateTaskRequest>> violations = validator.validate(validRequest());

        assertThat(violations).isEmpty();
    }

    @Test
    void nullDescriptionIsAllowed() {
        CreateTaskRequest request = validRequest();
        request.setDescription(null);

        assertThat(validator.validate(request)).isEmpty();
    }

    @Test
    void blankTitleIsRejected() {
        CreateTaskRequest request = validRequest();
        request.setTitle("   ");

        assertThat(violatedFields(request)).contains("title");
    }

    @Test
    void nullTitleIsRejected() {
        CreateTaskRequest request = validRequest();
        request.setTitle(null);

        assertThat(violatedFields(request)).contains("title");
    }

    @Test
    void titleLongerThan255CharactersIsRejected() {
        CreateTaskRequest request = validRequest();
        request.setTitle("a".repeat(256));

        assertThat(violatedFields(request)).contains("title");
    }

    @Test
    void nullStatusIsRejected() {
        CreateTaskRequest request = validRequest();
        request.setStatus(null);

        assertThat(violatedFields(request)).contains("status");
    }

    @Test
    void nullDueDateTimeIsRejected() {
        CreateTaskRequest request = validRequest();
        request.setDueDateTime(null);

        assertThat(violatedFields(request)).contains("dueDateTime");
    }
}
