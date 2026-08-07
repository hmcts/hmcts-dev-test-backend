output "resource_group" {
  description = "Resource group holding the service."
  value = {
    name     = azurerm_resource_group.case_management.name
    location = azurerm_resource_group.case_management.location
  }
}

output "registry" {
  description = "Container registry the pipeline pushes images to."
  value = {
    name         = azurerm_container_registry.case_management.name
    login_server = azurerm_container_registry.case_management.login_server
  }
}

output "keyvault" {
  description = "Key Vault holding the database credentials."
  value = {
    name = azurerm_key_vault.case_management.name
    uri  = azurerm_key_vault.case_management.vault_uri
  }
}

output "database" {
  description = "PostgreSQL server and the application database."
  value = {
    fqdn = azurerm_postgresql_flexible_server.case_management.fqdn
    name = azurerm_postgresql_flexible_server_database.application.name
  }
}

output "container_app" {
  description = "Container App and the URLs it serves."
  value = {
    name       = azurerm_container_app.api.name
    url        = "https://${azurerm_container_app.api.ingress[0].fqdn}"
    health_url = "https://${azurerm_container_app.api.ingress[0].fqdn}/health/readiness"
  }
}
