resource "azurerm_key_vault" "case_management" {
  name                = format(local.name, "kv")
  resource_group_name = azurerm_resource_group.case_management.name
  location            = azurerm_resource_group.case_management.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = var.key_vault_sku
  tags                = var.tags

  rbac_authorization_enabled = true
  purge_protection_enabled   = var.delete_protection_enabled

  lifecycle {
    precondition {
      condition     = length(format(local.name, "kv")) <= 24
      error_message = "Key Vault names are capped at 24 characters. Shorten organization or service.formattedName."
    }
  }
}

resource "azurerm_role_assignment" "kv_secrets_officer" {
  scope                = azurerm_key_vault.case_management.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.case_management.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}

resource "azurerm_key_vault_secret" "db_user" {
  name         = "db-user-name"
  value        = var.postgres_admin_username
  key_vault_id = azurerm_key_vault.case_management.id
  tags         = var.tags

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}

resource "azurerm_key_vault_secret" "db_password" {
  name         = "db-password"
  value        = random_password.postgres.result
  key_vault_id = azurerm_key_vault.case_management.id
  tags         = var.tags

  depends_on = [azurerm_role_assignment.kv_secrets_officer]
}
