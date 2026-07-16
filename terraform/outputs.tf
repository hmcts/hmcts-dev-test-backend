output "resource_group_name" {
  description = "Name of the resource group containing all service resources."
  value       = azurerm_resource_group.main.name
}

output "postgres_fqdn" {
  description = "Fully-qualified domain name of the PostgreSQL Flexible Server."
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "key_vault_uri" {
  description = "URI of the Key Vault (used to reference secrets from other services)."
  value       = azurerm_key_vault.main.vault_uri
}

output "container_app_url" {
  description = "Public HTTPS URL of the Container App."
  value       = "https://${azurerm_container_app.main.ingress[0].fqdn}"
}

output "managed_identity_client_id" {
  description = "Client ID of the user-assigned managed identity (useful for configuring additional resource access)."
  value       = azurerm_user_assigned_identity.app.client_id
}
