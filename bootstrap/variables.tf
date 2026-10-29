variable "subscription_id" {
  type        = string
  description = "Azure subscription ID where state storage resources are created."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid lowercase UUID."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the state storage resources, e.g. eastus2."
  default     = "eastus2"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group that holds the state storage account."
  default     = "rg-tfstate-contoso"

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()\\-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters: letters, numbers, periods, underscores, hyphens, or parentheses."
  }
}

variable "storage_account_name" {
  type        = string
  description = "Globally unique storage account name: 3-24 lowercase letters and numbers."

  validation {
    condition     = can(regex("^[a-z0-9]{3,24}$", var.storage_account_name))
    error_message = "storage_account_name must be 3-24 lowercase letters and numbers, no hyphens."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources created by the bootstrap."
  default = {
    managed_by  = "terraform"
    purpose     = "tfstate"
    environment = "shared"
  }
}
