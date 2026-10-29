variable "name" {
  type        = string
  description = "Name of the virtual network."

  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 64 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9_]$", var.name))
    error_message = "VNet name must be 2-64 characters: letters, numbers, underscores, periods, hyphens; start and end with a letter, number, or underscore."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to create the network resources."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()\\-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters: letters, numbers, periods, underscores, hyphens, or parentheses."
  }
}

variable "location" {
  type        = string
  description = "Azure region for all network resources."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "address_space" {
  type        = list(string)
  description = "One or more CIDR blocks for the VNet address space."

  validation {
    condition     = length(var.address_space) > 0
    error_message = "address_space must contain at least one CIDR block."
  }

  validation {
    condition     = alltrue([for cidr in var.address_space : can(cidrhost(cidr, 0))])
    error_message = "Every entry in address_space must be valid CIDR notation."
  }
}

variable "subnets" {
  type = list(object({
    name                              = string
    address_prefix                    = string
    private_endpoint_network_policies = optional(string, "Enabled")
    delegation = optional(object({
      service = string
      actions = optional(list(string), null)
    }), null)
    nsg_rules = optional(list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    })), [])
    nsg_enabled = optional(bool, true)
  }))
  description = "Subnets to create. Each subnet receives its own NSG; set nsg_enabled = false only for Azure-reserved subnet names that reject NSG associations."

  validation {
    condition     = length(var.subnets) > 0
    error_message = "At least one subnet must be provided."
  }

  validation {
    condition     = length(var.subnets) == length(toset([for s in var.subnets : s.name]))
    error_message = "Subnet names must be unique within the VNet."
  }

  validation {
    condition     = alltrue([for s in var.subnets : can(cidrhost(s.address_prefix, 0))])
    error_message = "Every subnet address_prefix must be valid CIDR notation."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : contains(
        ["Disabled", "Enabled", "NetworkSecurityGroupEnabled", "RouteTableEnabled"],
        s.private_endpoint_network_policies
      )
    ])
    error_message = "private_endpoint_network_policies must be Disabled, Enabled, NetworkSecurityGroupEnabled, or RouteTableEnabled."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.subnets : [
        for r in s.nsg_rules : contains(["Inbound", "Outbound"], r.direction)
      ]
    ]))
    error_message = "NSG rule direction must be Inbound or Outbound."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.subnets : [
        for r in s.nsg_rules : contains(["Allow", "Deny"], r.access)
      ]
    ]))
    error_message = "NSG rule access must be Allow or Deny."
  }

  validation {
    condition = alltrue(flatten([
      for s in var.subnets : [
        for r in s.nsg_rules : (r.priority >= 100 && r.priority <= 4096)
      ]
    ]))
    error_message = "NSG rule priority must be between 100 and 4096 inclusive."
  }

  validation {
    condition = alltrue([
      for s in var.subnets : s.nsg_enabled || contains(
        ["GatewaySubnet", "AzureFirewallSubnet", "AzureFirewallManagementSubnet", "RouteServerSubnet"],
        s.name
      )
    ])
    error_message = "nsg_enabled may only be false for Azure-reserved subnet names that reject NSG associations: GatewaySubnet, AzureFirewallSubnet, AzureFirewallManagementSubnet, RouteServerSubnet."
  }
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
