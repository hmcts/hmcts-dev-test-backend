locals {
  suffix = "${var.environment}-${var.location.short}"

  # <organization>-<resource abbreviation>-<service>-<environment>-<location>
  name = lower(replace(replace("${var.organization}-%s-${var.service.formattedName}-${local.suffix}", "_", "-"), " ", "-"))

  registry_name   = replace(format(local.name, "cr"), "-", "")
  container_name  = lower(replace(replace(var.service.name, "_", "-"), " ", "-"))
  container_image = "${azurerm_container_registry.case_management.login_server}/${var.image_name}:${var.image_tag}"

  container_secrets = {
    "db-user-name" = azurerm_key_vault_secret.db_user.versionless_id
    "db-password"  = azurerm_key_vault_secret.db_password.versionless_id
  }

  container_env = {
    SERVER_PORT         = tostring(var.container_port)
    DB_HOST             = azurerm_postgresql_flexible_server.case_management.fqdn
    DB_PORT             = "5432"
    DB_NAME             = azurerm_postgresql_flexible_server_database.application.name
    DB_OPTIONS          = "?sslmode=require"
    HEALTH_SHOW_DETAILS = "never"
  }

  container_secret_env = {
    DB_USER_NAME = "db-user-name"
    DB_PASSWORD  = "db-password"
  }
}
