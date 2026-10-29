variable "name" {
  type        = string
  description = "Application Gateway name (1-80 chars, letters, numbers, hyphens, periods, underscores)."

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 80 && can(regex("^[a-zA-Z0-9][a-zA-Z0-9._-]*$", var.name))
    error_message = "name must be 1-80 characters starting with a letter or number, containing only letters, numbers, hyphens, periods, or underscores."
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
  description = "Azure region for all resources in this module."
}

variable "subnet_id" {
  type        = string
  description = "Resource ID of the subnet dedicated to Application Gateway. Must have no other resources and a /24 or larger prefix. NSG must allow GatewayManager and AzureLoadBalancer inbound."

  validation {
    condition = can(regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.Network/virtualNetworks/[^/]+/subnets/[^/]+$",
      var.subnet_id
    ))
    error_message = "subnet_id must be a valid subnet resource ID."
  }
}

variable "zones" {
  type        = list(string)
  description = "Availability zones for the public IP and Application Gateway. Must be a subset of [\"1\",\"2\",\"3\"]."
  default     = ["1", "2", "3"]

  validation {
    condition     = length(var.zones) > 0 && alltrue([for z in var.zones : contains(["1", "2", "3"], z)])
    error_message = "zones must be a non-empty list containing only \"1\", \"2\", and/or \"3\"."
  }
}

variable "autoscale_min_capacity" {
  type        = number
  description = "Minimum number of Application Gateway units for autoscaling. Must be >= 0."
  default     = 1

  validation {
    condition     = var.autoscale_min_capacity >= 0
    error_message = "autoscale_min_capacity must be >= 0."
  }
}

variable "autoscale_max_capacity" {
  type        = number
  description = "Maximum number of Application Gateway units for autoscaling. Must be >= 1."
  default     = 10

  validation {
    condition     = var.autoscale_max_capacity >= 1
    error_message = "autoscale_max_capacity must be >= 1."
  }
}

variable "user_assigned_identity_id" {
  type        = string
  description = "Resource ID of the user-assigned managed identity. Used to pull TLS certificates from Key Vault."

  validation {
    condition = can(regex(
      "^/subscriptions/[^/]+/resourceGroups/[^/]+/providers/Microsoft\\.ManagedIdentity/userAssignedIdentities/[^/]+$",
      var.user_assigned_identity_id
    ))
    error_message = "user_assigned_identity_id must be a valid user-assigned managed identity resource ID."
  }
}

variable "backends" {
  type        = map(string)
  description = "Map of backend name to FQDN. App Gateway sends traffic to these FQDNs, which resolve via the private DNS zone linked to the VNet."

  validation {
    condition     = length(var.backends) > 0
    error_message = "backends must contain at least one entry."
  }
}

variable "default_backend" {
  type        = string
  description = "Key from the backends map used for the url_path_map default (unmatched paths). Defaults to 'web'."
  default     = "web"
}

variable "path_rules" {
  type = list(object({
    name    = string
    paths   = list(string)
    backend = string
  }))
  description = "URL path rules applied before the default backend. Each backend must be a key in the backends map."
  default = [
    { name = "api", paths = ["/api/*"], backend = "api" }
  ]
}

variable "health_path" {
  type        = string
  description = "HTTP path used for backend health probes."
  default     = "/health"

  validation {
    condition     = startswith(var.health_path, "/")
    error_message = "health_path must start with /."
  }
}

variable "waf_mode" {
  type        = string
  description = "WAF policy mode. Prevention blocks detected attacks; Detection logs them without blocking. Must be Prevention or Detection."
  default     = "Prevention"

  validation {
    condition     = contains(["Prevention", "Detection"], var.waf_mode)
    error_message = "waf_mode must be Prevention or Detection."
  }
}

variable "tls_certificate_key_vault_secret_id" {
  type        = string
  description = "Key Vault secret ID for the TLS certificate in PFX format. When set, App Gateway listens on HTTPS 443 and redirects HTTP 80 to HTTPS. When empty, a plain HTTP 80 listener is used (demo only - not for production)."
  default     = ""

  validation {
    condition = (
      var.tls_certificate_key_vault_secret_id == "" ||
      can(regex("^https://[a-zA-Z0-9-]+\\.vault\\.azure\\.net/secrets/[^/]+", var.tls_certificate_key_vault_secret_id))
    )
    error_message = "tls_certificate_key_vault_secret_id must be empty or a valid Key Vault secret URI."
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
  description = "Tags applied to all resources in this module."
  default     = {}
}
