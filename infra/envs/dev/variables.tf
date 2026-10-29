variable "subscription_id" {
  type        = string
  description = "Azure subscription ID."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.subscription_id))
    error_message = "subscription_id must be a valid lowercase UUID."
  }
}

variable "tenant_id" {
  type        = string
  description = "Azure Active Directory tenant ID. Used for Entra authentication on Key Vault and PostgreSQL."

  validation {
    condition     = can(regex("^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$", var.tenant_id))
    error_message = "tenant_id must be a valid lowercase UUID."
  }
}

variable "location" {
  type        = string
  description = "Azure region for all resources, e.g. eastus2."
  default     = "eastus2"

  validation {
    condition     = length(trimspace(var.location)) > 0
    error_message = "location must not be empty."
  }
}

variable "app_name" {
  type        = string
  description = "Short application name used in resource naming. 3-14 lowercase letters, numbers, and hyphens."
  default     = "goals"

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,12}[a-z0-9]$", var.app_name))
    error_message = "app_name must be 3-14 characters: start with a letter, end with a letter or number, and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  type        = string
  description = "Deployment environment: dev, test, or prod."
  default     = "dev"

  validation {
    condition     = contains(["dev", "test", "prod"], var.environment)
    error_message = "environment must be one of: dev, test, prod."
  }
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the virtual network. Must be a valid RFC1918 CIDR range."
  default     = ["10.20.0.0/22"]

  validation {
    condition     = alltrue([for cidr in var.vnet_address_space : can(cidrhost(cidr, 0))])
    error_message = "All entries in vnet_address_space must be valid CIDR blocks."
  }
}

variable "app_images" {
  type = object({
    web     = optional(string, "mcr.microsoft.com/k8se/quickstart:latest")
    api     = optional(string, "mcr.microsoft.com/k8se/quickstart:latest")
    migrate = optional(string, "mcr.microsoft.com/k8se/quickstart:latest")
  })
  description = "Container image references for each app component. Defaults to the Azure quickstart image for first-deploy; set to real ACR images after build-push runs."
  default     = {}
}

variable "zone_redundancy_enabled" {
  type        = bool
  description = "Enable zone redundancy for ACR and the Container Apps environment. Disable for dev to reduce cost."
  default     = false
}

variable "pg_sku_name" {
  type        = string
  description = "PostgreSQL Flexible Server SKU. Burstable B_ tiers are cheapest; General Purpose GP_ tiers are needed for HA and production load."
  default     = "B_Standard_B1ms"

  validation {
    condition     = can(regex("^(B|GP|MO)_", var.pg_sku_name))
    error_message = "pg_sku_name must start with B_, GP_, or MO_."
  }
}

variable "pg_backup_retention_days" {
  type        = number
  description = "Days to retain automated PostgreSQL backups (7-35)."
  default     = 7

  validation {
    condition     = var.pg_backup_retention_days >= 7 && var.pg_backup_retention_days <= 35
    error_message = "pg_backup_retention_days must be between 7 and 35."
  }
}

variable "pg_database_name" {
  type        = string
  description = "Name of the application database to create on the PostgreSQL server."
  default     = "appdb"
}

variable "kv_soft_delete_retention_days" {
  type        = number
  description = "Days to retain soft-deleted Key Vault objects (7-90). Lower values speed up teardown in dev."
  default     = 7

  validation {
    condition     = var.kv_soft_delete_retention_days >= 7 && var.kv_soft_delete_retention_days <= 90
    error_message = "kv_soft_delete_retention_days must be between 7 and 90."
  }
}

variable "log_analytics_retention_in_days" {
  type        = number
  description = "Log Analytics data retention in days (30-730)."
  default     = 30

  validation {
    condition     = var.log_analytics_retention_in_days >= 30 && var.log_analytics_retention_in_days <= 730
    error_message = "log_analytics_retention_in_days must be between 30 and 730."
  }
}

variable "agw_autoscale_min_capacity" {
  type        = number
  description = "App Gateway minimum autoscale capacity. Set to 0 to allow scale-to-zero in dev (cold start delay applies)."
  default     = 1

  validation {
    condition     = var.agw_autoscale_min_capacity >= 0
    error_message = "agw_autoscale_min_capacity must be >= 0."
  }
}

variable "agw_autoscale_max_capacity" {
  type        = number
  description = "App Gateway maximum autoscale capacity."
  default     = 2

  validation {
    condition     = var.agw_autoscale_max_capacity >= 1
    error_message = "agw_autoscale_max_capacity must be >= 1."
  }
}

variable "tls_certificate_key_vault_secret_id" {
  type        = string
  description = "Key Vault versioned secret ID for the App Gateway TLS certificate. Leave empty to use an HTTP listener (not for production)."
  default     = ""
}
