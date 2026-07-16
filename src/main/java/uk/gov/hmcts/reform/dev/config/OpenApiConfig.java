package uk.gov.hmcts.reform.dev.config;

import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class OpenApiConfig {

    @Bean
    public OpenAPI taskManagementOpenApi() {
        return new OpenAPI().info(
            new Info()
                .title("Task Management API")
                .description("API for caseworkers to create, view, update and delete tasks.")
                .version("0.0.1")
        );
    }
}
