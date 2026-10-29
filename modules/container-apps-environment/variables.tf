variable "name" {
  type        = string
  description = "Container Apps environment name (1-60 chars, lowercase letters, numbers, hyphens; must start and end with a letter or number)."

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 60 && can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?$", var.name))
    error_message = "name must be 1-60 characters: lowercase letters, numbers, or hyphens; must start and end with a letter or number."
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

variable "infrastructure_subnet_id" {
  type        = string
  description = "Resource ID of the subnet delegated to Microsoft.App/environments. Workload profiles require at least a /27 (32 addresses)."

  validation {
    condition = can(regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$",
      var.infrastructure_subnet_id
    ))
    error_message = "infrastructure_subnet_id must be a valid Azure subnet resource ID."
  }
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Spread environment replicas across availability zones. Requires a region with at least three zones."
  default     = true
}

variable "workload_profiles" {
  type = list(object({
    name                  = string
    workload_profile_type = string
    minimum_count         = optional(number)
    maximum_count         = optional(number)
  }))
  description = "Dedicated workload profiles to add alongside the always-present Consumption profile. Use for containers that need guaranteed CPU and memory."
  default     = []
}

variable "vnet_links" {
  type = list(object({
    name               = string
    virtual_network_id = string
  }))
  description = "VNet links for the environment's private DNS zone. Each entry needs a static name (used as the for_each key so it must be known at plan time) and the VNet resource ID. Include the VNet hosting the environment so internal ingress FQDNs resolve."

  validation {
    condition     = length(var.vnet_links) > 0
    error_message = "At least one VNet link is required."
  }

  validation {
    condition     = length(var.vnet_links) == length(toset([for l in var.vnet_links : l.name]))
    error_message = "Each vnet_links entry must have a unique name."
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
