resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = "PerGB2018"
  retention_in_days   = var.log_retention_days
  tags                = local.tags
}

resource "azurerm_container_app_environment" "this" {
  name                = "cae-${local.name_prefix}"
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location

  log_analytics_workspace_id = azurerm_log_analytics_workspace.this.id

  infrastructure_subnet_id = azurerm_subnet.container_apps.id

  internal_load_balancer_enabled = false

  tags = local.tags
}

resource "azurerm_container_app" "this" {
  name                         = "ca-${local.name_prefix}"
  resource_group_name          = azurerm_resource_group.this.name
  container_app_environment_id = azurerm_container_app_environment.this.id

  revision_mode = "Multiple"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  secret {
    name                = "db-password"
    key_vault_secret_id = azurerm_key_vault_secret.db_password.versionless_id
    identity            = azurerm_user_assigned_identity.app.id
  }

  dynamic "secret" {
    for_each = var.registry_password == null ? [] : [1]

    content {
      name  = "registry-password"
      value = var.registry_password
    }
  }

  dynamic "registry" {
    for_each = var.registry_password == null ? [] : [1]

    content {
      server               = var.registry_server
      username             = var.registry_username
      password_secret_name = "registry-password"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 4000
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.component
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      env {
        name  = "SERVER_PORT"
        value = "4000"
      }

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.this.fqdn
      }

      env {
        name  = "DB_PORT"
        value = "5432"
      }

      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.app.name
      }

      env {
        name  = "DB_USER_NAME"
        value = var.postgres_admin_username
      }

      env {
        name  = "DB_OPTIONS"
        value = "?sslmode=verify-full"
      }

      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      liveness_probe {
        transport = "HTTP"
        port      = 4000
        path      = "/health"

        initial_delay           = 30
        interval_seconds        = 15
        timeout                 = 5
        failure_count_threshold = 5
      }

      readiness_probe {
        transport = "HTTP"
        port      = 4000
        path      = "/health/readiness"

        interval_seconds        = 10
        timeout                 = 5
        failure_count_threshold = 3
      }
    }

    http_scale_rule {
      name                = "http-concurrency"
      concurrent_requests = "50"
    }
  }

  tags = local.tags

  depends_on = [azurerm_role_assignment.app_secrets_user]
}
