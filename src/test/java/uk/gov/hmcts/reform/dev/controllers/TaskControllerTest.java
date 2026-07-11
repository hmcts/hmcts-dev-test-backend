package uk.gov.hmcts.reform.dev.controllers;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.webmvc.test.autoconfigure.WebMvcTest;
import org.springframework.http.MediaType;
import org.springframework.test.context.bean.override.mockito.MockitoBean;
import org.springframework.test.web.servlet.MockMvc;
import uk.gov.hmcts.reform.dev.dto.CreateTaskRequest;
import uk.gov.hmcts.reform.dev.dto.TaskResponse;
import uk.gov.hmcts.reform.dev.exceptions.TaskNotFoundException;
import uk.gov.hmcts.reform.dev.models.TaskStatus;
import uk.gov.hmcts.reform.dev.services.TaskService;

import java.time.LocalDateTime;
import java.util.List;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.doThrow;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.delete;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.patch;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@WebMvcTest(TaskController.class)
class TaskControllerTest {

    private static final LocalDateTime DUE = LocalDateTime.of(2026, 7, 10, 9, 0);

    @Autowired
    private transient MockMvc mockMvc;

    @MockitoBean
    private transient TaskService taskService;

    private final ObjectMapper objectMapper = new ObjectMapper()
        .registerModule(new JavaTimeModule())
        .disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);

    private TaskResponse response(Long id, TaskStatus status) {
        return new TaskResponse(id, "Review case", "Check documents", status, DUE);
    }

    @Test
    void createReturns201WithLocationAndBody() throws Exception {
        CreateTaskRequest request =
            new CreateTaskRequest("Review case", "Check documents", TaskStatus.PENDING, DUE);
        when(taskService.createTask(any())).thenReturn(response(1L, TaskStatus.PENDING));

        mockMvc.perform(post("/api/tasks")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isCreated())
            .andExpect(header().string("Location", "http://localhost/api/tasks/1"))
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.status").value("PENDING"));
    }

    @Test
    void createWithBlankTitleReturns400AndDoesNotCallService() throws Exception {
        CreateTaskRequest request =
            new CreateTaskRequest("  ", "Check documents", TaskStatus.PENDING, DUE);

        mockMvc.perform(post("/api/tasks")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(objectMapper.writeValueAsString(request)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.status").value(400))
            .andExpect(jsonPath("$.message").value("Validation failed"))
            .andExpect(jsonPath("$.fieldErrors.title").exists());

        verify(taskService, org.mockito.Mockito.never()).createTask(any());
    }

    @Test
    void getByIdReturns200WithTask() throws Exception {
        when(taskService.getTaskById(1L)).thenReturn(response(1L, TaskStatus.IN_PROGRESS));

        mockMvc.perform(get("/api/tasks/1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(1))
            .andExpect(jsonPath("$.status").value("IN_PROGRESS"));
    }

    @Test
    void getAllReturns200WithList() throws Exception {
        when(taskService.getAllTasks())
            .thenReturn(List.of(response(1L, TaskStatus.PENDING), response(2L, TaskStatus.COMPLETED)));

        mockMvc.perform(get("/api/tasks"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(2))
            .andExpect(jsonPath("$[0].id").value(1))
            .andExpect(jsonPath("$[1].status").value("COMPLETED"));
    }

    @Test
    void updateStatusReturns200WithUpdatedTask() throws Exception {
        when(taskService.updateStatus(eq(1L), eq(TaskStatus.COMPLETED)))
            .thenReturn(response(1L, TaskStatus.COMPLETED));

        mockMvc.perform(patch("/api/tasks/1/status")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"status\":\"COMPLETED\"}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("COMPLETED"));
    }

    @Test
    void updateStatusWithMissingStatusReturns400() throws Exception {
        mockMvc.perform(patch("/api/tasks/1/status")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{}"))
            .andExpect(status().isBadRequest());

        verify(taskService, org.mockito.Mockito.never()).updateStatus(any(), any());
    }

    @Test
    void deleteReturns204() throws Exception {
        mockMvc.perform(delete("/api/tasks/1"))
            .andExpect(status().isNoContent());

        verify(taskService).deleteTask(1L);
    }

    @Test
    void getByIdReturns404WhenTaskNotFound() throws Exception {
        when(taskService.getTaskById(99L)).thenThrow(new TaskNotFoundException(99L));

        mockMvc.perform(get("/api/tasks/99"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.status").value(404))
            .andExpect(jsonPath("$.message").value("Task not found with id: 99"));
    }

    @Test
    void updateStatusReturns404WhenTaskNotFound() throws Exception {
        when(taskService.updateStatus(eq(99L), any())).thenThrow(new TaskNotFoundException(99L));

        mockMvc.perform(patch("/api/tasks/99/status")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content("{\"status\":\"COMPLETED\"}"))
            .andExpect(status().isNotFound());
    }

    @Test
    void deleteReturns404WhenTaskNotFound() throws Exception {
        doThrow(new TaskNotFoundException(99L)).when(taskService).deleteTask(99L);

        mockMvc.perform(delete("/api/tasks/99"))
            .andExpect(status().isNotFound());
    }

    @Test
    void createWithInvalidStatusValueReturns400() throws Exception {
        String body = "{\"title\":\"Review case\",\"status\":\"NOT_A_STATUS\","
            + "\"dueDateTime\":\"2026-07-10T09:00:00\"}";

        mockMvc.perform(post("/api/tasks")
                            .contentType(MediaType.APPLICATION_JSON)
                            .content(body))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.message").value("Malformed or invalid request body"));

        verify(taskService, org.mockito.Mockito.never()).createTask(any());
    }
}
