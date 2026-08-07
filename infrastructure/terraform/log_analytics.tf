resource "azurerm_log_analytics_workspace" "case_management" {
  name                = format(local.name, "log")
  resource_group_name = azurerm_resource_group.case_management.name
  location            = azurerm_resource_group.case_management.location
  retention_in_days   = var.log_retention_days
  tags                = var.tags
}
