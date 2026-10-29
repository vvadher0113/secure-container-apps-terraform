variable "name" {
  type        = string
  description = "Name of the private endpoint."

  validation {
    condition     = length(var.name) >= 2 && length(var.name) <= 80 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*[a-zA-Z0-9_]$", var.name))
    error_message = "Private endpoint name must be 2-80 characters: letters, numbers, underscores, hyphens, periods; start and end with a letter, number, or underscore."
  }
}

variable "location" {
  type        = string
  description = "Azure region for the private endpoint."

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "resource_group_name" {
  type        = string
  description = "Name of the resource group in which to create the private endpoint."

  validation {
    condition     = can(regex("^[a-zA-Z0-9._()\\-]{1,90}$", var.resource_group_name))
    error_message = "resource_group_name must be 1-90 characters: letters, numbers, periods, underscores, hyphens, or parentheses."
  }
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

variable "target_resource_id" {
  type        = string
  description = "Resource ID of the Azure resource to connect to via the private endpoint."

  validation {
    condition     = can(regex("^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/[^/]+/", var.target_resource_id))
    error_message = "target_resource_id must be a valid Azure resource ID."
  }
}

variable "subresource_names" {
  type        = list(string)
  description = "Subresource names for the private service connection. Supported values in this repo: vault, registry, postgresqlServer, blob, managedEnvironments."

  validation {
    condition     = length(var.subresource_names) == 1
    error_message = "Exactly one subresource name is required per private endpoint."
  }

  validation {
    condition = alltrue([
      for s in var.subresource_names : contains(
        ["vault", "registry", "postgresqlServer", "blob", "managedEnvironments"],
        s
      )
    ])
    error_message = "Each subresource_name must be one of the values used in this repo: vault, registry, postgresqlServer, blob, managedEnvironments."
  }
}

variable "private_dns_zone_ids" {
  type        = list(string)
  description = "Resource IDs of the private DNS zones to associate with the endpoint. At least one is required so DNS resolves the private IP."

  validation {
    condition     = length(var.private_dns_zone_ids) > 0
    error_message = "At least one private_dns_zone_id is required. An endpoint without a DNS zone group cannot resolve by private hostname."
  }

  validation {
    condition = alltrue([
      for id in var.private_dns_zone_ids : can(regex(
        "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/privateDnsZones/",
        id
      ))
    ])
    error_message = "Each entry in private_dns_zone_ids must be a valid Azure private DNS zone resource ID."
  }
}

variable "custom_network_interface_name" {
  type        = string
  description = "Custom name for the network interface attached to the private endpoint. When null, Azure assigns a name automatically."
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "Tags applied to all resources."
  default     = {}
}
