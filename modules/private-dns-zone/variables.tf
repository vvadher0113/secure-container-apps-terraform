variable "name" {
  type        = string
  description = "Private DNS zone name, e.g. privatelink.postgres.database.azure.com."

  validation {
    condition = (
      length(var.name) >= 3 &&
      length(var.name) <= 253 &&
      can(regex("^[a-zA-Z0-9][a-zA-Z0-9.-]*[a-zA-Z0-9]$", var.name)) &&
      !strcontains(var.name, "..")
    )
    error_message = "name must be a valid DNS zone name: 3-253 characters, valid DNS characters (letters, numbers, hyphens, dots), no consecutive dots."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to create the private DNS zone."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()\\-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters: letters, numbers, periods, underscores, hyphens, or parentheses."
  }
}

variable "vnet_links" {
  type = list(object({
    name                 = string
    virtual_network_id   = string
    registration_enabled = optional(bool, false)
  }))
  description = "VNet links. Each entry creates a virtual network link between the zone and a VNet. registration_enabled defaults to false to prevent automatic DNS record registration."

  validation {
    condition     = length(var.vnet_links) > 0
    error_message = "At least one VNet link is required. A private DNS zone without a VNet link is unreachable from any VNet."
  }

  validation {
    condition     = length(var.vnet_links) == length(toset([for l in var.vnet_links : l.name]))
    error_message = "vnet_links names must be unique."
  }

  validation {
    condition = alltrue([
      for l in var.vnet_links : can(regex(
        "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+$",
        l.virtual_network_id
      ))
    ])
    error_message = "Each virtual_network_id must be a valid Azure VNet resource ID."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
