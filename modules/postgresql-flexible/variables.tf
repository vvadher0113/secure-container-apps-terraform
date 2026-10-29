variable "name" {
  type        = string
  description = "Server name. Must be globally unique, 3-63 lowercase letters, numbers, or hyphens; must start with a letter."

  validation {
    condition     = length(var.name) >= 3 && length(var.name) <= 63 && can(regex("^[a-z][a-z0-9-]{1,61}[a-z0-9]$", var.name))
    error_message = "name must be 3-63 characters: lowercase letters, numbers, or hyphens; must start with a letter and end with a letter or number."
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

variable "tenant_id" {
  type        = string
  description = "Azure Active Directory tenant ID used for Entra authentication."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid lowercase UUID."
  }
}

variable "entra_admin" {
  type = object({
    object_id      = string
    principal_name = string
    principal_type = string
  })
  description = "Entra ID identity to set as the PostgreSQL Entra administrator. principal_type must be ServicePrincipal, User, or Group."

  validation {
    condition     = contains(["ServicePrincipal", "User", "Group"], var.entra_admin.principal_type)
    error_message = "entra_admin.principal_type must be ServicePrincipal, User, or Group."
  }
}

variable "pg_version" {
  type        = string
  description = "PostgreSQL major version."
  default     = "16"

  validation {
    condition     = contains(["11", "12", "13", "14", "15", "16"], var.pg_version)
    error_message = "pg_version must be one of: 11, 12, 13, 14, 15, 16."
  }
}

variable "sku_name" {
  type        = string
  description = "Server SKU. Must begin with B_ (Burstable), GP_ (General Purpose), or MO_ (Memory Optimized), e.g. GP_Standard_D2s_v3."
  default     = "GP_Standard_D2s_v3"

  validation {
    condition     = can(regex("^(B|GP|MO)_", var.sku_name))
    error_message = "sku_name must start with B_, GP_, or MO_ for Burstable, General Purpose, or Memory Optimized tier."
  }
}

variable "storage_mb" {
  type        = number
  description = "Storage size in MiB. Minimum 32768 (32 GiB). Must be a supported increment (32, 64, 128, 256, 512 GiB, or 1-16 TiB)."
  default     = 32768

  validation {
    condition     = var.storage_mb >= 32768
    error_message = "storage_mb must be at least 32768 (32 GiB)."
  }
}

variable "backup_retention_days" {
  type        = number
  description = "Days to retain automated backups (7-35)."
  default     = 7

  validation {
    condition     = var.backup_retention_days >= 7 && var.backup_retention_days <= 35
    error_message = "backup_retention_days must be between 7 and 35 inclusive."
  }
}

variable "geo_redundant_backup_enabled" {
  type        = bool
  description = "Replicate backups to a paired region. Not supported with Burstable SKUs."
  default     = false
}

variable "high_availability" {
  type = object({
    standby_availability_zone = optional(string)
  })
  description = "When set, creates a ZoneRedundant standby replica. Not supported with Burstable SKUs. Set standby_availability_zone to pin the standby to a specific zone."
  default     = null
}

variable "zone" {
  type        = string
  description = "Availability zone for the primary server (e.g. \"1\", \"2\", \"3\"). Null lets Azure choose."
  default     = null
}

variable "databases" {
  type = list(object({
    name      = string
    charset   = optional(string, "UTF8")
    collation = optional(string, "en_US.utf8")
  }))
  description = "One or more databases to create on the server. At least one database is required."

  validation {
    condition     = length(var.databases) > 0
    error_message = "At least one database must be specified."
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
  description = "Resource ID of the privatelink.postgres.database.azure.com private DNS zone."

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
