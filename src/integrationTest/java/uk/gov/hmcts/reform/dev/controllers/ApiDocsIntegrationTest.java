package uk.gov.hmcts.reform.dev.controllers;

import io.restassured.RestAssured;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.test.context.SpringBootTest;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class ApiDocsIntegrationTest {

    @Value("${local.server.port}")
    private int port;

    @BeforeEach
    void setUp() {
        RestAssured.baseURI = "http://localhost";
        RestAssured.port = port;
    }

    @Test
    void openApiDocumentDescribesTaskEndpoints() {
        given()
            .when()
            .get("/v3/api-docs")
            .then()
            .statusCode(200)
            .body("info.title", equalTo("Task Management API"))
            .body("paths.'/api/tasks'.post", notNullValue())
            .body("paths.'/api/tasks/{id}'.get", notNullValue())
            .body("paths.'/api/tasks/{id}/status'.patch", notNullValue())
            .body("paths.'/api/tasks/{id}'.delete", notNullValue());
    }
}
