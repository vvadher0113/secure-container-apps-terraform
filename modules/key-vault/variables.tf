variable "name" {
  type        = string
  description = "Name of the Key Vault. Must be globally unique."

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 24 && can(regex("^[a-zA-Z][a-zA-Z0-9-]{1,22}[a-zA-Z0-9]$", var.name))
    error_message = "Key Vault name must be 3-24 characters: letters, numbers, hyphens; must start with a letter and end with a letter or number."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to create the Key Vault."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()\\-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters: letters, numbers, periods, underscores, hyphens, or parentheses."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the Key Vault."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "tenant_id" {
  type        = string
  description = "Azure Active Directory tenant ID."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid lowercase UUID."
  }
}

variable "sku_name" {
  type        = string
  description = "SKU for the Key Vault. Use premium only when HSM-backed keys are required."
  default     = "standard"

  validation {
    condition     = contains(["standard", "premium"], var.sku_name)
    error_message = "sku_name must be standard or premium."
  }
}

variable "purge_protection_enabled" {
  type        = bool
  description = "Protect against immediate permanent deletion. Must be true for production vaults. Requires soft delete to be active."
  default     = true
}

variable "soft_delete_retention_days" {
  type        = number
  description = "Days to retain deleted vault objects (7-90). Defaults to the maximum of 90."
  default     = 90

  validation {
    condition     = var.soft_delete_retention_days >= 7 && var.soft_delete_retention_days <= 90
    error_message = "soft_delete_retention_days must be between 7 and 90 inclusive."
  }
}

variable "public_network_access_enabled" {
  type        = bool
  description = "Allow access from public networks. Defaults to false; the vault is reachable only via its private endpoint."
  default     = false
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet in which to place the private endpoint."

  validation {
    condition = can(regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$",
      var.subnet_id
    ))
    error_message = "subnet_id must be a valid Azure subnet resource ID."
  }
}

variable "private_dns_zone_id" {
  type        = string
  description = "Resource ID of the privatelink.vaultcore.azure.net private DNS zone."

  validation {
    condition = can(regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/privateDnsZones/",
      var.private_dns_zone_id
    ))
    error_message = "private_dns_zone_id must be a valid Azure private DNS zone resource ID."
  }
}

variable "log_analytics_workspace_id" {
  type        = string
  description = "Resource ID of the Log Analytics workspace for diagnostic settings. Required when diagnostics_enabled is true."
  default     = ""

  validation {
    condition = (
      var.log_analytics_workspace_id == "" ||
      can(regex(
        "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.OperationalInsights/workspaces/[^/]+$",
        var.log_analytics_workspace_id
      ))
    )
    error_message = "log_analytics_workspace_id must be empty or a valid Log Analytics workspace resource ID."
  }
}

variable "diagnostics_enabled" {
  type        = bool
  description = "When true, create a diagnostic setting that sends logs to log_analytics_workspace_id. Requires log_analytics_workspace_id to be non-empty."
  default     = false
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
