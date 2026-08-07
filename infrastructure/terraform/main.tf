terraform {
  required_version = "~> 1.15.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.20"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Remote state. Uncomment for a real deployment. See the README.
  # backend "azurerm" {
  #   resource_group_name  = "hmcts-rg-terraform-state-prd-uks"
  #   storage_account_name = "hmctssttfstateprduks"
  #   container_name       = "tfstate"
  #   key                  = "cms/prd.tfstate"
  #   use_azuread_auth     = true
  #   use_oidc             = true
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy = !var.delete_protection_enabled
    }
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_resource_group" "case_management" {
  name     = format(local.name, "rg")
  location = var.location.long
  tags     = var.tags
}
