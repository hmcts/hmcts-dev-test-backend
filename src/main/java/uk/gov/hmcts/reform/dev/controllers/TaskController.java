package uk.gov.hmcts.reform.dev.controllers;

import jakarta.validation.Valid;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import uk.gov.hmcts.reform.dev.models.ExampleCase;
import uk.gov.hmcts.reform.dev.models.Task;
import uk.gov.hmcts.reform.dev.repository.TaskRepository;

import java.time.LocalDateTime;

import static org.springframework.http.ResponseEntity.ok;

@RestController
// CHANGE: Removing the base '/api' mapping to avoid double-prefixing 
// if a proxy or frontend configuration is already adding it.
public class TaskController { 
// NOTE: I am removing the @RequestMapping("/api") line entirely.

    private final TaskRepository taskRepository;

    public TaskController(TaskRepository taskRepository) {
        this.taskRepository = taskRepository;
    }
    
    // Existing endpoint kept for reference
    // Update GET to include /api
    @GetMapping(value = "/api/get-example-case", produces = "application/json")
    public ResponseEntity<ExampleCase> getExampleCase() {
        return ok(new ExampleCase(1, "ABC12345", "Case Title",
                                 "Case Description", "Case Status", LocalDateTime.now()
        ));
    }
    
    // FIX: Set the complete, expected path here: /api/task/new
    @PostMapping(value = "/api/task/new", consumes = "application/json", produces = "application/json") 
    public ResponseEntity<Task> createTask(@Valid @RequestBody Task newTask) {
        // Validation handled by @Valid and Spring Boot.
        Task savedTask = taskRepository.save(newTask);
        
        // Return 201 Created and the task details
        return new ResponseEntity<>(savedTask, HttpStatus.CREATED); 
    }
}