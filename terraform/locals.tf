# Shared derived values used across resources (naming, tags, flags).
# Environment-specific *input* values live in environments/*.tfvars — not here.
# Tunable declarations: variables.tf | Env overrides: environments/dev.tfvars, prod.tfvars

locals {
  is_production = var.environment == "production"

  # Tagging strategy: common tags live here and are applied via `tags = local.tags`.
  # Keep shared keys in one place so cost/owner filters stay consistent across resources.
  # To add resource-specific tags, merge at the resource, e.g.:
  #   tags = merge(local.tags, { component = "database" })
  tags = {
    service     = var.service_name
    environment = var.environment
    managed_by  = "terraform"
  }

  # Resource names — patterns stay here; service/environment come from variables / tfvars.
  resource_group_name            = "rg-${var.service_name}-${var.environment}"
  postgres_server_name           = "psql-${var.service_name}-${var.environment}"
  managed_identity_name          = "id-${var.service_name}-${var.environment}"
  container_app_environment_name = "cae-${var.service_name}-${var.environment}"
  container_app_name             = "ca-${var.service_name}-${var.environment}"

  # Container App secret name — referenced by secret {} and container_secret_env.
  db_password_secret_name = "db-password"

  # Derived Postgres hostname — merged into container_env (tfvars can't reference resources/locals).
  postgres_fqdn = azurerm_postgresql_flexible_server.main.fqdn

  container_env = merge(var.container_env, {
    DB_HOST = local.postgres_fqdn
  })
}
