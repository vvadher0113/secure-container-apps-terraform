terraform {
  required_version = ">= 1.10.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "5.10.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.13.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.9.1"
    }
  }
}

provider "azurerm" {
  subscription_id     = var.subscription_id
  storage_use_azuread = true

  features {}
}

provider "azapi" {
  subscription_id = var.subscription_id
}
