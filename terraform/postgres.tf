# PostgreSQL Flexible Server for the application database.
# Note: administrator_login/password are also what the app uses (DB_USER_NAME / DB_PASSWORD).
# No separate least-privilege app DB user is created yet — fine for simple/dev; for prod,
# prefer an app-only role and keep this admin for ops/migrations.
resource "azurerm_postgresql_flexible_server" "main" {
  name                   = local.postgres_server_name
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = var.db_version
  administrator_login    = var.db_admin_username
  administrator_password = var.db_admin_password # Same sensitive input as Key Vault secret — pass via -var / TF_VAR_* / CI secret, not tfvars.
  sku_name               = var.db_sku
  storage_mb             = var.db_storage_mb
  backup_retention_days  = var.db_backup_retention_days

  tags = local.tags
}

# Application database on the Flexible Server (name from var.db_name).
# Collation/charset match typical UTF-8 app defaults.
resource "azurerm_postgresql_flexible_server_database" "app" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

# Permits connections from other Azure services (including Container Apps).
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
