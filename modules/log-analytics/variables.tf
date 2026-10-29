variable "name" {
  type        = string
  description = "Name of the Log Analytics workspace."

  validation {
    condition     = length(var.name) >= 4 && length(var.name) <= 63 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.name))
    error_message = "Workspace name must be 4-63 characters: letters, numbers, hyphens; start and end with a letter or number."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to create the workspace."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()\\-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters: letters, numbers, periods, underscores, hyphens, or parentheses."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the workspace."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "sku" {
  type        = string
  description = "Pricing SKU for the workspace."
  default     = "PerGB2018"

  validation {
    condition = contains(
      ["PerGB2018", "CapacityReservation", "Free", "PerNode", "Premium", "Standard", "Standalone", "Unlimited"],
      var.sku
    )
    error_message = "sku must be one of: PerGB2018, CapacityReservation, Free, PerNode, Premium, Standard, Standalone, Unlimited."
  }
}

variable "retention_in_days" {
  type        = number
  description = "Data retention period in days. Must be between 30 and 730."
  default     = 30

  validation {
    condition     = var.retention_in_days >= 30 && var.retention_in_days <= 730
    error_message = "retention_in_days must be between 30 and 730 inclusive."
  }
}

variable "local_authentication_enabled" {
  type        = bool
  description = "Allow local authentication (shared keys). Defaults to false so only Entra ID authentication is accepted."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
