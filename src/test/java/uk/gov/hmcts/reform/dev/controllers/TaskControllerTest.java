package uk.gov.hmcts.reform.dev.controllers;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.WebMvcTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import uk.gov.hmcts.reform.dev.models.Task;
import uk.gov.hmcts.reform.dev.repository.TaskRepository;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(TaskController.class)
public class TaskControllerTest { 

    @Autowired
    private MockMvc mockMvc;

    @MockBean
    private TaskRepository taskRepository; 

    // Helper JSON payloads for testing
    private final String validTaskJson = // Renamed to camelCase
        "{\"title\":\"File Review\",\"status\":\"TO_DO\",\"dueDate\":\"2026-01-01T10:00:00\"}";
    private final String invalidTaskJsonMissingTitle = // Renamed to camelCase
        "{\"status\":\"TO_DO\",\"dueDate\":\"2026-01-01T10:00:00\"}";
    @Test
    void createTask_Success_Returns201Created() throws Exception {
        // Mock the repository save operation
        when(taskRepository.save(any(Task.class))).thenReturn(new Task()); 

        mockMvc.perform(post("/api/tasks")
                .contentType(MediaType.APPLICATION_JSON)
                .content(validTaskJson))
                .andExpect(status().isCreated()); 
    }

    @Test
    void createTask_MissingRequiredField_Returns400BadRequest() throws Exception {
        mockMvc.perform(post("/api/tasks")
                .contentType(MediaType.APPLICATION_JSON)
                .content(invalidTaskJsonMissingTitle))
                .andExpect(status().isBadRequest()); 
    }
}