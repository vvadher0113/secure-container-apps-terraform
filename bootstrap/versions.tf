terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.11.0"
    }
  }
}

provider "azurerm" {
  subscription_id     = var.subscription_id
  storage_use_azuread = true

  features {}
}
