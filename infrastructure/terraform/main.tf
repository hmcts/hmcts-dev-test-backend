data "azurerm_client_config" "current" {}

locals {
  common_tags = {
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "Terraform"
  }
}

# Base Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.project_name}-${var.environment}-${var.location_short}-rg"
  location = var.location
  tags     = local.common_tags
}

# User-Assigned Identity
resource "azurerm_user_assigned_identity" "app_identity" {
  name                = "${var.project_name}-${var.environment}-${var.location_short}-id"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.common_tags
}
