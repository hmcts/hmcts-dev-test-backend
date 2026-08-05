terraform {
  required_version = ">= 1.9.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # Commented out so validate runs without Azure credentials. CI passes the real
  # values with -backend-config at init time. See the README for how the storage
  # account is set up.
  #
  # backend "azurerm" {
  #   resource_group_name  = "rg-hmcts-tfstate"
  #   storage_account_name = "sthmctstfstate"
  #   container_name       = "tfstate"
  #   key                  = "hmcts-dev-test-backend/prod.terraform.tfstate"
  #   use_azuread_auth     = true
  # }
}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = false
      recover_soft_deleted_key_vaults = true
    }
  }
}
