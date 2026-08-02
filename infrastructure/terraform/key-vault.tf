resource "random_string" "kv_suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "azurerm_key_vault" "kv" {
  name                        = "${var.project_name}-${var.environment}-${var.location_short}-kv-${random_string.kv_suffix.result}"
  location                    = azurerm_resource_group.rg.location
  resource_group_name         = azurerm_resource_group.rg.name
  enabled_for_disk_encryption = true
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  soft_delete_retention_days  = 7
  purge_protection_enabled    = false
  sku_name                    = "standard"
  tags                        = local.common_tags
}

resource "azurerm_key_vault_access_policy" "deployer_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  secret_permissions = ["Get", "List", "Set", "Delete", "Purge", "Recover"]
}

resource "azurerm_key_vault_access_policy" "app_access" {
  key_vault_id = azurerm_key_vault.kv.id
  tenant_id    = azurerm_user_assigned_identity.app_identity.tenant_id
  object_id    = azurerm_user_assigned_identity.app_identity.principal_id

  secret_permissions = ["Get", "List"]
}

resource "time_sleep" "wait_for_rbac" {
  depends_on = [
    azurerm_key_vault_access_policy.deployer_access,
    azurerm_key_vault_access_policy.app_access
  ]
  create_duration = "30s"
}

resource "random_password" "db_password" {
  length           = 24
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.db_password.result
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [time_sleep.wait_for_rbac]
}
