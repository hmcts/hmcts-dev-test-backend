output "resource_group_name" {
  description = "Resource group containing everything in this configuration."
  value       = azurerm_resource_group.this.name
}

output "app_url" {
  description = "Public URL of the service."
  value       = "https://${azurerm_container_app.this.ingress[0].fqdn}"
}

output "app_health_url" {
  description = "Readiness URL; UP only when the database is reachable."
  value       = "https://${azurerm_container_app.this.ingress[0].fqdn}/health/readiness"
}

output "container_app_name" {
  description = "For az containerapp operations such as revision rollback."
  value       = azurerm_container_app.this.name
}

output "deployed_image" {
  description = "Image this configuration currently deploys."
  value       = var.container_image
}

output "postgres_server_name" {
  description = "PostgreSQL Flexible Server name."
  value       = azurerm_postgresql_flexible_server.this.name
}

output "postgres_fqdn" {
  description = "Private FQDN of the server; only resolvable inside the VNet."
  value       = azurerm_postgresql_flexible_server.this.fqdn
}

output "database_name" {
  description = "Application database name."
  value       = azurerm_postgresql_flexible_server_database.app.name
}

output "key_vault_name" {
  description = "Key Vault holding the database credentials."
  value       = azurerm_key_vault.this.name
}

output "db_password_secret_name" {
  description = "Secret name to pass to az keyvault secret show."
  value       = azurerm_key_vault_secret.db_password.name
}

output "app_identity_principal_id" {
  description = "App managed identity, for granting any further access it needs."
  value       = azurerm_user_assigned_identity.app.principal_id
}

output "virtual_network_name" {
  description = "VNet shared by the app and the database."
  value       = azurerm_virtual_network.this.name
}
