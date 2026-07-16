# Looks up the identity Terraform is currently authenticated as (CLI user or CI SP).
# Used below for tenant_id / object_id when granting the deployer Key Vault access.
data "azurerm_client_config" "current" {}

# Creates the Key Vault that holds app secrets (e.g. DB password).
# Azure RBAC controls who can read/write secrets (role assignments below).
# Purge protection is on for production only — once enabled it cannot be turned off.
resource "azurerm_key_vault" "main" {
  name                      = var.key_vault_name
  resource_group_name       = azurerm_resource_group.main.name
  location                  = azurerm_resource_group.main.location
  tenant_id                 = data.azurerm_client_config.current.tenant_id
  sku_name                  = "standard"
  enable_rbac_authorization = true
  purge_protection_enabled  = local.is_production

  tags = local.tags
}

# Deployer (CI / Terraform principal) — create and manage secrets.
# Owner / User Access Administrator can assign roles but do not themselves allow writing
# secrets on an RBAC vault, so the applying identity assigns itself Key Vault Secrets Officer,
# then uses that to write secrets.
resource "azurerm_role_assignment" "deployer_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = data.azurerm_client_config.current.object_id
}

# App managed identity — Key Vault Secrets User (read-only).
# Used by the Container App at runtime to fetch secrets (e.g. db-password → DB_PASSWORD).
resource "azurerm_role_assignment" "app_secrets" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app.principal_id
}

# Stores the DB admin password in Key Vault (name from local.db_password_secret_name).
# Written by Terraform (deployer) during apply; read at runtime by the Container App via its managed identity.
# depends_on ensures Key Vault Secrets Officer is assigned before the write.
resource "azurerm_key_vault_secret" "db_password" {
  name         = local.db_password_secret_name
  value        = var.db_admin_password # Sensitive input — not in committed tfvars; pass via -var / TF_VAR_* / CI secret at apply time.
  key_vault_id = azurerm_key_vault.main.id

  depends_on = [azurerm_role_assignment.deployer_secrets]
}
