resource "azurerm_container_registry" "case_management" {
  name                = local.registry_name
  resource_group_name = azurerm_resource_group.case_management.name
  location            = azurerm_resource_group.case_management.location
  sku                 = var.registry_sku
  tags                = var.tags
}

resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.case_management.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.api.principal_id
}
