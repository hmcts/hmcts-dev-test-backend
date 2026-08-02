output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "The name of the created Resource Group."
}

output "key_vault_uri" {
  value       = azurerm_key_vault.kv.vault_uri
  description = "The URI of the created Key Vault."
}

output "postgres_fqdn" {
  value       = azurerm_postgresql_flexible_server.postgres.fqdn
  description = "The Fully Qualified Domain Name of the PostgreSQL Server."
}

output "container_app_fqdn" {
  value       = azurerm_container_app.app.ingress[0].fqdn
  description = "The ingress FQDN for the deployed Container App."
}
