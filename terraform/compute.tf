# Creates a user-assigned managed identity for use by the Container App
# (authenticate to Key Vault for secrets — no credentials stored in the app).
resource "azurerm_user_assigned_identity" "app" {
  name                = local.managed_identity_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = local.tags
}

# Required hosting plane for Container Apps (networking/logging/scaling boundary).
# The Container App below must run inside this environment.
resource "azurerm_container_app_environment" "main" {
  name                = local.container_app_environment_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  tags = local.tags
}

resource "azurerm_container_app" "main" {
  name                         = local.container_app_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"

  # Identity the Container App runs as (used to pull Key Vault secrets at runtime).
  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app.id]
  }

  # Registers a Container App secret (not an env var by itself).
  # Value is fetched from Key Vault at runtime via the managed identity, then wired
  # into the container as env DB_PASSWORD below via secret_name.
  secret {
    name                = local.db_password_secret_name
    key_vault_secret_id = azurerm_key_vault_secret.db_password.id
    identity            = azurerm_user_assigned_identity.app.id
  }

  template {
    # Autoscale bounds: min can be 0 (scale to zero when idle); max caps concurrent replicas.
    min_replicas = var.min_replicas
    max_replicas = var.max_replicas

    container {
      name   = var.service_name
      image  = var.container_image
      cpu    = var.container_cpu
      memory = var.container_memory

      # Plain env vars — var.container_env from *.tfvars, plus DB_HOST from local.postgres_fqdn.
      dynamic "env" {
        for_each = local.container_env
        content {
          name  = env.key
          value = env.value
        }
      }

      # Secret env vars — map of ENV_NAME -> secret name in var.container_secret_env.
      dynamic "env" {
        for_each = var.container_secret_env
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }
  }

  # Public HTTP ingress: accept traffic from the internet on the app's external URL,
  # forward to the container listening on server_port, send 100% to the latest revision.
  ingress {
    external_enabled = true
    # Prefer SERVER_PORT from container_env map; fall back to var.server_port.
    target_port = try(tonumber(var.container_env["SERVER_PORT"]), var.server_port)

    # Deliberately send all traffic to the latest revision (simple full cutover).
    # For safer prod rollouts, split e.g. 10% latest / 90% previous, then ramp up.
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  tags = local.tags

  # Wait until the app identity has Key Vault Secrets User before the app starts
  # (otherwise the Key Vault secret reference can fail on first revision).
  depends_on = [azurerm_role_assignment.app_secrets]
}
