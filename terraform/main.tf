# Terraform + provider constraints — pin so CI and local runs use compatible versions.
# ~> 3.110 allows 3.110.x patches but not 4.x breaking changes.
terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }

  # Remote state in Azure Blob Storage — shared source of truth + blob-lease locking for concurrent applies.
  # Replace storage_account_name with a real, globally unique account.
  backend "azurerm" {
    resource_group_name  = "rg-tfstate"
    storage_account_name = "<globally-unique-storage-account>"
    container_name       = "tfstate"
    key                  = "dev-test-backend/production.tfstate"
  }
}

provider "azurerm" {
  features {
    key_vault {
      # Non-prod: purge on destroy for clean teardown. Prod: leave soft-deleted (purge protection).
      purge_soft_delete_on_destroy    = !local.is_production
      recover_soft_deleted_key_vaults = true
    }
  }
}

# Production resource group — parent container for all service resources in this environment.
resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location

  tags = local.tags
}
