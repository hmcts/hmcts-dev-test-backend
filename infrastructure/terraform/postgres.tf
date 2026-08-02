resource "azurerm_postgresql_flexible_server" "postgres" {
  name                   = "${var.project_name}-${var.environment}-${var.location_short}-psql"
  resource_group_name    = azurerm_resource_group.rg.name
  location               = azurerm_resource_group.rg.location
  version                = "15"
  administrator_login    = var.db_admin_username
  administrator_password = random_password.db_password.result

  storage_mb = 32768
  sku_name   = "GP_Standard_D2s_v3"
  zone       = "1"
  tags       = local.common_tags
}

resource "azurerm_postgresql_flexible_server_database" "app_db" {
  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.postgres.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "allow-azure-internal"
  server_id        = azurerm_postgresql_flexible_server.postgres.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
