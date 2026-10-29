variable "name" {
  type        = string
  description = "Container registry name. Must be globally unique, 5-50 alphanumeric characters."

  validation {
    condition     = length(var.name) >= 5 && length(var.name) <= 50 && can(regex("^[a-zA-Z0-9]+$", var.name))
    error_message = "name must be 5-50 alphanumeric characters with no hyphens or underscores."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()\\-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters: letters, numbers, periods, underscores, hyphens, or parentheses."
  }
}

variable "location" {
  type        = string
  description = "Azure region."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Enable zone redundancy. Requires Premium SKU and a region with availability zones."
  default     = true
}

variable "retention_days" {
  type        = number
  description = "Days to retain untagged manifests before automatic deletion (1-365). Defaults to 7."
  default     = 7

  validation {
    condition     = var.retention_days >= 1 && var.retention_days <= 365
    error_message = "retention_days must be between 1 and 365 inclusive."
  }
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet for the private endpoint."

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
  description = "Resource ID of the privatelink.azurecr.io private DNS zone."

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
