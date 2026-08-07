resource "azurerm_user_assigned_identity" "api" {
  name                = format(local.name, "id")
  resource_group_name = azurerm_resource_group.case_management.name
  location            = azurerm_resource_group.case_management.location
  tags                = var.tags
}

resource "azurerm_container_app_environment" "case_management" {
  name                       = format(local.name, "cae")
  resource_group_name        = azurerm_resource_group.case_management.name
  location                   = azurerm_resource_group.case_management.location
  log_analytics_workspace_id = azurerm_log_analytics_workspace.case_management.id
  tags                       = var.tags
}

resource "azurerm_container_app" "api" {
  name                         = format(local.name, "ca")
  container_app_environment_id = azurerm_container_app_environment.case_management.id
  resource_group_name          = azurerm_resource_group.case_management.name
  revision_mode                = "Single"
  tags                         = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.api.id]
  }

  registry {
    server   = azurerm_container_registry.case_management.login_server
    identity = azurerm_user_assigned_identity.api.id
  }

  dynamic "secret" {
    for_each = local.container_secrets
    content {
      name                = secret.key
      identity            = azurerm_user_assigned_identity.api.id
      key_vault_secret_id = secret.value
    }
  }

  ingress {
    external_enabled = true
    target_port      = var.container_port

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    http_scale_rule {
      name                = "http-requests"
      concurrent_requests = tostring(var.container_concurrent_requests)
    }

    container {
      name   = local.container_name
      image  = local.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      dynamic "env" {
        for_each = local.container_env
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = local.container_secret_env
        content {
          name        = env.key
          secret_name = env.value
        }
      }

      liveness_probe {
        transport        = "HTTP"
        port             = var.container_port
        path             = "/health/liveness"
        initial_delay    = 30
        interval_seconds = 15
      }

      readiness_probe {
        transport               = "HTTP"
        port                    = var.container_port
        path                    = "/health/readiness"
        interval_seconds        = 10
        failure_count_threshold = 10
      }
    }
  }

  depends_on = [
    azurerm_role_assignment.acr_pull,
    azurerm_role_assignment.kv_secrets_user,
  ]
}
