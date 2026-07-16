package uk.gov.hmcts.reform.dev.controllers;

import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;
import uk.gov.hmcts.reform.dev.repositories.TaskRepository;

import java.util.Map;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class TaskIntegrationTest {

    @Value("${local.server.port}")
    private int port;

    @Autowired
    private TaskRepository taskRepository;

    @BeforeEach
    void setUp() {
        RestAssured.baseURI = "http://localhost";
        RestAssured.port = port;
        taskRepository.deleteAll();
    }

    private Map<String, Object> createBody() {
        return Map.of(
            "title", "Review case file",
            "description", "Check all documents",
            "status", "PENDING",
            "dueDateTime", "2026-07-10T09:00:00"
        );
    }

    @Test
    void fullTaskLifecyclePersistsAcrossRequests() {
        int id = given()
            .contentType(ContentType.JSON)
            .body(createBody())
            .when()
            .post("/api/tasks")
            .then()
            .statusCode(201)
            .header("Location", notNullValue())
            .body("id", notNullValue())
            .body("title", equalTo("Review case file"))
            .body("status", equalTo("PENDING"))
            .extract().path("id");

        given()
            .when()
            .get("/api/tasks/" + id)
            .then()
            .statusCode(200)
            .body("description", equalTo("Check all documents"));

        given()
            .when()
            .get("/api/tasks")
            .then()
            .statusCode(200)
            .body("size()", equalTo(1))
            .body("[0].id", equalTo(id));

        given()
            .contentType(ContentType.JSON)
            .body(Map.of("status", "COMPLETED"))
            .when()
            .patch("/api/tasks/" + id + "/status")
            .then()
            .statusCode(200)
            .body("status", equalTo("COMPLETED"));

        given()
            .when()
            .get("/api/tasks/" + id)
            .then()
            .statusCode(200)
            .body("status", equalTo("COMPLETED"));

        given()
            .when()
            .delete("/api/tasks/" + id)
            .then()
            .statusCode(204);

        given()
            .when()
            .get("/api/tasks/" + id)
            .then()
            .statusCode(404);
    }

    @Test
    void createWithBlankTitleReturns400WithFieldError() {
        Map<String, Object> invalid = Map.of(
            "title", "  ",
            "status", "PENDING",
            "dueDateTime", "2026-07-10T09:00:00"
        );

        given()
            .contentType(ContentType.JSON)
            .body(invalid)
            .when()
            .post("/api/tasks")
            .then()
            .statusCode(400)
            .body("message", equalTo("Validation failed"))
            .body("fieldErrors.title", notNullValue());
    }

    @Test
    void getUnknownTaskReturns404() {
        given()
            .when()
            .get("/api/tasks/999999")
            .then()
            .statusCode(404)
            .body("status", equalTo(404));
    }
}
