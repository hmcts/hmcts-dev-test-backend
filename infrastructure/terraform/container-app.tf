resource "azurerm_container_app_environment" "app_env" {
  name                = "${var.project_name}-${var.environment}-${var.location_short}-env"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}

resource "azurerm_container_app" "app" {
  name                         = "${var.project_name}-${var.environment}-${var.location_short}-ca"
  container_app_environment_id = azurerm_container_app_environment.app_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Multiple"
  tags                         = local.common_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app_identity.id]
  }

  template {
    container {
      name   = "app"
      image  = var.container_image
      cpu    = 0.5
      memory = "1.0Gi"

      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.postgres.fqdn
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_NAME"
        value = azurerm_postgresql_flexible_server_database.app_db.name
      }
      env {
        name  = "DB_USER"
        value = var.db_admin_username
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }
    }
  }

  secret {
    name  = "db-password"
    value = azurerm_key_vault_secret.db_password.value
  }

  depends_on = [
    azurerm_postgresql_flexible_server_database.app_db,
    azurerm_postgresql_flexible_server_firewall_rule.allow_azure_services,
    time_sleep.wait_for_rbac
  ]
}
