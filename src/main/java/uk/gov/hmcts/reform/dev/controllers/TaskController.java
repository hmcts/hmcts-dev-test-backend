package uk.gov.hmcts.reform.dev.controllers;

import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import uk.gov.hmcts.reform.dev.services.TaskService;
import uk.gov.hmcts.reform.dev.dtos.request.CreateTaskRequest;
import uk.gov.hmcts.reform.dev.dtos.response.TaskResponse;

@RestController
@RequestMapping("/tasks")
public class TaskController {

    private final TaskService service;

    public TaskController(TaskService service) {
        this.service = service;
    }

    @PostMapping
    public ResponseEntity<TaskResponse> create(
            @Valid @RequestBody CreateTaskRequest request
    ) {
        return ResponseEntity.ok(service.create(request));
    }
}